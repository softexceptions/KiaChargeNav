# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projektbeschreibung

Vollständiger Kontext: `core/02 Projekte/KiaChargeNav.md`

Flutter-App + FastAPI-Backend: Spracheingabe während der Fahrt → nächste Ladestation in Fahrtrichtung finden → Ziel per Send2Car ins Kia-Navi einspeisen. Kein Routenplan — nur Koordinaten + Name werden übertragen, das Kia-Navi berechnet die Route selbst.

## Stack

| Schicht | Technologie |
|---|---|
| Mobile App | Flutter + Dart |
| Spracheingabe | `speech_to_text` |
| GPS + Heading | `geolocator` |
| Ladestation-Daten | OpenChargeMap API + GoingElectric API |
| Backend | FastAPI + Python |
| Kia-Anbindung | `hyundai-kia-connect-api` (PyPI) |
| Deployment | Proxmox LXC / Docker |

## Architektur

```
Nutzer spricht: „Shell-Ladestation"
  │
  ▼
Flutter App
  ├── speech_to_text → Keyword-Matching → Netzwerk-Filter
  ├── GPS: Koordinaten + Heading (Fahrtrichtung)
  ├── OpenChargeMap / GoingElectric API
  │     └── Filter: Netzwerk + Radius → nächste in Fahrtrichtung
  ├── UI: Bestätigung anzeigen (auto-dismiss 3 Sek.)
  └── HTTP POST → FastAPI Backend
                    └── hyundai-kia-connect-api
                          └── send_destination(lat, lon, name)
                                └── Kia Server (Mobilfunk)
                                      └── Popup im Fahrzeug-Display
```

**Sicherheitsregel:** Kia-Zugangsdaten liegen **ausschließlich** im Backend (`.env`). Die Flutter-App kennt nur die Backend-URL + einen API-Key als Bearer-Header.

## Build & Run

```bash
# Flutter (App)
flutter run                                   # über USB
flutter run --device-id <wireless-id>        # über WLAN (Android 11+)
flutter build apk --release                  # APK → build/app/outputs/flutter-apk/app-release.apk

# Backend (Python)
cd backend
python -m uvicorn main:app --reload          # Dev-Server

# Tests
flutter test                                  # alle Flutter-Tests
flutter test test/unit/foo_test.dart         # einzelner Test
cd backend && pytest                          # alle Python-Tests
cd backend && pytest tests/test_foo.py       # einzelner Test
```

## Workflow-Regeln

### Skills (automatisch anwenden)

- `.dart` Dateien → `/tdd` **vor** der Implementierung → implementieren → `/flutter-solid` danach
- `.py` Dateien → `/tdd` **vor** der Implementierung → implementieren → `/python-solid` danach
- UI-Arbeit → `/ui-ux-pro-max` mit Hinweis auf `core/02 Projekte/KiaChargeNav.md`

### context7-Pflicht

Vor jeder Library-Nutzung aktuelle Docs holen — nie auf Trainingswissen verlassen:

| Library | context7 | Hinweis |
|---|---|---|
| `riverpod` | ✅ Immer | API ändert sich aktiv |
| `speech_to_text` | ✅ Immer | Plattform-Konfiguration variiert |
| `geolocator` | ✅ Immer | Permissions-Setup ändert sich |
| `mocktail` | ✅ Immer | Syntax-Änderungen möglich |
| `FastAPI` | ✅ Immer | DI-Patterns und async-Verhalten |
| `hyundai-kia-connect-api` | ⚠️ Nicht in context7 | GitHub direkt lesen: https://github.com/Hyundai-Kia-Connect/hyundai_kia_connect_api |

## Bekannte Stolperfallen

- **Kia EU vs. US:** Immer `Region.Europe` setzen — falsche Region → Authentifizierungsfehler
- **Fahrzeug-ID:** Die API benötigt eine Vehicle-ID (mehrere Fahrzeuge im Account möglich) → beim ersten API-Test auslesen, in `.env` festhalten
- **GPS-Heading:** Bei Kurvenfahrt springt der Wert — Durchschnitt der letzten 5 Sekunden verwenden
- **Suchradius:** Als Konfigurationswert anlegen (Standard 15 km, Autobahn 30–50 km) — nicht hardcoden
- **Zwischenziel vs. Ziel:** Ob `send_destination` ein Waypoint oder neues Ziel setzt, muss beim ersten Live-Test geprüft werden
- **Backend-Auth:** `/send`-Endpoint muss durch API-Key geschützt sein — sonst öffentlich erreichbar

## UI-Anforderungen (Fahrer-Kontext)

Die App wird **während der Fahrt** benutzt — ein Finger, max. 1 Sekunde Blick.

- Touch-Targets min. 72px
- Schriftgröße min. 18sp
- Auto-dismiss nach 3 Sek. (Bestätigung), 4 Sek. (Fehlermeldung)
- Dark Mode als Standard
- Max. 2 Interaktionen pro Vorgang
- App darf **niemals einfrieren oder leeren Bildschirm zeigen** — jeder Fehler bekommt einen sichtbaren Toast

## Ressourcen

- [hyundai-kia-connect-api GitHub](https://github.com/Hyundai-Kia-Connect/hyundai_kia_connect_api)
- [OpenChargeMap API](https://openchargemap.org/site/develop/api)
- [GoingElectric API](https://www.goingelectric.de/stromtankstellen/api/)
- [Flutter speech_to_text](https://pub.dev/packages/speech_to_text)
- [Flutter geolocator](https://pub.dev/packages/geolocator)
