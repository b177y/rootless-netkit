#!/bin/bash

buildah rm --all

wc=$(buildah from docker.io/library/debian:10)

#buildah run $wc update-alternatives --set iptables /usr/sbin/iptables-legacy

buildah config --env DEBIAN_FRONTEND="noninteractive" $wc

buildah run $wc apt update --assume-yes

cat debconf-package-selections | buildah run $wc debconf-set-selections

PACKAGES_LIST=`cat packages-list | grep -v '#'`
buildah run $wc apt install --assume-yes ${PACKAGES_LIST}

#buildah run $wc apt install --assume-yes --no-install-recommends wireguard-tools

buildah config --cmd "/sbin/init"

buildah commit $wc netkit-deb-test

buildah rm $wc
