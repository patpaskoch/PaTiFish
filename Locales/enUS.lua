-- PaTiFish strings, English (source and fallback). One key per line: L.KEY = "Text".
local _, ns = ...
ns.Locales = ns.Locales or {}
local L = ns.Locales.enUS or {}
ns.Locales.enUS = L

-- Window
L.SKILL = "Fishing %d / %d"
L.SKILL_BONUS = " (+%d)"
L.NO_SKILL = "Fishing not learned yet"
L.LURE_ACTIVE = "Lure: %s left"
L.LURE_NONE = "No lure on the pole"
L.NO_POLE = "No fishing pole in your hands"
L.REEL_KEY = "Reel in: press %s when the bobber splashes"
L.REEL_NO_KEY = "Reel in faster: bind a key to \"Interact with Target\" (Key Bindings > Targeting)"
L.REEL_SOFT_OFF = "Key %s: turn on \"Soft interact\" in the settings so it finds the bobber"

-- Buttons
L.CAST = "Cast"
L.CAST_TIP = "Casts Fishing. Catching stays yours: click the bobber or press your Interact key."
L.APPLY_LURE = "Lure"
L.APPLY_LURE_TIP = "Puts your best lure (+%d) on the fishing pole."
L.APPLY_LURE_NONE = "No lure in your bags."
L.CATCHES = "Catches"
L.CATCHES_TIP = "Everything you have fished so far, with the count."
L.EQUIP_POLE = "Pole on"
L.EQUIP_POLE_TIP = "Equips your fishing pole. Your weapons are remembered."
L.EQUIP_WEAPONS = "Weapons"
L.EQUIP_WEAPONS_TIP = "Puts the weapons from before the pole back on."
L.NO_WEAPONS_TIP = "No weapons remembered yet: equip them once yourself."
L.GEAR_NONE_TIP = "No fishing pole in your bags."
L.BIND_GEAR = "Pole on / weapons back"
L.MINIMAP_DRAG_TIP = "Right button or Shift + left button held: move this button around the minimap."

-- Catch list
L.NO_CATCHES = "Nothing caught yet."
L.MORE_CATCHES = "+%d more"

-- Settings
L.GENERAL = "General"
L.SCALE = "Scale"
L.LOCK_WINDOW = "Lock window"
L.FISHING = "Fishing"
L.LOUD_SPLASH = "Louder splash while fishing (effects up, music and ambience off)"
L.MINIMAP_BUTTON = "Minimap button (pole on / weapons back)"
L.FLASH_WARNING = "Flash the frame when the cast is about to end"
L.SOFT_INTERACT = "Soft interact: the Interact key finds the bobber (WoW setting)"

-- Chat
L.HIDDEN_HINT = "hidden. /pfish show brings it back."
L.NO_POLE_HINT = "the bar shows with a fishing pole in your hands (minimap button or /pfish test)."
L.DIAGNOSE_ON = "bite diagnosis on: cast once and wait for a bite; the events of that cast are listed when it ends."
L.DIAGNOSE_RESULT = "bite diagnosis: %d different events during the cast (time after the cast start):"
L.HELP = "/pfish show, hide, lock, unlock, reset, settings, test, debug, diagnose, version"
L.VERSION = "version %s"
L.CMD_DIAGNOSE = "list the events of the next cast (does WoW report the bite?)"
