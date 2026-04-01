#!/bin/bash
set -e
export SPRING_CLI_SETUP_COMMANDS_CONFIGURATION=${SPRING_CLI_SETUP_COMMANDS_CONFIGURATION:-/snap/devpack-for-spring/current/setup-configuration.yaml}

NATIVE_ACCESS="--sun-misc-unsafe-memory-access=allow --enable-native-access=ALL-UNNAMED"
AOT_PATH="$SNAP/cli/devpack-for-spring-cli.aot"
AOT_FLAG="-XX:AOTCache=$AOT_PATH -XX:AOTMode=on"
CLASSPATH=$(find "$SNAP/cli/lib/" -type f -name "*.jar" -print | sort | tr '\n' ':')

if [ -n "$DEVPACK_FOR_SPRING_DEBUG_FLAG" ]; then
    AOT_FLAG=""
fi

"$SNAP/usr/bin/java" \
    $DEVPACK_FOR_SPRING_DEBUG_FLAG \
    $AOT_FLAG \
    -Xlog:aot=error \
    -Dspring.aot.enabled=true \
    -Dio.netty.noUnsafe=true \
    $NATIVE_ACCESS \
    -cp "$SNAP/cli/devpack-for-spring-cli.jar:$CLASSPATH" \
    org.springframework.cli.DevpackForSpringCliApplication "$@"
