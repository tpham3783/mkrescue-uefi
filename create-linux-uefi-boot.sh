#!/bin/bash
# Author:  Toan Pham (modified from a gummiboot project)
# Purpose: Repackage linux to boot directly from UEFI supported BIOS.
#          In other words, this script converts linux kernel, initrd image,
#          and custom kernel param to a signal bootx64.efi executable,
#          which can then be used to boot directly from UEFI compatible Bioses.
#################################################################################

set -e

if ! [[ $1 ]]; then
    echo "Usage: $0 <input kernel> <input initrd> <custom kernel param> <output efi file>" >&2
	echo "ie: ./$0 /boot/vmlinuz-4.4.0-64-generic /boot/initrd.img-4.4.0-64-generic \"root=ZFS=portable/rootfs boot=zfs\" /tmp/bootx64.efi"
	echo ""
	echo " To support zfs boot, make sure you install zfs-initramfs package, then run this command to repackage initrd"
	echo "     update-initramfs -k 4.4.0-64-generic -u -v"
	echo " and then run this command to generate a efi executable:"
	echo "     $0 /boot/vmlinuz-4.4.0-64-generic /boot/initrd.img-4.4.0-64-generic \"root=ZFS=portable/rootfs boot=zfs\" /tmp/bootx64.efi"
	echo " Note: Please not that CONFIG_EFI_STUB=y must be enabled in the kernel to be able to boot linux from UEFI."
    exit 1
fi

if [[ -f /etc/machine-id ]]; then
    read MACHINE_ID < /etc/machine-id
fi

if ! [[ $MACHINE_ID ]]; then
    echo "Could not determine your machine ID from /etc/machine-id." >&2
    echo "Please run 'systemd-machine-id-setup' as root. See man:machine-id(5)" >&2
    exit 1
fi

if [[ -d /boot/${MACHINE_ID}/0-rescue ]]; then
    KERNEL="/boot/${MACHINE_ID}/0-rescue/linux"
    INITRD="/boot/${MACHINE_ID}/0-rescue/initrd"
else
    KERNEL="/tmp/vmlinuz-${MACHINE_ID}"
    INITRD="/tmp/initrd-${MACHINE_ID}.img"
	install $1 $KERNEL
	install $2 $INITRD
fi

if ! [[ -f $KERNEL ]] || ! [[ -f $INITRD ]]; then
    [[ -f $KERNEL ]] || echo "Could not find $KERNEL" >&2
    [[ -f $INITRD ]] || echo "Could not find $INITRD" >&2
    exit 1
fi

trap '
    ret=$?;
	[[ $CMDLINE_DIR ]] && rm -rf -- "$CMDLINE_DIR";
    exit $ret;
    ' EXIT

[[ $CMDLINE_DIR ]] && rm -rf -- "$CMDLINE_DIR";
readonly CMDLINE_DIR="$(mktemp -d -t cmdline.XXXXXX)"
#CMDLINE_DIR="$(mktemp -t cmdline.XXXXXX)"

echo -ne "$3\x00" > "$CMDLINE_DIR/cmdline.txt"

EFI_EXE_STUB=/usr/lib/gummiboot/linuxx64.efi.stub
if [ ! -f $EFI_EXE_STUB ]; then
	echo "Missing gummiboot dependency, please install it."
	echo "On ubuntu, you can run apt install gummiboot to install it"
	EFI_EXE_STUB=resources/gummiboot/linuxx64.efi.stub
fi

objcopy -v\
    --update-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
    --update-section .linux="$KERNEL" --change-section-vma .linux=0x40000 \
    --update-section .initrd="$INITRD" --change-section-vma .initrd=0x3000000 \
    --update-section .cmdline="$CMDLINE_DIR/cmdline.txt" --change-section-vma .cmdline=0x30000 \
    $EFI_EXE_STUB "$4"


echo "--------------------------------------------------------------------------------------"
echo "Succesfully created '$4'"
echo "   input kernel: $1"
echo "   input initrd: $2"
echo "   input kernel param: $(< $CMDLINE_DIR/cmdline.txt)"
echo "Now copy '$4' to <efi_boot_drive>/EFI/BOOT/BOOTX64.EFI, and then"
echo "point your BIOS to boot from the drive"
