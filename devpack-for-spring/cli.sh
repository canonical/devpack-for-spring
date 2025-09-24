#!/bin/bash
export SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION=${SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION:-/snap/devpack-for-spring/current/build-plugins.yaml}
export SPRING_CLI_SETUP_COMMANDS_CONFIGURATION=${SPRING_CLI_SETUP_COMMANDS_CONFIGURATION:-/snap/devpack-for-spring/current/setup.yaml}
$SNAP/cli/devpack-for-spring-cli $*
