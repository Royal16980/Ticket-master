import { v4 as uuidv4 } from 'uuid';
import { db, track } from './store.js';

export function signup({ email, name, role = 'attendee' }) {
  const user = { id: uuidv4(), email, name, role, points: 0, createdAt: new Date().toISOString() };
  db.users.push(user);
  track('signup_completed', { userId: user.id, role: user.role, timestamp: user.createdAt });
  return user;
}

export function listTrendingEvents() {
  return [...db.events].sort((a, b) => b.trendingScore - a.trendingScore);
}

export function createEvent({ organiserId, title, category, city, venue, startTime, tickets }) {
  const event = { id: uuidv4(), organiserId, title, category, city, venue, startTime, trendingScore: 50, published: true };
  db.events.push(event);
  for (const t of tickets) {
    db.ticketTypes.push({ id: uuidv4(), eventId: event.id, name: t.name, price: t.price, capacity: t.capacity, sold: 0 });
  }
  track('organiser_event_created', { organiserId, eventId: event.id, timestamp: new Date().toISOString() });
  return event;
}

export function checkout({ userId, eventId, ticketTypeId, quantity, referralCode }) {
  const ticketType = db.ticketTypes.find((t) => t.id === ticketTypeId && t.eventId === eventId);
  if (!ticketType) throw new Error('Ticket type not found');
  if (ticketType.sold + quantity > ticketType.capacity) throw new Error('Insufficient inventory');

  track('ticket_checkout_started', { userId, eventId, ticketTypeId, quantity, timestamp: new Date().toISOString() });

  ticketType.sold += quantity;
  const total = ticketType.price * quantity;
  const order = { id: uuidv4(), userId, eventId, amount: total, quantity, status: 'paid', createdAt: new Date().toISOString() };
  db.orders.push(order);

  const createdTickets = Array.from({ length: quantity }).map(() => {
    const ticket = { id: uuidv4(), orderId: order.id, eventId, userId, qrToken: uuidv4(), used: false };
    db.tickets.push(ticket);
    return ticket;
  });

  const buyer = db.users.find((u) => u.id === userId);
  if (buyer) {
    buyer.points += 20;
    db.pointsLedger.push({ id: uuidv4(), userId, reason: 'attend_purchase', points: 20 });
  }

  if (referralCode) applyReferralReward(referralCode, order);

  track('ticket_purchase_completed', { userId, eventId, orderId: order.id, amount: total, timestamp: new Date().toISOString() });
  return { order, tickets: createdTickets };
}

export function createReferralCode({ userId, eventId }) {
  const code = `REF-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
  const record = { id: uuidv4(), code, userId, eventId, createdAt: new Date().toISOString() };
  db.referrals.push(record);

  const user = db.users.find((u) => u.id === userId);
  if (user) {
    user.points += 5;
    db.pointsLedger.push({ id: uuidv4(), userId, reason: 'share_event', points: 5 });
  }

  return record;
}

function applyReferralReward(referralCode, order) {
  const referral = db.referrals.find((r) => r.code === referralCode && r.eventId === order.eventId);
  if (!referral) return;

  const owner = db.users.find((u) => u.id === referral.userId);
  if (owner) {
    owner.points += 30;
    db.pointsLedger.push({ id: uuidv4(), userId: owner.id, reason: 'friend_purchase', points: 30, orderId: order.id });
  }
}

export function checkinTicket({ qrToken, checkedInBy }) {
  const ticket = db.tickets.find((t) => t.qrToken === qrToken);
  if (!ticket) throw new Error('Ticket not found');
  if (ticket.used) throw new Error('Ticket already used');

  ticket.used = true;
  const checkin = { id: uuidv4(), ticketId: ticket.id, eventId: ticket.eventId, checkedInBy, checkedInAt: new Date().toISOString() };
  db.checkins.push(checkin);
  track('checkin_completed', { ticketId: ticket.id, eventId: ticket.eventId, checkedInBy, timestamp: checkin.checkedInAt });
  return checkin;
}

export function redeemReward({ userId, rewardCode }) {
  const user = db.users.find((u) => u.id === userId);
  if (!user) throw new Error('User not found');

  const reward = db.rewardsCatalog.find((r) => r.code === rewardCode);
  if (!reward) throw new Error('Reward not found');
  if (user.points < reward.points) throw new Error('Insufficient points');

  user.points -= reward.points;
  db.pointsLedger.push({ id: uuidv4(), userId, reason: 'reward_redeemed', points: -reward.points, rewardCode });
  track('reward_redeemed', { userId, rewardCode, pointsSpent: reward.points, timestamp: new Date().toISOString() });
  return { userId, rewardCode, remainingPoints: user.points };
}

export function adminOverview() {
  return {
    users: db.users.length,
    events: db.events.length,
    ticketsIssued: db.tickets.length,
    checkins: db.checkins.length,
    grossSales: db.orders.reduce((sum, o) => sum + o.amount, 0),
    analyticsEvents: db.analytics.length
  };
}
