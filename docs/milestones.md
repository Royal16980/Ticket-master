# Milestones (Aligned to PRD Section 20)

> Assumption: PRD Section 20 defines phased delivery from foundation through scale. The phases below map that structure into execution milestones.

## Phase 1 — Foundation and Access

### Scope
- Core authentication (email/password and OTP) and baseline RBAC.
- Project scaffolding: API gateway, service templates, CI/CD, observability baseline.
- Initial admin roles and audit log framework.

### Dependencies
- Environment setup (cloud accounts, secrets manager, base networking).
- Identity provider decisions and security policy baselines.
- Logging/monitoring stack availability.

### Definition of done
- Users can sign up, sign in, refresh sessions, and sign out.
- RBAC enforcement is active on protected endpoints.
- Audit logs capture privileged actions and authentication events.
- CI pipeline includes lint/test/build and deploy-to-staging.

### Risks and mitigations
- **Risk:** RBAC model too coarse, causing future rework.  
  **Mitigation:** define permission matrix per role and add policy tests before widening scope.
- **Risk:** Security misconfiguration in early environments.  
  **Mitigation:** enforce baseline IaC policies and security checklist gate in CI.

---

## Phase 2 — Discovery and Event Publishing

### Scope
- Event creation/edit/publish workflow for organizers.
- Discovery APIs with search/filter/sort and pagination.
- Media upload support and public event detail pages/data contracts.

### Dependencies
- Phase 1 identity + RBAC controls.
- Storage/CDN and search/index infrastructure.
- Organizer moderation policy for publish flow.

### Definition of done
- Organizer can create and publish events with required metadata.
- End users can browse and search events with acceptable latency targets.
- Draft events are never exposed publicly.
- Search index remains consistent with source-of-truth update SLAs.

### Risks and mitigations
- **Risk:** Search relevance quality is poor at launch.  
  **Mitigation:** ship default ranking heuristics plus manual boosting controls.
- **Risk:** Event data quality inconsistency.  
  **Mitigation:** strict validation, required field checks, and moderation queue for risky listings.

---

## Phase 3 — Commerce (Ticketing, Orders, Payments)

### Scope
- Ticket type/inventory model, reservation holds, checkout, order lifecycle.
- Stripe payment intent integration and webhook-based reconciliation.
- Ticket fulfillment (QR issuance), receipts, refunds (initial policy).

### Dependencies
- Phase 2 event model and publish controls.
- Stripe account readiness, webhook endpoint, secrets and signing config.
- Email infrastructure for confirmation/receipt delivery.

### Definition of done
- Users can complete checkout for published events and receive valid tickets.
- Inventory is decremented safely; no oversell in normal and concurrent scenarios.
- Stripe webhook verification and idempotent event processing are in place.
- Refund path updates financial and fulfillment states correctly.

### Risks and mitigations
- **Risk:** Race conditions causing inventory oversell.  
  **Mitigation:** reservation TTL + transactional locks/idempotency keys + concurrency tests.
- **Risk:** Webhook replay or forgery.  
  **Mitigation:** strict signature verification, event-id dedupe store, timestamp tolerance checks.

---

## Phase 4 — Engagement (Rewards and Referrals)

### Scope
- Referral code generation/tracking and conversion attribution.
- Rewards ledger with accrual and redemption primitives.
- Campaign configuration for promotional boosts.

### Dependencies
- Phase 3 order completion events for reward triggers.
- Notification channels for user reward/referral updates.
- Abuse/fraud controls from commerce module.

### Definition of done
- Referral lifecycle works end-to-end (create, share, attribute, reward).
- Rewards ledger is immutable and supports reconciliation.
- Campaign rules can be enabled/disabled without code changes.

### Risks and mitigations
- **Risk:** Referral abuse and self-referral loops.  
  **Mitigation:** anti-abuse constraints (device/account/payment fingerprints, rule thresholds).
- **Risk:** Reward balance inconsistency.  
  **Mitigation:** append-only ledger model plus periodic reconciliation jobs.

---

## Phase 5 — Operations (Check-in, Moderation, Analytics)

### Scope
- Check-in scanning API with duplicate protection and offline sync flow.
- Moderation tools for user/event reports and admin actions.
- Analytics pipeline + operational dashboards (sales, attendance, conversion).

### Dependencies
- Phase 3 fulfilled tickets and payment/order events.
- Staff/admin RBAC extensions.
- Event stream and warehouse ingestion pipeline.

### Definition of done
- Staff can validate tickets in real time with low-latency responses.
- Duplicate/invalid scans are blocked and logged.
- Moderators can triage reports and take auditable actions.
- Dashboards expose agreed KPIs with documented refresh cadence.

### Risks and mitigations
- **Risk:** Venue connectivity issues degrade check-in throughput.  
  **Mitigation:** offline cache mode with eventual sync and conflict resolution rules.
- **Risk:** Analytics trust gap due to metric mismatches.  
  **Mitigation:** canonical metric definitions and automated data quality checks.
