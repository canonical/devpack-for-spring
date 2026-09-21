#!/usr/bin/env bash

set -e

if [ -f /etc/iptables.rules ]; then
    iptables -F OUTPUT
    iptables-restore < /etc/iptables.rules
    rm -f /etc/iptables.rules
fi
