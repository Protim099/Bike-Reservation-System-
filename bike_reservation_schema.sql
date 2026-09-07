-- Bike Reservation — PostgreSQL schema
-- Matches the tables referenced in the Laravel backend (bikes, bookings,
-- payments) plus the users table extended with phone/role.
-- Run this against the `bike_reservation` database, or use it as a
-- reference alongside the Laravel migrations.

-- ── users ────────────────────────────────────────────────────────────────
-- Laravel's default users table, extended with phone + role.
CREATE TABLE IF NOT EXISTS users (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL UNIQUE,
    email_verified_at   TIMESTAMP NULL,
    password            VARCHAR(255) NOT NULL,
    phone               VARCHAR(30) NULL,
    role                VARCHAR(20) NOT NULL DEFAULT 'customer'
                        CHECK (role IN ('customer', 'admin')),
    remember_token      VARCHAR(100) NULL,
    created_at          TIMESTAMP NULL,
    updated_at          TIMESTAMP NULL
);

-- ── bikes ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bikes (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    type            VARCHAR(50)  NOT NULL,          -- e.g. city, mountain, electric
    model           VARCHAR(100) NULL,
    color           VARCHAR(30)  NULL,
    station_name    VARCHAR(255) NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'available'
                    CHECK (status IN ('available', 'booked', 'maintenance')),
    hourly_rate     NUMERIC(10, 2) NOT NULL,
    daily_rate      NUMERIC(10, 2) NOT NULL,
    image_url       VARCHAR(500) NULL,
    description     TEXT NULL,
    created_at      TIMESTAMP NULL,
    updated_at      TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS idx_bikes_status  ON bikes (status);
CREATE INDEX IF NOT EXISTS idx_bikes_type    ON bikes (type);
CREATE INDEX IF NOT EXISTS idx_bikes_station ON bikes (station_name);
CREATE INDEX IF NOT EXISTS idx_bikes_color   ON bikes (color);

-- ── bookings ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
    id              BIGSERIAL PRIMARY KEY,
    bike_id         BIGINT NOT NULL REFERENCES bikes(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time      TIMESTAMP NOT NULL,
    end_time        TIMESTAMP NOT NULL,
    duration_type   VARCHAR(10) NOT NULL CHECK (duration_type IN ('hourly', 'daily')),
    total_price     NUMERIC(10, 2) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending_payment'
                    CHECK (status IN ('pending_payment', 'confirmed', 'cancelled', 'completed')),
    created_at      TIMESTAMP NULL,
    updated_at      TIMESTAMP NULL,

    CONSTRAINT chk_booking_time_order CHECK (end_time > start_time)
);

-- Speeds up the overlap check BookingService runs before creating a booking.
CREATE INDEX IF NOT EXISTS idx_bookings_bike_time ON bookings (bike_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_bookings_user       ON bookings (user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status      ON bookings (status);

-- ── payments ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id              BIGSERIAL PRIMARY KEY,
    booking_id      BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    amount          NUMERIC(10, 2) NOT NULL,
    gateway         VARCHAR(30) NOT NULL DEFAULT 'sslcommerz',
    transaction_id  VARCHAR(255) NULL UNIQUE,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'success', 'failed', 'cancelled')),
    created_at      TIMESTAMP NULL,
    updated_at      TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments (booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_status  ON payments (status);

-- ── sample data (optional — remove if not needed) ───────────────────────
INSERT INTO bikes (name, type, model, color, station_name, status, hourly_rate, daily_rate)
VALUES
    ('City Cruiser #1', 'city',      'Cruiser X1', 'red',   'Dhanmondi Station',  'available', 30.00, 200.00),
    ('Trailblazer #2',  'mountain',  'Trail T2',   'green', 'Gulshan Station',    'available', 40.00, 280.00),
    ('E-Rider #3',      'electric',  'Volt E3',    'black', 'Uttara Station',     'available', 60.00, 400.00)
ON CONFLICT DO NOTHING;
