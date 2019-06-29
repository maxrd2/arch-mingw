#!/bin/bash

set -e
info() { echo -e "\e[1;39m$@\e[m"; }

info "Creating user: devel"
_ps='PS1='\''\[\033[1;34m\]\u@arch-docker\[\033[m\]:\[\033[1;39m\]\w\[\033[m\]\$ '\'''
echo "$_ps" >>/etc/skel/.bashrc
echo "$_ps" >>/etc/bash.bashrc
groupmod -g 100 users
useradd -m -d /home/devel -u 1000 -g users -G tty -s /bin/bash devel
echo 'devel ALL=(ALL) NOPASSWD: /usr/sbin/pacman, /usr/sbin/makepkg' >>/etc/sudoers

info "Setting up pacman"
pacman -Sy --noconfirm --noprogressbar pacman-contrib
# select pacman mirrors
echo 'Server = http://192.168.1.5:15678/pacman/$repo/$arch' >/etc/pacman.d/mirrorlist
curl -s 'https://www.archlinux.org/mirrorlist/?country=DE&country=CH&country=GB&country=US&protocol=https&ip_version=4&use_mirror_status=on' \
	| sed 's|^#||;/^#/ d' | rankmirrors -n 6 - >>/etc/pacman.d/mirrorlist
# add mingw-repo - https://github.com/Martchus/PKGBUILDs/
cat >>/etc/pacman.conf <<EOF
[ownstuff]
SigLevel = Optional TrustAll
Server = http://192.168.1.5:15678/pacman/\$repo/\$arch
Server = https://martchus.no-ip.biz/repo/arch/ownstuff/os/\$arch
EOF
# setup pacman
pacman -Sy
pacman -S archlinux-keyring --noconfirm --noprogressbar --quiet
pacman -S pacman --noconfirm --noprogressbar --quiet
pacman-db-upgrade

info "Updating system"
pacman -Su --noconfirm --noprogressbar --quiet

info "Installing system packages"
pacman -S --noconfirm --noprogressbar imagemagick make git binutils patch base-devel python2 wget curl \
	expac yajl vim openssh rsync lzop unzip bash-completion ncdu jq
	
info "Installing mingw packages"
pacman -S --noconfirm mingw-w64-binutils mingw-w64-crt mingw-w64-gcc mingw-w64-headers mingw-w64-winpthreads \
	mingw-w64-cmake mingw-w64-configure mingw-w64-pkg-config mingw-w64-bzip2 mingw-w64-expat mingw-w64-freeglut \
	mingw-w64-freetype2 mingw-w64-gettext mingw-w64-libdbus mingw-w64-libiconv mingw-w64-libjpeg-turbo \
	mingw-w64-libpng mingw-w64-libtiff mingw-w64-libxml2 mingw-w64-mariadb-connector-c mingw-w64-openssl \
	mingw-w64-openjpeg mingw-w64-openjpeg2 mingw-w64-pcre mingw-w64-pdcurses mingw-w64-readline mingw-w64-fontconfig \
	mingw-w64-sdl2 mingw-w64-sqlite mingw-w64-termcap mingw-w64-tools mingw-w64-zlib mingw-w64-boost mingw-w64-eigen \
	mingw-w64-ffmpeg mingw-w64-qt5 mingw-w64-kf5 \

info "Installing auracle-git"
su - devel -c 'cd /tmp && aur=auracle-git && git clone https://aur.archlinux.org/$aur.git && (cd $aur && makepkg -irs --noconfirm) && rm -rf $aur'

info "Installing pacaur"
su - devel -c 'cd /tmp && aur=pacaur && git clone https://aur.archlinux.org/$aur.git && (cd $aur && PATH="/usr/bin/core_perl:$PATH" && makepkg -irs --noconfirm) && rm -rf $aur'
	
info "Installing pacaur packages"
su - devel -c 'VISUAL=/bin/cat pacaur -S --noconfirm --noedit --noprogressbar --needed mingw-w64-python-bin nsis'
	
info "Cleaning up"
rm -rf \
	/usr/share/{doc,man}/* \
	/tmp/* \
	/var/{tmp,cache/pacman/pkg,lib/pacman/sync}/* \
	/home/devel/.cache
