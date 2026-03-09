# API Surface (MVP)

## Public/Attendee
- `POST /auth/signup`
- `GET /events/trending`
- `GET /events/:id`
- `POST /tickets/checkout`
- `POST /referrals/share`
- `POST /rewards/redeem`

## Organiser
- `POST /organiser/events`

## Check-in Staff
- `POST /checkin/scan`

## Admin
- `GET /admin/overview`
- `GET /analytics/events`

## Webhooks
- `POST /webhooks/stripe` (planned):
  - Verify Stripe signature header before processing.
  - Apply idempotency key checks.
  - Confirm payment intent before marking order paid.
