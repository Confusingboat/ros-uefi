#!/bin/bash

# Must be run as root
[[ $EUID > 0 ]] && echo "Error: must run as root/su" && exit 1

DEVICE_NAME="/dev/nvme0n1"
P1_DIR="/mnt/p1"
P2_DIR="/mnt/p2"

# Mount partitions
echo
echo "Mounting partitions"
mkdir "${P1_DIR}"
mkdir "${P2_DIR}"
mount "${DEVICE_NAME}p1" "${P1_DIR}"
mount "${DEVICE_NAME}p2" "${P2_DIR}"

# Run the upgrade
echo
echo "Upgrading Rancher OS"
ros os upgrade --force --no-reboot

# Copy kernels and initrds
echo
echo "Copying OS files"
find "${P2_DIR}/boot" | grep -i -E "initrd|linuz" | xargs -I '{}' cp '{}' "${P1_DIR}/boot"

echo
echo "Gathering current and previous files and versions"
CURRENT_KERNEL_FILE="$(grep -i -E "vmlinuz" ${P2_DIR}/boot/linux-current.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
CURRENT_INITRD_FILE="$(grep -i -E "initrd" ${P2_DIR}/boot/linux-current.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
CURRENT_VERSION="$(echo ${CURRENT_INITRD_FILE} | cut -d'-' -f2)"

PREVIOUS_KERNEL_FILE="$(grep -i -E "vmlinuz" ${P2_DIR}/boot/linux-previous.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
PREVIOUS_INITRD_FILE="$(grep -i -E "initrd" ${P2_DIR}/boot/linux-previous.cfg | cut -d'/' -f2 | sed -e 's/\r//g')"
PREVIOUS_VERSION="$(echo ${PREVIOUS_INITRD_FILE} | cut -d'-' -f2)"

GRUB_CFG_PATH="${P1_DIR}/boot/grub/grub.cfg"
echo
echo "Modifying grub config"

if [ -f "${GRUB_CFG_PATH}" ]; then
    mv "${GRUB_CFG_PATH}" "${GRUB_CFG_PATH}.bak"
fi
cat >> "${GRUB_CFG_PATH}" <<EOF
set timeout=5

menuentry "Rancher $CURRENT_VERSION from GPT" {
        search --no-floppy --set=root --label RANCHER_STATE
    linux    /boot/$CURRENT_KERNEL_FILE printk.devkmsg=on rancher.state.dev=LABEL=RANCHER_STATE rancher.state.wait panic=10 console=tty0
    initrd   /boot/$CURRENT_INITRD_FILE
}

menuentry "Previous Rancher from GPT ($PREVIOUS_VERSION)" {
        search --no-floppy --set=root --label RANCHER_STATE
    linux    /boot/$PREVIOUS_KERNEL_FILE printk.devkmsg=on rancher.state.dev=LABEL=RANCHER_STATE rancher.state.wait panic=10 console=tty0
    initrd   /boot/$PREVIOUS_INITRD_FILE
}

menuentry "Install Rancher" {
    linux    /boot/$CURRENT_KERNEL_FILE rancher.autologin=tty1 rancher.autologin=ttyS0 rancher.autologin=ttyS1 console=tty1 console=ttyS0 console=ttyS1 printk.devkmsg=on panic=10 ---
    initrd   /boot/$CURRENT_INITRD_FILE
}
EOF