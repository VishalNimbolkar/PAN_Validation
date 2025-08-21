# PAN Validation SQL Project

This project validates Indian PAN numbers using SQL.

## Features
- Data cleaning (nulls, duplicates, spaces, casing)
- PAN format validation (length, pattern `AAAAA1234A`)
- Custom PL/pgSQL functions:
  - `fn_check_adj_charactes` → checks repeated adjacent characters
  - `fn_check_seq_charactes` → checks sequential characters
- Categorizes PAN numbers as **Valid** or **Invalid**
- Summary report of processed, valid, invalid, and missing PANs

## Usage
1. Run the SQL script in PostgreSQL.
2. Load your dataset into `public.pan_dataset`.
3. Execute queries to validate and generate reports.

