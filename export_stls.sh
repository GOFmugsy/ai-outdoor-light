#!/usr/bin/env bash
# Export every printable part of solar_light.scad to stl/<part>.stl
# Extra args are passed to OpenSCAD, e.g.:  ./export_stls.sh -D 'battery_type="lipo"'
set -euo pipefail

cd "$(dirname "$0")"
OPENSCAD="${OPENSCAD:-$(command -v openscad || echo /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD)}"
mkdir -p stl

for part in cap reflector spine diffuser deck gasket body base stake usb_plug; do
    echo "==> $part"
    "$OPENSCAD" --backend=Manifold -D "part=\"$part\"" "$@" -o "stl/$part.stl" solar_light.scad
done
