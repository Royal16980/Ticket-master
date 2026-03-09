# Architecture Mapping: PRD to Technical Modules

This document maps the core PRD functional sections to the initial technical module boundaries.

## 1) Authentication and RBAC

**Primary services/modules**
- `identity-service`: user registration/login, token issuance, session lifecycle.
- `rbac-service`: role and permission models (attendee, organizer, staff, admin, moderator).
- `auth-gateway-middleware`: request authentication and authorization checks at API boundary.

**Key data domains**
- Users, identities, credentials, OAuth links, roles, permission grants, audit events.

**Core integrations**
- Email/SMS provider for OTP and verification.
- OAuth providers (optional phase).

**Cross-cutting concerns**
- Token revocation strategy, permission cache invalidation, and audit logging for all privileged actions.

---

## 2) Event discovery

**Primary services/modules**
- `event-catalog-service`: event CRUD, organizer ownership, publishing states.
- `search-indexer`: denormalized index for fast browse/filter/sort.
- `discovery-api`: faceted search endpoints, recommendation hooks.

**Key data domains**
- Events, venues, categories, tags, organizer profiles, media assets.

**Core integrations**
- Search backend (Postgres full-text / OpenSearch / Algolia depending on scale).
- CDN/object storage for event images.

**Cross-cutting concerns**
- Ranking quality, cache invalidation, draft vs published visibility constraints.

---

## 3) Ticketing / orders / payments

**Primary services/modules**
- `inventory-service`: ticket types, quotas, holds, reservation TTL, oversell protection.
- `order-service`: cart/checkout orchestration, order state machine.
- `payment-service`: payment intent creation, reconciliation, refund orchestration.
- `fulfillment-service`: ticket issuance (QR/barcode), receipt and confirmation delivery.

**Key data domains**
- Ticket classes, reservations, orders, line items, payments, refunds, invoices.

**Core integrations**
- Stripe (payment intents, refunds, disputes, webhooks).
- Tax and invoicing provider (region-dependent).

**Cross-cutting concerns**
- Idempotent checkout, transactional consistency around inventory decrement, anti-fraud controls.

---

## 4) Rewards / referrals

**Primary services/modules**
- `rewards-ledger-service`: immutable points and rewards transaction ledger.
- `referral-service`: referral code generation, attribution, anti-abuse checks.
- `campaign-service`: reward rules and promotional campaign configuration.

**Key data domains**
- Reward balances, accrual/redemption entries, referral links, conversion events.

**Core integrations**
- Notification systems (email/push) for reward/referral milestones.

**Cross-cutting concerns**
- Double-spend prevention, expiry processing, abuse detection heuristics.

---

## 5) Check-in

**Primary services/modules**
- `checkin-service`: ticket validation, check-in status transitions, duplicate entry prevention.
- `scanner-client-api`: low-latency validation APIs for staff devices.
- `offline-sync-module`: local cache and reconciliation for intermittent connectivity.

**Key data domains**
- Ticket validation tokens, check-in logs, device/staff audit trail.

**Core integrations**
- Device management/MDM (optional), analytics stream for live attendance.

**Cross-cutting concerns**
- P99 latency target for scan operations, replay attack prevention, eventual consistency in offline mode.

---

## 6) Admin moderation / analytics

**Primary services/modules**
- `moderation-service`: user/event/report workflows, sanctions, escalation queue.
- `admin-console-backend`: privileged operations and policy controls.
- `analytics-pipeline`: event stream ingestion, aggregation, dashboard-ready marts.

**Key data domains**
- Moderation reports/actions, policy violations, aggregate KPIs, cohorts.

**Core integrations**
- BI warehouse (BigQuery/Snowflake/Redshift), alerting/incident systems.

**Cross-cutting concerns**
- PII minimization, role-segregated admin privileges, auditable moderation decisions.

---

## Shared platform foundations

- **API gateway + service mesh:** routing, auth enforcement, observability.
- **Event bus:** asynchronous domain events (order paid, ticket issued, referral converted, checked in).
- **Data platform:** OLTP store(s), cache, search index, analytics warehouse.
- **Observability:** structured logs, traces, SLO dashboards, security/audit logs.
- **Security/compliance:** secrets management, encryption at rest/in transit, webhook signature verification, retention policies.
