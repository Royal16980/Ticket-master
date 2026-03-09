export const analyticsEventSchema = {
  signup_completed: ['userId', 'role', 'timestamp'],
  event_viewed: ['userId', 'eventId', 'timestamp'],
  ticket_checkout_started: ['userId', 'eventId', 'ticketTypeId', 'quantity', 'timestamp'],
  ticket_purchase_completed: ['userId', 'eventId', 'orderId', 'amount', 'timestamp'],
  reward_redeemed: ['userId', 'rewardCode', 'pointsSpent', 'timestamp'],
  checkin_completed: ['ticketId', 'eventId', 'checkedInBy', 'timestamp'],
  review_submitted: ['userId', 'eventId', 'rating', 'timestamp'],
  organiser_event_created: ['organiserId', 'eventId', 'timestamp']
};
