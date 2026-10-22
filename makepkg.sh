#!/bin/sh -e

# prep - credit Samueru

echo "Installing basic packages..."
pacman-key --init
pacman -Syy --noconfirm archlinux-keyring
pacman -Syu --noconfirm \
	base-devel \
	cmake \
	curl \
	gcc \
	git \
	ninja \
	wget
echo "------------------------------------------------------------"

echo "Settings up build options..."
sed -i \
	-e 's|DEBUG_CFLAGS="-g"|DEBUG_CFLAGS="-g0"|' \
	-e 's|-fno-omit-frame-pointer|-fomit-frame-pointer|' \
	-e 's|-mno-omit-leaf-frame-pointer||' \
	-e 's|-Wp,-D_FORTIFY_SOURCE=3||' \
	-e 's|-fstack-clash-protection||' \
	-e 's|MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|' \
	-e 's|!ccache|ccache|' \
	-e 's|#MAKEFLAGS|MAKEFLAGS|' /etc/makepkg.conf
cat /etc/makepkg.conf
echo "------------------------------------------------------------"

echo "Hacking makepkg to allow building as root in the container..."
sed -i 's|EUID == 0|EUID == 69|g' /usr/bin/makepkg
mkdir -p /usr/local/bin
cp /usr/bin/makepkg /usr/local/bin
echo "------------------------------------------------------------"

git clone --depth 1 https://github.com/archlinuxarm/PKGBUILDs.git
cd PKGBUILDs

cd "$1"

# awesome
if ! grep -q "arch=.*$ARCH" PKGBUILD; then
	sed -i -e "s|x86_64|$ARCH|" PKGBUILD
fi

# always build without debug info
sed -i -e 's|-g1|-g0|' PKGBUILD

makepkg -s --noconfirm

mkdir ../artifacts
rm -f ./*debug* || true
mv ./*.pkg.tar* ../artifacts

ls -lh ../artifacts
