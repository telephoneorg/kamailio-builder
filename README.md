# Kamailio 5.x Builder
[![Build Status](https://travis-ci.org/telephoneorg/kamailio-builder.svg?branch=master)](https://travis-ci.org/telephoneorg/kamailio-builder)


## Maintainer
Joe Black <me@joeblack.nyc> | [github](https://github.com/joeblackwaslike)


## Description
This is just a builder for kamailio 5.x, which is used in [docker-kamailio](https://github.com/telephoneorg/docker-kamailio).


## Build Environment
Build environment variables are often used in the build script to bump version numbers and set other options during the docker build phase.  Their values can be overridden using a build argument of the same name.
* `KAZOO_CONFIGS_BRANCH`: supplied to `git clone -b` when cloning the kazoo-configs repo. Defaults to `$KAZOO_BRANCH`.

The following variables are standard in most of our dockerfiles to reduce duplication and make scripts reusable among different projects:
* `APP`: kazoo
* `USER`: kazoo
* `HOME` /opt/kazoo
