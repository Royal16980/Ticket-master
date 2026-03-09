import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { db, seed, track } from './store.js';
import {
  signup,
  listTrendingEvents,
  createEvent,
  checkout,
  createReferralCode,
  checkinTicket,
  redeemReward,
  adminOverview
} from './services.js';

seed();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.post('/auth/signup', (req, res) => {
  try {
    res.status(201).json(signup(req.body));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.get('/events/trending', (_req, res) => res.json(listTrendingEvents()));

app.get('/events/:id', (req, res) => {
  const event = db.events.find((e) => e.id === req.params.id);
  if (!event) return res.status(404).json({ error: 'Event not found' });
  const ticketTypes = db.ticketTypes.filter((t) => t.eventId === event.id);
  track('event_viewed', { userId: 'anonymous', eventId: event.id, timestamp: new Date().toISOString() });
  res.json({ ...event, ticketTypes });
});

app.post('/organiser/events', (req, res) => {
  try {
    res.status(201).json(createEvent(req.body));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/tickets/checkout', (req, res) => {
  try {
    res.status(201).json(checkout(req.body));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/referrals/share', (req, res) => {
  try {
    res.status(201).json(createReferralCode(req.body));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/checkin/scan', (req, res) => {
  try {
    res.status(201).json(checkinTicket(req.body));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/rewards/redeem', (req, res) => {
  try {
    res.status(201).json(redeemReward(req.body));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.get('/admin/overview', (_req, res) => res.json(adminOverview()));
app.get('/analytics/events', (_req, res) => res.json(db.analytics));

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const webDir = path.resolve(__dirname, '../../web');
app.use(express.static(webDir));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Pulse Events API listening on ${port}`));
