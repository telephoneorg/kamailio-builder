FROM telephoneorg/debian:stretch

MAINTAINER Joe Black <me@joeblack.nyc>

ARG     KAZOO_CONFIGS_BRANCH
ARG     DEB_CPPFLAGS_SET

ENV     KAZOO_CONFIGS_BRANCH=${KAZOO_CONFIGS_BRANCH:-4.2}
ENV     DEB_CPPFLAGS_SET=${DEB_CPPFLAGS_SET:--DUSE_RAW_SOCKS}

LABEL   app.kamailio.configs.kazoo.branch=$KAZOO_CONFIGS_BRANCH
LABEL   app.kamailio.build.cppflags=$DEB_CPPFLAGS_SET

ENV     APP kamailio
ENV     USER $APP
ENV     HOME /var/run/$APP

COPY    build-builder.sh /tmp/
RUN     /tmp/build-builder.sh

VOLUME ["/dist"]

COPY    build-kamailio.sh /

CMD     ["/build-kamailio.sh"]
