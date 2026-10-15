-- One schema per layer: raw -> staging -> analytics
CREATE SCHEMA IF NOT EXISTS raw;        -- CSV data exactly as received (all TEXT)
CREATE SCHEMA IF NOT EXISTS staging;    -- cleaned + correctly typed
CREATE SCHEMA IF NOT EXISTS analytics;  -- business-ready tables (dimensions, facts, marts)
