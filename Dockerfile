FROM ubuntu:22.04

# The Qt version to build
ARG QT_VERSION=6.5.3
ARG PARALLELIZATION=12
ARG TZ=America/Sao_Paulo
ENV DEBIAN_FRONTEND=noninteractive

#############################
# Prepare and update Ubuntu #
#############################
RUN apt update \
 && apt upgrade -y

#############################
# Install required packages #
#############################
# Qt
RUN TZ="${TZ}" apt install -y \
sudo \
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
&& apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
# package for building CMake \
&& apt install -y libssl-dev \
# data transfer \
&& apt install -y rsync wget \
# for chroot
&& apt install -y qemu-user-static parted

# RUN apt install -y sudo

# Create a non-root user with sudo privileges
RUN useradd -m -s /bin/bash qtpi && echo 'qtpi:qtpi' | chpasswd && adduser qtpi sudo

# Allow 'qtpi' user to use sudo without a password
RUN echo 'qtpi ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set the working directory
WORKDIR /home/qtpi

# Copy the script into the Docker container
COPY qt-build.sh /home/qtpi/qt-build.sh

# Make the script executable
RUN chmod +x /home/qtpi/qt-build.sh

USER qtpi

# Run the shell script
CMD ["sudo", "./qt-build.sh"]