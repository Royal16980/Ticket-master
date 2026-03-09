import test from 'node:test';
import assert from 'node:assert/strict';
import { db, seed } from '../src/store.js';
import { signup, checkout, checkinTicket, createReferralCode } from '../src/services.js';

seed();

test('checkout should reduce inventory and issue tickets', () => {
  const user = signup({ email: 'test1@pulse.com', name: 'Test User' });
  const event = db.events[0];
  const tt = db.ticketTypes.find((t) => t.eventId === event.id);
  const beforeSold = tt.sold;

  const result = checkout({ userId: user.id, eventId: event.id, ticketTypeId: tt.id, quantity: 2 });

  assert.equal(result.tickets.length, 2);
  assert.equal(tt.sold, beforeSold + 2);
});

test('checkin should prevent duplicate scans', () => {
  const user = signup({ email: 'test2@pulse.com', name: 'Scan User' });
  const event = db.events[0];
  const tt = db.ticketTypes.find((t) => t.eventId === event.id);
  const { tickets } = checkout({ userId: user.id, eventId: event.id, ticketTypeId: tt.id, quantity: 1 });

  checkinTicket({ qrToken: tickets[0].qrToken, checkedInBy: 'staff-1' });
  assert.throws(() => checkinTicket({ qrToken: tickets[0].qrToken, checkedInBy: 'staff-1' }));
});

test('referral should reward owner on friend purchase', () => {
  const owner = signup({ email: 'owner@pulse.com', name: 'Owner' });
  const buyer = signup({ email: 'buyer@pulse.com', name: 'Buyer' });
  const event = db.events[0];
  const tt = db.ticketTypes.find((t) => t.eventId === event.id);
  const referral = createReferralCode({ userId: owner.id, eventId: event.id });
  const startPoints = owner.points;

  checkout({ userId: buyer.id, eventId: event.id, ticketTypeId: tt.id, quantity: 1, referralCode: referral.code });

  assert.equal(owner.points, startPoints + 30);
});
