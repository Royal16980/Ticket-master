# Data Model Notes

## Invariants
- A ticket QR token is globally unique.
- A ticket can be checked in once.
- Ticket type `sold` must never exceed `capacity`.
- Referral rewards apply only to matching event and valid code.

## Relationships
- organiser 1..* events
- event 1..* ticket_types
- order 1..* tickets
- ticket 0..1 checkin
- user 1..* points_ledger entries
