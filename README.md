# Smart Classroom Ventilation

IoT semester project for **ETEW5E Internet of Things** (ČZU Prague, ZS 2026/27).

Every classroom has a CO₂ / temperature / humidity sensor. The system stores the readings and
shows each room as a traffic light, so the teacher knows when to open the window.

| CO₂ (ppm)   | Status     | Meaning                 |
|-------------|------------|-------------------------|
| < 1000      | `good`     | air quality is fine     |
| 1000 – 1400 | `warning`  | ventilation recommended |
| > 1400      | `critical` | ventilate now           |

## Architecture

```
 Node-RED "Sensor simulator"  (3 classrooms, one reading every 10 s)
        │  MQTT publish   classroom/<room>/telemetry   {"room","co2","temp","hum"}
        ▼
 Mosquitto (MQTT broker)
        │  MQTT subscribe classroom/+/telemetry
        ▼
 Node-RED "Ingest & classify"  validate → good / warning / critical → INSERT
        ▼
 PostgreSQL  (tables: rooms, measurements)
        ▼
 Grafana  (dashboard)
```

In a real deployment the simulator is replaced by an ESP32 + Sensirion SCD41 in every room,
publishing the same JSON to the same topic. The rest of the system stays the same.
The hardware is only part of the proposal (see `docs/`); the running demo uses simulated sensors.

## Quick start

Requirements: Docker Desktop (or Docker Engine + Compose v2).

```bash
cp .env.example .env      # then change the passwords in .env
docker compose up -d --build
```

| Service    | URL                     | Login                                   |
|------------|-------------------------|-----------------------------------------|
| Node-RED   | http://localhost:1880   | none (bound to localhost only)          |
| Grafana    | http://localhost:3000   | `GRAFANA_ADMIN_USER` / `_PASSWORD` from `.env` |
| PostgreSQL | `localhost:5432`        | `POSTGRES_USER` / `_PASSWORD` from `.env` |
| MQTT       | `localhost:1883`        | anonymous                               |

If port 5432 is already used by a local PostgreSQL, set `POSTGRES_HOST_PORT=5433` in `.env`.

### Check that data is flowing

```bash
# live MQTT messages
docker compose exec mosquitto mosquitto_sub -t 'classroom/#' -v

# latest rows in the database
docker compose exec postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT room_id, co2, temp, hum, status, ts FROM measurements ORDER BY id DESC LIMIT 9;"'
```

### Stop / reset

```bash
docker compose down        # stop, keep data
docker compose down -v     # stop and delete all data (DB is re-created from db/init.sql)
```

## Repository layout

```
docker-compose.yml          all services
.env.example                configuration template (.env is not committed)
mosquitto/mosquitto.conf    MQTT broker config
node-red/Dockerfile         Node-RED image + node-red-contrib-postgresql
node-red/data/flows.json    Node-RED flows (simulator, ingest)
db/init.sql                 database schema + classrooms
grafana/                    Grafana provisioning (datasource, dashboard)      — to do
docs/                       technical documentation, hardware, costs         — to do
video/                      Remotion project for the video presentation       — to do
```

## Working on the flows

Node-RED saves directly to `node-red/data/flows.json`, so after editing in the browser
and clicking **Deploy**, just commit that file. Database and MQTT connection settings
come from environment variables (see `docker-compose.yml`), so no passwords are stored in the flow.

On Linux, if Node-RED cannot write to `node-red/data`, run `sudo chown -R 1000:1000 node-red/data`.
