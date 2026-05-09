# NomadTracker — Product Specification

## Overview

NomadTracker is a macOS/iOS app for tracking digital nomad visa stays. It helps users monitor how many days they've spent in each country, detect visa violations before they happen, and import travel history from iCloud Photos GPS data.

## Problem Statement

Digital nomads face complex visa rules:
- **Calendar year** limits (e.g., 90 days per year in many countries)
- **Rolling 90/180** windows (Schengen zone)
- **Custom rolling windows** (country-specific)
- **Multiple countries** with different rules
- **Photo-based travel history** that's hard to reconcile with visa limits

Users need a single source of truth that tracks active stays, warns before limits are hit, and imports historical GPS data from their photo library.

## Target Users

- Digital nomads working remotely across multiple countries
- Remote-first employees of companies like AndesLabs
- Frequent travelers who need to track visa compliance
- Users with 20k+ photos in iCloud who want GPS-based travel history

## Core Capabilities

1. **Active Stay Tracking** — Monitor current country stays with countdown timers
2. **Visa Rule Engine** — Calculate remaining days using calendar year, rolling 90/180, and custom rules
3. **Alert System** — Push notifications at configurable thresholds (30, 15, 7, 3, 1 days)
4. **Photos Import** — Extract GPS data from iCloud Photos, geocode to countries, generate stay records
5. **Year Summary** — Annual breakdown of days per country
6. **Widget Support** — Desktop/mobile widgets showing active stays and year summaries
7. **Data Export/Import** — JSON export/import for backup and migration

## Non-Goals (v1)

- Multi-user sync (single device only)
- CloudKit sync (local Core Data only)
- Apple Watch support
- Social features or sharing
