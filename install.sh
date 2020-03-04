#!/bin/bash

# Must be run as root
[[ $EUID > 0 ]] && echo "Error: must run as root/su" && exit 1

USB_DEVICE_NAME="/dev/sda1"
USB_DEVICE_MOUNT_DIR="/mnt/ddd"
DEVICE_NAME="/dev/nvme0n1"
CLOUD_CONFIG_FILE_PATH="${USB_DEVICE_MOUNT_DIR}/cloud-config.yml"

P1_DIR="/tmp/d"

echo
echo "Formatting device ${DEVICE_NAME}"
echo "  (ignore any warnings about 'y' command)"
fdisk ${DEVICE_NAME} <<EOF
g
n
1

+2G
y
t
1
n
2


y
p
w
EOF

echo
echo "Formatting EFI partition"
mkdosfs -n RANCHER -F 32 ${DEVICE_NAME}p1
echo "Mounting EFI partition"
mkdir "${P1_DIR}"
mount -t vfat ${DEVICE_NAME}p1 "${P1_DIR}"

echo
echo "Mounting USB device"
mkdir "${USB_DEVICE_MOUNT_DIR}"
mount ${USB_DEVICE_NAME} "${USB_DEVICE_MOUNT_DIR}"

echo
echo "Copying EFI boot files"
cp "${USB_DEVICE_MOUNT_DIR}/boot" "${P1_DIR}" -r
cp "${USB_DEVICE_MOUNT_DIR}/EFI" "${P1_DIR}" -r

echo
echo "Creating ext4 filesystem on p2"
mkfs.ext4 -F -i 4096 -O 64bit -L RANCHER_STATE ${DEVICE_NAME}p2
mkdir /dev/sr0

echo
echo "Installing RancherOS"
ros install \
    -t gptsyslinux \
    -c "${CLOUD_CONFIG_FILE_PATH}" \
    -d ${DEVICE_NAME} \
    -p ${DEVICE_NAME}p2 \
    --force \
    --no-reboot
# ros install -t gptsyslinux -c "${CLOUD_CONFIG_FILE_PATH}" -d ${DEVICE_NAME} -p ${DEVICE_NAME}p2 <<EOF
# y
# n
# EOF

# If accidentally rebooted run the following:
# mkdir /mnt/large
# mount -t ext4 ${DEVICE_NAME}p2 /mnt/large
# mkdir /tmp/d
# mount -t vfat ${DEVICE_NAME}p1 /tmp/d

echo
echo "Modifying grub config"

CURRENT_KERNEL_FILE="$(grep -i -E "vmlinuz" ${P1_DIR}/boot/linux-current.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
CURRENT_INITRD_FILE="$(grep -i -E "initrd" ${P1_DIR}/boot/linux-current.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
CURRENT_VERSION="$(echo ${CURRENT_INITRD_FILE} | cut -d'-' -f2)"

GRUB_CFG_PATH="${P1_DIR}/boot/grub/grub.cfg"

rm ${GRUB_CFG_PATH}
cat >> ${GRUB_CFG_PATH} <<EOF
set timeout=5

menuentry "Rancher $CURRENT_VERSION from GPT" {
        search --no-floppy --set=root --label RANCHER_STATE
    linux    /boot/$CURRENT_KERNEL_FILE printk.devkmsg=on rancher.state.dev=LABEL=RANCHER_STATE rancher.state.wait panic=10 console=tty0
    initrd   /boot/$CURRENT_INITRD_FILE
}

menuentry "Install Rancher" {
    linux    /boot/$CURRENT_KERNEL_FILE rancher.autologin=tty1 rancher.autologin=ttyS0 rancher.autologin=ttyS1 console=tty1 console=ttyS0 console=ttyS1 printk.devkmsg=on panic=10 ---
    initrd   /boot/$CURRENT_INITRD_FILE
}
EOF

echo
echo "Installation (should be) complete, remove USB installation device and reboot."