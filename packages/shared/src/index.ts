export enum Role {
  Attendee = 'attendee',
  Organiser = 'organiser',
  CheckinStaff = 'checkin_staff',
  Admin = 'admin'
}

export interface Event {
  id: string;
  slug: string;
  name: string;
  startsAt: string;
  endsAt?: string;
  venueName?: string;
  organiserId: string;
}

export interface Ticket {
  id: string;
  eventId: string;
  purchaserId: string;
  ticketType: string;
  priceMinor: number;
  currency: string;
  status: 'reserved' | 'paid' | 'checked_in' | 'cancelled';
}

export interface Order {
  id: string;
  eventId: string;
  buyerId: string;
  ticketIds: string[];
  subtotalMinor: number;
  discountMinor: number;
  totalMinor: number;
  currency: string;
  createdAt: string;
}

export interface ReferralReward {
  id: string;
  referrerUserId: string;
  referredOrderId: string;
  rewardType: 'cash' | 'credit' | 'perk';
  rewardValue: number;
  status: 'pending' | 'approved' | 'rejected';
}
