# Pulse Events Architecture

## Runtime Components
- **Web app (`apps/web`)**: mobile-first attendee discovery and checkout UI.
- **API service (`apps/api`)**: role-aware endpoints for attendees, organisers, check-in staff, and admins.
- **Shared package (`packages/shared`)**: canonical roles and analytics event contracts.
- **Database (planned PostgreSQL)**: schema baseline under `database/migrations`.

## Core Modules
1. Authentication + user profiles (`/auth/signup`, roles in shared package)
2. Event discovery (`/events/trending`, `/events/:id`)
3. Ticketing/orders (`/tickets/checkout`)
4. Referrals + rewards (`/referrals/share`, `/rewards/redeem`)
5. Check-in validation (`/checkin/scan`)
6. Admin and moderation metrics (`/admin/overview`)
7. Analytics stream (`/analytics/events`)

## Reliability and Security Controls
- Inventory guard prevents overselling at checkout.
- Duplicate check-in detection blocks second scan.
- Structured analytics supports fraud and funnel monitoring.
- Stripe webhook verification reserved in API surface doc for payment integrity.
