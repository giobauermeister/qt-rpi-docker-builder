FROM ubuntu:22.04

ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG USER
ARG UID
ARG GID

# The Qt version to build
ARG QT_VERSION=6.5.3
ARG RPI_IMAGE=2024-07-04-raspios-bookworm-arm64-lite.img.xz
ARG PARALLELIZATION=12
ENV DEBIAN_FRONTEND=noninteractive

#############################
# Prepare and update Ubuntu #
#############################
RUN apt update

#############################
# Install required packages #
#############################
# Qt
RUN apt install -y \
sudo \
perl \
make \ 
cmake \ 
build-essential \ 
libclang-dev \ 
ninja-build \ 
gcc \ 
git \ 
bison \ 
python3 \ 
gperf \ 
pkg-config \ 
libfontconfig1-dev \ 
libfreetype6-dev \ 
libx11-dev \ 
libx11-xcb-dev \ 
libxext-dev \ 
libxfixes-dev \ 
libxi-dev \ 
libxrender-dev \ 
libxcb1-dev \ 
libxcb-glx0-dev \ 
libxcb-keysyms1-dev \ 
libxcb-image0-dev \ 
libxcb-shm0-dev \ 
libxcb-icccm4-dev \ 
libxcb-sync-dev \ 
libxcb-xfixes0-dev \ 
libxcb-shape0-dev \ 
libxcb-randr0-dev \ 
libxcb-render-util0-dev \ 
libxcb-util-dev \ 
libxcb-xinerama0-dev \ 
libxcb-xkb-dev \ 
libxkbcommon-dev \ 
libxkbcommon-x11-dev \ 
libatspi2.0-dev \ 
libgl1-mesa-dev \ 
libglu1-mesa-dev \ 
freeglut3-dev \
# cross-compiler toolchain \
gcc-aarch64-linux-gnu \ 
g++-aarch64-linux-gnu \
# package for building CMake \
libssl-dev \
# data transfer \
rsync \
wget \
# for chroot \
qemu-user-static \
parted \
udev

RUN apt-get clean --yes && rm -rf /var/lib/apt/lists/*

RUN useradd -m ${USER} --uid=${UID} && echo "${USER}:${USER}" | chpasswd && adduser ${USER} sudo
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
RUN echo "sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${UID}:${GID}

WORKDIR /home/${USER}
# Create Qt directories
RUN mkdir qt-raspi qt-host qt-pibuild qt-hostbuild

# Download Raspbian OS Lite 64Bit
RUN echo "Download RPi image: ${RPI_IMAGE}"
RUN wget -O ${RPI_IMAGE} https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-07-04/${RPI_IMAGE}
RUN echo "Extracting image ${RPI_IMAGE}"
RUN xz -d ${RPI_IMAGE}

# Clone Qt6 source
RUN git clone -b ${QT_VERSION} "https://codereview.qt-project.org/qt/qt5" qt6
WORKDIR /home/${USER}/qt6
RUN git submodule update --init \
qtbase \
qtdeclarative \
qtsvg \
qtimageformats \
qtmultimedia \
qtwebsockets \
qtserialport \
qtcharts \
qtconnectivity \
qtnetworkauth \
qtmqtt \
qthttpserver \
qtcharts \
qtshadertools

WORKDIR /home/${USER}

# Copy the script into the Docker container
USER root
COPY qt-build.sh /home/${USER}/qt-build.sh
RUN chmod +x /home/${USER}/qt-build.sh
COPY rpi-toolchain.cmake /home/${USER}/rpi-toolchain.cmake

USER ${UID}:${GID}
# Run the shell script
CMD ["./qt-build.sh"]