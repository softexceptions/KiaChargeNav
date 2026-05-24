"""
Kia API Test-Script — hyundai-kia-connect-api

Voraussetzung: Erst kia_get_token.py ausführen um den Refresh Token zu holen.
Der Refresh Token landet automatisch in .env als KIA_PASSWORD.
Dann dieses Script starten.
"""

import os
from dotenv import load_dotenv
from hyundai_kia_connect_api import VehicleManager, POIInfo, POICoord
from hyundai_kia_connect_api.const import REGION_EUROPE, BRAND_KIA

load_dotenv()

USERNAME = os.environ["KIA_USERNAME"]
PASSWORD = os.environ["KIA_PASSWORD"]
PIN = os.environ.get("KIA_PIN", "")
VEHICLE_ID = os.environ.get("KIA_VEHICLE_ID", "")

# Region 1 = Europa, Brand 1 = Kia
vm = VehicleManager(
    region=1,
    brand=1,
    username=USERNAME,
    password=PASSWORD,
    pin=PIN,
    language="de",
)

# --- Schritt 1: Einloggen & Fahrzeugliste holen ---
print("Einloggen...")
vm.check_and_refresh_token()
vm.update_all_vehicles_with_cached_state()

print(f"\nFahrzeuge im Account: {len(vm.vehicles)}")
for vid, vehicle in vm.vehicles.items():
    print(f"  ID:    {vid}")
    print(f"  Name:  {vehicle.name}")
    print(f"  Model: {vehicle.model}")
    print(f"  SOC:   {vehicle.ev_battery_percentage}%")
    print()

# --- Schritt 2: Fahrzeug-ID wählen ---
if not VEHICLE_ID:
    # Automatisch das erste Fahrzeug nehmen
    VEHICLE_ID = list(vm.vehicles.keys())[0]
    print(f"HINWEIS: Trage diese Vehicle-ID in deine .env ein:")
    print(f"  KIA_VEHICLE_ID={VEHICLE_ID}\n")

vehicle = vm.get_vehicle(VEHICLE_ID)
print(f"Gewähltes Fahrzeug: {vehicle.name} ({vehicle.model})")

# --- Schritt 3: Testdestination senden ---
# Koordinaten: Shell-Ladestation Hamburg (Beispiel)
test_poi = POIInfo(
    name="Shell Recharge Hamburg Test",
    addr="Teststraße 1, Hamburg",
    coord=POICoord(lat=53.5753, lon=10.0153),
    phone="",
    waypoint_id=1,
)

print("\nSende Ziel ans Fahrzeug...")
try:
    msg_id = vm.set_navigation(VEHICLE_ID, [test_poi])
    print(f"Erfolgreich! Message-ID: {msg_id}")
    print("→ Schau jetzt aufs Kia-Display: Popup mit 'Neues Ziel empfangen' erwartet.")
    print("→ Prüfen: Erscheint es als Zwischenziel oder neues Hauptziel?")
except Exception as e:
    print(f"Fehler beim Senden: {e}")
