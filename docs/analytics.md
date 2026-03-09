# Analytics Contract

Event names are sourced from `packages/shared/src/index.js`.

## Emission policy
- Client emits discovery/UI events (e.g. `event_viewed`).
- Server emits financial and integrity events (`ticket_purchase_completed`, `checkin_completed`).

## Required identifiers
- `signup_completed`: `userId`, `role`
- `event_viewed`: `userId`, `eventId`
- `ticket_checkout_started`: `userId`, `eventId`, `ticketTypeId`, `quantity`
- `ticket_purchase_completed`: `userId`, `eventId`, `orderId`, `amount`
- `reward_redeemed`: `userId`, `rewardCode`, `pointsSpent`
- `checkin_completed`: `ticketId`, `eventId`, `checkedInBy`
- `review_submitted`: `userId`, `eventId`, `rating`
- `organiser_event_created`: `organiserId`, `eventId`

All payloads include ISO8601 UTC timestamp and should be versioned if schema evolves.
