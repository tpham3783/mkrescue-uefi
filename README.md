# mkrescue-uefi
Creates a custom BOOTX64.EFI from a linux kernel, initrd and kernel cmdline

Lately Kay Sievers and David Herrmann created a UEFI loader stub, which starts a linux kernel with an initrd and a kernel command line, which are COFF sections of the executable. This enables us to create single UEFI executable with a standard distribution kernel, a custom initrd and our own kernel command line attached.

Of course booting a linux kernel directly from the UEFI has been possible before with the kernel EFI stub. But to add an initrd and kernel command line, this had to be specified at kernel compile time.

To run the script, you have to install gummiboot >= 46 and binutils.
```
# yum install gummiboot binutils
```

Run the script:
```
# bash create-linux-uefi-boot.sh <kernel> <initrd> <kernel_param> BOOTX64.EFI
# ie: ./create-linux-uefi-boot.sh /boot/vmlinuz-4.4.0-64-generic /boot/initrd.img-4.4.0-64-generic "root=ZFS=portable/rootfs boot=zfs" /tmp/bootx64.efi 
```

Copy BOOTX64.EFI to e.g. a USB stick to EFI/BOOT/BOOTX64.EFI in the FAT boot partition and point your BIOS to boot from the USB stick.

