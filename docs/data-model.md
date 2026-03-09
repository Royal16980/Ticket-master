# Data model notes

This project uses the foundational schema in `database/migrations/0001_init.sql`.

## ERD-style relationships

- `users` is the root identity table.
  - `user_profiles.user_id -> users.id` (1:1, `ON DELETE CASCADE`).
  - `organisers.owner_user_id -> users.id` (N:1, `ON DELETE RESTRICT`).
  - `orders.user_id -> users.id` (optional N:1, `ON DELETE SET NULL`).
  - `tickets.holder_user_id -> users.id` (optional N:1, `ON DELETE SET NULL`).
  - `checkins.checked_in_by_user_id -> users.id` (optional N:1, `ON DELETE SET NULL`).
  - `reviews.user_id -> users.id` (N:1, `ON DELETE CASCADE`).
  - `points_ledger.user_id -> users.id` (N:1, `ON DELETE CASCADE`).

- `organisers.id -> events.organiser_id` (1:N, `ON DELETE RESTRICT`).

- `events` owns event-level entities.
  - `ticket_types.event_id -> events.id` (1:N, `ON DELETE CASCADE`).
  - `orders.event_id -> events.id` (1:N, `ON DELETE RESTRICT`).
  - `tickets.event_id -> events.id` (N:1, `ON DELETE RESTRICT`).
  - `checkins.event_id -> events.id` (N:1, `ON DELETE CASCADE`).
  - `referral_codes.event_id -> events.id` (optional N:1, `ON DELETE CASCADE`).
  - `promo_codes.event_id -> events.id` (optional N:1, `ON DELETE CASCADE`).
  - `reviews.event_id -> events.id` (N:1, `ON DELETE CASCADE`).
  - `fraud_flags.event_id -> events.id` (optional N:1, `ON DELETE SET NULL`).

- Commerce chain:
  - `orders.id -> order_items.order_id` (1:N, `ON DELETE CASCADE`).
  - `order_items.ticket_type_id -> ticket_types.id` (N:1, `ON DELETE RESTRICT`).
  - `tickets.order_item_id -> order_items.id` (N:1, `ON DELETE CASCADE`).
  - `tickets.order_id -> orders.id` (N:1, `ON DELETE CASCADE`).
  - `tickets.ticket_type_id -> ticket_types.id` (N:1, `ON DELETE RESTRICT`).

- Attribution and incentives:
  - `orders.referral_code_id -> referral_codes.id` (`ON DELETE SET NULL`).
  - `orders.promo_code_id -> promo_codes.id` (`ON DELETE SET NULL`).
  - `points_ledger.order_id -> orders.id` (`ON DELETE SET NULL`).
  - `points_ledger.referral_code_id -> referral_codes.id` (`ON DELETE SET NULL`).

- Trust/safety:
  - `fraud_flags` can reference `users`, `orders`, `tickets`, and `events` (all nullable FKs for flexible evidence linking).

## Key invariants

1. **Inventory locking / oversell prevention**
   - `ticket_types` tracks `inventory_total`, `inventory_reserved`, and `inventory_sold`.
   - Constraint: `inventory_reserved + inventory_sold <= inventory_total`.
   - `order_items` insert/update/delete triggers atomically reserve/release inventory rows with `SELECT ... FOR UPDATE` row locking.
   - `orders.status` transition trigger settles counters:
     - `pending -> paid`: reserved moves to sold.
     - `pending -> cancelled|expired`: reserved is released.
     - `paid -> refunded`: sold is decremented.

2. **Referral attribution**
   - `orders` stores nullable `referral_code_id` and `promo_code_id` to preserve attribution for each checkout.
   - `points_ledger` can point to both `order_id` and `referral_code_id` so reward grants/audits stay linkable even if referral owners change.

3. **Duplicate check-in prevention**
   - `checkins` has `UNIQUE(ticket_id, event_id)`.
   - Lookup index on `(ticket_id, event_id)` supports fast scanner validation and idempotent insert logic.

4. **Ticket authenticity**
   - `tickets.ticket_code` and `tickets.qr_token` are both unique to prevent collisions.

## Discovery and operational indexes

- Event discovery index: `events(category, city, starts_at)` plus support indexes on `(city, starts_at)` and `starts_at`.
- Check-in lookup index: `checkins(ticket_id, event_id)`.
- Additional lifecycle indexes exist for orders, tickets, reviews, points, and fraud workflows.
