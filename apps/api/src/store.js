import { v4 as uuidv4 } from 'uuid';

export const db = {
  users: [],
  organisers: [],
  events: [],
  ticketTypes: [],
  orders: [],
  tickets: [],
  checkins: [],
  referrals: [],
  pointsLedger: [],
  rewardsCatalog: [
    { code: 'DISC10', points: 100, label: '10% Discount' },
    { code: 'VIPUP', points: 200, label: 'VIP Upgrade' }
  ],
  analytics: []
};

export function track(event, payload) {
  db.analytics.push({ id: uuidv4(), event, payload, timestamp: new Date().toISOString() });
}

export function seed() {
  if (db.events.length) return;

  const organiserId = uuidv4();
  db.organisers.push({ id: organiserId, name: 'Pulse Originals' });

  const eventA = {
    id: uuidv4(),
    organiserId,
    title: 'City Night Festival',
    category: 'Nightlife',
    city: 'Lagos',
    venue: 'Pulse Arena',
    startTime: '2026-06-20T20:00:00.000Z',
    trendingScore: 99,
    published: true
  };

  const eventB = {
    id: uuidv4(),
    organiserId,
    title: 'Founders & Product Summit',
    category: 'Conference',
    city: 'Nairobi',
    venue: 'Summit Hall',
    startTime: '2026-07-12T09:00:00.000Z',
    trendingScore: 88,
    published: true
  };

  db.events.push(eventA, eventB);
  db.ticketTypes.push(
    { id: uuidv4(), eventId: eventA.id, name: 'General', price: 50, capacity: 100, sold: 0 },
    { id: uuidv4(), eventId: eventA.id, name: 'VIP', price: 120, capacity: 30, sold: 0 },
    { id: uuidv4(), eventId: eventB.id, name: 'Early Bird', price: 80, capacity: 80, sold: 0 }
  );
}
