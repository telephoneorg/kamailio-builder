#!/bin/bash -l

set -e

CODENAME=$(cat /etc/debian_codename)

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER

log::m-info "Installing $APP repo ..."
build::apt::add-key 508EA4C8
echo -e "deb http://deb.kamailio.org/kamailio50 $CODENAME main
deb-src http://deb.kamailio.org/kamailio50 $CODENAME main" > /etc/apt/sources.list.d/kamailio.list
apt-get -qq update

# # kazoo-db
#
# # needed to resolve lib links in db_kazoo.so
# #   libsrdb1.so.1 => /usr/lib/x86_64-linux-gnu/kamailio/libsrdb1.so.1 (0x00007f50d11ec000)
# echo /usr/lib/x86_64-linux-gnu/kamailio >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf
# ldconfig -v 2> /dev/null | grep libsrdb
#
#
# apt-get install -yqq patchelf
# patchelf --force-rpath --set-rpath /usr/lib/x86_64-linux-gnu/kamailio/ /usr/lib/x86_64-linux-gnu/kamailio/modules/db_kazoo.so
# apt-get purge -y --auto-remove patchelf

#

log::m-info "Installing utils ..."
apt-get install -yqq \
    ca-certificates \
    curl \
    git \

apt-get install -y build-essential fakeroot devscripts
apt-get install -y rpm2cpio cpio patchelf


mkdir -p /tmp/build
pushd $_
	log::m-info "Getting $APP source ..."
	apt-get source -yqq kamailio
	apt-get build-dep kamailio -y


# mkdir -p /dist


# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
