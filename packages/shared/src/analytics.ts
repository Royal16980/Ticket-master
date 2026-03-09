/**
 * Canonical analytics event names defined from PRD section 21.
 */
export const ANALYTICS_EVENT_NAMES = [
  'signup_completed',
  'event_viewed',
  'ticket_checkout_started',
  'ticket_purchase_completed',
  'reward_redeemed',
  'checkin_completed',
  'review_submitted',
  'organiser_event_created',
] as const;

export type AnalyticsEventName = (typeof ANALYTICS_EVENT_NAMES)[number];

export const isAnalyticsEventName = (
  value: string,
): value is AnalyticsEventName => {
  return (ANALYTICS_EVENT_NAMES as readonly string[]).includes(value);
};
