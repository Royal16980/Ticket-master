# Pulse Events (Ticket-master)

Pulse Events is a social event discovery and ticketing platform with attendee, organiser, check-in, and admin flows.

## Workspace layout
- `apps/api`: Express API implementing core MVP workflows.
- `apps/web`: Mobile-first web UI served by the API.
- `packages/shared`: Shared role and analytics contracts.
- `database/migrations`: PostgreSQL schema baseline.
- `docs`: Architecture, milestones, API surface, analytics, and data model notes.

## Quick start
```bash
npm install
npm run dev
```
Then open `http://localhost:3000`.

## Core endpoints
- `POST /auth/signup`
- `GET /events/trending`
- `POST /tickets/checkout`
- `POST /referrals/share`
- `POST /checkin/scan`
- `GET /admin/overview`

## Validation
```bash
npm test
```
