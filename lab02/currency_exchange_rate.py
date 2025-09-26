#!/usr/bin/env python3
"""
currency_exchange_rate.py получение курса валют через локальный Web API,
с сохранением результата в data/<FROM>_to_<TO>_<DATE>.json и логированием ошибок.

Требует запущенный сервис на http://localhost:8080 .
"""

from __future__ import annotations
import argparse
import json
import logging
import os
import re
import sys
from pathlib import Path
from datetime import datetime, date

import requests

# --- Константы путей (корень проекта = на уровень выше lab02/) ---
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / 'data'
ERROR_LOG = PROJECT_ROOT / 'error.log'
BASE_URL_DEFAULT = os.environ.get('LAB02_BASE_URL', 'http://localhost:8080/')

# --- Настройка логирования (ошибки в error.log) ---
def setup_logger() -> logging.Logger:
    logger = logging.getLogger('lab02')
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(ERROR_LOG)
    fh.setLevel(logging.ERROR)
    fmt = logging.Formatter('%(asctime)s %(levelname)s: %(message)s')
    fh.setFormatter(fmt)
    logger.addHandler(fh)
    return logger

# --- Загрузка API key ---
def load_api_key(cli_api_key: str | None) -> str:
    if cli_api_key:
        return cli_api_key
    env_key = os.environ.get('API_KEY') or os.environ.get('LAB02_API_KEY')
    if not env_key:
        raise RuntimeError("API key is not provided. Pass --api-key or set environment variable API_KEY.")
    return env_key

# --- Валидации ---
def validate_currency(code: str, allowed: set[str]) -> str:
    code = (code or '').upper()
    if not re.fullmatch(r'[A-Z]{3}', code):
        raise ValueError(f"Invalid currency code '{code}'. Expected 3 uppercase letters, e.g., USD.")
    if allowed and code not in allowed:
        raise ValueError(f"Unknown currency '{code}'. Allowed: {', '.join(sorted(allowed))}.")
    return code

def parse_date(s: str) -> date:
    try:
        return datetime.strptime(s, '%Y-%m-%d').date()
    except ValueError:
        raise ValueError(f"Invalid date '{s}'. Expected YYYY-MM-DD.")

def check_range(d: date) -> date:
    lo = date(2025, 1, 1)
    hi = date(2025, 9, 15)
    if d < lo or d > hi:
        raise ValueError(f"Date '{d}' is outside dataset range [2025-01-01 .. 2025-09-15].")
    return d

# --- Взаимодействие с API ---
def fetch_currencies(base_url: str, api_key: str, timeout: float = 10.0) -> set[str]:
    try:
        resp = requests.post(base_url, params={'currencies': ''}, data={'key': api_key}, timeout=timeout)
        resp.raise_for_status()
        payload = resp.json()
        if payload.get('error'):
            raise RuntimeError(f"API error: {payload['error']}")
        return set(payload.get('data') or [])
    except Exception:
        # Фолбэк на известный набор из задания
        return {'MDL', 'USD', 'EUR', 'RON', 'RUS', 'UAH'}

def fetch_rate(base_url: str, api_key: str, from_curr: str, to_curr: str, d: date, timeout: float = 10.0) -> dict:
    params = {'from': from_curr, 'to': to_curr, 'date': d.isoformat()}
    resp = requests.post(base_url, params=params, data={'key': api_key}, timeout=timeout)
    resp.raise_for_status()
    payload = resp.json()
    if payload.get('error'):
        raise RuntimeError(payload['error'])
    data = payload.get('data')
    if not isinstance(data, dict):
        raise RuntimeError("Unexpected API response format: 'data' is missing.")
    return data

# --- Сохранение результата ---
def save_json(payload: dict, data_dir: Path, from_curr: str, to_curr: str, d: date) -> Path:
    data_dir.mkdir(parents=True, exist_ok=True)
    fname = f"{from_curr}_to_{to_curr}_{d.isoformat()}.json"
    path = data_dir / fname
    with path.open('w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    return path

# --- CLI ---
def main() -> None:
    parser = argparse.ArgumentParser(description='Get currency exchange rate and save as JSON.')
    parser.add_argument('--from', dest='from_curr', required=True, help='Source currency (e.g., USD)')
    parser.add_argument('--to', dest='to_curr', required=True, help='Target currency (e.g., EUR)')
    parser.add_argument('--date', required=True, help='Date YYYY-MM-DD (2025-01-01..2025-09-15)')
    parser.add_argument('--api-key', dest='api_key', help='API key (fallback to env API_KEY)')
    parser.add_argument('--base-url', default=BASE_URL_DEFAULT, help='Service base URL (default http://localhost:8080/)')
    args = parser.parse_args()

    logger = setup_logger()
    try:
        api_key = load_api_key(args.api_key)
        allowed = fetch_currencies(args.base_url, api_key)
        from_curr = validate_currency(args.from_curr, allowed)
        to_curr = validate_currency(args.to_curr, allowed)
        d = check_range(parse_date(args.date))

        data = fetch_rate(args.base_url, api_key, from_curr, to_curr, d)
        path = save_json(data, DATA_DIR, from_curr, to_curr, d)
        print(f"OK: {from_curr}->{to_curr} on {d}: rate={data.get('rate')} saved to {path}")
    except Exception as e:
        msg = f"FAILED: {e}"
        print(msg, file=sys.stderr)
        logger.error(msg)

if __name__ == '__main__':
    main()