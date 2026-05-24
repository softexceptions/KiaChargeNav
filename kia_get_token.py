"""
Kia EU Refresh Token holen — einmaliger Browser-Login.

Hintergrund: Die headless Passwort-Authentifizierung der Library ist für Kia EU
broken (bekannter Bug). Dieser Script öffnet einen echten Browser, du loggst
dich manuell ein, und das Script schnappt sich automatisch den Code aus der
Redirect-URL und tauscht ihn gegen einen Refresh Token.

Danach: Refresh Token in .env als KIA_PASSWORD eintragen.

Voraussetzung: pip install selenium
"""

import os
import time
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import InvalidSessionIdException
from dotenv import load_dotenv, set_key

load_dotenv()
os.environ.setdefault("DISPLAY", ":0")

CLIENT_ID = "fdc85c00-0a2f-4c64-bcb4-2cfb1500730a"
CLIENT_SECRET = "secret"
REDIRECT_URI = "https://prd.eu-ccapi.kia.com:8080/api/v1/user/oauth2/redirect"
LOGIN_URL = (
    "https://idpconnect-eu.kia.com/auth/api/v2/user/oauth2/authorize"
    f"?response_type=code&client_id={CLIENT_ID}"
    f"&redirect_uri={REDIRECT_URI}&lang=de&state=ccsp&country=de"
)

# Chromium mit sichtbarem Fenster (kein headless!)
options = Options()
options.binary_location = "/usr/bin/chromium"
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")

print("Browser öffnet sich — bitte einloggen...")
print(f"Login-URL: {LOGIN_URL}\n")

driver = webdriver.Chrome(options=options)
driver.get(LOGIN_URL)

# Warte bis die Redirect-URL den Code enthält
print("Warte auf erfolgreichen Login und Redirect...")
code = None
timeout = 120  # 2 Minuten Zeit zum Einloggen

from urllib.parse import urlparse, parse_qs

for _ in range(timeout):
    try:
        current_url = driver.current_url
    except InvalidSessionIdException:
        print("Browser wurde geschlossen.")
        break
    if "oauth2/redirect" in current_url and "code=" in current_url:
        params = parse_qs(urlparse(current_url).query)
        if "code" in params:
            code = params["code"][0]
            print(f"\nCode gefunden: {code[:20]}...")
            break
    time.sleep(1)

try:
    driver.quit()
except Exception:
    pass

if not code:
    print("Timeout — kein Code erhalten. Hast du dich eingeloggt?")
    exit(1)

# Code gegen Refresh Token tauschen
print("\nTausche Code gegen Token...")
resp = requests.post(
    "https://idpconnect-eu.kia.com/auth/api/v2/user/oauth2/token",
    data={
        "client_id": CLIENT_ID,
        "grant_type": "authorization_code",
        "redirect_uri": REDIRECT_URI,
        "code": code,
        "client_secret": CLIENT_SECRET,
    },
)

if resp.status_code != 200:
    print(f"Fehler beim Token-Tausch: HTTP {resp.status_code}")
    print(resp.text[:300])
    exit(1)

data = resp.json()

# Refresh Token aus der Antwort holen (verschachtelt oder direkt)
refresh_token = data.get("refresh_token") or (
    data.get("connector", {}).get("hmgid1.0", {}).get("refresh_token")
)
access_token = data.get("access_token")

if not refresh_token:
    print("Kein Refresh Token in der Antwort:")
    print(data)
    exit(1)

print(f"\nRefresh Token: {refresh_token[:40]}...")
print(f"Access Token:  {access_token[:40] if access_token else 'n/a'}...")

# In .env schreiben
set_key(".env", "KIA_PASSWORD", refresh_token)
print("\n✓ Refresh Token wurde in .env als KIA_PASSWORD gespeichert.")
print("→ Jetzt kia_api_test.py ausführen.")
