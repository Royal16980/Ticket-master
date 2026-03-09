# Ticket-master

Monorepo starter structure for a ticketing platform with clear app/service boundaries.

## Workspace layout

```text
.
├── apps
│   ├── api          # Express + TypeScript API service starter
│   └── web          # Next.js + TypeScript + Tailwind frontend starter
├── packages
│   └── shared       # Shared types/constants used by apps
├── package.json     # Root workspace config and shared scripts
└── tsconfig.base.json
```

## Prerequisites

- Node.js 20+
- npm 10+

## Local setup

1. Install dependencies at repo root:

   ```bash
   npm install
   ```

2. Copy API environment variables:

   ```bash
   cp apps/api/.env.example apps/api/.env
   ```

## Run commands

From the repo root:

- Start web app (Next.js):

  ```bash
  npm run dev:web
  ```

- Start API service:

  ```bash
  npm run dev:api
  ```

- Build all workspaces:

  ```bash
  npm run build
  ```

- Typecheck all workspaces:

  ```bash
  npm run typecheck
  ```

## Notes

- `apps/api` exposes a starter health endpoint at `GET /health`.
- `packages/shared/src/index.ts` includes role enums and core domain interfaces (`Event`, `Ticket`, `Order`, `ReferralReward`) for immediate shared usage.
