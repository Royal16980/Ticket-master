# Analytics Events (PRD §21)

This document defines payload expectations for the analytics events listed in PRD section 21 and provides implementation guidance for consistency, deduplication, and schema evolution.

## Canonical Event Names

- `signup_completed`
- `event_viewed`
- `ticket_checkout_started`
- `ticket_purchase_completed`
- `reward_redeemed`
- `checkin_completed`
- `review_submitted`
- `organiser_event_created`

## Common Envelope (all events)

All events should include the following top-level fields:

- `event_name` (string): one of the canonical event names.
- `event_version` (string): semantic schema version for this event payload (for example `"1.0"`).
- `event_id` (string, UUID recommended): globally unique identifier for this emitted analytics record.
- `occurred_at` (string, ISO-8601 UTC): business timestamp for when the user/business action occurred.
- `emitted_at` (string, ISO-8601 UTC): timestamp when the analytics producer sent the event.
- `source` (enum): `client` or `server`.

## Timestamp Source & Timezone Policy

- **Timezone standard:** all transmitted timestamps must be normalized to UTC (`Z` suffix).
- **Client-emitted events:**
  - `occurred_at` should use the client-side interaction time.
  - `emitted_at` should use the send time from the client transport.
- **Server-emitted events:**
  - Prefer database-backed business timestamps (for example payment capture time, check-in persisted time) for `occurred_at`.
  - Use server send time for `emitted_at`.
- If local time must be retained for analysis, include optional `occurred_at_local` and `timezone` fields; do not replace UTC fields.

## Per-Event Payload Schema

### 1) `signup_completed`

**Required identifiers**

- `user_id`

**Recommended fields**

- `signup_method` (email, google, apple, etc.)
- `is_new_device` (boolean)

**Emission rule**

- Emit once after account creation is fully persisted (server preferred).

### 2) `event_viewed`

**Required identifiers**

- `user_id` (or `anonymous_id` when unauthenticated)
- `event_id`

**Recommended fields**

- `referrer`
- `surface` (home_feed, search, deep_link, etc.)

**Emission rule**

- Client emits on screen render completion (not on initial route intent).

### 3) `ticket_checkout_started`

**Required identifiers**

- `user_id`
- `event_id`
- `checkout_id`

**Recommended fields**

- `ticket_type_ids` (array)
- `currency`
- `subtotal_amount`

**Emission rule**

- Emit when checkout session is initialized and quote is available.

### 4) `ticket_purchase_completed`

**Required identifiers**

- `user_id`
- `event_id`
- `order_id`
- `payment_intent_id` (or provider-equivalent transaction id)

**Recommended fields**

- `total_amount`
- `currency`
- `ticket_count`
- `promotion_id` (if applicable)

**Emission rule**

- **Server must be source of truth** and emit only after durable payment success + order persistence.

### 5) `reward_redeemed`

**Required identifiers**

- `user_id`
- `reward_id`
- `redemption_id`

**Recommended fields**

- `points_spent`
- `remaining_points`

**Emission rule**

- Emit from server transaction boundary after redemption state commit.

### 6) `checkin_completed`

**Required identifiers**

- `user_id`
- `event_id`
- `checkin_id`

**Recommended fields**

- `checkin_method` (qr, manual, nfc)
- `gate_id`

**Emission rule**

- Server emits after check-in is persisted as successful.

### 7) `review_submitted`

**Required identifiers**

- `user_id`
- `event_id`
- `review_id`

**Recommended fields**

- `rating`
- `has_text` (boolean)

**Emission rule**

- Emit once after review write succeeds.

### 8) `organiser_event_created`

**Required identifiers**

- `organiser_id`
- `event_id`

**Recommended fields**

- `category`
- `is_paid_event`
- `publish_state` (draft/published)

**Emission rule**

- Emit from server after event record creation commit.

## Client vs Server Emission Rules

- Prefer **server emission** for irreversible or money-sensitive lifecycle events:
  - `ticket_purchase_completed`
  - `checkin_completed`
  - `reward_redeemed`
  - `organiser_event_created`
- Client emission is acceptable for discovery/UX events where eventual consistency is acceptable:
  - `event_viewed`
  - `ticket_checkout_started`
- For `signup_completed` and `review_submitted`, either side may emit, but only one system should be authoritative in production to avoid duplicates.

## Deduplication Strategy (Payments & Check-ins)

For `ticket_purchase_completed` and `checkin_completed`:

1. Generate deterministic idempotency keys:
   - purchase: `purchase:{order_id}:{payment_intent_id}`
   - check-in: `checkin:{checkin_id}`
2. Store and enforce uniqueness server-side before publishing analytics.
3. Replays/retries should reuse the same `event_id` when possible.
4. Downstream warehouse should also de-duplicate by (`event_name`, business key, `occurred_at` date bucket) as a safety net.

## Validation, Versioning, and Backward Compatibility Guidance

- Define JSON Schema (or equivalent runtime validator) per `event_name` + `event_version`.
- Treat `event_version` as required and immutable once emitted.
- Backward-compatible changes:
  - adding optional fields
  - widening enum values (with consumer fallback handling)
- Breaking changes require version bump (for example `1.0` -> `2.0`) and dual-write/dual-read migration window.
- Validation should enforce:
  - presence of required identifiers
  - timestamp format and UTC normalization
  - source-specific required fields where applicable
- Keep a schema registry table in-repo and in ingestion service; reject unknown `event_name` or unsupported `event_version`.
