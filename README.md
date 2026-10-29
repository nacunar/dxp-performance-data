# DXP+ performance tracker

A static page (`index.html`) that reads per-site, per-month performance data from Supabase
(project `dxp-performance-tracker`, table `performance_data`) and shows it as a filterable table:
year, month, region, market, brand, search and "off target only".

## Files

| File | What it is |
| --- | --- |
| `index.html` | The tracker page. No build step. |
| `config.js` | Supabase URL and **publishable** key. Read-only by Row Level Security. |
| `vercel.json` | Keeps the site out of search engines and stops `config.js` being cached. |
| `supabase/migrations/` | The database schema, so it can be recreated on a new project. |

## Adding data

In Supabase, Table Editor:

1. Open **`performance_import`** (not `performance_data`).
2. **Insert → Import data from CSV**, or add rows by hand.
   Columns: `year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms, sessions, migrated_on`.
   `migrated_on` is optional: the date a site moved to DXP+ (2026-10-14 or 14/10/2026). Fill it on the row for the month the
   migration happened and the tracker marks that month as partial.
   Decimals may use `,` or `.`; month can be a number or a name (Sep, September, septiembre).
3. Each row is converted and saved to `performance_data`. Importing the same site and month again updates it.
   Editing a row in `performance_import` updates the tracker, and deleting it removes that site and month from the tracker.
   Always fix or delete data in `performance_import`, not in `performance_data`.
4. Click **Refresh** on the tracker.

## Deploy

Import this repo in Vercel (no framework, no build command). Then in the Vercel project:
**Settings → Deployment Protection → Vercel Authentication → All Deployments**.

## Run locally

Open `index.html` in a browser. It reads the same Supabase data.
