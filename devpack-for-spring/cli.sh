#!/bin/bash
set -e
export SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION=${SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION:-/snap/devpack-for-spring/current/plugin-configuration.yaml}
export SPRING_CLI_SETUP_COMMANDS_CONFIGURATION=${SPRING_CLI_SETUP_COMMANDS_CONFIGURATION:-/snap/devpack-for-spring/current/setup-configuration.yaml}

NATIVE_ACCESS="--sun-misc-unsafe-memory-access=allow --enable-native-access=ALL-UNNAMED"
AOT_PATH="$SNAP/cli/devpack-for-spring-cli.aot"
AOT_FLAG="-XX:AOTCache=$AOT_PATH -XX:AOTMode=on"
CLASSPATH=$(find $SNAP/cli/BOOT-INF/lib/ -type f -name "*.jar" -print | sort | tr '\n' ':')

$SNAP/usr/bin/java \
    $AOT_FLAG \
    -Xlog:aot=error \
    -Dspring.aot.enabled=true \
    -Dio.netty.noUnsafe=true \
    $NATIVE_ACCESS \
    -cp $SNAP/cli/devpack-for-spring-cli.jar:$CLASSPATH \
    org.springframework.cli.DevpackForSpringCliApplication $*
