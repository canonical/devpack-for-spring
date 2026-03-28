#!/bin/bash
set -e
export SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION=${SPRING_CLI_BUILD_COMMANDS_PLUGIN_CONFIGURATION:-/snap/devpack-for-spring/current/plugin-configuration.yaml}
export SPRING_CLI_SETUP_COMMANDS_CONFIGURATION=${SPRING_CLI_SETUP_COMMANDS_CONFIGURATION:-/snap/devpack-for-spring/current/setup-configuration.yaml}
AOT_PATH="$SNAP_USER_DATA/devpack-for-spring-cli.aot"

if [ ! -f "$AOT_PATH" ]; then
    AOT_FLAG="-XX:AOTCacheOutput=$AOT_PATH"
else
    if ! $SNAP/usr/bin/java --enable-native-access=ALL-UNNAMED -XX:AOTCache="$AOT_PATH" -XX:AOTMode=on -version > /dev/null 2>&1; then
        rm -f "$AOT_PATH"
        AOT_FLAG="-XX:AOTCacheOutput=$AOT_PATH"
    else
        AOT_FLAG="-XX:AOTCache=$AOT_PATH -XX:AOTMode=on"
    fi
fi

$SNAP/usr/bin/java \
    $AOT_FLAG \
    -Xlog:aot=error \
    -Dspring.aot.enabled=true \
    -Dio.netty.noUnsafe=true \
    --enable-native-access=ALL-UNNAMED \
    -jar $SNAP/cli/devpack-for-spring-cli.jar $*
