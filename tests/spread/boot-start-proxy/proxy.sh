#!/usr/bin/env bash

set -e

export http_proxy="http://127.0.0.1:3128/"
export https_proxy="http://127.0.0.1:3128/"

echo "Block outbound 80/443 traffic"
iptables-save > /etc/iptables.rules

# Clear existing rules for a clean state during testing
iptables -F OUTPUT

# 1. Allow local loopback traffic
iptables -A OUTPUT -o lo -j ACCEPT

# 2. Allow the 'proxy' user (Squid) to actually reach the internet over 80 and 443
iptables -A OUTPUT -p tcp -m owner --uid-owner proxy --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp -m owner --uid-owner proxy --dport 443 -j ACCEPT

# 3. REJECT all other direct outgoing HTTP (80) and HTTPS (443) traffic
iptables -A OUTPUT -p tcp --dport 80 -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -p tcp --dport 443 -j REJECT --reject-with icmp-port-unreachable

echo "Testing DIRECT HTTPS connection (Should Fail):"
curl -I --noproxy '*' https://www.google.com || echo "Successfully blocked direct access."

echo "Testing PROXIED HTTPS connection (Should Succeed):"
curl -I https://www.google.com

echo "=== Initialize Spring Boot project ==="
devpack-for-spring version
devpack-for-spring boot start --path foo --project gradle-project \
    --language java --boot-version 4.1.0 --group sample \
    --artifact sample --name sample --description sample \
    --package-name sample --packaging jar \
    --java-version 17 --version 1
