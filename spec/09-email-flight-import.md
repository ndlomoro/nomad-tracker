# NomadTracker — Email Flight Import Specification

**Status: NOT IMPLEMENTED.** This document records the design and the access
constraints discovered while attempting it. No code in the repo implements any
part of this yet.

## Motivation

The photos pipeline (see `03-photos-import.md`) reliably captures *entry* to a
country but frequently misses the *exit*, because people photograph arrivals and
not departures. The import compensates with a heuristic — auto-closing any
unclosed stay older than 90 days at `entry + 90 days` — which is explicitly
flagged as a known limitation.

Airline confirmation emails do not have this problem. A booking email states both
directions of travel, with dates, as structured text. For border-crossing dates
they are a materially better source than GPS clustering.

First target: **Colombia entry/exit dates** (`BOG`, `MDE`, `CTG`), because
Colombia's tourist permit (PIP-5, 90 days, extendable to 180 per calendar year)
makes exact dates consequential.

## Data Flow

```
Gmail → search airline/OTA senders → parse itinerary legs → country crossings → JSON → Core Data
```

## Step 1: Access Gmail

Four routes were evaluated on 2026-07-24 against `ndlomoro@gmail.com`:

| Route | Result |
|---|---|
| **Gmail connector** (`gmail.mcp.claude.com`) | **Viable.** Registered in `~/.claude.json`; read-only tools (search threads, get message, get thread, list labels) set to "Always allow". Connector tools load at Claude Code **startup**, so enabling it mid-session does not expose the tools — the session must be restarted. |
| Claude in Chrome extension | Dead end. Extension present in the `Default` profile (v1.0.81, not disabled) but never paired: `list_connected_browsers` returned `[]` and a broadcast pairing request found nothing. Pairing is per-claude.ai-account, and the profile holding `ndlomoro@gmail.com` is not the profile signed in as the account running Claude Code. |
| chrome-devtools-mcp | Dead end. Drives a throwaway Chrome profile with no Google session; `mail.google.com` redirects to the marketing page. |
| Apple Mail local store | Dead end. `~/Library/Mail/V10` holds one iCloud account, 11 messages. The Gmail account is not synced locally. |
| Google Takeout mbox | Viable fallback. Fully offline, no browser or credential handling. Slower for the user. |

**Chosen route:** Gmail connector, restarting Claude Code first.

Note the account split — Claude Code runs as `nick.lamore@locallabs.com` while the
mailbox of interest is `ndlomoro@gmail.com`. The connector must be OAuth'd against
the Gmail account, not the locallabs mailbox, or it will search the wrong inbox.

## Step 2: Search Query

```
(BOG OR MDE OR CTG OR Bogota OR Bogotá OR Medellin OR Medellín OR Cartagena OR Colombia)
(from:avianca.com OR from:latam.com OR from:copaair.com OR from:aa.com OR from:delta.com
 OR from:united.com OR from:jetblue.com OR from:spirit.com OR from:wingo.com
 OR from:expedia.com OR from:kayak.com OR from:booking.com OR from:google.com
 OR subject:(itinerary OR "boarding pass" OR confirmation OR "e-ticket" OR reservation))
```

Sender-scoping matters: an unscoped Colombia keyword search pulls in newsletters,
fare alerts, and unbooked searches, all of which look like itineraries to a parser.

## Step 3: Parse Itinerary Legs

Extract per leg: airline, flight number, origin IATA, destination IATA, departure
date, arrival date, confirmation code.

Rules:

1. **Only ticketed travel counts.** Fare alerts, price-drop notices, cancellations,
   and abandoned carts must be discarded. A booking confirmation superseded by a
   later change email loses to the newer one, matched on confirmation code.
2. **Map IATA → country**, not city. `BOG`/`MDE`/`CTG`/`CLO`/`SMR`/`ADZ` → `CO`.
3. **A crossing is a leg whose origin and destination countries differ.** Domestic
   Colombian legs (`BOG`→`MDE`) are movement inside a stay, not entry or exit.
4. **Use the local arrival date for entry and the local departure date for exit** —
   immigration stamps the calendar day at the border, so a UTC-normalised timestamp
   can land on the wrong day for red-eyes.
5. **Layovers are not entries.** A connection through `PTY` or `BOG` under ~24h
   without clearing immigration is not a stay. Airside transit cannot be
   distinguished from a real entry from email alone — flag these for user review
   rather than guessing.

## Step 4: Output

Reuse the `photos_import.json` stay schema (see `03-photos-import.md`) so the
existing `PersistenceController.importStaysFromJSON(data:)` path can consume it
unchanged, with `source` set to identify the provenance:

```json
{
  "exported_at": "ISO 8601 timestamp",
  "source": "Gmail flight confirmations",
  "stays": [
    {
      "country_code": "CO",
      "country_name": "Colombia",
      "entry_date": "2024-01-14T00:00:00+00:00",
      "exit_date": "2024-03-02T00:00:00+00:00",
      "cities": ["Bogotá"]
    }
  ]
}
```

## Step 5: Reconciliation

Email and photo stays will disagree. Precedence:

- **Email wins on dates.** A flight is a documented border crossing; a photo
  cluster is an inference.
- **Photos win on presence.** Land crossings and bus travel leave no flight email
  at all; a photo-derived stay with no matching flight is still a real stay.
- Merge when an email crossing falls within ±2 days of a photo stay boundary;
  otherwise treat as separate stays and surface the conflict.
- Every auto-closed photo stay (`exit == entry + 90`) that an email can date
  properly should be corrected on import.

Requires a new import version string to force re-import (`photosImportVersion`
mechanism, currently `v3`).

## Known Limitations

- **Airside transit is ambiguous** — cannot distinguish a layover from a short
  entry without a stamp.
- **Land and sea crossings are invisible.** Colombia↔Ecuador (Ipiales) and
  Colombia↔Panama (San Blas boats) produce no email.
- **Flown ≠ booked.** A confirmed booking the user never boarded reads as a real
  crossing. No-shows and involuntary reroutes will be wrong.
- **Email retention bounds history.** Deleted confirmations are unrecoverable, so
  this can only ever supplement the photos pipeline, not replace it.
- Sender list is hand-maintained and will miss regional carriers.

## Resuming This Work

1. Restart Claude Code so the Gmail connector's tools load.
2. Confirm the connector is authorised against `ndlomoro@gmail.com`.
3. Run the Step 2 query; read each thread; extract legs per Step 3.
4. Report Colombia entry/exit dates with the source flight for each, for user
   verification, **before** writing any JSON or touching Core Data.
