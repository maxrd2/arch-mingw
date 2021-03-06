#!/bin/bash

use_cache= #192.168.1.5 # set to pacserve ip

set -e
info() { echo -e "\e[1;39m$@\e[m"; }

info "Creating user: devel"
_ps='PS1='\''\[\033[1;34m\]\u@arch-docker\[\033[m\]:\[\033[1;39m\]\w\[\033[m\]\$ '\'''
echo "$_ps" >>/etc/skel/.bashrc
echo -e "$_ps\nexport VISUAL=/usr/bin/vim" >>/etc/bash.bashrc
groupmod -g 100 users
useradd -m -d /home/devel -u 1000 -g users -G tty -s /bin/bash devel
echo 'devel ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers

# setup pacman
info "Setting up pacman"
rm -rf /etc/pacman.d/gnupg
pacman-key --init
echo 'keyserver hkp://pool.sks-keyservers.net' >> /etc/pacman.d/gnupg/gpg.conf
pacman-key --populate archlinux
pacman -Sy archlinux-keyring pacman --noconfirm --noprogressbar --needed --quiet
pacman-db-upgrade

pacman -Sy --noconfirm --noprogressbar pacman-contrib
# select pacman mirrors
[[ -z "$use_cache" ]] && rm /etc/pacman.d/mirrorlist || echo 'Server = http://'$use_cache':15678/pacman/$repo/$arch' >/etc/pacman.d/mirrorlist
curl -s 'https://www.archlinux.org/mirrorlist/?country=DE&country=CH&country=GB&country=US&protocol=https&ip_version=4&use_mirror_status=on' \
	| sed 's|^#||;/^#/ d' | rankmirrors -n 6 - >>/etc/pacman.d/mirrorlist
# add mingw repos - https://github.com/maxrd2/arch-repo/
cat >>/etc/pacman.conf <<EOF
[multilib]
Include = /etc/pacman.d/mirrorlist
[maxrd2]
SigLevel = Optional TrustAll
EOF
[[ ! -z "$use_cache" ]] && echo 'Server = http://'$use_cache':15678/pacman/$repo' >>/etc/pacman.conf
echo 'Server = https://github.com/maxrd2/arch-repo/releases/download/continuous' >>/etc/pacman.conf

# tell pacman to extract localization
sed -r -e '/^NoExtract/ s, [^ ]*(locale|i18n)[^/]*/[^ ]*,,g' -i /etc/pacman.conf

info "Updating system"
pacman -Syyu --noconfirm --noprogressbar --quiet

info "Installing system packages"
pacman -S --noconfirm --noprogressbar \
	imagemagick make git binutils patch base-devel python2 wget curl \
	expac yajl vim openssh rsync lzop unzip bash-completion ncdu jq pacaur
	
info "Installing mingw packages"
pacman -S --noconfirm --noprogressbar \
	mingw-w64-toolchain mingw-w64-cmake mingw-w64-configure mingw-w64-pkg-config \
	mingw-w64-ffmpeg mingw-w64-qt5 mingw-w64-kf5 nsis

info "Cleaning up"
rm -rf \
	/usr/share/{doc,man}/* \
	/tmp/* \
	/var/{tmp,cache/pacman/pkg,lib/pacman/sync}/* \
	/home/devel/.cache
