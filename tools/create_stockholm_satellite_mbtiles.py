#!/usr/bin/env python3
"""Build the small CC BY 4.0 Stockholm satellite demo used by the example app."""

import math
import sqlite3
import sys
import urllib.request
from pathlib import Path


WEST, SOUTH, EAST, NORTH = 17.75, 59.15, 18.35, 59.50
MIN_ZOOM, MAX_ZOOM = 8, 14
SOURCE = (
    "https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless_3857/"
    "default/g/{z}/{y}/{x}.jpg"
)
ATTRIBUTION = (
    "Sentinel-2 cloudless — https://s2maps.eu by EOX IT Services GmbH "
    "(Contains modified Copernicus Sentinel data 2016), CC BY 4.0"
)


def tile_x(lon: float, zoom: int) -> int:
    return int((lon + 180.0) / 360.0 * (1 << zoom))


def tile_y(lat: float, zoom: int) -> int:
    value = math.radians(lat)
    return int(
        (1.0 - math.asinh(math.tan(value)) / math.pi)
        / 2.0
        * (1 << zoom)
    )


def main() -> None:
    output = Path(sys.argv[1] if len(sys.argv) > 1 else "stockholm_satellite.mbtiles")
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()
    database = sqlite3.connect(output)
    database.executescript(
        """
        CREATE TABLE metadata (name TEXT PRIMARY KEY, value TEXT);
        CREATE TABLE tiles (
          zoom_level INTEGER,
          tile_column INTEGER,
          tile_row INTEGER,
          tile_data BLOB,
          PRIMARY KEY (zoom_level, tile_column, tile_row)
        );
        """
    )
    metadata = {
        "name": "Stockholm Sentinel-2 Cloudless 2016",
        "type": "baselayer",
        "version": "1",
        "description": "Offline satellite demo for Stockholm",
        "format": "jpg",
        "bounds": f"{WEST},{SOUTH},{EAST},{NORTH}",
        "center": "18.0686,59.3293,12",
        "minzoom": str(MIN_ZOOM),
        "maxzoom": str(MAX_ZOOM),
        "attribution": ATTRIBUTION,
    }
    database.executemany("INSERT INTO metadata VALUES (?, ?)", metadata.items())
    tiles = []
    for zoom in range(MIN_ZOOM, MAX_ZOOM + 1):
        for x in range(tile_x(WEST, zoom), tile_x(EAST, zoom) + 1):
            for y in range(tile_y(NORTH, zoom), tile_y(SOUTH, zoom) + 1):
                tiles.append((zoom, x, y))
    total = len(tiles)
    for index, (zoom, x, y) in enumerate(tiles, start=1):
        url = SOURCE.format(z=zoom, x=x, y=y)
        request = urllib.request.Request(url, headers={"User-Agent": "EdgeZ-SDK-demo/0.1"})
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = response.read()
        except Exception as error:
            print(f"skip {zoom}/{x}/{y}: {error}", file=sys.stderr)
            continue
        tms_y = (1 << zoom) - 1 - y
        database.execute("INSERT INTO tiles VALUES (?, ?, ?, ?)", (zoom, x, tms_y, payload))
        if index % 50 == 0 or index == total:
            database.commit()
            print(f"{index}/{total} tiles")
    database.commit()
    database.execute("VACUUM")
    database.close()
    print(f"created {output} ({output.stat().st_size / 1024 / 1024:.1f} MiB)")


if __name__ == "__main__":
    main()
