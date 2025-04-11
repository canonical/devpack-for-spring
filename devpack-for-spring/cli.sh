#!/bin/sh
export SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION=${SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION:-/snap/devpack-for-spring/current/build-plugins.yaml}
$SNAP/usr/bin/java -jar $SNAP/cli/spring-cli-*.jar $*
