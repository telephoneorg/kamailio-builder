#!/bin/bash -l

set -e

# export DEB_CPPFLAGS_SET="-DUSE_RAW_SOCKS"

log::m-info "Building kamailio and modules ..."
pushd /tmp/build
	pushd kamailio-*
		dch --bin-nmu "Added build flag: USE_RAW_SOCKS"
		popd
	pushd kamailio-*
		debuild --preserve-envvar=DEB_CPPFLAGS_SET -b -uc -us
		popd
	mv *.deb /dist
	popd




log::m-info "Building kamailio-dbkazoo-modules ..."
mkdir -p /tmp/build/kamailio-dbkazoo-modules_5.0.3+stretch+b1
pushd $_
    # curl -LO https://packages.2600hz.com/centos/7/stable/kamailio-mirror/5.0.3a/kamailio-db-kazoo-5.0.3a-2.1.x86_64.rpm
    curl -LO https://packages.2600hz.com/centos/7/stable/kamailio-mirror/5.0.3b/kamailio-db-kazoo-5.0.3b-3.1.x86_64.rpm
    rpm2cpio kamailio* | cpio -idmv
    chmod -x usr/lib64/kamailio/modules/db_kazoo.so
	patchelf --force-rpath --set-rpath /usr/lib/x86_64-linux-gnu/kamailio/ usr/lib64/kamailio/modules/db_kazoo.so

	mv usr/lib64 usr/lib
	mkdir usr/lib/x86_64-linux-gnu
	mv usr/lib/kamailio usr/lib/x86_64-linux-gnu/
	rm -f kamailio-db-kazoo*

	mkdir DEBIAN

	tee DEBIAN/control <<'EOF'
Package: kamailio-dbkazoo-modules
Version: 5.0.3+stretch+b1
Architecture: any
Depends: kamailio (>= 5.0.3+stretch+b1)
Maintainer: Joe Black <me@joeblack.nyc>
Description: DBKazoo module for Kamailio SIP server
 Kamailio is a very fast and flexible SIP (RFC3261)
 server. Written entirely in C, Kamailio can handle thousands calls
 per second even on low-budget hardware.
 .
 This Kamailio module provides the KazooDB module (db_kazoo.so) and the
 KazooDB utility script.

EOF

	tee DEBIAN/postinst <<'EOF'
#!/bin/sh

set -e

case "$1" in
    configure)
		echo /usr/lib/x86_64-linux-gnu/kamailio >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf
		ldconfig

		mkdir -p /etc/kamailio/db
		chown -R kamailio:kamailio /etc/kamailio/db
		chmod -R 0755 /etc/kamailio/db
    	;;
esac

exit 0

EOF

	chmod 0755 DEBIAN/postinst
	cd ..

	dpkg-deb --build kamailio-dbkazoo-modules_5.0.3+stretch+b1
	mv *.deb /dist
	popd


log::m-info "Building kamailio-kazoo-configs ..."
mkdir /tmp/configs
pushd $_
    git clone -b $KAZOO_CONFIGS_BRANCH --single-branch --depth 1 \
        https://github.com/2600hz/kazoo-configs-kamailio .

    pushd kamailio
        log::m-info "Fixing /etc paths: /etc/kazoo/kamailio > /etc/kamailio ..."
        for f in $(grep -rl '/etc/kazoo/kamailio' *)
        do
            sed -i -r 's|/etc/kazoo/kamailio|/etc/kamailio|g' $f
            grep '/etc/k' $f
        done

        log::m-info "Adding secondary and tertiary amqp url substring sections (commented) to local.cfg"
        sed -i "\|MY_AMQP_URL|a \\
# # #!substdef \"!MY_AMQP_SECONDARY_URL!<MY_AMQP_SECONDARY_URL>!g\" \\
# # #!substdef \"!MY_AMQP_TERTIARY_URL!<MY_AMQP_TERTIARY_URL>!g\"" local.cfg

        sed -i '/MY_HOSTNAME/s/kamailio\.2600hz\.com/<MY_HOSTNAME>/' $_
        sed -i '/!MY_IP_ADDRESS/s/127\.0\.0\.1/<MY_IP_ADDRESS>/' $_
        sed -i '/MY_AMQP_URL/s/kazoo:\/\/guest:guest@127\.0\.0\.1:5672/<MY_AMQP_URL>/' $_
        sed -i '/MY_WEBSOCKET_DOMAIN/s/2600hz\.com/<MY_WEBSOCKET_DOMAIN>/' $_

        log::m-info "We're in docker so let's set logging to stderr ..."
        sed -i '/log_stderror/s/\b\w*$/yes/' default.cfg

        log::m-info "Setting user and group in config"
        sed -i '/Global Parameters/a \user = "kamailio"' default.cfg
        sed -i '/Global Parameters/a \group = "kamailio"' $_

        log::m-info "Setting DNS settings ..."
        # this is beneficial in a kubernetes environment where /etc/resolv.conf
        # has search domains.
        sed -i '/DNS Parameters/a \dns_use_search_list = no' default.cfg

        log::m-info "Whitelabeling headers ..."
        sed -i '/server_header/s/".*"/"Server: K"/' default.cfg
        sed -i '/user_agent_header/s/".*"/"User-Agent: K"/' $_
		popd

	mkdir -p kamailio-kazoo-configs_5.0.3+stretch+b1-4.2/{DEBIAN,etc}
	mv kamailio kamailio-kazoo-configs*/etc
	pushd kamailio-kazoo-configs*
		tee DEBIAN/control <<'EOF'
Package: kamailio-kazoo-configs
Version: 5.0.3+stretch+b1-4.2
Architecture: any
Depends: kamailio (>= 5.0.3+stretch+b1)
Maintainer: Joe Black <me@joeblack.nyc>
Description: Kazoo configs for Kamailio SIP server
 Kamailio is a very fast and flexible SIP (RFC3261)
 server. Written entirely in C, Kamailio can handle thousands calls
 per second even on low-budget hardware.
 .
 This package provides the kazoo configs for Kamailio SIP server.

EOF


		tee DEBIAN/preinst <<'EOF'
#!/bin/sh

set -e

case "$1" in
    install)
		rm -rf /etc/kazoo/*
    	;;
esac

exit 0

EOF

		tee DEBIAN/postinst <<'EOF'
#!/bin/sh

set -e

case "$1" in
    configure)
		chown -R kamailio:kamailio /etc/kamailio
		chmod -R 0700 /etc/kamailio/certs
    	;;
esac

exit 0

EOF

		chmod 0755 DEBIAN/{preinst,postinst}
		popd

	dpkg-deb --build kamailio-kazoo-configs*
	mv *.deb /dist
	popd



log::m-info "Creating archive ..."
cd /dist
	tar czvf kamailio-debs-all.tar.gz *.deb
