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

- [ ] PT-FISH-001 PaTiFish erscheint in der AddOn-Liste mit Symbol und Beschreibung; Login ohne Lua-Fehler
- [ ] PT-FISH-002 `/pfish test`: die Leiste erscheint mit Beispielwerten (Angeln 75 / 150 (+25), Köder 8:30,
  Wurf-Balken), der Rahmen blinkt gelb; „Fänge“ öffnet links die Liste mit Beispielfischen; nochmal `/pfish test` → weg

## Angel und Waffen

- [ ] PT-FISH-003 Knopf an der Minimap (Angel-Symbol) mit Waffen in der Hand und Angel in der Tasche: ein Klick legt
  die Angel an, die Leiste erscheint unten in der Mitte
- [ ] PT-FISH-004 Nochmal Minimap-Knopf (oder „Waffen“ in der Leiste): deine Waffen von vorher sind wieder in der
  Hand (auch Schild/Nebenhand), die Leiste verschwindet; Tooltip des Knopfs sagt jeweils, was er tut
- [ ] PT-FISH-014 Minimap-Knopf mit gedrückter rechter Maustaste ziehen, und ebenso mit Umschalt + linker Maustaste: er
  wandert am Rand der Minimap mit und bleibt nach `/reload` dort; dabei wechselt nichts (keine Angel/Waffen); normaler
  Linksklick wechselt weiter; im Kampf lässt er sich nicht verschieben
- [ ] PT-FISH-005 Leiste verschieben, `/reload`: sie steht wieder dort; Einstellungen → Minimap-Knopf aus → Knopf weg

## Angeln

- [ ] PT-FISH-006 „Auswerfen“ wirft die Angel aus; der Balken läuft ab, in den letzten 3 Sekunden gelb und der Rahmen
  blinkt; Fisch einholen → Balken leer, Blinken aus
- [ ] PT-FISH-007 Beim Auswerfen werden Effekte laut und Musik/Umgebung leise; etwa 15 s nach dem letzten Wurf sind
  deine Lautstärken wieder wie vorher; `/reload` mitten im Angeln → nach dem Laden wieder deine Lautstärken
- [ ] PT-FISH-008 Mit Köder in der Tasche: „Köder“ legt ihn an die Angel, oben steht „Köder: noch 10:00“ und zählt
  herunter; ohne Köder ist der Knopf grau
- [ ] PT-FISH-009 Anzeige „Angeln x / y“ stimmt mit dem Fertigkeiten-Fenster; mit Köder steht „(+25)“ o. ä. dahinter
- [ ] PT-FISH-010 Hinweis unten: ohne Taste für „Mit Ziel interagieren“ steht der Weg zur Tastenbelegung; mit Taste und
  „Weiches Interagieren“ an: beim Platschen Taste drücken → Fisch wird eingeholt, ohne den Schwimmer anzuklicken
- [ ] PT-FISH-011 Tastenbelegung > PaTiFish: Auswerfen, Köder und „Angel an / Waffen zurück“ lassen sich belegen und
  funktionieren

## Fänge

- [ ] PT-FISH-012 Fisch fangen → „Fänge“ zeigt ihn mit Anzahl; mehr fangen → Zahl steigt, meiste oben; bleibt nach
  `/reload`; volle Tasche (Fisch bleibt liegen) zählt nicht

## Biss-Diagnose

- [ ] PT-FISH-013 `/pfish diagnose`, auswerfen, auf Biss warten, einholen: im Chat stehen die Ereignisse mit Zeit; bitte
  den Chat-Ausschnitt an Claude schicken (zeigt, ob WoW den Biss meldet)
