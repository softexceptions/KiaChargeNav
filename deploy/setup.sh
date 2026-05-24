#!/usr/bin/env bash
# KiaChargeNav — LXC Setup-Script
# Einmalig auf dem frischen LXC als root ausführen.
set -euo pipefail

REPO_URL="https://github.com/DEIN_USERNAME/KiaChargeNav.git"  # <-- anpassen
INSTALL_DIR="/opt/kiachargenav"
SERVICE_USER="kiachargenav"

echo "=== 1/6  Pakete installieren ==="
apt-get update -qq
apt-get install -y --no-install-recommends \
    git python3 python3-venv python3-pip nginx

echo "=== 2/6  Service-User anlegen ==="
id "$SERVICE_USER" &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"

echo "=== 3/6  Repo clonen ==="
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "  Repo vorhanden — git pull"
    git -C "$INSTALL_DIR" pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

echo "=== 4/6  Python venv aufbauen ==="
python3 -m venv "$INSTALL_DIR/backend/.venv"
"$INSTALL_DIR/backend/.venv/bin/pip" install --quiet --upgrade pip
"$INSTALL_DIR/backend/.venv/bin/pip" install --quiet -r "$INSTALL_DIR/backend/requirements.txt"

echo ""
echo "=== 5/6  .env anlegen (manuell!) ==="
if [ ! -f "$INSTALL_DIR/backend/.env" ]; then
    cp "$INSTALL_DIR/backend/.env.example" "$INSTALL_DIR/backend/.env"
    echo ""
    echo "  ACHTUNG: Fülle jetzt $INSTALL_DIR/backend/.env aus:"
    echo "    KIA_USERNAME=..."
    echo "    KIA_PASSWORD=..."
    echo "    KIA_PIN=..."
    echo "    KIA_VEHICLE_ID=..."
    echo "    API_KEY=..."
    echo "    OPENCHARGEMAP_API_KEY=..."
    echo "    GOINGELECTRIC_API_KEY=..."
    echo ""
    echo "  Dann: systemctl start kiachargenav"
    echo ""
fi
chown "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR/backend/.env"
chmod 600 "$INSTALL_DIR/backend/.env"

echo "=== 6/6  systemd + nginx konfigurieren ==="
cp "$INSTALL_DIR/deploy/kiachargenav.service" /etc/systemd/system/kiachargenav.service
systemctl daemon-reload
systemctl enable kiachargenav

cp "$INSTALL_DIR/deploy/nginx.conf" /etc/nginx/sites-available/kiachargenav
ln -sf /etc/nginx/sites-available/kiachargenav /etc/nginx/sites-enabled/kiachargenav
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo ""
echo "=== Setup abgeschlossen ==="
echo "  Nächster Schritt: .env befüllen, dann:"
echo "    systemctl start kiachargenav"
echo "    systemctl status kiachargenav"
echo "    curl http://localhost/health"
