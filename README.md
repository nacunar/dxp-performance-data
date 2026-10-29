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
   Columns: `year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms`
   (optional: `sessions`, `migrated_on`). Decimals may use `,` or `.`; month can be a number or a name (Sep, September, septiembre).
3. Each row is converted and saved to `performance_data`. Importing the same site and month again updates it.
   Editing a row in `performance_import` updates the tracker, and deleting it removes that site and month from the tracker.
   Always fix or delete data in `performance_import`, not in `performance_data`.
4. Click **Refresh** on the tracker.

## Marking migrated sites

Add one row per site to **`site_migrations`**: `site` (exactly as in the data) and `migrated_on` (the go-live date on DXP+).
You only do this once per site. The tracker marks the month that contains that date as a partial month.
Including a `migrated_on` column in an import also saves the date to `site_migrations`.

## Deploy

Import this repo in Vercel (no framework, no build command). Then in the Vercel project:
**Settings → Deployment Protection → Vercel Authentication → All Deployments**.

## Run locally

Open `index.html` in a browser. It reads the same Supabase data.
