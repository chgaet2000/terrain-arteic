#!/usr/bin/env bash
# Test de fumée sur émulateur : installe l'APK, lance l'appli, ouvre un formulaire, prend des captures.
set -ux
PKG=fr.arteic.terrain
mkdir -p shots

adb install -r -g Terrain-ARTEIC.apk
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 25
adb exec-out screencap -p > shots/01-accueil.png
echo "pid: $(adb shell pidof $PKG)" | tee shots/pid.txt

tap_text() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb pull /sdcard/ui.xml shots/ui.xml >/dev/null 2>&1
  python3 - "$1" <<'PY'
import re, sys, subprocess
text = sys.argv[1]
xml = open('shots/ui.xml', encoding='utf-8', errors='ignore').read()
for m in re.finditer(r'<node[^>]*?(?:text|content-desc)="([^"]*)"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml):
    if text.lower() in m.group(1).lower():
        l, t, r, b = map(int, m.groups()[1:])
        x, y = (l + r) // 2, (t + b) // 2
        print(f"tap '{m.group(1)}' at {x},{y}")
        subprocess.run(['adb', 'shell', 'input', 'tap', str(x), str(y)])
        sys.exit(0)
print(f"texte '{text}' introuvable")
sys.exit(1)
PY
}

cp shots/ui.xml shots/ui-accueil.xml 2>/dev/null || true
tap_text "Situation dangereuse"; sleep 3
adb exec-out screencap -p > shots/02-formulaire.png
tap_text "Nouvelle saisie"; sleep 3
adb exec-out screencap -p > shots/03-nouvelle-saisie.png
tap_text "Suivant"; sleep 2
adb exec-out screencap -p > shots/04-etape-suivante.png

adb logcat -d -s Capacitor Capacitor/Console chromium:E AndroidRuntime:E > shots/logcat.txt
exit 0
