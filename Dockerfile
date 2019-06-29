# MingW64 + Qt5 + FFMPEG for cross-compile builds to Windows
# https://github.com/maxrd2/arch-mingw
# Based on ArchLinux image - https://github.com/archlinux/archlinux-docker

FROM archlinux/base:latest

COPY setup.sh /opt/maxrd2/
RUN /opt/maxrd2/setup.sh

USER devel
ENV HOME=/home/devel
WORKDIR /home/devel

ONBUILD USER root
ONBUILD WORKDIR /
