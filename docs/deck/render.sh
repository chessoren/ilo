#!/bin/bash
# Re-renders the Devpost image gallery from docs/deck/src/deck.html.
# Screenshots are read from docs/deck/shots/ — replace files there (same names) and re-run.
# Usage: docs/deck/render.sh            # all 14 slides + logo
#        docs/deck/render.sh 3 7        # only slides 3 and 7
set -euo pipefail
DECK="$(cd "$(dirname "$0")" && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
TOTAL=14
SLIDES=("$@")
if [ ${#SLIDES[@]} -eq 0 ]; then SLIDES=($(seq 1 $TOTAL)); fi

for n in "${SLIDES[@]}"; do
  out="$DECK/slide-$(printf %02d "$n").png"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=4000 --window-size=2400,1600 \
    --screenshot="$out" "file://$DECK/src/deck.html?n=$n" >/dev/null 2>&1
  echo "rendered $(basename "$out")"
done

# Logo: the app icon, as shipped.
if [ $# -eq 0 ]; then
  cp "$DECK/../../ilo/Assets.xcassets/AppIcon.appiconset/icon-1024.png" "$DECK/logo-1024.png"
  echo "copied logo-1024.png"
fi

python3 - "$DECK" <<'PY'
import sys, glob, os
try:
    from PIL import Image
except ImportError:
    sys.exit(0)
for f in sorted(glob.glob(os.path.join(sys.argv[1], '*.png'))):
    w, h = Image.open(f).size
    ok = (w, h) in [(2400, 1600), (1024, 1024)]
    print(f"{'ok ' if ok else 'BAD'} {os.path.basename(f)} {w}x{h}")
PY
