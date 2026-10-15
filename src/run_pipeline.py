"""Run the whole pipeline: CSV + IBGE API -> raw -> staging.

Usage (from the project root):
    python src/run_pipeline.py
"""
import build_staging
import load_raw
import load_states

if __name__ == "__main__":
    load_raw.main()
    print()
    load_states.main()
    print()
    build_staging.main()
