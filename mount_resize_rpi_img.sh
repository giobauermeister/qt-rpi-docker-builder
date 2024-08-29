#!/bin/bash

# Define the image file and mount point
IMG_FILE="2024-07-04-raspios-bookworm-arm64-lite.img"
MOUNT_POINT="/mnt/rpi-sysroot"
START_OFFSET=1056768  # Adjust this value based on the output of `fdisk -l`
# Calculate the offset in bytes
OFFSET=$((START_OFFSET * 512))


# Download Raspbian OS Lite 64Bit

wget -O /home/qtpi/2024-07-04-raspios-bookworm-arm64-lite.img.xz https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-07-04/2024-07-04-raspios-bookworm-arm64-lite.img.xz


xz -d /home/qtpi/$IMG_FILE.xz
truncate -s +2G /home/qtpi/$IMG_FILE
parted -s $IMG_FILE resizepart 2 100%

# Mount the partition using the calculated offset
sudo mount -o loop,offset=$OFFSET /home/qtpi/$IMG_FILE $MOUNT_POINT

# List the contents of the mounted directory
ls -l $MOUNT_POINT

# Find the loop device associated with the mounted partition
LOOP_DEVICE=$(lsblk -o NAME,MOUNTPOINT | grep "$MOUNT_POINT" | awk '{print $1}')

# Check if the loop device was found
if [ -z "$LOOP_DEVICE" ]; then
    echo "Error: Could not find the loop device for the mounted partition."
    exit 1
fi

# Resize the filesystem on the loop device
sudo resize2fs /dev/$LOOP_DEVICE

# Output the result
echo "The filesystem on /dev/$LOOP_DEVICE has been resized."
