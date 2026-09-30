#!/bin/bash
# Copies fresh app screenshots into docs/deck/shots/ under the names deck.html uses, downscaled to 800 px wide.
# Usage: docs/deck/sync-shots.sh <dir-with-screenshots> [more dirs…]   then: docs/deck/render.sh
# Source names follow the XCUITest capture names (03-goal.png, 50-wordBricks.png…); the first match wins.
set -euo pipefail
DECK="$(cd "$(dirname "$0")" && pwd)"
[ $# -ge 1 ] || { echo "usage: $0 <screenshot dir>..."; exit 1; }
python3 - "$DECK/shots" "$@" <<'PY'
import sys, os
from PIL import Image
dest, dirs = sys.argv[1], sys.argv[2:]
MAP = {
  'welcome': ['01-welcome', 'screenshot-01-welcome'],
  'how-it-works': ['02-how-it-works'],
  'goal': ['03-goal', '01-goal', 'screenshot-02-goal'],
  'bloub-maker': ['07-bloub'],
  'claude': ['07b-claude', 'screenshot-11-claude'],
  'building': ['08-building', '02-building', 'screenshot-03-building'],
  'path-ready': ['09-path-ready'],
  'commit': ['10-commit', '03-commit'],
  'paywall-hero': ['11-paywall-hero'],
  'paywall': ['12-paywall-plans', '04-paywall', 'screenshot-04-paywall'],
  'home': ['13-home', '30-home-seeded', 'screenshot-05-home'],
  'path': ['20-path', 'screenshot-06-path'],
  'node-popover': ['21-node-popover'],
  'story-card': ['50-storyCards', '05-story-card', 'screenshot-07-lesson'],
  'metronome': ['50-practiceTimer', '06-metronome', 'practiceTimer'],
  'code-lab': ['50-codeLab', '07-code-lab-preview', 'codeLab'],
  'lesson-complete': ['24-celebration-0', 'screenshot-08-complete'],
  'streak': ['24-celebration-1', '08-streak'],
  'badges': ['24-celebration-2'],
  'leagues': ['31-leagues', 'screenshot-09-leagues'],
  'quests': ['32-quests'],
  'profile': ['33-profile', 'screenshot-10-profile'],
  'bloub-studio': ['34-bloub-studio'],
  'create': ['37-create'],
}
for m in ['cameraCoach', 'mission', 'liveCall', 'roleplay', 'teachBack', 'freeAnswer', 'wordBricks', 'matchPairs',
          'trueFalse', 'scenario', 'estimate', 'flashcards', 'audioLesson', 'categorize', 'spotTheMistake',
          'speedRound', 'multipleChoice', 'fillBlank', 'reorder', 'highlight']:
    MAP['module-' + m] = ['50-' + m, m]
import re
used = set(re.findall(r'shots/([\w-]+)\.png', open(os.path.join(os.path.dirname(dest), 'src', 'deck.html')).read()))
for name, candidates in MAP.items():
    if name not in used:
        continue
    src = next((os.path.join(d, c + '.png') for c in candidates for d in dirs if os.path.exists(os.path.join(d, c + '.png'))), None)
    if not src:
        continue
    im = Image.open(src).convert('RGB')
    w, h = im.size
    im.resize((800, round(h * 800 / w)), Image.LANCZOS).save(os.path.join(dest, name + '.png'), optimize=True)
    print(f'{name:22s} <- {src}')
PY
