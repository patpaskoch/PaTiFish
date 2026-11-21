-- PaTiFish strings, German. Missing keys fall back to English.
local _, ns = ...
ns.Locales = ns.Locales or {}
local L = ns.Locales.deDE or {}
ns.Locales.deDE = L

-- Window
L.SKILL = "Angeln %d / %d"
L.SKILL_BONUS = " (+%d)"
L.NO_SKILL = "Angeln noch nicht erlernt"
L.LURE_ACTIVE = "Köder: noch %s"
L.LURE_NONE = "Kein Köder an der Angel"
L.NO_POLE = "Keine Angel in der Hand"
L.REEL_KEY = "Einholen: %s drücken, wenn der Schwimmer platscht"
L.REEL_NO_KEY = "Schneller einholen: Taste für „Mit Ziel interagieren“ belegen (Tastenbelegung > Zielauswahl)"
L.REEL_SOFT_OFF = "Taste %s: in den Einstellungen „Weiches Interagieren“ einschalten, damit sie den Schwimmer findet"

-- Buttons
L.CAST = "Auswerfen"
L.CAST_TIP = "Wirft die Angel aus. Einholen machst du selbst: Schwimmer anklicken oder Interagieren-Taste drücken."
L.APPLY_LURE = "Köder"
L.APPLY_LURE_TIP = "Legt deinen besten Köder (+%d) an die Angel."
L.APPLY_LURE_NONE = "Kein Köder in den Taschen."
L.CATCHES = "Fänge"
L.CATCHES_TIP = "Alles, was du bisher geangelt hast, mit Anzahl."
L.EQUIP_POLE = "Angel an"
L.EQUIP_POLE_TIP = "Legt deine Angel an. Deine Waffen werden gemerkt."
L.EQUIP_WEAPONS = "Waffen"
L.EQUIP_WEAPONS_TIP = "Legt die Waffen von vor der Angel wieder an."
L.NO_WEAPONS_TIP = "Noch keine Waffen gemerkt: lege sie einmal selbst an."
L.GEAR_NONE_TIP = "Keine Angel in den Taschen."
L.BIND_GEAR = "Angel an / Waffen zurück"
L.ARROW_UP = "Taste: Pfeil hoch (solange die Angel in der Hand ist)"
L.ARROW_RIGHT = "Taste: Pfeil rechts (solange die Angel in der Hand ist)"
L.ARROW_LEFT = "Taste: Pfeil links (solange die Angel in der Hand ist)"
L.ARROW_DOWN = "Taste: Pfeil runter (solange die Angel in der Hand ist)"
L.ARROW_KEYS = "Pfeiltasten, solange die Angel in der Hand ist: hoch Auswerfen, rechts Köder, links Fänge, runter Waffen (Laufen mit den Pfeilen geht dann nicht)"
L.MINIMAP_DRAG_TIP = "Rechte Maustaste oder Umschalt + linke Maustaste halten: Knopf beliebig verschieben."

-- Catch list
L.NO_CATCHES = "Noch nichts gefangen."
L.MORE_CATCHES = "+%d weitere"

-- Settings
L.GENERAL = "Allgemein"
L.SCALE = "Größe"
L.LOCK_WINDOW = "Fenster sperren"
L.FISHING = "Angeln"
L.LOUD_SPLASH = "Lauteres Platschen beim Angeln (Effekte laut, Musik und Umgebung aus)"
L.MINIMAP_BUTTON = "Knopf an der Minimap (Angel an / Waffen zurück)"
L.FLASH_WARNING = "Rahmen blinkt, wenn die Angel gleich ausläuft (auch in PaTiAlerts)"
L.ALERT_CAST_ENDING = "Angel läuft gleich aus – neu auswerfen"
L.SOFT_INTERACT = "Weiches Interagieren: die Interagieren-Taste findet den Schwimmer (WoW-Einstellung)"

-- Chat
L.HIDDEN_HINT = "ausgeblendet. /pfish show holt es zurück."
L.NO_POLE_HINT = "die Leiste erscheint mit einer Angel in der Hand (Minimap-Knopf oder /pfish test)."
L.DIAGNOSE_ON = "Biss-Diagnose an: einmal auswerfen und auf einen Biss warten; die Ereignisse dieses Wurfs stehen danach im Chat."
L.DIAGNOSE_RESULT = "Biss-Diagnose: %d verschiedene Ereignisse während des Wurfs (Zeit nach dem Auswerfen):"
L.HELP = "/pfish show, hide, lock, unlock, reset, settings, test, debug, diagnose, version"
L.VERSION = "Version %s"
L.CMD_DIAGNOSE = "Ereignisse des nächsten Wurfs auflisten (meldet WoW den Biss?)"
