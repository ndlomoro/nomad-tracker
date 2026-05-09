#!/usr/bin/env python3
"""
Import GPS data from Apple Photos library into Nomad Tracker format.
Generates JSON stay records from geotagged photos.

Usage:
    python3 import_photos_data.py > nomad-tracker/Data/photos_import.json
"""

import sqlite3
import json
from datetime import datetime, timezone
from collections import defaultdict

# Configuration
PHOTOS_DB = "/Users/ndlomoro/Pictures/Photos Library.photoslibrary/database/Photos.sqlite"
APPLE_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

def main():
    # Connect to Photos database
    conn = sqlite3.connect(PHOTOS_DB)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Query geotagged photos with valid coordinates
    query = """
        SELECT 
            ZLATITUDE,
            ZLONGITUDE,
            ZDATECREATED,
            ZDURATION,
            ZFILENAME
        FROM ZASSET 
        WHERE ZLATITUDE IS NOT NULL 
          AND ZLONGITUDE IS NOT NULL
          AND ABS(ZLATITUDE) < 90 
          AND ABS(ZLONGITUDE) < 180
          AND ZTRASHEDSTATE = 0
        ORDER BY ZDATECREATED ASC
    """
    
    cursor.execute(query)
    rows = cursor.fetchall()
    print(f"📸 Found {len(rows)} geotagged photos")
    
    # Convert timestamps and group by location
    locations = []
    for row in rows:
        timestamp = APPLE_EPOCH + __import__('datetime').timedelta(seconds=row['ZDATECREATED'])
        locations.append({
            'lat': round(row['ZLATITUDE'], 2),
            'lon': round(row['ZLONGITUDE'], 2),
            'date': timestamp.isoformat(),
            'timestamp': row['ZDATECREATED']
        })
    
    # Install reverse_geocoder for offline country lookup
    try:
        import reverse_geocoder as rg
    except ImportError:
        print("⚠️ Installing reverse_geocoder...")
        import subprocess
        subprocess.run(['/Users/ndlomoro/anaconda3/bin/pip', 'install', 'reverse_geocoder'], 
                      capture_output=True)
        import reverse_geocoder as rg
    
    # Group by country and calculate stays
    country_timeline = defaultdict(list)
    
    for loc in locations:
        try:
            result = rg.search([(loc['lat'], loc['lon'])])[0]
            country_code = result['cc']
            city = result['name']
            country_name = result['country']
            
            country_timeline[country_code].append({
                'date': loc['date'],
                'city': city,
                'country_name': country_name
            })
        except Exception as e:
            continue
    
    # Calculate continuous stays per country
    stays = []
    for country_code, entries in sorted(country_timeline.items(), 
                                        key=lambda x: x[1][0]['date']):
        if not entries:
            continue
        
        current_stay = {
            'country_code': country_code,
            'country_name': entries[0]['country_name'],
            'entry_date': entries[0]['date'],
            'cities': list(set(e['city'] for e in entries[:1]))
        }
        
        for i in range(1, len(entries)):
            prev_date = datetime.fromisoformat(entries[i-1]['date'])
            curr_date = datetime.fromisoformat(entries[i]['date'])
            gap_days = (curr_date - prev_date).days
            
            if gap_days <= 7:  # 7-day gap = same stay
                current_stay['cities'].append(entries[i]['city'])
            else:
                # End current stay, start new one
                current_stay['exit_date'] = entries[i-1]['date']
                current_stay['cities'] = list(set(current_stay['cities']))
                stays.append(current_stay)
                
                current_stay = {
                    'country_code': country_code,
                    'country_name': entries[i]['country_name'],
                    'entry_date': entries[i]['date'],
                    'cities': [entries[i]['city']]
                }
        
        # Close last stay (still active)
        current_stay['exit_date'] = None
        current_stay['cities'] = list(set(current_stay['cities']))
        stays.append(current_stay)
    
    # Generate output
    output = {
        'exported_at': datetime.now(timezone.utc).isoformat(),
        'source': 'Apple Photos Library',
        'total_photos': len(locations),
        'countries_visited': len(country_timeline),
        'stays': stays
    }
    
    print(json.dumps(output, indent=2, default=str))
    
    conn.close()

if __name__ == '__main__':
    main()
