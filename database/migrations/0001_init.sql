BEGIN;

-- Core identity tables
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_profiles (
    user_id BIGINT PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    city TEXT,
    country_code CHAR(2),
    birth_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_profiles_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE TABLE organisers (
    id BIGSERIAL PRIMARY KEY,
    owner_user_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    bio TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_organisers_owner
        FOREIGN KEY (owner_user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
);

-- Event and catalog
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    organiser_id BIGINT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    city TEXT NOT NULL,
    venue_name TEXT,
    venue_address TEXT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
    capacity INTEGER CHECK (capacity IS NULL OR capacity >= 0),
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_events_organiser
        FOREIGN KEY (organiser_id)
        REFERENCES organisers(id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_events_time_range CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX idx_events_category_city_start_time ON events(category, city, starts_at);
CREATE INDEX idx_events_city_start_time ON events(city, starts_at);
CREATE INDEX idx_events_starts_at ON events(starts_at);

CREATE TABLE ticket_types (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    currency CHAR(3) NOT NULL,
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    inventory_total INTEGER NOT NULL CHECK (inventory_total >= 0),
    inventory_reserved INTEGER NOT NULL DEFAULT 0 CHECK (inventory_reserved >= 0),
    inventory_sold INTEGER NOT NULL DEFAULT 0 CHECK (inventory_sold >= 0),
    sale_starts_at TIMESTAMPTZ,
    sale_ends_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ticket_types_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_ticket_types_inventory_bounds
        CHECK (inventory_reserved + inventory_sold <= inventory_total),
    CONSTRAINT chk_ticket_type_sale_window
        CHECK (sale_ends_at IS NULL OR sale_starts_at IS NULL OR sale_ends_at > sale_starts_at)
);

CREATE INDEX idx_ticket_types_event ON ticket_types(event_id);

-- Commercial tables
CREATE TABLE referral_codes (
    id BIGSERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    owner_user_id BIGINT NOT NULL,
    event_id BIGINT,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    max_uses INTEGER CHECK (max_uses IS NULL OR max_uses >= 0),
    uses_count INTEGER NOT NULL DEFAULT 0 CHECK (uses_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_referral_codes_user
        FOREIGN KEY (owner_user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_referral_codes_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_referral_time_window CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at),
    CONSTRAINT chk_referral_use_bounds CHECK (max_uses IS NULL OR uses_count <= max_uses)
);

CREATE TABLE promo_codes (
    id BIGSERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    event_id BIGINT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
    discount_value NUMERIC(10,2) NOT NULL CHECK (discount_value > 0),
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    max_redemptions INTEGER CHECK (max_redemptions IS NULL OR max_redemptions >= 0),
    redeemed_count INTEGER NOT NULL DEFAULT 0 CHECK (redeemed_count >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_promo_codes_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_promo_time_window CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at),
    CONSTRAINT chk_promo_redeem_bounds CHECK (max_redemptions IS NULL OR redeemed_count <= max_redemptions)
);

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    event_id BIGINT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled', 'expired', 'refunded')),
    currency CHAR(3) NOT NULL,
    subtotal_cents INTEGER NOT NULL DEFAULT 0 CHECK (subtotal_cents >= 0),
    discount_cents INTEGER NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    total_cents INTEGER NOT NULL DEFAULT 0 CHECK (total_cents >= 0),
    referral_code_id BIGINT,
    promo_code_id BIGINT,
    expires_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_orders_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_referral_code
        FOREIGN KEY (referral_code_id)
        REFERENCES referral_codes(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_orders_promo_code
        FOREIGN KEY (promo_code_id)
        REFERENCES promo_codes(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_orders_event_status ON orders(event_id, status);
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    ticket_type_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
    total_price_cents INTEGER NOT NULL CHECK (total_price_cents >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_ticket_type
        FOREIGN KEY (ticket_type_id)
        REFERENCES ticket_types(id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_total
        CHECK (total_price_cents = quantity * unit_price_cents)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_ticket_type ON order_items(ticket_type_id);

CREATE TABLE tickets (
    id BIGSERIAL PRIMARY KEY,
    order_item_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    ticket_type_id BIGINT NOT NULL,
    holder_user_id BIGINT,
    ticket_code TEXT NOT NULL UNIQUE,
    qr_token TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used', 'cancelled', 'refunded')),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    cancelled_at TIMESTAMPTZ,
    CONSTRAINT fk_tickets_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES order_items(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tickets_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tickets_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_ticket_type
        FOREIGN KEY (ticket_type_id)
        REFERENCES ticket_types(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_holder
        FOREIGN KEY (holder_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_tickets_event_status ON tickets(event_id, status);
CREATE INDEX idx_tickets_holder ON tickets(holder_user_id);

CREATE TABLE checkins (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    checked_in_by_user_id BIGINT,
    checked_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT NOT NULL DEFAULT 'scanner',
    CONSTRAINT fk_checkins_ticket
        FOREIGN KEY (ticket_id)
        REFERENCES tickets(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_checkins_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_checkins_scanner_user
        FOREIGN KEY (checked_in_by_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,
    CONSTRAINT uq_checkins_ticket_event UNIQUE (ticket_id, event_id)
);

CREATE INDEX idx_checkins_ticket_event ON checkins(ticket_id, event_id);
CREATE INDEX idx_checkins_event_checked_at ON checkins(event_id, checked_in_at DESC);

CREATE TABLE points_ledger (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    order_id BIGINT,
    referral_code_id BIGINT,
    points_delta INTEGER NOT NULL,
    reason TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_points_ledger_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_points_ledger_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_points_ledger_referral_code
        FOREIGN KEY (referral_code_id)
        REFERENCES referral_codes(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_points_ledger_user_created ON points_ledger(user_id, created_at DESC);

CREATE TABLE reviews (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title TEXT,
    body TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_reviews_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_reviews_event_user UNIQUE (event_id, user_id)
);

CREATE INDEX idx_reviews_event_rating ON reviews(event_id, rating);

CREATE TABLE fraud_flags (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    order_id BIGINT,
    ticket_id BIGINT,
    event_id BIGINT,
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'dismissed')),
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    CONSTRAINT fk_fraud_flags_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_fraud_flags_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_fraud_flags_ticket
        FOREIGN KEY (ticket_id)
        REFERENCES tickets(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_fraud_flags_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_fraud_flags_status_severity ON fraud_flags(status, severity);
CREATE INDEX idx_fraud_flags_event_created ON fraud_flags(event_id, created_at DESC);

-- Inventory guards against overselling
CREATE OR REPLACE FUNCTION reserve_ticket_inventory()
RETURNS TRIGGER AS $$
DECLARE
    available INTEGER;
BEGIN
    SELECT (inventory_total - inventory_reserved - inventory_sold)
      INTO available
      FROM ticket_types
     WHERE id = NEW.ticket_type_id
     FOR UPDATE;

    IF available IS NULL THEN
        RAISE EXCEPTION 'Ticket type % does not exist', NEW.ticket_type_id;
    END IF;

    IF available < NEW.quantity THEN
        RAISE EXCEPTION 'Not enough inventory for ticket_type_id %, requested %, available %',
            NEW.ticket_type_id, NEW.quantity, available;
    END IF;

    UPDATE ticket_types
       SET inventory_reserved = inventory_reserved + NEW.quantity,
           updated_at = NOW()
     WHERE id = NEW.ticket_type_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION adjust_ticket_inventory_on_item_update()
RETURNS TRIGGER AS $$
DECLARE
    available INTEGER;
BEGIN
    IF OLD.ticket_type_id <> NEW.ticket_type_id THEN
        UPDATE ticket_types
           SET inventory_reserved = GREATEST(0, inventory_reserved - OLD.quantity),
               updated_at = NOW()
         WHERE id = OLD.ticket_type_id;

        SELECT (inventory_total - inventory_reserved - inventory_sold)
          INTO available
          FROM ticket_types
         WHERE id = NEW.ticket_type_id
         FOR UPDATE;

        IF available < NEW.quantity THEN
            RAISE EXCEPTION 'Not enough inventory for ticket_type_id %, requested %, available %',
                NEW.ticket_type_id, NEW.quantity, available;
        END IF;

        UPDATE ticket_types
           SET inventory_reserved = inventory_reserved + NEW.quantity,
               updated_at = NOW()
         WHERE id = NEW.ticket_type_id;
    ELSIF NEW.quantity <> OLD.quantity THEN
        SELECT (inventory_total - inventory_reserved - inventory_sold + OLD.quantity)
          INTO available
          FROM ticket_types
         WHERE id = NEW.ticket_type_id
         FOR UPDATE;

        IF available < NEW.quantity THEN
            RAISE EXCEPTION 'Not enough inventory for ticket_type_id %, requested %, available %',
                NEW.ticket_type_id, NEW.quantity, available;
        END IF;

        UPDATE ticket_types
           SET inventory_reserved = inventory_reserved - OLD.quantity + NEW.quantity,
               updated_at = NOW()
         WHERE id = NEW.ticket_type_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION release_ticket_inventory_on_item_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ticket_types
       SET inventory_reserved = GREATEST(0, inventory_reserved - OLD.quantity),
           updated_at = NOW()
     WHERE id = OLD.ticket_type_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_items_reserve_inventory
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION reserve_ticket_inventory();

CREATE TRIGGER trg_order_items_adjust_inventory
BEFORE UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION adjust_ticket_inventory_on_item_update();

CREATE TRIGGER trg_order_items_release_inventory
AFTER DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION release_ticket_inventory_on_item_delete();

CREATE OR REPLACE FUNCTION settle_inventory_on_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    IF NEW.status = 'paid' AND OLD.status IN ('pending') THEN
        UPDATE ticket_types tt
           SET inventory_reserved = GREATEST(0, tt.inventory_reserved - oi.quantity),
               inventory_sold = tt.inventory_sold + oi.quantity,
               updated_at = NOW()
          FROM order_items oi
         WHERE oi.order_id = NEW.id
           AND oi.ticket_type_id = tt.id;
    ELSIF NEW.status IN ('cancelled', 'expired') AND OLD.status = 'pending' THEN
        UPDATE ticket_types tt
           SET inventory_reserved = GREATEST(0, tt.inventory_reserved - oi.quantity),
               updated_at = NOW()
          FROM order_items oi
         WHERE oi.order_id = NEW.id
           AND oi.ticket_type_id = tt.id;
    ELSIF NEW.status = 'refunded' AND OLD.status = 'paid' THEN
        UPDATE ticket_types tt
           SET inventory_sold = GREATEST(0, tt.inventory_sold - oi.quantity),
               updated_at = NOW()
          FROM order_items oi
         WHERE oi.order_id = NEW.id
           AND oi.ticket_type_id = tt.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_settle_inventory
AFTER UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION settle_inventory_on_order_status_change();

COMMIT;
