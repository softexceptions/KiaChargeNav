"""
Ladestation-Suche via GoingElectric API (primär) mit OCM als Fallback.

Kernfunktion: find_nearest(lat, lon, heading, network, radius_km)
→ findet die nächste Ladestation, die in Fahrtrichtung liegt.

Heading-Logik:
  Stationen innerhalb von ±60° der Fahrtrichtung werden bevorzugt.
  Unter diesen wird die nächstgelegene zurückgegeben.
  Gibt es keine im Korridor, fällt der Code auf die schlicht nächste zurück.
"""

import math
import os
import requests
from dataclasses import dataclass

GE_API_URL  = "https://api.goingelectric.de/chargepoints/"
OCM_API_URL = "https://api.openchargemap.io/v3/poi/"

HEADING_CORRIDOR_DEG = 60

# Keyword → exakter GoingElectric-Netzwerkname
GE_NETWORK_MAP: dict[str, str] = {
    "shell":    "Shell Recharge",
    "ionity":   "IONITY",
    "enbw":     "EnBW",
    "aral":     "Aral pulse",
    "ewe":      "EWE Go",
    "fastned":  "Fastned",
    "allego":   "allego",
    "tesla":    "Tesla Supercharger",
    "aldi":     "ALDI Süd",
    "lidl":     "Lidl",
    "rewe":     "REWE",
    "maingau":  "Maingau Energie",
    "mer":      "Mer",
}


@dataclass
class ChargingStation:
    name: str
    address: str
    lat: float
    lon: float
    distance_km: float
    heading_diff_deg: float
    operator: str


def _bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlon = lon2 - lon1
    x = math.sin(dlon) * math.cos(lat2)
    y = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dlon)
    return (math.degrees(math.atan2(x, y)) + 360) % 360


def _angular_diff(a: float, b: float) -> float:
    diff = abs(a - b) % 360
    return min(diff, 360 - diff)


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


def _best_in_pool(pool: list[ChargingStation]) -> ChargingStation:
    in_corridor = [s for s in pool if s.heading_diff_deg <= HEADING_CORRIDOR_DEG]
    candidates = in_corridor if in_corridor else pool
    return min(candidates, key=lambda s: s.distance_km)


def _find_via_goingelectric(
    lat: float, lon: float, heading: float, network: str, radius_km: float
) -> ChargingStation | None:
    ge_key = os.environ.get("GOINGELECTRIC_API_KEY", "")
    if not ge_key:
        return None

    # Keyword auf exakten GE-Namen mappen
    ge_network = GE_NETWORK_MAP.get(network.lower(), network)

    resp = requests.get(GE_API_URL, params={
        "key": ge_key,
        "lat": lat, "lng": lon,
        "radius": int(radius_km),
        "networks": ge_network,
        "orderby": "distance",
    }, timeout=10)
    resp.raise_for_status()
    locations = resp.json().get("chargelocations", [])

    pool: list[ChargingStation] = []
    for loc in locations:
        coords = loc.get("coordinates", {})
        slat = coords.get("lat")
        slon = coords.get("lng")
        if slat is None or slon is None:
            continue
        addr = loc.get("address", {})
        address_str = f"{addr.get('street', '')}, {addr.get('city', '')}".strip(", ")
        dist = _haversine_km(lat, lon, slat, slon)
        bearing = _bearing(lat, lon, slat, slon)
        pool.append(ChargingStation(
            name=loc.get("name", "Unbekannte Station"),
            address=address_str,
            lat=slat, lon=slon,
            distance_km=dist,
            heading_diff_deg=_angular_diff(heading, bearing),
            operator=ge_network,
        ))

    return _best_in_pool(pool) if pool else None


def _find_via_ocm(
    lat: float, lon: float, heading: float, network: str, radius_km: float
) -> ChargingStation | None:
    ocm_key = os.environ.get("OPENCHARGEMAP_API_KEY", "")
    params = {
        "output": "json",
        "latitude": lat, "longitude": lon,
        "distance": radius_km, "distanceunit": "KM",
        "maxresults": 100,
        "countrycode": "DE",
        "compact": "false",
        "verbose": "false",
    }
    if ocm_key:
        params["key"] = ocm_key

    resp = requests.get(OCM_API_URL, params=params, timeout=10)
    resp.raise_for_status()

    pool: list[ChargingStation] = []
    for poi in resp.json():
        operator_title = (poi.get("OperatorInfo") or {}).get("Title", "")
        if network.lower() not in operator_title.lower():
            continue
        addr = poi.get("AddressInfo", {})
        slat, slon = addr.get("Latitude"), addr.get("Longitude")
        if slat is None or slon is None:
            continue
        dist = _haversine_km(lat, lon, slat, slon)
        bearing = _bearing(lat, lon, slat, slon)
        pool.append(ChargingStation(
            name=addr.get("Title", "Unbekannte Station"),
            address=f"{addr.get('AddressLine1', '')}, {addr.get('Town', '')}".strip(", "),
            lat=slat, lon=slon,
            distance_km=dist,
            heading_diff_deg=_angular_diff(heading, bearing),
            operator=operator_title,
        ))

    return _best_in_pool(pool) if pool else None


def find_nearest(
    lat: float,
    lon: float,
    heading: float,
    network: str,
    radius_km: float = 15.0,
) -> ChargingStation | None:
    """
    Findet die nächste Ladestation in Fahrtrichtung.
    Nutzt GoingElectric (primär, bessere DE-Abdeckung) mit OCM als Fallback.
    """
    result = _find_via_goingelectric(lat, lon, heading, network, radius_km)
    if result is None:
        result = _find_via_ocm(lat, lon, heading, network, radius_km)
    return result
