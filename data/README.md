# Data

The CSV files are **not** stored in this repository (size and dataset licence).

1. Download the dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Unzip and place these 9 files in `data/raw/`:

```
olist_customers_dataset.csv
olist_geolocation_dataset.csv
olist_order_items_dataset.csv
olist_order_payments_dataset.csv
olist_order_reviews_dataset.csv
olist_orders_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
product_category_name_translation.csv
```

The Brazilian states reference data is not a file: it is fetched from the IBGE API by `src/load_states.py`.
