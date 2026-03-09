# Initial API Surface (REST/RPC + Event/Webhook Contracts)

This document defines a first-pass API and event contract surface for implementation planning.

## Conventions

- Base REST path: `/api/v1`.
- Auth: `Authorization: Bearer <JWT>` unless marked public.
- Idempotency for writes: `Idempotency-Key` header on checkout/payment/refund operations.
- Traceability: `X-Request-Id` echoed by APIs.

---

## 1) Authentication and RBAC

### REST endpoints
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`
- `GET /api/v1/users/{userId}/roles` (admin)
- `PUT /api/v1/users/{userId}/roles` (admin)

### RPC-style operations (internal)
- `AuthService.ValidateToken(token) -> principal`
- `RbacService.CheckPermission(principal, resource, action) -> allow|deny`

---

## 2) Event discovery

### REST endpoints
- `GET /api/v1/events` (search/filter/sort/paginate)
- `GET /api/v1/events/{eventId}`
- `POST /api/v1/events` (organizer)
- `PATCH /api/v1/events/{eventId}` (organizer)
- `POST /api/v1/events/{eventId}/publish` (organizer/moderator)
- `POST /api/v1/events/{eventId}/unpublish` (organizer/moderator)
- `POST /api/v1/events/{eventId}/media` (organizer)

### RPC-style operations (internal)
- `SearchService.IndexEvent(eventDocument)`
- `SearchService.QueryEvents(query) -> resultSet`

---

## 3) Ticketing / orders / payments

### REST endpoints
- `GET /api/v1/events/{eventId}/ticket-types`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders` (create pending order + reservation hold)
- `GET /api/v1/orders/{orderId}`
- `POST /api/v1/orders/{orderId}/confirm`
- `POST /api/v1/payments/intents`
- `POST /api/v1/payments/{paymentId}/capture` (if manual capture flow)
- `POST /api/v1/orders/{orderId}/cancel`
- `POST /api/v1/refunds`
- `GET /api/v1/tickets/{ticketId}`
- `GET /api/v1/users/me/tickets`

### RPC-style operations (internal)
- `InventoryService.Hold(request) -> holdId, expiresAt`
- `InventoryService.CommitHold(holdId)`
- `InventoryService.ReleaseHold(holdId)`
- `PaymentService.ReconcileGatewayEvent(event)`
- `FulfillmentService.IssueTickets(orderId)`

---

## 4) Rewards / referrals

### REST endpoints
- `GET /api/v1/rewards/balance`
- `GET /api/v1/rewards/ledger`
- `POST /api/v1/rewards/redeem`
- `POST /api/v1/referrals`
- `GET /api/v1/referrals/me`
- `POST /api/v1/referrals/validate`

### RPC-style operations (internal)
- `RewardsService.Accrue(userId, sourceEvent, amount)`
- `RewardsService.Redeem(userId, rewardId)`
- `ReferralService.AttributeConversion(referralCode, orderId)`

---

## 5) Check-in

### REST endpoints
- `POST /api/v1/checkin/validate`
- `POST /api/v1/checkin/scan`
- `GET /api/v1/events/{eventId}/checkins` (staff/admin)
- `POST /api/v1/checkin/sync` (offline client batch sync)

### RPC-style operations (internal)
- `CheckinService.ValidateTicket(scanToken, eventId)`
- `CheckinService.MarkCheckedIn(ticketId, staffId, gateId)`

---

## 6) Admin moderation / analytics

### REST endpoints
- `POST /api/v1/moderation/reports`
- `GET /api/v1/moderation/reports` (moderator)
- `POST /api/v1/moderation/reports/{reportId}/resolve` (moderator)
- `POST /api/v1/admin/events/{eventId}/review` (moderator/admin)
- `GET /api/v1/admin/analytics/kpis` (admin)
- `GET /api/v1/admin/analytics/sales` (admin)
- `GET /api/v1/admin/analytics/attendance` (admin)

### RPC-style operations (internal)
- `ModerationService.ApplyAction(subject, action, reason)`
- `AnalyticsService.Query(metric, dimensions, range)`

---

## Event contracts (domain events)

Use an event bus topic naming pattern: `tm.<domain>.<event_name>.v1`.

- `tm.auth.user_registered.v1`
  - Payload: `userId`, `email`, `createdAt`.
- `tm.events.event_published.v1`
  - Payload: `eventId`, `organizerId`, `publishedAt`.
- `tm.orders.order_created.v1`
  - Payload: `orderId`, `userId`, `eventId`, `amount`, `currency`, `createdAt`.
- `tm.payments.payment_succeeded.v1`
  - Payload: `paymentId`, `orderId`, `gateway`, `gatewayEventId`, `capturedAt`.
- `tm.tickets.ticket_issued.v1`
  - Payload: `ticketId`, `orderId`, `eventId`, `ownerUserId`, `issuedAt`.
- `tm.referrals.referral_converted.v1`
  - Payload: `referralId`, `referrerUserId`, `referredUserId`, `orderId`, `convertedAt`.
- `tm.checkin.ticket_checked_in.v1`
  - Payload: `ticketId`, `eventId`, `staffId`, `gateId`, `checkedInAt`.

---

## Webhook contracts

### Stripe inbound webhook
- Endpoint: `POST /api/v1/webhooks/stripe`
- Required headers:
  - `Stripe-Signature`
  - `Content-Type: application/json`
- Expected events (initial):
  - `payment_intent.succeeded`
  - `payment_intent.payment_failed`
  - `charge.refunded`
  - `charge.dispute.created`

### Verification and processing requirements
1. Read the **raw request body** bytes (no prior JSON mutation).
2. Verify signature with Stripe webhook secret.
3. Enforce timestamp tolerance (e.g., 5 minutes) to reduce replay risk.
4. Deduplicate by Stripe `event.id` in durable storage.
5. Process asynchronously via queue/job worker for reliability.
6. Return `2xx` only when event accepted for processing.

### Internal webhook fan-out (optional)
- `POST /api/v1/webhooks/internal/order-paid`
- `POST /api/v1/webhooks/internal/ticket-issued`

Use HMAC signatures (`X-Signature`, `X-Timestamp`) and the same replay/idempotency safeguards.
