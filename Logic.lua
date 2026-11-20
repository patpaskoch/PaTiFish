-- PaTiFish: saved settings and the pure fishing rules — no WoW API calls (tests/logic_spec.lua).
local _, ns = ...
local Logic = {}
ns.Logic = Logic

Logic.SCHEMA = 1
Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }

-- Fishing, Apprentice rank: its localized name casts the highest rank the character knows (also "Angeln").
Logic.FISHING_SPELL = 7620
Logic.FISHING_SPELLS = { [7620] = true, [7731] = true, [7732] = true, [18248] = true } -- all ranks
-- Weapon slots: the fishing pole goes into the main hand and holds the lure.
Logic.MAIN_HAND, Logic.OFF_HAND = 16, 17
-- Fishing poles: the known Classic poles by item ID, else item class Weapon (2), subclass Fishing Pole (20).
Logic.KNOWN_POLES = { [6256] = true, [6365] = true, [6366] = true, [6367] = true, [12225] = true, [19022] = true,
    [19970] = true, [25978] = true }
Logic.POLE_CLASS, Logic.POLE_SUBCLASS = 2, 20
-- The last seconds of a cast: the frame flashes, time to cast again (owner 2026-11-20).
Logic.WARN_SECONDS = 3
-- Louder splash: after the last cast ended, the sound stays boosted this long before it is restored (no flicker
-- between two casts).
Logic.SOUND_HOLD = 15

-- Lures, best first: item ID and fishing bonus (Classic items). Applied with "/use item:<id>" + "/use 16".
Logic.LURES = {
    { item = 6533, bonus = 100 }, -- Aquadynamic Fish Attractor
    { item = 7307, bonus = 75 },  -- Flesh Eating Worm
    { item = 6532, bonus = 75 },  -- Bright Baubles
    { item = 6811, bonus = 50 },  -- Aquadynamic Fish Lens
    { item = 6530, bonus = 50 },  -- Nightcrawlers
    { item = 6529, bonus = 25 },  -- Shiny Bauble
}

-- Sound settings while fishing: effects full, music and ambience off.
Logic.SOUND_CVARS = { "Sound_SFXVolume", "Sound_MusicVolume", "Sound_AmbienceVolume" }
Logic.SOUND_BOOST = { Sound_SFXVolume = "1", Sound_MusicVolume = "0", Sound_AmbienceVolume = "0" }

-- Position (point, relativePoint, x, y) is written by the PaTiShared window, not listed here.
Logic.DEFAULTS = {
    opacity = 0.75,
    theme = "default",
    locked = false,
    collapsed = false,
    scale = 1,
    language = "auto",
    loudSplash = true,
    flashWarning = true,
}

local function itemId(value)
    return type(value) == "number" and value > 0 and value == math.floor(value) and value or nil
end

-- A saved sound backup: only the known CVars with string values; anything else → nil (nothing to restore).
function Logic.CleanBackup(backup)
    if type(backup) ~= "table" then return nil end
    local clean, any = {}, false
    for _, cvar in ipairs(Logic.SOUND_CVARS) do
        if type(backup[cvar]) == "string" then clean[cvar], any = backup[cvar], true end
    end
    return any and clean or nil
end

-- Saved weapons from before the pole: { main = id, off = id|nil } or nil.
function Logic.CleanWeapons(weapons)
    if type(weapons) ~= "table" or not itemId(weapons.main) then return nil end
    return { main = weapons.main, off = itemId(weapons.off) }
end

-- Fills missing values and keeps every saved one (also false). A sound backup from a session that ended while
-- fishing stays, so the login can put the player's volumes back; so do the saved weapons.
function Logic.Migrate(db)
    if type(db) ~= "table" then db = {} end
    for key, value in pairs(Logic.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    if type(db.scale) ~= "number" or db.scale < 0.5 or db.scale > 2 then db.scale = Logic.DEFAULTS.scale end
    local knownTheme = { default = true, woforever = true, dracula = true, softfantasy = true }
    if not knownTheme[db.theme] then db.theme = "default" end
    for _, key in ipairs({ "locked", "collapsed", "loudSplash", "flashWarning" }) do
        if type(db[key]) ~= "boolean" then db[key] = Logic.DEFAULTS[key] end
    end
    db.soundBackup = Logic.CleanBackup(db.soundBackup)
    db.weapons = Logic.CleanWeapons(db.weapons)
    db.catches = Logic.CleanCatches(db.catches)
    if type(db.catchWindow) ~= "table" then db.catchWindow = {} end -- position of the catch list (PaTiShared)
    if type(db.minimapAngle) ~= "number" or db.minimapAngle ~= db.minimapAngle then
        db.minimapAngle = Logic.MINIMAP_ANGLE
    end
    if type(db.minimapButton) ~= "boolean" then db.minimapButton = true end
    if type(db.minimapX) ~= "number" or type(db.minimapY) ~= "number" or db.minimapX ~= db.minimapX
        or db.minimapY ~= db.minimapY then
        db.minimapX, db.minimapY = nil, nil
    else
        db.minimapX, db.minimapY = Logic.ClampOffset(db.minimapX), Logic.ClampOffset(db.minimapY)
    end
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": settings back; position, a pending sound backup and the saved weapons kept.
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    return db
end

-- The best lure in the bags: countOf(itemID) → number. Returns the LURES entry or nil.
function Logic.BestLure(countOf)
    for _, lure in ipairs(Logic.LURES) do
        local count = countOf(lure.item)
        if type(count) == "number" and count > 0 then return lure end
    end
    return nil
end

-- Secure macro for "apply lure": use the item, then put it on the main hand (the pole). nil without a lure.
function Logic.LureMacro(lure)
    if not lure then return nil end
    return ("/use item:%d\n/use %d"):format(lure.item, Logic.MAIN_HAND)
end

-- The pole / weapons button (owner 2026-11-20: put the pole on, and the weapons from before back on).
-- gear = { mainIsPole, main, off, bagPole, saved = { main, off } } (item IDs). Returns the mode and its macro:
-- "POLE" (equip the pole from the bags), "WEAPONS" (the saved weapons back) or nil (nothing to do).
function Logic.GearAction(gear)
    if gear.mainIsPole then
        local saved = Logic.CleanWeapons(gear.saved)
        if not saved then return nil end
        local macro = ("/equip item:%d"):format(saved.main)
        if saved.off then macro = macro .. ("\n/equipslot %d item:%d"):format(Logic.OFF_HAND, saved.off) end
        return "WEAPONS", macro
    end
    if itemId(gear.bagPole) then return "POLE", ("/equip item:%d"):format(gear.bagPole) end
    return nil
end

-- What to remember just before the pole goes on: the weapons in the hands now (nil without a main-hand weapon).
function Logic.WeaponsToSave(gear)
    if gear.mainIsPole then return nil end
    return Logic.CleanWeapons({ main = gear.main, off = gear.off })
end

-- "8:05" / "0:42" from seconds; nil for nothing usable.
function Logic.FormatTime(seconds)
    if type(seconds) ~= "number" or seconds ~= seconds or seconds < 0 then return nil end
    seconds = math.floor(seconds)
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

-- Fishing skill from the skill list: entries { name, rank, modifier, max }; fishingName = the localized skill name.
-- Returns { rank, modifier, max } or nil (not learned).
function Logic.FindSkill(entries, fishingName)
    for _, entry in ipairs(entries) do
        if entry.name == fishingName and type(entry.rank) == "number" then
            return { rank = entry.rank, modifier = type(entry.modifier) == "number" and entry.modifier or 0,
                max = type(entry.max) == "number" and entry.max or entry.rank }
        end
    end
    return nil
end

-- The running cast: start/finish and now in seconds. Returns remaining seconds, share left (0–1) and whether the end
-- is near; nil when there is no cast.
function Logic.CastState(now, start, finish)
    if type(now) ~= "number" or type(start) ~= "number" or type(finish) ~= "number" or finish <= start then
        return nil
    end
    local remaining = math.max(0, finish - now)
    local share = math.min(1, remaining / (finish - start))
    return remaining, share, remaining <= Logic.WARN_SECONDS
end

-- Sound while fishing. current: { [cvar] = value } as read now. Returns the backup to keep (the player's values) and
-- the values to set. An existing backup is kept (a second cast must not save the boosted values as the player's).
function Logic.SoundPlan(current, backup)
    local keep = Logic.CleanBackup(backup)
    if not keep then
        keep = {}
        for _, cvar in ipairs(Logic.SOUND_CVARS) do
            if type(current[cvar]) == "string" then keep[cvar] = current[cvar] end
        end
    end
    return keep, Logic.SOUND_BOOST
end

-- Catch log (owner 2026-11-20: "what I have caught and how many"): catches[itemID] = { name, count }, kept forever.
function Logic.CleanCatches(catches)
    local clean = {}
    if type(catches) ~= "table" then return clean end
    for id, entry in pairs(catches) do
        if itemId(id) and type(entry) == "table" and type(entry.count) == "number" and entry.count > 0 then
            clean[id] = { name = type(entry.name) == "string" and entry.name or nil, count = math.floor(entry.count) }
        end
    end
    return clean
end

-- Adds one looted stack. quantity < 1 or a missing item ID adds nothing. Returns true when something was added.
function Logic.AddCatch(catches, id, name, quantity)
    if not itemId(id) then return false end
    quantity = type(quantity) == "number" and quantity >= 1 and math.floor(quantity) or 1
    local entry = catches[id] or { count = 0 }
    entry.count = entry.count + quantity
    if type(name) == "string" and name ~= "" then entry.name = name end
    catches[id] = entry
    return true
end

-- The log as a list, most caught first (then by name, then ID): { { id, name, count }, … }.
function Logic.CatchList(catches)
    local list = {}
    for id, entry in pairs(catches) do list[#list + 1] = { id = id, name = entry.name, count = entry.count } end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        if (a.name or "") ~= (b.name or "") then return (a.name or "") < (b.name or "") end
        return a.id < b.id
    end)
    return list
end

-- Item ID from an item link or "item:1234" string; nil otherwise.
function Logic.ItemIdFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

-- Minimap button position: angle in degrees (0 = right, 90 = top) on a circle of radius → x, y offsets.
Logic.MINIMAP_ANGLE = 45
function Logic.MinimapOffset(angle, radius)
    if type(angle) ~= "number" or angle ~= angle then angle = Logic.MINIMAP_ANGLE end
    local rad = math.rad(angle)
    return math.cos(rad) * radius, math.sin(rad) * radius
end

-- A dragged offset from the minimap centre, kept on a sane range (far enough for any screen; SetClampedToScreen
-- is not used for the button).
Logic.MAX_OFFSET = 2000
function Logic.ClampOffset(value)
    if type(value) ~= "number" or value ~= value then return 0 end
    return math.max(-Logic.MAX_OFFSET, math.min(Logic.MAX_OFFSET, value))
end

-- Where the minimap button sits: the dragged offset, else on the minimap edge at minimapAngle.
function Logic.MinimapPosition(db, radius)
    if type(db.minimapX) == "number" and type(db.minimapY) == "number" then return db.minimapX, db.minimapY end
    return Logic.MinimapOffset(db.minimapAngle, radius)
end

-- Angle in degrees (0–360, 0 = right, 90 = top) of a point dx, dy from the minimap centre; the default for no offset.
function Logic.AngleTo(dx, dy)
    if type(dx) ~= "number" or type(dy) ~= "number" or (dx == 0 and dy == 0) then return Logic.MINIMAP_ANGLE end
    local angle = math.deg(math.atan2(dy, dx))
    if angle < 0 then angle = angle + 360 end
    return angle
end

-- The bar shows while the pole is in the hand (owner 2026-11-20), in test mode, and never while the player hid it
-- with /pfish hide until the pole changes again.
function Logic.BarShown(mainIsPole, testMode, hiddenByPlayer)
    if testMode then return true end
    return mainIsPole == true and not hiddenByPlayer
end

-- Whether the sound boost should end now: lastCastEnd = when the last cast stopped (nil while one runs).
function Logic.SoundExpired(now, lastCastEnd)
    return type(lastCastEnd) == "number" and type(now) == "number" and now - lastCastEnd >= Logic.SOUND_HOLD
end
