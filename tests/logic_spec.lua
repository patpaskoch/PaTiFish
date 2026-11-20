-- PaTiFish rules: settings, lures, weapon swap, catches, cast timing, sound. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Logic.lua", {}).Logic
end

describe("Logic.Migrate", function()
    it("a new character gets the defaults, an empty catch log and the minimap button", function()
        local db = load().Migrate(nil)
        assert.same({ true, true, false, 1, 1, true }, { db.loudSplash, db.flashWarning, db.collapsed, db.scale,
            db.schema, db.minimapButton })
        assert.same({}, db.catches)
        assert.is_nil(db.soundBackup)
        assert.is_nil(db.weapons)
    end)

    it("keeps saved values (also false), the sound backup, weapons and catches; drops broken parts", function()
        local db = load().Migrate({ loudSplash = false, minimapButton = false,
            soundBackup = { Sound_SFXVolume = "0.4", junk = "x", Sound_MusicVolume = 3 },
            weapons = { main = 1234, off = "x" },
            catches = { [6303] = { name = "Raw Slitherskin Mackerel", count = 4 }, [7] = { count = -1 }, x = 5 } })
        assert.is_false(db.loudSplash)
        assert.is_false(db.minimapButton)
        assert.same({ Sound_SFXVolume = "0.4" }, db.soundBackup)
        assert.same({ main = 1234 }, db.weapons)
        assert.same({ [6303] = { name = "Raw Slitherskin Mackerel", count = 4 } }, db.catches)
    end)

    it("RestoreDefaults keeps the sound backup, weapons and catches", function()
        local Logic = load()
        local db = Logic.Migrate({ loudSplash = false, weapons = { main = 5 }, soundBackup = { Sound_SFXVolume = "1" } })
        Logic.AddCatch(db.catches, 6303, "Fish", 2)
        Logic.RestoreDefaults(db)
        assert.is_true(db.loudSplash)
        assert.same({ main = 5 }, db.weapons)
        assert.equal(2, db.catches[6303].count)
        assert.same({ Sound_SFXVolume = "1" }, db.soundBackup)
    end)
end)

describe("Lures", function()
    it("picks the best lure in the bags and builds its macro", function()
        local Logic = load()
        local bags = { [6529] = 3, [6530] = 1 }
        local lure = Logic.BestLure(function(id) return bags[id] or 0 end)
        assert.equal(6530, lure.item)
        assert.equal(50, lure.bonus)
        assert.equal("/use item:6530\n/use 16", Logic.LureMacro(lure))
        assert.is_nil(Logic.BestLure(function() return 0 end))
        assert.is_nil(Logic.LureMacro(nil))
    end)
end)

describe("Pole and weapons (owner 2026-11-20)", function()
    it("weapons in the hands, pole in the bags: equip the pole and remember the weapons", function()
        local Logic = load()
        local gear = { mainIsPole = false, main = 100, off = 200, bagPole = 6256 }
        assert.same({ "POLE", "/equip item:6256" }, { Logic.GearAction(gear) })
        assert.same({ main = 100, off = 200 }, Logic.WeaponsToSave(gear))
    end)

    it("pole in the hand: the saved weapons back, the off hand into its slot", function()
        local Logic = load()
        local gear = { mainIsPole = true, main = 6256, saved = { main = 100, off = 200 } }
        assert.same({ "WEAPONS", "/equip item:100\n/equipslot 17 item:200" }, { Logic.GearAction(gear) })
        gear.saved = { main = 300 }
        assert.same({ "WEAPONS", "/equip item:300" }, { Logic.GearAction(gear) })
        assert.is_nil(Logic.WeaponsToSave(gear)) -- never remember the pole as a weapon
    end)

    it("nothing to do: no pole anywhere, or pole on without saved weapons", function()
        local Logic = load()
        assert.is_nil(Logic.GearAction({ mainIsPole = false, main = 100 }))
        assert.is_nil(Logic.GearAction({ mainIsPole = true, main = 6256 }))
        assert.is_nil(Logic.WeaponsToSave({ mainIsPole = false })) -- empty hands: nothing to remember
    end)

    it("the bar follows the pole, test mode always shows it, /pfish hide wins until the pole changes", function()
        local Logic = load()
        assert.is_true(Logic.BarShown(true, false, false))
        assert.is_false(Logic.BarShown(false, false, false))
        assert.is_false(Logic.BarShown(true, false, true))
        assert.is_true(Logic.BarShown(false, true, true))
    end)
end)

describe("Catch log", function()
    it("adds stacks, keeps the name and lists most caught first", function()
        local Logic = load()
        local catches = {}
        assert.is_true(Logic.AddCatch(catches, 6303, "Mackerel", 1))
        Logic.AddCatch(catches, 6303, nil, 2)
        Logic.AddCatch(catches, 6291, "Raw Brilliant Smallfish", nil)
        assert.is_false(Logic.AddCatch(catches, nil, "x", 1))
        assert.same({ { id = 6303, name = "Mackerel", count = 3 }, { id = 6291, name = "Raw Brilliant Smallfish",
            count = 1 } }, Logic.CatchList(catches))
    end)

    it("reads the item ID from a link", function()
        local Logic = load()
        assert.equal(6303, Logic.ItemIdFromLink("|cffffffff|Hitem:6303::::::::5:::::::|h[Mackerel]|h|r"))
        assert.is_nil(Logic.ItemIdFromLink(nil))
        assert.is_nil(Logic.ItemIdFromLink("nothing"))
    end)
end)

describe("Skill, time and cast", function()
    it("finds the fishing skill by its localized name", function()
        local Logic = load()
        local entries = { { name = "Kochkunst", rank = 10, max = 75 }, { name = "Angeln", rank = 75, modifier = 25,
            max = 150 } }
        assert.same({ rank = 75, modifier = 25, max = 150 }, Logic.FindSkill(entries, "Angeln"))
        assert.is_nil(Logic.FindSkill(entries, "Fishing"))
    end)

    it("formats seconds", function()
        local Logic = load()
        assert.equal("8:05", Logic.FormatTime(485.7))
        assert.equal("0:00", Logic.FormatTime(0))
        assert.is_nil(Logic.FormatTime(-1))
        assert.is_nil(Logic.FormatTime(nil))
    end)

    it("cast state: remaining, share left and the warning in the last seconds", function()
        local Logic = load()
        assert.same({ 10, 0.5, false }, { Logic.CastState(110, 100, 120) })
        assert.same({ 2, 0.1, true }, { Logic.CastState(118, 100, 120) })
        assert.same({ 0, 0, true }, { Logic.CastState(125, 100, 120) })
        assert.is_nil(Logic.CastState(110, nil, 120))
    end)
end)

describe("Sound while fishing", function()
    it("saves the player's values once and boosts effects", function()
        local Logic = load()
        local current = { Sound_SFXVolume = "0.5", Sound_MusicVolume = "0.4", Sound_AmbienceVolume = "0.6" }
        local backup, values = Logic.SoundPlan(current, nil)
        assert.same(current, backup)
        assert.same({ Sound_SFXVolume = "1", Sound_MusicVolume = "0", Sound_AmbienceVolume = "0" }, values)
        -- second cast: the boosted values must not replace the player's
        local again = Logic.SoundPlan(values, backup)
        assert.same(current, again)
    end)

    it("restores after the hold time, never while a cast runs", function()
        local Logic = load()
        assert.is_false(Logic.SoundExpired(110, 100))
        assert.is_true(Logic.SoundExpired(115, 100))
        assert.is_false(Logic.SoundExpired(115, nil))
    end)

    it("minimap drag: angle from the cursor offset (owner 2026-11-20: move the button)", function()
        local Logic = load()
        assert.equal(0, Logic.AngleTo(10, 0))
        assert.equal(90, Logic.AngleTo(0, 10))
        assert.equal(180, Logic.AngleTo(-10, 0))
        assert.equal(270, Logic.AngleTo(0, -10))
        assert.equal(Logic.MINIMAP_ANGLE, Logic.AngleTo(0, 0))
    end)

    it("minimap button anywhere: the dragged offset wins, else the edge; broken saves are dropped", function()
        local Logic = load()
        assert.same({ 150, -40 }, { Logic.MinimapPosition({ minimapX = 150, minimapY = -40 }, 80) })
        local x, y = Logic.MinimapPosition({ minimapAngle = 90 }, 80)
        assert.is_true(math.abs(x) < 1e-9 and math.abs(y - 80) < 1e-9)
        assert.equal(2000, Logic.ClampOffset(99999))
        local db = Logic.Migrate({ minimapX = "x", minimapY = 3 })
        assert.is_nil(db.minimapX)
        assert.equal(-2000, Logic.Migrate({ minimapX = -5000, minimapY = 1 }).minimapX)
    end)

    it("minimap offset: angle on the circle", function()
        local Logic = load()
        local x, y = Logic.MinimapOffset(90, 80)
        assert.is_true(math.abs(x) < 1e-9 and math.abs(y - 80) < 1e-9)
        local dx, dy = Logic.MinimapOffset(nil, 80)
        assert.is_true(dx > 0 and dy > 0) -- default 45°
    end)
end)
