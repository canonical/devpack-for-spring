#!/usr/bin/env bash

set -e

apt-get update && apt-get install -y squid-openssl openssl iptables ca-certificates-java

echo "=== 2. Generating SSL Certificate for HTTPS Interception ==="

CERT_DIR="/etc/squid/certs"
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/squid.pem" ]; then
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
      -subj "/C=US/ST=State/L=City/O=Testing/CN=SquidCA" \
      -keyout "$CERT_DIR/squid.key" -out "$CERT_DIR/squid.crt"

    # Combine them for Squid
    cat "$CERT_DIR/squid.crt" "$CERT_DIR/squid.key" > "$CERT_DIR/squid.pem"
    chmod 400 "$CERT_DIR/squid.pem"
    chown -R proxy:proxy "$CERT_DIR"
fi

rm -rf /var/lib/squid/ssl_db
mkdir -p /var/lib/squid
chown -R proxy:proxy /var/lib/squid
/usr/lib/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 4MB

echo "=== 3. Configuring Squid for HTTP & HTTPS (SSL-Bump) ==="
SQUID_CONF="/etc/squid/squid.conf"

cat << 'EOF' > "$SQUID_CONF"
# Define local network access
acl localnet src 0.0.0.1-0.255.255.255
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 443		# https

http_access deny !Safe_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost
http_access deny all

# --- SSL-Bump Configuration ---
# Listen on 3128 for standard explicit HTTP/HTTPS proxying with SSL-Bump
http_port 3128 ssl-bump cert=/etc/squid/certs/squid.pem generate-host-certificates=on dynamic_cert_mem_cache_size=4MB

# Configure SSL-Bump steps
# step1: Discover client SNI (Server Name Indication)
# peek: Look at the SNI without establishing a connection yet
# bump: Intercept and establish a secure connection using a generated cert
acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

# SSL database helper program
sslcrtd_program /usr/lib/squid/security_file_certgen -s /var/lib/squid/ssl_db -M 4MB

coredump_dir /var/spool/squid
EOF

# Restart Squid to apply SSL-Bump configuration
systemctl restart squid

echo "=== 4. Setting Environment Variables & Trusting the CA ==="
# Applications using the proxy must trust Squid's self-signed CA certificate,
# otherwise HTTPS requests will fail with "SSL Certificate Untrusted" errors.
cp "$CERT_DIR/squid.crt" /usr/local/share/ca-certificates/squid-ca.crt
update-ca-certificates -f

# Set up global proxy variables
cat << 'EOF' > /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
http_proxy="http://127.0.0.1:3128/"
https_proxy="http://127.0.0.1:3128/"
HTTP_PROXY="http://127.0.0.1:3128/"
HTTPS_PROXY="http://127.0.0.1:3128/"
no_proxy="localhost,127.0.0.1"
NO_PROXY="localhost,127.0.0.1"
EOF

# Export to current shell session
export http_proxy="http://127.0.0.1:3128/"
export https_proxy="http://127.0.0.1:3128/"

echo "=== 5. Hardening Firewall (Blocking direct Outgoing 80/443) ==="
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

echo "=== Configuration Complete ==="
echo "Testing DIRECT HTTPS connection (Should Fail):"
curl -I --noproxy '*' https://www.google.com || echo "Successfully blocked direct access."

echo "-----------------------------"

echo "Testing PROXIED HTTPS connection (Should Succeed):"
curl -I https://www.google.com

echo "=== Initialize Spring Boot project ==="
devpack-for-spring version
devpack-for-spring boot start --path foo --project gradle-project \
    --language java --boot-version 4.1.0 --group sample \
    --artifact sample --name sample --description sample \
    --package-name sample --packaging jar \
    --java-version 17 --version 1
