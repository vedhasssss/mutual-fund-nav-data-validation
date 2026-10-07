# Mutual Fund NAV Data Validation

A small SQL project that checks public mutual fund NAV data for bad records and logs the reason for each one.

## What it does
1. Cleans AMFI's public daily NAV file in Excel (removes heading rows, fixes headers).
2. Loads a sample of **2,470 records** into MySQL.
3. Runs 5 SQL validation checks and saves every flagged record, with its reason, in a `data_issues` table.
4. Summarizes the results with SQL queries.

## Data
- Source: AMFI public daily NAV file (`https://www.amfiindia.com/spages/NAVAll.txt`)
- `nav_data_small.csv` is a sample of the cleaned file. It was built to include records with problems so the checks have something to find, so the issue counts below do not show the error rate of the full data.

## Checks and results
| Check | Issues found |
|---|---|
| NAV zero or negative | 241 |
| Missing ISIN | 287 |
| Old NAV date | 660 |
| Missing plan | 640 |
| Duplicate ISIN | 10 |
| **Total** | **1,838** |

## How to run
1. Open `nav_data_validation.sql` in MySQL Workbench.
2. Run section 1 to create the database and table.
3. Import `nav_data_small.csv` into `nav_raw` (Table Data Import Wizard).
4. Run the remaining sections in order.

## Tools
SQL (MySQL), Excel, MySQL Workbench

## Author
Vedhas Shinde, [LinkedIn](https://linkedin.com/in/vedhas-shinde)
