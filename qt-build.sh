#!/bin/bash

echo "Starting RPi image customization!"

# Define the image file and mount point
RPI_IMAGE="$HOME/2024-07-04-raspios-bookworm-arm64-lite.img"
MOUNT_POINT="$HOME/rpi-sysroot"
START_OFFSET=1056768  # Adjust this value based on the output of `fdisk -l`
# Calculate the offset in bytes
OFFSET=$((START_OFFSET * 512))

mkdir $HOME/qt-build/qt-raspi $HOME/qt-build/qt-host $HOME/qt-pibuild $HOME/qt-hostbuild

echo "Truncating image +2G"
truncate -s +2G $RPI_IMAGE

echo "Resizing image"
parted -s $RPI_IMAGE resizepart 2 100%

mkdir -p $MOUNT_POINT

LOOP_DEVICE=$(losetup -j $RPI_IMAGE | awk -F: '{print $1}')
# Check if there is already a loop device
if [ -n "$LOOP_DEVICE" ]; then
    echo "Loop device already found"
    sudo losetup -d $LOOP_DEVICE
fi

# Mount the partition using the calculated offset
echo "sudo mount -o loop,offset=$OFFSET $RPI_IMAGE $MOUNT_POINT"
sudo mount -o loop,offset=$OFFSET $RPI_IMAGE $MOUNT_POINT

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

sudo mount -o bind /dev $MOUNT_POINT/dev
sudo mount -o bind /proc $MOUNT_POINT/proc
sudo mount -o bind /sys $MOUNT_POINT/sys
sudo mount -o bind /dev/pts $MOUNT_POINT/dev/pts

sudo cp /usr/bin/qemu-arm-static $MOUNT_POINT/bin

sudo chroot $MOUNT_POINT /bin/bash -c "apt update"
sudo chroot $MOUNT_POINT /bin/bash -c "apt install -y locales && locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 && dpkg-reconfigure --frontend=noninteractive locales"
sudo chroot $MOUNT_POINT /bin/bash -c "apt install -y xinput-calibrator evtest libts-bin libboost-all-dev libudev-dev libinput-dev libts-dev libmtdev-dev libjpeg-dev libfontconfig1-dev libssl-dev libdbus-1-dev libglib2.0-dev libxkbcommon-dev libegl1-mesa-dev libgbm-dev libgles2-mesa-dev mesa-common-dev libasound2-dev libpulse-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev  gstreamer1.0-alsa libvpx-dev libsrtp2-dev libsnappy-dev libnss3-dev "^libxcb.*" flex bison libxslt-dev ruby gperf libbz2-dev libcups2-dev libatkmm-1.6-dev libxi6 libxcomposite1 libfreetype6-dev libicu-dev libsqlite3-dev libxslt1-dev libavcodec-dev libavformat-dev libswscale-dev libx11-dev freetds-dev libpq-dev libiodbc2-dev firebird-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libxcb-xinerama0 libxcb-xinerama0-dev libatspi2.0-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxss-dev libxtst-dev libpci-dev libcap-dev libxrandr-dev libdirectfb-dev libaudio-dev libxkbcommon-x11-dev libvulkan-dev vulkan-tools mesa-vulkan-drivers libbluetooth-dev bluez bluez-tools"
sudo chroot $MOUNT_POINT /bin/bash -c "mkdir -p /usr/local/qt6"
sudo chroot $MOUNT_POINT /bin/bash -c "echo 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/qt6/lib/' | tee -a /etc/environment > /dev/null"

echo "Starting Qt Host Build!"

cd $HOME/qt-hostbuild
cmake $HOME/qt6/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/qt-build/qt-host
cmake --build . --parallel
cmake --install .

echo "Starting Qt RPi Build!"

cd $HOME/qt-pibuild

$HOME/qt6/configure \
-release \
-opengl es2 \
-nomake examples \
-nomake tests \
-skip qtwayland \
-skip qtwebengine \
-qt-host-path $HOME/qt-build/qt-host \
-extprefix $HOME/qt-build/qt-raspi \
-prefix /usr/local/qt6 \
-device linux-rasp-pi4-aarch64 \
-device-option CROSS_COMPILE=aarch64-linux-gnu- \
-- \
-DCMAKE_TOOLCHAIN_FILE=$HOME/rpi-toolchain.cmake \
-DQT_FEATURE_kms=ON \
-DQT_FEATURE_opengles2=ON \
-DQT_FEATURE_opengles3=ON \
-DQT_FEATURE_vulkan=ON \
-DQT_FEATURE_xcb=OFF \
-DFEATURE_xcb_xlib=OFF \
-DQT_FEATURE_xlib=OFF \
-DFEATURE_dbus=OFF

cmake --build . --parallel
cmake --install .

echo "Copying qt-raspi to $MOUNT_POINT/usr/local/qt6"
sudo cp -r $HOME/qt-build/qt-raspi/* $MOUNT_POINT/usr/local/qt6

echo "Unmounting rpi-sysroot!"
sudo umount $MOUNT_POINT/dev/pts
sudo umount $MOUNT_POINT/dev
sudo umount $MOUNT_POINT/proc
sudo umount $MOUNT_POINT/sys
sudo umount $MOUNT_POINT

echo "Copying $RPI_IMAGE to $HOME/qt-build"
cp $RPI_IMAGE $HOME/qt-build

echo "Copying Qt6 source to $HOME/qt-build"
cp -rf $HOME/qt6 $HOME/qt-build

echo "Done RPi Qt Builder!"