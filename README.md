# Music Store Sales Analysis (PostgreSQL)

A SQL analysis of a digital music store's sales, customer, and catalog data; modeled on the classic Chinook dataset to answer real business questions about revenue, customer value, and genre/artist performance across markets.

## 📌 Project Overview

This project takes a relational music-store dataset (customers, invoices, tracks, albums, artists, genres) and answers a set of stakeholder-style business questions using PostgreSQL: from "who are our highest-value customers" to "which genre dominates in each country." It's built to demonstrate practical analyst SQL: joins, aggregations, subqueries, CTEs, and window functions applied to questions a sales, marketing, or ops team would actually ask.

**Dataset:** 59 customers across 24 countries, 614 invoices, 3,503 tracks, 347 albums, 275 artists.

## 🗂️ Schema

The database follows a standard star-like relational structure:

- **Reference tables:** `artist`, `genre`, `media_type`, `playlist`
- **Catalog tables:** `album` (→ artist), `track` (→ album, genre, media_type)
- **Bridge table:** `playlist_track` (many-to-many between playlists and tracks)
- **People tables:** `employee` (self-referencing manager hierarchy via `reports_to`), `customer` (→ assigned support rep)
- **Transaction tables:** `invoice` (→ customer), `invoice_line` (→ invoice, track)

## 🛠️ Tools Used
 -	PostgreSQL for schema design and querying
 -	SQL techniques: multi-table joins, correlated subqueries, GROUP BY aggregation, CTEs, and window functions (ROW_NUMBER(), RANK())

## ❓ Business Questions Answered

| # | Question | Technique |
|---|----------|-----------|
| 1 | Who's the most senior employee by title? | Self-join / `WHERE reports_to IS NULL` |
| 2 | Which country generates the most invoices? | `GROUP BY` + `COUNT` |
| 3 | What are the top 3 highest-value invoices? | `ORDER BY ... LIMIT` |
| 4 | Which city generates the most revenue? | `GROUP BY` + `SUM` |
| 5 | Who is the single best customer by spend? | Join + aggregation |
| 6 | Who are all the Rock genre listeners? | Subquery + `DISTINCT` |
| 7 | Which artists have the most Rock tracks? | Multi-table join + `GROUP BY` |
| 8 | Which tracks run longer than average length? | Correlated subquery |
| 9 | How much does each customer spend on the single best-selling artist? | CTE + join |
| 10 | What's the most popular genre in each country? | CTE + `ROW_NUMBER()` |
| 11 | Who's the top spender in each country (ties included)? | CTE + `RANK()` |

## 💡 Key Findings
- **Invoice volume and revenue leadership point to different places**. The USA generates the most invoices of any country (131), but Prague has the highest total invoice revenue of any city ($273.24). Volume leader and revenue leader aren't the same place.
- **Rock reaches the entire customer base**. All 59 customers in the dataset have purchased at least one Rock track - a 100% match against the total customer count.
- **Rock also dominates at the country level, almost everywhere**. Rock is the top-purchased genre in 23 of the 24 countries in the dataset; the remaining country's top genre is Alternative & Punk.

## Resources
Dataset access: <a href= "https://github.com/Pawani10/Music_Store_Sales_Analysis-/blob/main/music%20store%20data.zip"> Dataset </a>

Query access: <a href= "https://github.com/Pawani10/Music_Store_Sales_Analysis-/blob/main/Music_store_Analysis.sql"> Queries </a>
