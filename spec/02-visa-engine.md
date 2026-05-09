# NomadTracker — Visa Rule Engine Specification

## Overview

The visa rule engine calculates remaining days and compliance status for each country stay. It supports three rule types defined in `VisaCalculator`.

## Rule Types

### 1. Calendar Year (`calendar_year`)

**How it works:** Days are counted within Jan 1 – Dec 31. Resets every year.

**Algorithm:**
```
remaining = country.totalMaxDays - stay.daysSpent
```

**Status thresholds:**
| Remaining Days | Status |
|----------------|--------|
| < 0 | `.expired` |
| 0-3 | `.critical` |
| 4-14 | `.critical` |
| 15-30 | `.warning` |
| > 30 | `.safe` |
| Active stay | `.active` |

**Example countries:** Most non-Schengen countries (Argentina, Thailand, etc.)

### 2. Rolling 90/180 (`rolling_90_180`)

**How it works:** Maximum 90 days in any rolling 180-day window. Used for Schengen zone.

**Algorithm:**
1. Find all stays in Schengen countries within past 180 days
2. For each stay, calculate days overlapping with the 180-day window starting today
3. Sum all overlapping days = `totalDaysInWindow`
4. `remaining = 90 - totalDaysInWindow`

**Important:** This aggregates across ALL Schengen countries, not per-country.

**Example countries:** All 27 Schengen member states (Germany, France, Spain, etc.)

### 3. Custom Rolling Window (`rolling_window`)

**How it works:** Currently falls back to calendar year logic. Placeholder for country-specific rolling rules.

## Entry Eligibility Check

`VisaCalculator.canEnterCountry()` determines if a new stay can begin:

- **Calendar year:** Sum days used this year, compare to `totalMaxDays`
- **Rolling 90/180:** Sum all Schengen days in 180-day window, compare to 90
- **Rolling window:** Always returns `true` (manual check required)

## Year Summary Calculation

`VisaCalculator.calculateYearSummary()` computes days per country for a given year:

1. Filter stays that overlap with the target year
2. Clamp entry/exit dates to Jan 1 – Dec 31 of that year
3. Sum days per country name
4. Return `[countryName: days]` dictionary

## Integration Points

- **StayStore.stayStatus(for:)** — calls `VisaCalculator` for each stay
- **DashboardView** — displays status via `CountryCardView`
- **HistoryView** — displays year summaries using `calculateYearSummary`
- **AlertManager** — monitors status changes and triggers notifications
