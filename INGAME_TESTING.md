# Ingame Testing – PaTiFish

World of Warcraft: Forever
Interface: 16001

Diese Datei dokumentiert ausschließlich Tests im echten WoW-Client.

Automatisierte Tests, CI und Code Review zählen NICHT als Ingame-Verifikation.
Regeln und Eintragen von Ergebnissen: [PaTiAdmin/docs/TESTING.md](https://github.com/patpaskoch/PaTiAdmin/blob/main/docs/TESTING.md#in-game-test-files).

## Legende

- [ ] offen / noch nicht bestätigt
- [x] vom Owner im echten Client bestätigt
- ❌ FAIL = im echten Client fehlgeschlagen
- 🔧 FIX IMPLEMENTED = Codefix vorhanden, Retest noch offen
- ✅ VERIFIED = erfolgreich im echten Client bestätigt
- MANUAL RETEST REQUIRED = erneuter Test notwendig

## Laden (2026-11-20)

- [x] PT-FISH-001 PaTiFish erscheint in der AddOn-Liste mit Symbol und Beschreibung; Login ohne Lua-Fehler
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [x] PT-FISH-002 `/pfish test`: die Leiste erscheint mit Beispielwerten (Angeln 75 / 150 (+25), Köder 8:30,
  Wurf-Balken), der Rahmen blinkt gelb; „Fänge“ öffnet links die Liste mit Beispielfischen; nochmal `/pfish test` → weg
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.

## Angel und Waffen

- [x] PT-FISH-003 Knopf an der Minimap (Angel-Symbol) mit Waffen in der Hand und Angel in der Tasche: ein Klick legt
  die Angel an, die Leiste erscheint unten in der Mitte
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [x] PT-FISH-004 Nochmal Minimap-Knopf (oder „Waffen“ in der Leiste): deine Waffen von vorher sind wieder in der
  Hand (auch Schild/Nebenhand), die Leiste verschwindet; Tooltip des Knopfs sagt jeweils, was er tut
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [x] PT-FISH-014 Minimap-Knopf mit gedrückter rechter Maustaste ziehen, und ebenso mit Umschalt + linker Maustaste: er
  lässt sich überall hin ziehen (auch weg von der Minimap) und bleibt nach `/reload` dort; dabei wechselt nichts (keine Angel/Waffen); normaler
  Linksklick wechselt weiter; im Kampf lässt er sich nicht verschieben
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [x] PT-FISH-005 Leiste verschieben, `/reload`: sie steht wieder dort; Einstellungen → Minimap-Knopf aus → Knopf weg
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.

## Angeln

- [x] PT-FISH-006 „Auswerfen“ wirft die Angel aus; der Balken läuft ab, in den letzten 3 Sekunden gelb und der Rahmen
  blinkt; Fisch einholen → Balken leer, Blinken aus
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [x] PT-FISH-007 Beim Auswerfen werden Effekte laut und Musik/Umgebung leise; etwa 15 s nach dem letzten Wurf sind
  deine Lautstärken wieder wie vorher; `/reload` mitten im Angeln → nach dem Laden wieder deine Lautstärken
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [ ] PT-FISH-008 Mit Köder in der Tasche: „Köder“ legt ihn an die Angel, oben steht „Köder: noch 10:00“ und zählt
  herunter; ohne Köder ist der Knopf grau
  - Owner 2026-11-21: auf der Testseite „Kann ich nicht testen“ (ohne Grund).
- [x] PT-FISH-009 Anzeige „Angeln x / y“ stimmt mit dem Fertigkeiten-Fenster; mit Köder steht „(+25)“ o. ä. dahinter
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [ ] PT-FISH-010 Hinweis unten: ohne Taste für „Mit Ziel interagieren“ steht der Weg zur Tastenbelegung; mit Taste und
  „Weiches Interagieren“ an: beim Platschen Taste drücken → Fisch wird eingeholt, ohne den Schwimmer anzuklicken
  - ❌ FAIL 2026-11-21
  - Owner: auf der Testseite „Geht nicht“; die Notiz ging verloren (Speicherfehler der Testseite, behoben 2026-11-21) – Owner fragen, was passiert ist.
- [x] PT-FISH-011 Tastenbelegung > PaTiFish: Auswerfen, Köder und „Angel an / Waffen zurück“ lassen sich belegen und
  funktionieren
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
- [ ] PT-FISH-018 Mit PaTiAlerts (2026-11-21): auswerfen und nicht einholen → in den letzten 3 Sekunden erscheint in
  PaTiAlerts „Angel läuft gleich aus – neu auswerfen“ (gelb, Quelle PaTiFish) mit 3 s / 2 s / 1 s; Wurf endet oder
  Fisch eingeholt → Zeile weg; neu auswerfen → kommt beim nächsten Ablauf wieder
- [ ] PT-FISH-019 Einstellung „Rahmen blinkt …“ aus → auch in PaTiAlerts keine Zeile; `/pfish test` → nichts in
  PaTiAlerts; ohne PaTiAlerts angeln → kein Lua-Fehler

## Fänge
- [x] PT-FISH-016 Angel anlegen: die Fang-Liste ist gleich offen, am linken Bildschirmrand; verschieben → bleibt nach
  `/reload` dort; „Fänge“ oder ihr roter Kreis schließt sie, sie bleibt dann auch beim nächsten Angeln zu, bis du
  „Fänge“ wieder drückst
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.

## Pfeiltasten
- [x] PT-FISH-017 Angel in der Hand: Pfeil hoch = Auswerfen, rechts = Köder, links = Fänge auf/zu, runter = Waffen
  zurück; danach laufen die Pfeiltasten wieder normal (Figur bewegt sich); Einstellungen → Pfeiltasten aus → die
  Pfeile bewegen wieder die Figur, auch mit Angel; Tastenbelegung im WoW-Menü bleibt unverändert
  - ❌ FAIL 2026-11-20
  - Owner: „Mit Ziel interagieren“ liegt auf Pfeil runter; der Hinweis sagt „Pfeil runter drücken“, das holt aber
    nicht ein (PaTiFish hatte die Taste mit „Waffen zurück“ belegt).
  - 🔧 FIX IMPLEMENTED 2026-11-20 (eine Pfeiltaste, die auf „Mit Ziel interagieren“ liegt, bleibt frei und holt ein)
  - MANUAL RETEST REQUIRED
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.

- [x] PT-FISH-012 Fisch fangen → „Fänge“ zeigt ihn mit Anzahl; mehr fangen → Zahl steigt, meiste oben; bleibt nach
  `/reload`; volle Tasche (Fisch bleibt liegen) zählt nicht
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.

## Biss-Diagnose

- [x] PT-FISH-013 `/pfish diagnose`, auswerfen, auf Biss warten, einholen: im Chat stehen die Ereignisse mit Zeit; bitte
  den Chat-Ausschnitt an Claude schicken (zeigt, ob WoW den Biss meldet)
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.

## Angel erkennen (2026-11-20)

- [x] PT-FISH-015 Angel erkennen (Owner 2026-11-20: „sagt, ich habe keine Angel in den Taschen“): Angel angelegt →
  die Leiste erscheint, Tooltip des Minimap-Knopfs „Waffen“; Angel in der Tasche → Tooltip „Angel an“, Klick legt sie
  an; bei Problemen bitte die Ausgabe von `/pfish debug` schicken (Zeile „Main hand …“)
  - ❌ FAIL 2026-11-20
  - Owner: Tooltip meldete „Keine Angel in den Taschen“, obwohl die Angel angelegt war (also auch in der Hand nicht
    erkannt).
  - 🔧 FIX IMPLEMENTED 2026-11-20 (bekannte Angeln per Item-Nummer, Untertyp-Name als dritte Prüfung, Taschen beim
    Drüberfahren neu gelesen; `/pfish debug` zeigt Klasse/Unterklasse der Waffe)
  - MANUAL RETEST REQUIRED
  - ✅ VERIFIED 2026-11-21
  - Owner: auf der Testseite mit „Geht“ bestätigt.
