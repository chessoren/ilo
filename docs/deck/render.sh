#!/bin/bash
# Re-renders the Devpost image gallery (slide-01…14.png + logo-1024.png) from docs/deck/src/deck.html.
# Screenshots are read from docs/deck/shots/: replace a file there (same name) and re-run.
# Usage: docs/deck/render.sh          # all slides + logo
#        docs/deck/render.sh 3 7      # only slides 3 and 7
# Preview in a browser: open "docs/deck/src/deck.html" (all slides stacked) or deck.html?n=3.
set -euo pipefail
DECK="$(cd "$(dirname "$0")" && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
export CHROME

if command -v node >/dev/null && node -e 'process.exit(typeof WebSocket === "function" ? 0 : 1)'; then
  # One headless Chrome for every slide (fast).
  node "$DECK/src/render.mjs" "$DECK" "$@"
else
  # Fallback: one headless Chrome per slide.
  SLIDES=("$@"); [ ${#SLIDES[@]} -eq 0 ] && SLIDES=($(seq 1 14))
  for n in "${SLIDES[@]}"; do
    out="$DECK/slide-$(printf %02d "$n").png"
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
      --allow-file-access-from-files --virtual-time-budget=4000 --window-size=2400,1600 \
      --screenshot="$out" "file://$DECK/src/deck.html?n=$n" >/dev/null 2>&1
    echo "rendered $(basename "$out")"
  done
fi

# Logo: the shipped app icon.
if [ $# -eq 0 ]; then
  cp "$DECK/../../ilo/Assets.xcassets/AppIcon.appiconset/icon-1024.png" "$DECK/logo-1024.png"
  echo "copied logo-1024.png"
fi

python3 - "$DECK" <<'PY' || true
import sys, glob, os
from PIL import Image
for f in sorted(glob.glob(os.path.join(sys.argv[1], '*.png'))):
    w, h = Image.open(f).size
    ok = (w, h) in [(2400, 1600), (1024, 1024)]
    print(f"{'ok ' if ok else 'BAD'} {os.path.basename(f)} {w}x{h}")
PY
