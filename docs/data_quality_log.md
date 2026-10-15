# Data quality log

One row per problem found: what, where, and what was decided. Add rows as profiling and EDA reveal more.

| # | Table | Problem | Decision | Implemented in |
|---|---|---|---|---|
| 1 | orders | Timestamps stored as text | Cast all 5 to `TIMESTAMP` | `03_staging.sql` |
| 2 | orders | Nulls in approved / carrier / customer delivery dates (canceled or undelivered orders) | Keep NULL, they carry meaning | `03_staging.sql` |
| 3 | order_items | `shipping_limit_date` stored as text | Cast to `TIMESTAMP` | `03_staging.sql` |
| 4 | order_items | `order_item_id` is not unique alone (1, 2, 3 within an order) | Key is `(order_id, order_item_id)` | `03_staging.sql` |
| 5 | order_payments | Several rows per order (installments, vouchers): joining naively inflates revenue | Key is `(order_id, payment_sequential)`; aggregate to order level before joining | analytics layer (todo) |
| 6 | order_reviews | `review_id` repeats (814 duplicates) but `(review_id, order_id)` is unique | Key is `(review_id, order_id)` | `03_staging.sql` |
| 7 | order_reviews | Dates stored as text | Cast to `TIMESTAMP` | `03_staging.sql` |
| 8 | products | Misspelled columns `product_name_lenght`, `product_description_lenght` | Rename to `...length` | `03_staging.sql` |
| 9 | products | Missing category and size/weight values | Keep NULL; label as `'unknown'` in analytics | analytics layer (todo) |
| 10 | category translation | 2 categories in products have no English name (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`) | Add translations manually | `03_staging.sql` |
| 11 | geolocation | Many rows per zip prefix; some points outside Brazil | Filter to Brazil's bounding box, then one row per prefix using the **mean** lat/lng | `03_staging.sql` |
| 12 | customers / sellers | Inconsistent city text (spaces, case, accents) | Trim and lowercase city, uppercase state | `03_staging.sql` |
| 13 | customers | `customer_id` is per order; the real person is `customer_unique_id` | Use `customer_unique_id` for repeat-purchase analysis | analytics layer (todo) |
| 14 | brazil_states (IBGE API) | Endpoint returns one row per mesoregion, so each state is repeated | Land as received in `raw`, `SELECT DISTINCT` in staging (27 states) | `03_staging.sql` |

