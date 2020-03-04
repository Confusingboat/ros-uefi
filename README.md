# ROS UEFI
### Scripts for installing and upgrading Rancher OS on a UEFI system

`make-uefi.sh` was tested in WSL Debian

`install.sh` was tested with Rancher OS 1.5.4 ISO

`upgrade.sh` was tested with Rancher OS 1.5.5 default console

Installation target was an Odroid H2 SBC with an NVMe M.2 drive.
<br />
<br />

### `> make-uefi.sh`

#### This script prepares the directories and files necessary to create a UEFI-bootable USB installer for Rancher OS.

**1. Set** (optional)

`ROS_ISO_URL` to the URL of the Rancher OS ISO you'd like to install, or drop your own `rancheros.iso` file adjacent to the script.

**2. Run** `sudo ./make-uefi.sh` and it will spit out a `tmp` directory adjacent to the script.

**3. Copy** the `./tmp/iso` subdirectory contents to a FAT32-formatted USB drive that you will boot to and install Rancher OS from.
<br />
<br />
<br />

### `> install.sh`

#### This script installs Rancher OS from the prepared USB installer.

**1. Copy** the `install.sh` script to your USB installer drive.

**2. Set**

`DEVICE_NAME` to the name of the device you'll be installing Rancher OS to.

`USB_DEVICE_NAME` to the name of the USB device you'll be booting from.

`CLOUD_CONFIG_FILE_PATH` to the path or URL where your cloud config is located, or leave it as is and drop a `cloud-config.yml` adjacent to the `install.sh` script.

**3. Run**

Once live inside the Rancher OS install image, make sure the device you're installing to is free of any partitions and then mount it and run `sudo ./install.sh`.
<br />
<br />
<br />

### `> upgrade.sh`

#### This script will upgrade an existing Rancher OS installation that was installed using this method to the latest version.

**1. Copy** the `upgrade.sh` script to your Rancher OS installation. I just drop it in the home directory.

**2. Set**

`DEVICE_NAME` to the name of the device Rancher OS is installed to.

**3. Run** `sudo ./upgrade.sh`
