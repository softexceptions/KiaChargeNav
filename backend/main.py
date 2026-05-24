import os
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from hyundai_kia_connect_api import VehicleManager, POIInfo, POICoord
from services.charging_service import find_nearest

load_dotenv()

app = FastAPI(title="KiaChargeNav Backend")

_vm: VehicleManager | None = None


def get_vm() -> VehicleManager:
    global _vm
    if _vm is None:
        _vm = VehicleManager(
            region=1,
            brand=1,
            username=os.environ["KIA_USERNAME"],
            password=os.environ["KIA_PASSWORD"],
            pin=os.environ["KIA_PIN"],
            language="de",
        )
        _vm.check_and_refresh_token()
    return _vm


class SendRequest(BaseModel):
    name: str
    address: str
    lat: float
    lon: float


@app.post("/send")
def send_destination(
    req: SendRequest,
    x_api_key: str = Header(...),
):
    if x_api_key != os.environ["API_KEY"]:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if os.environ.get("DRY_RUN", "false").lower() == "true":
        return {"status": "sent", "message_id": "dry-run"}

    vehicle_id = os.environ["KIA_VEHICLE_ID"]
    vm = get_vm()
    try:
        vm.check_and_refresh_token()
        poi = POIInfo(
            name=req.name,
            addr=req.address,
            coord=POICoord(lat=req.lat, lon=req.lon),
        )
        msg_id = vm.set_navigation(vehicle_id, [poi])
        return {"status": "sent", "message_id": msg_id}
    except Exception as e:
        _vm = None  # Token zurücksetzen bei Fehler
        raise HTTPException(status_code=502, detail=str(e))


class FindRequest(BaseModel):
    lat: float
    lon: float
    heading: float
    network: str
    radius_km: float = 15.0


@app.post("/find")
def find_station(
    req: FindRequest,
    x_api_key: str = Header(...),
):
    if x_api_key != os.environ["API_KEY"]:
        raise HTTPException(status_code=401, detail="Unauthorized")

    station = find_nearest(
        lat=req.lat,
        lon=req.lon,
        heading=req.heading,
        network=req.network,
        radius_km=req.radius_km,
    )
    if station is None:
        raise HTTPException(
            status_code=404,
            detail=f"Keine {req.network}-Station in {req.radius_km} km Fahrtrichtung gefunden.",
        )
    return {
        "name": station.name,
        "address": station.address,
        "lat": station.lat,
        "lon": station.lon,
        "distance_km": round(station.distance_km, 1),
        "heading_diff_deg": round(station.heading_diff_deg, 1),
        "operator": station.operator,
    }


@app.get("/health")
def health():
    return {"status": "ok"}
