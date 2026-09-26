#!/bin/bash
# ─── Jitsi Meet setup for meet.tippingjar.co.za ────────────────────────────
set -e

DOMAIN="meet.tippingjar.co.za"
EMAIL="admin@tippingjar.co.za"

echo "=== Installing Docker ==="
apt-get update -qq
apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "=== Installing Docker Compose ==="
curl -SL "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "=== Cloning Jitsi Docker ==="
mkdir -p /opt/jitsi-meet
cd /opt/jitsi-meet

curl -fsSL https://github.com/jitsi/docker-jitsi-meet/archive/refs/heads/master.tar.gz \
  | tar -xz --strip-components=1

echo "=== Generating .env ==="
cp env.example .env

# Set domain
sed -i "s|#PUBLIC_URL=https://meet.example.com|PUBLIC_URL=https://${DOMAIN}|g" .env
sed -i "s|PUBLIC_URL=https://meet.example.com|PUBLIC_URL=https://${DOMAIN}|g" .env

# Strong secrets
JVB_SECRET=$(openssl rand -hex 16)
JICOFO_AUTH_PASSWORD=$(openssl rand -hex 16)
JIGASI_XMPP_PASSWORD=$(openssl rand -hex 16)
JIBRI_RECORDER_PASSWORD=$(openssl rand -hex 16)
JIBRI_XMPP_PASSWORD=$(openssl rand -hex 16)

sed -i "s|JICOFO_AUTH_PASSWORD=|JICOFO_AUTH_PASSWORD=${JICOFO_AUTH_PASSWORD}|g" .env
sed -i "s|JVB_AUTH_PASSWORD=|JVB_AUTH_PASSWORD=${JVB_SECRET}|g" .env
sed -i "s|JIGASI_XMPP_PASSWORD=|JIGASI_XMPP_PASSWORD=${JIGASI_XMPP_PASSWORD}|g" .env
sed -i "s|JIBRI_RECORDER_PASSWORD=|JIBRI_RECORDER_PASSWORD=${JIBRI_RECORDER_PASSWORD}|g" .env
sed -i "s|JIBRI_XMPP_PASSWORD=|JIBRI_XMPP_PASSWORD=${JIBRI_XMPP_PASSWORD}|g" .env

# TLS via Let's Encrypt
sed -i "s|#ENABLE_LETSENCRYPT=1|ENABLE_LETSENCRYPT=1|g" .env
sed -i "s|#LETSENCRYPT_DOMAIN=meet.example.com|LETSENCRYPT_DOMAIN=${DOMAIN}|g" .env
sed -i "s|#LETSENCRYPT_EMAIL=alice@atlanta.net|LETSENCRYPT_EMAIL=${EMAIL}|g" .env
sed -i "s|LETSENCRYPT_DOMAIN=meet.example.com|LETSENCRYPT_DOMAIN=${DOMAIN}|g" .env
sed -i "s|LETSENCRYPT_EMAIL=alice@atlanta.net|LETSENCRYPT_EMAIL=${EMAIL}|g" .env

# TippingJar branding
sed -i "s|#DEFAULT_REMOTE_DISPLAY_NAME=Fellow Jitster|DEFAULT_REMOTE_DISPLAY_NAME=TippingJar Guest|g" .env
sed -i "s|#TOOLBAR_BUTTONS=|TOOLBAR_BUTTONS=microphone,camera,closedcaptions,desktop,chat,raisehand,participants-pane,tileview,hangup|g" .env

# Create config dirs
./gen-passwords.sh 2>/dev/null || true
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

echo "=== Starting Jitsi Meet ==="
docker-compose up -d

echo ""
echo "=== Jitsi Meet is starting at https://${DOMAIN} ==="
echo "Allow 2-3 minutes for Let's Encrypt to issue the certificate."
