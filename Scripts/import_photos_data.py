#!/usr/bin/env python3
"""
Import GPS data from Apple Photos into Nomad Tracker stay records.
Optimized for speed - processes in batches, outputs progress.
"""

import sqlite3
import json
import sys
from datetime import datetime, timezone, timedelta
from collections import defaultdict

PHOTOS_DB = "/Users/ndlomoro/Pictures/Photos Library.photoslibrary/database/Photos.sqlite"
APPLE_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

def main():
    print("📸 Connecting to Photos library...")
    conn = sqlite3.connect(PHOTOS_DB)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # Get count first
    cur.execute("""
        SELECT COUNT(*) FROM ZASSET 
        WHERE ZLATITUDE IS NOT NULL AND ZLONGITUDE IS NOT NULL
          AND ABS(ZLATITUDE) < 90 AND ABS(ZLONGITUDE) < 180
          AND ZTRASHEDSTATE = 0
    """)
    total = cur.fetchone()[0]
    print(f"📊 Found {total} geotagged photos")
    
    # Query in batches
    BATCH = 5000
    offset = 0
    all_locations = []
    
    while offset < total:
        cur.execute(f"""
            SELECT ZLATITUDE, ZLONGITUDE, ZDATECREATED
            FROM ZASSET 
            WHERE ZLATITUDE IS NOT NULL AND ZLONGITUDE IS NOT NULL
              AND ABS(ZLATITUDE) < 90 AND ABS(ZLONGITUDE) < 180
              AND ZTRASHEDSTATE = 0
            ORDER BY ZDATECREATED ASC
            LIMIT {BATCH} OFFSET {offset}
        """)
        rows = cur.fetchall()
        if not rows:
            break
        
        for row in rows:
            ts = APPLE_EPOCH + timedelta(seconds=row['ZDATECREATED'])
            all_locations.append({
                'lat': round(row['ZLATITUDE'], 2),
                'lon': round(row['ZLONGITUDE'], 2),
                'date': ts,
            })
        
        offset += BATCH
        print(f"  📥 Batch {offset}/{total}...")
    
    conn.close()
    print(f"✅ Loaded {len(all_locations)} locations")
    
    # Reverse geocode in batches
    print("🌍 Geocoding locations...")
    try:
        import reverse_geocoder as rg
    except ImportError:
        print("❌ Install: pip install reverse_geocoder")
        sys.exit(1)
    
    # Group by country
    country_timeline = defaultdict(list)
    geocoded = 0
    
    for i in range(0, len(all_locations), 1000):
        batch = all_locations[i:i+1000]
        coords = [(loc['lat'], loc['lon']) for loc in batch]
        
        try:
            results = rg.search(coords)
            for loc, result in zip(batch, results):
                cc = result.get('cc', 'XX')
                if cc and cc != 'ZZ':
                    country_timeline[cc].append({
                        'date': loc['date'],
                        'city': result.get('name', 'Unknown'),
                        'country_name': result.get('country', 'Unknown'),
                    })
                    geocoded += 1
        except Exception as e:
            print(f"  ⚠️ Batch error: {e}")
        
        print(f"  🌍 Geocoded {min(i+1000, len(all_locations))}/{len(all_locations)}...")
    
    print(f"✅ Geocoded {geocoded} locations to {len(country_timeline)} countries")
    
    # Calculate continuous stays
    print("📅 Calculating stays...")
    stays = []
    GAP_DAYS = 7  # Max gap to consider same stay
    
    for cc, entries in sorted(country_timeline.items(), key=lambda x: x[1][0]['date']):
        if not entries:
            continue
        
        current = {
            'country_code': cc,
            'country_name': entries[0]['country_name'],
            'entry_date': entries[0]['date'].isoformat(),
            'cities': list(set([entries[0]['city']])),
        }
        
        for i in range(1, len(entries)):
            prev = entries[i-1]['date']
            curr = entries[i]['date']
            gap = (curr - prev).days
            
            if gap <= GAP_DAYS:
                current['cities'].append(entries[i]['city'])
            else:
                # Close current stay
                current['exit_date'] = prev.isoformat()
                current['cities'] = list(set(current['cities']))[:5]  # Limit cities
                stays.append(current)
                current = {
                    'country_code': cc,
                    'country_name': entries[i]['country_name'],
                    'entry_date': curr.isoformat(),
                    'cities': [entries[i]['city']],
                }
        
        # Close last stay (active)
        current['exit_date'] = None
        current['cities'] = list(set(current['cities']))[:5]
        stays.append(current)
    
    # Output
    output = {
        'exported_at': datetime.now(timezone.utc).isoformat(),
        'source': 'Apple Photos Library',
        'total_photos': len(all_locations),
        'countries_visited': len(country_timeline),
        'total_stays': len(stays),
        'stays': stays,
    }
    
    # Save to file
    outpath = "/Users/ndlomoro/Documents/Develop/nomad-tracker/Data/photos_import.json"
    with open(outpath, 'w') as f:
        json.dump(output, f, indent=2, default=str)
    
    print(f"\n📁 Saved to {outpath}")
    print(f"📊 Summary:")
    print(f"   Photos: {len(all_locations)}")
    print(f"   Countries: {len(country_timeline)}")
    print(f"   Stays: {len(stays)}")
    
    # Print active stays
    active = [s for s in stays if s['exit_date'] is None]
    if active:
        print(f"\n📍 Active stays:")
        for s in active:
            entry = datetime.fromisoformat(s['entry_date'])
            days = (datetime.now(timezone.utc) - entry).days
            print(f"   🇨🇴 {s['country_name']}: {days} days ({', '.join(s['cities'][:3])})")

if __name__ == '__main__':
    main()
