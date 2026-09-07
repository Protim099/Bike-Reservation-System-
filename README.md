# Bike Reservation — Backend Core (Laravel 12 + PHP 8.4)

This is the **core booking API**: browse bikes, create/cancel bookings with
race-safe availability checking, and pay via SSLCommerz. It's meant to be
dropped into a fresh Laravel 12 install, not run standalone.

## What's included
- `database/migrations/` — bikes, bookings, payments tables + user phone/role
- `app/Models/` — Bike, Booking, Payment, User (with relations)
- `app/Services/BookingService.php` — **the core logic**: Redis-backed lock
  to prevent double-booking races, overlap-based availability check, and
  hourly/daily price calculation
- `app/Services/SslCommerzService.php` — payment session creation + callback
  handling (swap this class for Stripe/bKash later; controller stays the same)
- `app/Http/Controllers/Api/` — Auth, Bike, Booking, Payment controllers
- `routes/api.php` — full route list
- `.env.example` — all required env vars, including Postgres + Redis

## Setup

```bash
composer create-project laravel/laravel bike-reservation-backend
cd bike-reservation-backend

composer require laravel/sanctum

# Copy the files from this package over the fresh install:
# app/Models, app/Services, app/Http/Controllers/Api, app/Http/Requests,
# app/Http/Resources, database/migrations, routes/api.php

cp .env.example .env
php artisan key:generate
```

Add the `sslcommerz` block from `config/services_snippet.php` into your
`config/services.php`.

Enable Sanctum API auth in `bootstrap/app.php`:
```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->api(prepend: [
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
    ]);
})
```

Add to `config/app.php` (or read directly via `env()`):
```php
'frontend_url' => env('APP_FRONTEND_URL', 'http://localhost:3000'),
```

Set up Postgres + Redis (docker-compose is easiest — see below), then:

```bash
php artisan migrate
php artisan serve
```

## Quick docker-compose for local Postgres + Redis

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: bike_reservation
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports: ["5432:5432"]
  redis:
    image: redis:7
    ports: ["6379:6379"]
```

## API reference

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/register` | – | Create account, returns Sanctum token |
| POST | `/api/login` | – | Returns Sanctum token |
| POST | `/api/logout` | ✓ | Revoke current token |
| GET | `/api/me` | ✓ | Current user |
| GET | `/api/bikes?type=&status=&station_name=` | – | Browse bikes (cached 30s) |
| GET | `/api/bikes/{id}` | – | Bike detail |
| GET | `/api/bookings` | ✓ | Current user's bookings |
| POST | `/api/bookings` | ✓ | Create booking `{bike_id, start_time, end_time, duration_type}` |
| GET | `/api/bookings/{id}` | ✓ | Booking detail (owner only) |
| POST | `/api/bookings/{id}/cancel` | ✓ | Cancel a booking |
| POST | `/api/payments/initiate` | ✓ | `{booking_id}` → returns SSLCommerz redirect URL |
| POST | `/api/payments/callback/{success,fail,cancel,ipn}` | – | Gateway callbacks |

## Why the Redis lock in BookingService

Two users hitting "Book" on the same bike/slot within milliseconds of each
other is the classic double-booking bug. `Cache::lock()` (backed by Redis)
serializes the check-then-create for a given bike ID, and the DB transaction
with `lockForUpdate()` adds a second layer of protection at the database level.

## Next pieces (not built yet, per your scoping choice)
- Laravel Filament admin dashboard (manage bikes/bookings/payments)
- Laravel Reverb broadcasting for live bike status updates
- SMS/OTP verification on register (Twilio)
- Additional payment gateways (Stripe, bKash, Nagad) — implement the same
  two methods as `SslCommerzService` and swap it in `PaymentController`
- Next.js web frontend and Flutter app consuming this API
