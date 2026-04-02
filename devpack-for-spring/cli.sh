#!/bin/bash
set -e
export SPRING_CLI_SETUP_COMMANDS_CONFIGURATION=${SPRING_CLI_SETUP_COMMANDS_CONFIGURATION:-/snap/devpack-for-spring/current/setup-configuration.yaml}

NATIVE_ACCESS="--sun-misc-unsafe-memory-access=allow --enable-native-access=ALL-UNNAMED"
AOT_PATH="$SNAP/cli/devpack-for-spring-cli.aot"
AOT_FLAG="-XX:AOTCache=$AOT_PATH -XX:AOTMode=on -Xlog:aot=error"
CLASSPATH=$(envsubst < "$SNAP/cli/classpath.txt")

if [ -n "$DEVPACK_FOR_SPRING_DEBUG_FLAG" ]; then
    AOT_FLAG=""
    set -ex
fi

"$SNAP/usr/bin/java" \
    $DEVPACK_FOR_SPRING_DEBUG_FLAG \
    $AOT_FLAG \
    -Dspring.aot.enabled=true \
    -Dio.netty.noUnsafe=true \
    $NATIVE_ACCESS \
    -cp "$SNAP/cli/devpack-for-spring-cli.jar:$CLASSPATH" \
    org.springframework.cli.DevpackForSpringCliApplication "$@"
