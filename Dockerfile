# MingW64 + Qt5 + FFMPEG for cross-compile builds to Windows
# https://github.com/maxrd2/arch-mingw
# Based on ArchLinux image - https://github.com/archlinux/archlinux-docker
# Based on Mykola Dimura's docker script - https://github.com/mdimura/docker-mingw-qt5

FROM archlinux/base:latest

# Create devel user
RUN useradd -m -d /home/devel -u 1000 -g users -G tty -s /bin/bash devel \
	&& echo 'devel ALL=(ALL) NOPASSWD: /usr/sbin/pacman, /usr/sbin/makepkg, /usr/sbin/cleantemp' >> /etc/sudoers \
	&& echo 'PS1='\''\[\033[1;34m\]\u@arch-docker\[\033[m\]:\[\033[1;39m\]\w\[\033[m\]\$ '\''' >> /etc/bash.bashrc \
	&& echo -e '#!/bin/sh\nrm -rfv /usr/share/{doc,man}/* /tmp/* /var/{tmp,cache/pacman/pkg,lib/pacman/sync}/* /home/devel/.cache' > /usr/sbin/cleantemp \
	&& chmod 755 /usr/sbin/cleantemp

# Select a mirror
RUN pacman -Sy --noconfirm --noprogressbar pacman-contrib \
	&& mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup \
	&& echo 'Server = http://192.168.1.5:15678/pacman/$repo/$arch' > /etc/pacman.d/mirrorlist \
	&& rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup >> /etc/pacman.d/mirrorlist \
	&& rm /etc/pacman.d/mirrorlist.backup

# Add mingw-repo - https://github.com/Martchus/PKGBUILDs/
RUN echo "[ownstuff]" >> /etc/pacman.conf \
	&& echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf \
	&& echo 'Server = http://192.168.1.5:15678/pacman/$repo/$arch' >> /etc/pacman.conf \
	&& echo "Server = https://martchus.no-ip.biz/repo/arch/ownstuff/os/\$arch" >> /etc/pacman.conf

# Pacman - update system, install system packages, install mingw-w64 packages
RUN pacman -Sy \
	&& pacman -S archlinux-keyring --noconfirm --noprogressbar --quiet \
	&& pacman -S pacman --noconfirm --noprogressbar --quiet \
	&& pacman-db-upgrade \
	&& pacman -Su --noconfirm --noprogressbar --quiet \
	&& pacman -S --noconfirm --noprogressbar imagemagick make git binutils patch base-devel python2 wget curl \
		expac yajl vim openssh rsync lzop unzip bash-completion ncdu jq \
	&& pacman -S --noconfirm mingw-w64-binutils mingw-w64-crt mingw-w64-gcc mingw-w64-headers mingw-w64-winpthreads \
		mingw-w64-cmake mingw-w64-configure mingw-w64-pkg-config mingw-w64-bzip2 mingw-w64-expat mingw-w64-freeglut \
		mingw-w64-freetype2 mingw-w64-gettext mingw-w64-libdbus mingw-w64-libiconv mingw-w64-libjpeg-turbo \
		mingw-w64-libpng mingw-w64-libtiff mingw-w64-libxml2 mingw-w64-mariadb-connector-c mingw-w64-openssl \
		mingw-w64-openjpeg mingw-w64-openjpeg2 mingw-w64-pcre mingw-w64-pdcurses mingw-w64-readline mingw-w64-fontconfig \
		mingw-w64-sdl2 mingw-w64-sqlite mingw-w64-termcap mingw-w64-tools mingw-w64-zlib mingw-w64-boost mingw-w64-eigen \
		mingw-w64-ffmpeg mingw-w64-qt5 mingw-w64-kf5 \
	&& rm -rf /usr/share/{doc,man}/* /tmp/* /var/{tmp,cache/pacman/pkg}/*

# Install pacaur and AUR packages
USER devel
RUN cd /tmp \
	&& PATH="/usr/bin/core_perl:$PATH" \
	&& aur=auracle-git && git clone https://aur.archlinux.org/$aur.git && (cd $aur && makepkg -irs --noconfirm) && rm -rf $aur \
	&& aur=pacaur && git clone https://aur.archlinux.org/$aur.git && (cd $aur && makepkg -irs --noconfirm) && rm -rf $aur \
	&& VISUAL=/bin/cat pacaur -S --noconfirm --noedit --noprogressbar --needed mingw-w64-python-bin nsis \
	&& sudo /usr/sbin/cleantemp

# Setup user and home
USER devel
ENV HOME=/home/devel
WORKDIR /home/devel

# ... but don't use it on the next image builds
ONBUILD USER root
ONBUILD WORKDIR /
