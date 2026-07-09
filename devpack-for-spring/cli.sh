#!/bin/bash
set -e
export SPRING_CLI_SETUP_COMMANDS_CONFIGURATION=${SPRING_CLI_SETUP_COMMANDS_CONFIGURATION:-/snap/devpack-for-spring/current/setup-configuration.yaml}

DEFAULT_KEYSTORE=""
if [ -f /etc/ssl/certs/java/cacerts ] || [ -n "$DEVPACK_FOR_SPRING_KEYSTORE" ]; then
  DEFAULT_KEYSTORE="-Djavax.net.ssl.trustStore=${DEVPACK_FOR_SPRING_KEYSTORE:-/etc/ssl/certs/java/cacerts}"
fi

NATIVE_ACCESS="--sun-misc-unsafe-memory-access=allow --enable-native-access=ALL-UNNAMED"
AOT_PATH="$SNAP/cli/devpack-for-spring-cli.aot"
AOT_FLAG="-XX:AOTCache=$AOT_PATH -XX:AOTMode=on -Xlog:aot=error"
eval "CLASSPATH=\"$(cat "$SNAP/cli/classpath.txt")\""

if [ -n "$DEVPACK_FOR_SPRING_DEBUG_FLAG" ]; then
    AOT_FLAG=""
    set -ex
fi

JAVA="${DEVPACK_FOR_SPRING_JAVA_HOME:-$SNAP/usr}/bin/java"

"$JAVA" \
    $DEFAULT_KEYSTORE \
    $DEVPACK_FOR_SPRING_DEBUG_FLAG \
    $AOT_FLAG \
    -Dspring.aot.enabled=true \
    -Dio.netty.noUnsafe=true \
    $NATIVE_ACCESS \
    -cp "$SNAP/cli/devpack-for-spring-cli.jar:$CLASSPATH" \
    org.springframework.cli.DevpackForSpringCliApplication "$@"
