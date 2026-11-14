-- Runs once, when the PostgreSQL volume is created for the first time.

CREATE TABLE rooms (
    id        VARCHAR(16) PRIMARY KEY,          -- e.g. 'C21', also used in the MQTT topic
    name      TEXT        NOT NULL,
    building  TEXT        NOT NULL,
    capacity  INTEGER     NOT NULL
);

CREATE TABLE measurements (
    id       BIGSERIAL    PRIMARY KEY,
    room_id  VARCHAR(16)  NOT NULL REFERENCES rooms(id),
    co2      INTEGER      NOT NULL,             -- ppm
    temp     NUMERIC(4,1) NOT NULL,             -- °C
    hum      NUMERIC(4,1) NOT NULL,             -- % RH
    status   VARCHAR(8)   NOT NULL CHECK (status IN ('good', 'warning', 'critical')),
    ts       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX measurements_room_ts_idx ON measurements (room_id, ts DESC);

INSERT INTO rooms (id, name, building, capacity) VALUES
    ('C21',  'Seminar room C21', 'C', 30),
    ('E101', 'Lecture hall E101', 'E', 120),
    ('D105', 'Computer lab D105', 'D', 20);
