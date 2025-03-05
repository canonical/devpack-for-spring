#!/bin/sh
find . -name *.snap -delete
make prepare
(cd devpack-for-spring-manifest && snapcraft)
(cd devpack-for-spring && snapcraft)
spread $*
