#!/bin/bash

# Must be run as root
[[ $EUID > 0 ]] && echo "Error: must run as root/su" && exit 1

apt update
apt install wget p7zip-full -y

UB_ISO_URL="http://releases.ubuntu.com/18.04.4/ubuntu-18.04.4-live-server-amd64.iso"
UB_ISO_FILE_NAME="ubuntu.iso"
ROS_ISO_URL="https://github.com/rancher/os/releases/download/v1.5.5/rancheros.iso"
ROS_ISO_FILE_NAME="rancheros.iso"
DOWNLOAD_DIR="."
TEMP_DIR="./tmp"
ISO_DIR_NAME="iso"

# Rebuild temp dir
rm -rf ${TEMP_DIR}
mkdir ${TEMP_DIR}

# Download the ubuntu iso if not already downloaded
UB_ISO_FILE_PATH="${DOWNLOAD_DIR}/${UB_ISO_FILE_NAME}"
if [ ! -f "${UB_ISO_FILE_PATH}" ]; then
    wget ${UB_ISO_URL} -O "${UB_ISO_FILE_PATH}"
fi

# Download the ros iso if not already downloaded
ROS_ISO_FILE_PATH="${DOWNLOAD_DIR}/${ROS_ISO_FILE_NAME}"
if [ ! -f "${ROS_ISO_FILE_PATH}" ]; then
    wget ${ROS_ISO_URL} -O "${ROS_ISO_FILE_PATH}"
fi

if [ ! -f "${UB_ISO_FILE_PATH}" ] || [ ! -f "${ROS_ISO_FILE_PATH}" ]; then
    echo "Missing iso file. Exiting." && exit 1
fi

# Extract files
UB_ISO_DIR_PATH="${TEMP_DIR}/ub"
7z x "${UB_ISO_FILE_PATH}" -o"${UB_ISO_DIR_PATH}"
ISO_DIR_PATH="${TEMP_DIR}/${ISO_DIR_NAME}"
7z x "${ROS_ISO_FILE_PATH}" -o"${ISO_DIR_PATH}"

# Copy efi
ISO_EFI_DIR_PATH="${ISO_DIR_PATH}/EFI"
cp "${UB_ISO_DIR_PATH}/EFI" "${ISO_EFI_DIR_PATH}" -r

# Copy grub
ISO_GRUB_DIR_PATH="${ISO_DIR_PATH}/boot/grub"
cp "${UB_ISO_DIR_PATH}/boot/grub" "${ISO_GRUB_DIR_PATH}" -r

# Find
CURRENT_KERNEL_FILE="$(grep -i -E "vmlinuz" ${ISO_DIR_PATH}/boot/linux-current.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
CURRENT_INITRD_FILE="$(grep -i -E "initrd" ${ISO_DIR_PATH}/boot/linux-current.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
CURRENT_VERSION="$(echo ${CURRENT_INITRD_FILE} | cut -d'-' -f2)"

GRUB_CFG_PATH="${ISO_DIR_PATH}/boot/grub/grub.cfg"
rm ${GRUB_CFG_PATH}
cat >> ${GRUB_CFG_PATH} <<EOF
set timeout=5
menuentry "Install Rancher $CURRENT_VERSION" {
    linux	/boot/$CURRENT_KERNEL_FILE rancher.autologin=tty1 rancher.autologin=ttyS0 rancher.autologin=ttyS1 console=tty1 console=ttyS0 console=ttyS1 printk.devkmsg=on panic=10 ---
    initrd	/boot/$CURRENT_INITRD_FILE
}
EOF