-- RAW LAYER
-- Every column is TEXT so the load can never fail because of a bad value.
-- Column names are kept exactly as in the CSV (including the original
-- misspellings such as "product_name_lenght"); fixing them is staging's job.
-- _loaded_at records when each row was loaded.

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id               TEXT,
    customer_unique_id        TEXT,
    customer_zip_code_prefix  TEXT,
    customer_city             TEXT,
    customer_state            TEXT,
    _loaded_at                TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.geolocation (
    geolocation_zip_code_prefix  TEXT,
    geolocation_lat              TEXT,
    geolocation_lng              TEXT,
    geolocation_city             TEXT,
    geolocation_state            TEXT,
    _loaded_at                   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id                       TEXT,
    customer_id                    TEXT,
    order_status                   TEXT,
    order_purchase_timestamp       TEXT,
    order_approved_at              TEXT,
    order_delivered_carrier_date   TEXT,
    order_delivered_customer_date  TEXT,
    order_estimated_delivery_date  TEXT,
    _loaded_at                     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id             TEXT,
    order_item_id        TEXT,
    product_id           TEXT,
    seller_id            TEXT,
    shipping_limit_date  TEXT,
    price                TEXT,
    freight_value        TEXT,
    _loaded_at           TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.order_payments (
    order_id              TEXT,
    payment_sequential    TEXT,
    payment_type          TEXT,
    payment_installments  TEXT,
    payment_value         TEXT,
    _loaded_at            TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.order_reviews (
    review_id                TEXT,
    order_id                 TEXT,
    review_score             TEXT,
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    review_creation_date     TEXT,
    review_answer_timestamp  TEXT,
    _loaded_at               TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id                  TEXT,
    product_category_name       TEXT,
    product_name_lenght         TEXT,   -- sic (misspelled in source)
    product_description_lenght  TEXT,   -- sic (misspelled in source)
    product_photos_qty          TEXT,
    product_weight_g            TEXT,
    product_length_cm           TEXT,
    product_height_cm           TEXT,
    product_width_cm            TEXT,
    _loaded_at                  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.sellers (
    seller_id                TEXT,
    seller_zip_code_prefix   TEXT,
    seller_city              TEXT,
    seller_state             TEXT,
    _loaded_at               TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.product_category_translation (
    product_category_name          TEXT,
    product_category_name_english  TEXT,
    _loaded_at                     TIMESTAMPTZ DEFAULT now()
);

-- Source: IBGE API (mesoregions endpoint). The API returns one row per
-- MESOREGION, so each state appears several times here; staging keeps one row
-- per state.
CREATE TABLE IF NOT EXISTS raw.brazil_states (
    state_id        TEXT,
    state_initial   TEXT,
    state_name      TEXT,
    region_name     TEXT,
    _loaded_at      TIMESTAMPTZ DEFAULT now()
);
