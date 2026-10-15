-- STAGING LAYER: cleaned + correctly typed copies of the raw tables.
DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA staging;

-- ---------------------------------------------------------------- reference
-- Built from raw.brazil_states, which src/load_states.py fills from the IBGE API.
-- The API returns one row per mesoregion, so DISTINCT leaves one row per state.
CREATE TABLE staging.brazil_states AS
SELECT DISTINCT
    UPPER(TRIM(state_initial))::CHAR(2) AS state_initial,
    TRIM(state_name)                    AS state_name,
    TRIM(region_name)                   AS region_name
FROM raw.brazil_states;

ALTER TABLE staging.brazil_states ADD PRIMARY KEY (state_initial);

-- ------------------------------------------------- product category translation
CREATE TABLE staging.product_category_translation AS
SELECT
    TRIM(product_category_name)         AS product_category_name,
    TRIM(product_category_name_english) AS product_category_name_english
FROM raw.product_category_translation;

-- Two categories used by products have no translation in the source file
INSERT INTO staging.product_category_translation
SELECT v.product_category_name, v.product_category_name_english
FROM (VALUES
    ('pc_gamer', 'gaming_pc'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_appliances_and_food_processors')
) AS v (product_category_name, product_category_name_english)
WHERE v.product_category_name NOT IN
      (SELECT product_category_name FROM staging.product_category_translation);

ALTER TABLE staging.product_category_translation ADD PRIMARY KEY (product_category_name);

-- ------------------------------------------------------------------ customers
CREATE TABLE staging.customers AS
SELECT
    TRIM(customer_id)                       AS customer_id,
    TRIM(customer_unique_id)                AS customer_unique_id,
    TRIM(customer_zip_code_prefix)::INTEGER AS customer_zip_code_prefix,
    LOWER(TRIM(customer_city))              AS customer_city,
    UPPER(TRIM(customer_state))             AS customer_state
FROM raw.customers;

ALTER TABLE staging.customers ADD PRIMARY KEY (customer_id);

-- -------------------------------------------------------------------- sellers
CREATE TABLE staging.sellers AS
SELECT
    TRIM(seller_id)                        AS seller_id,
    TRIM(seller_zip_code_prefix)::INTEGER  AS seller_zip_code_prefix,
    LOWER(TRIM(seller_city))               AS seller_city,
    UPPER(TRIM(seller_state))              AS seller_state
FROM raw.sellers;

ALTER TABLE staging.sellers ADD PRIMARY KEY (seller_id);

-- ------------------------------------------------------------------- products
-- Fixes the misspelled column names ("lenght" -> "length").
-- Products without a category keep a NULL category (how to label them to be decided
-- in the analytics layer, e.g. COALESCE(category, 'unknown')).
CREATE TABLE staging.products AS
SELECT
    TRIM(product_id)                                          AS product_id,
    NULLIF(TRIM(product_category_name), '')                   AS product_category_name,
    NULLIF(TRIM(product_name_lenght), '')::NUMERIC::INTEGER        AS product_name_length,
    NULLIF(TRIM(product_description_lenght), '')::NUMERIC::INTEGER AS product_description_length,
    NULLIF(TRIM(product_photos_qty), '')::NUMERIC::INTEGER         AS product_photos_qty,
    NULLIF(TRIM(product_weight_g), '')::NUMERIC               AS product_weight_g,
    NULLIF(TRIM(product_length_cm), '')::NUMERIC              AS product_length_cm,
    NULLIF(TRIM(product_height_cm), '')::NUMERIC              AS product_height_cm,
    NULLIF(TRIM(product_width_cm), '')::NUMERIC               AS product_width_cm
FROM raw.products;

ALTER TABLE staging.products ADD PRIMARY KEY (product_id);
ALTER TABLE staging.products
    ADD FOREIGN KEY (product_category_name)
    REFERENCES staging.product_category_translation (product_category_name);

-- --------------------------------------------------------------------- orders
CREATE TABLE staging.orders AS
SELECT
    TRIM(order_id)                                          AS order_id,
    TRIM(customer_id)                                       AS customer_id,
    LOWER(TRIM(order_status))                               AS order_status,
    NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP      AS order_purchase_timestamp,
    NULLIF(TRIM(order_approved_at), '')::TIMESTAMP             AS order_approved_at,
    NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP  AS order_delivered_carrier_date,
    NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP AS order_delivered_customer_date,
    NULLIF(TRIM(order_estimated_delivery_date), '')::TIMESTAMP AS order_estimated_delivery_date
FROM raw.orders;

ALTER TABLE staging.orders ADD PRIMARY KEY (order_id);
ALTER TABLE staging.orders
    ADD FOREIGN KEY (customer_id) REFERENCES staging.customers (customer_id);
CREATE INDEX idx_orders_customer_id ON staging.orders (customer_id);

-- ---------------------------------------------------------------- order_items
-- Grain: one row per item in an order -> key is (order_id, order_item_id).
CREATE TABLE staging.order_items AS
SELECT
    TRIM(order_id)                             AS order_id,
    TRIM(order_item_id)::INTEGER               AS order_item_id,
    TRIM(product_id)                           AS product_id,
    TRIM(seller_id)                            AS seller_id,
    NULLIF(TRIM(shipping_limit_date), '')::TIMESTAMP AS shipping_limit_date,
    TRIM(price)::NUMERIC(10,2)                 AS price,
    TRIM(freight_value)::NUMERIC(10,2)         AS freight_value
FROM raw.order_items;

ALTER TABLE staging.order_items ADD PRIMARY KEY (order_id, order_item_id);
ALTER TABLE staging.order_items ADD FOREIGN KEY (order_id)   REFERENCES staging.orders (order_id);
ALTER TABLE staging.order_items ADD FOREIGN KEY (product_id) REFERENCES staging.products (product_id);
ALTER TABLE staging.order_items ADD FOREIGN KEY (seller_id)  REFERENCES staging.sellers (seller_id);
CREATE INDEX idx_order_items_product_id ON staging.order_items (product_id);
CREATE INDEX idx_order_items_seller_id  ON staging.order_items (seller_id);

-- -------------------------------------------------------------- order_payments
-- Grain: one row per payment; an order can have several (installments, vouchers)
CREATE TABLE staging.order_payments AS
SELECT
    TRIM(order_id)                          AS order_id,
    TRIM(payment_sequential)::INTEGER       AS payment_sequential,
    LOWER(TRIM(payment_type))               AS payment_type,
    TRIM(payment_installments)::INTEGER     AS payment_installments,
    TRIM(payment_value)::NUMERIC(10,2)      AS payment_value
FROM raw.order_payments;

ALTER TABLE staging.order_payments ADD PRIMARY KEY (order_id, payment_sequential);
ALTER TABLE staging.order_payments ADD FOREIGN KEY (order_id) REFERENCES staging.orders (order_id);

-- --------------------------------------------------------------- order_reviews
-- review_id is NOT unique on its own (the same review_id can appear on several
-- orders), but (review_id, order_id) is
CREATE TABLE staging.order_reviews AS
SELECT
    TRIM(review_id)                                   AS review_id,
    TRIM(order_id)                                    AS order_id,
    TRIM(review_score)::INTEGER                       AS review_score,
    NULLIF(TRIM(review_comment_title), '')            AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '')          AS review_comment_message,
    NULLIF(TRIM(review_creation_date), '')::TIMESTAMP   AS review_creation_date,
    NULLIF(TRIM(review_answer_timestamp), '')::TIMESTAMP AS review_answer_timestamp
FROM raw.order_reviews;

ALTER TABLE staging.order_reviews ADD PRIMARY KEY (review_id, order_id);
ALTER TABLE staging.order_reviews ADD FOREIGN KEY (order_id) REFERENCES staging.orders (order_id);

-- ---------------------------------------------------------------- geolocation
-- Raw has many rows per zip prefix (~1M rows). Staging keeps ONE row per prefix:
--   * drop points outside Brazil's bounding box (same limits as the notebook)
--   * AVG of lat/lng
--   * city/state = most frequent value for that prefix
CREATE TABLE staging.geolocation AS
WITH typed AS (
    SELECT
        TRIM(geolocation_zip_code_prefix)::INTEGER AS zip_code_prefix,
        TRIM(geolocation_lat)::DOUBLE PRECISION    AS lat,
        TRIM(geolocation_lng)::DOUBLE PRECISION    AS lng,
        LOWER(TRIM(geolocation_city))              AS city,
        UPPER(TRIM(geolocation_state))             AS state
    FROM raw.geolocation
)
SELECT
    zip_code_prefix,
    AVG(lat) AS geolocation_lat,
    AVG(lng) AS geolocation_lng,
    MODE() WITHIN GROUP (ORDER BY city)  AS geolocation_city,
    MODE() WITHIN GROUP (ORDER BY state) AS geolocation_state
FROM typed
WHERE lat BETWEEN -33.75116944 AND 5.27438888
  AND lng BETWEEN -73.98283055 AND -34.79314722
GROUP BY zip_code_prefix;

ALTER TABLE staging.geolocation ADD PRIMARY KEY (zip_code_prefix);
-- No foreign keys to geolocation on purpose: some customer/seller zip prefixes
-- have no geolocation entry, so always LEFT JOIN to it.