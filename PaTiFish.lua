-- PaTiFish: a simple fishing helper (owner 2026-11-20). Cast, lure and pole/weapons are secure buttons: one click =
-- one action, nothing happens by itself. WoW sends no event when a fish bites; the louder splash (sound settings while
-- fishing) and the flashing frame near the end of a cast help, catching stays the player's click or Interact key.
local addonName, ns = ...
local UI, L, Logic, Catches = ns.UI, ns.UI.L, ns.Logic, ns.Catches

local DB
local testMode = false
local G = _G

local function say(key, ...)
    print("|cff68caffPaTiFish:|r " .. L[key]:format(...))
end

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end

local function addonVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(addonName, "Version") or "?"
end

-- API adapters ---------------------------------------------------------------------------------------------------

local function spellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
    return nil
end

local function fishingName()
    local name = spellName(Logic.FISHING_SPELL)
    if isSecret(name) or type(name) ~= "string" then return nil end
    return name
end

local function readSkill()
    if not GetNumSkillLines or not GetSkillLineInfo then return nil end
    local entries = {}
    for index = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, modifier, max = GetSkillLineInfo(index)
        if not isHeader and not isSecret(name) then
            entries[#entries + 1] = { name = name, rank = rank, modifier = modifier, max = max }
        end
    end
    return Logic.FindSkill(entries, fishingName())
end

-- A fishing pole: one of the known poles, or item class Weapon / subclass Fishing Pole (owner 2026-11-20: a pole in
-- the bags was not found — the class check alone is not trusted in this client).
-- The client's name for the item subclass "Fishing Pole" (e.g. "Angelruten"), if it can tell.
local function poleSubclassName()
    local info = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo
    local name = info and info(Logic.POLE_CLASS, Logic.POLE_SUBCLASS)
    return type(name) == "string" and not isSecret(name) and name or nil
end

local function isPole(itemID)
    if type(itemID) ~= "number" then return false end
    if Logic.KNOWN_POLES[itemID] then return true end
    if not GetItemInfoInstant then return false end
    local _, _, subType, _, _, classID, subclassID = GetItemInfoInstant(itemID)
    if classID == Logic.POLE_CLASS and subclassID == Logic.POLE_SUBCLASS then return true end
    local poleName = poleSubclassName()
    return poleName ~= nil and subType == poleName
end

-- /pfish debug: what the client says about an item (to see why a pole is or is not recognised).
local function itemFacts(itemID)
    if type(itemID) ~= "number" or not GetItemInfoInstant then return tostring(itemID) end
    local _, itemType, subType, equipLoc, _, classID, subclassID = GetItemInfoInstant(itemID)
    return ("%d (%s/%s, class %s/%s, %s)"):format(itemID, tostring(itemType), tostring(subType), tostring(classID),
        tostring(subclassID), tostring(equipLoc))
end

local function bagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
    return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function bagItem(bag, slot)
    if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
    return GetContainerItemID and GetContainerItemID(bag, slot) or nil
end

local BAGS = 4 -- backpack 0 plus four bags
local function firstBagPole()
    for bag = 0, BAGS do
        for slot = 1, bagSlots(bag) do
            local id = bagItem(bag, slot)
            if isPole(id) then return id end
        end
    end
    return nil
end

local function readGear()
    local main = GetInventoryItemID("player", Logic.MAIN_HAND)
    local off = GetInventoryItemID("player", Logic.OFF_HAND)
    return { main = main, off = off, mainIsPole = isPole(main), bagPole = firstBagPole(),
        saved = DB and DB.weapons }
end

local function countOf(itemID) return GetItemCount and GetItemCount(itemID) or 0 end

-- The lure on the pole: seconds left, or nil (none / no pole in the hand).
local function lureLeft(gear)
    if not gear.mainIsPole or not GetWeaponEnchantInfo then return nil end
    local hasMain, expiration = GetWeaponEnchantInfo()
    if hasMain and type(expiration) == "number" then return expiration / 1000 end
    return nil
end

local function interactKey()
    local key = GetBindingKey and GetBindingKey("INTERACTTARGET")
    if type(key) ~= "string" then return nil end
    return GetBindingText and GetBindingText(key) or key
end

local SOFT_INTERACT = "SoftTargetInteract"
local function softInteractOn()
    local value = GetCVar and GetCVar(SOFT_INTERACT)
    return value ~= nil and value ~= "0"
end

-- Window ---------------------------------------------------------------------------------------------------------

local WIDTH, PAD, GAP, LINE = 230, UI.Spacing.MD, UI.Spacing.SM, 16
local BAR = 8
local THIRD = (WIDTH - 2 * PAD - 2 * GAP) / 3
local window = UI.CreateWindow("PaTiFishFrame", "PaTiFish", WIDTH, 120)
local content = CreateFrame("Frame", nil, window)
content:SetPoint("TOPLEFT", 0, -UI.Sizes.HeaderHeight)
content:SetPoint("BOTTOMRIGHT")

local function textLine(top, font)
    local text = content:CreateFontString(nil, "OVERLAY", font or UI.Fonts.Text)
    text:SetPoint("TOPLEFT", PAD, -top)
    text:SetWidth(WIDTH - 2 * PAD)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    return text
end

local top = GAP
local skillText = textLine(top); top = top + LINE
local lureText = textLine(top); top = top + LINE + GAP

-- The running cast: a bar that empties and the seconds left on it.
local castBar = CreateFrame("StatusBar", nil, content)
castBar:SetPoint("TOPLEFT", PAD, -top)
castBar:SetSize(WIDTH - 2 * PAD, BAR)
castBar:SetStatusBarTexture(UI.WHITE)
castBar:SetMinMaxValues(0, 1)
UI.Paint(castBar, "SetStatusBarColor", "Accent")
local castBack = castBar:CreateTexture(nil, "BACKGROUND")
castBack:SetAllPoints()
UI.Paint(castBack, "SetColorTexture", "Panel")
top = top + BAR + GAP

-- Secure buttons: attributes only out of combat (applyButtons). PaTiLead is the pattern.
local function secureButton(name, labelKey, width)
    local button = CreateFrame("Button", name, content, "SecureActionButtonTemplate,BackdropTemplate")
    UI.StyleButton(button, labelKey, width)
    button:RegisterForClicks("AnyUp", "AnyDown") -- down or up, whichever ActionButtonUseKeyDown says
    return button
end

local cast = secureButton("PaTiFishCast", "CAST", WIDTH - 2 * PAD)
cast:SetPoint("TOPLEFT", PAD, -top)
cast:SetAttribute("type", "spell")
top = top + UI.Sizes.ButtonHeight + GAP

local lure = secureButton("PaTiFishLure", "APPLY_LURE", THIRD)
lure:SetPoint("TOPLEFT", PAD, -top)
lure:SetAttribute("type", "macro")
local catchesButton = UI.CreateButton(content, "CATCHES", THIRD, function() Catches.Toggle(testMode) end)
catchesButton:SetPoint("TOPLEFT", PAD + THIRD + GAP, -top)
local gear = secureButton("PaTiFishGear", "EQUIP_WEAPONS", THIRD)
gear:SetPoint("TOPLEFT", PAD + 2 * (THIRD + GAP), -top)
gear:SetAttribute("type", "macro")
top = top + UI.Sizes.ButtonHeight + GAP

-- Minimap button (owner 2026-11-20): one click puts the pole on, the next one the weapons from before back on.
-- Secure (the same macro as the gear button); placed by DB.minimapX/Y (dragged anywhere), first on the minimap edge.
local MINIMAP_SIZE, MINIMAP_ICON, MINIMAP_BORDER, MINIMAP_RADIUS = 31, 20, 53, 80
local minimapButton = CreateFrame("Button", "PaTiFishMinimap", Minimap, "SecureActionButtonTemplate")
minimapButton:SetSize(MINIMAP_SIZE, MINIMAP_SIZE)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
-- Left click: pole on / weapons back. Right button or Shift + left button held: drag the button along the minimap
-- edge (owner 2026-11-20). Shift + left click does nothing ("shift-type1" empty), so a drag never swaps gear.
minimapButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
minimapButton:SetAttribute("type", "macro")
minimapButton:SetAttribute("shift-type1", "")
minimapButton:RegisterForDrag("LeftButton", "RightButton")
minimapButton:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(MINIMAP_ICON, MINIMAP_ICON)
minimapIcon:SetPoint("CENTER")
minimapIcon:SetTexture([[Interface\Icons\Trade_Fishing]])
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(MINIMAP_BORDER, MINIMAP_BORDER)
minimapBorder:SetPoint("TOPLEFT")
minimapBorder:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])

local hint = textLine(top, UI.Fonts.Muted)
local HINT_LINES = 2
local CONTENT_HEIGHT = top + HINT_LINES * LINE

-- Flashing frame near the end of a cast (owner 2026-11-20): four warning-coloured edges over the window border.
local EDGE = 2
local flash = CreateFrame("Frame", nil, window)
flash:SetAllPoints()
flash:SetFrameLevel(window:GetFrameLevel() + 20)
flash.edges = {}
for _, spec in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
    { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false } }) do
    local edge = flash:CreateTexture(nil, "OVERLAY")
    edge:SetPoint(spec[1])
    edge:SetPoint(spec[2])
    if spec[3] then edge:SetHeight(EDGE) else edge:SetWidth(EDGE) end
    UI.Paint(edge, "SetColorTexture", "Warning")
    flash.edges[#flash.edges + 1] = edge
end
flash:Hide()

-- State ----------------------------------------------------------------------------------------------------------

local castStart, castEnd   -- seconds (GetTime) of the running cast, nil when none
local lastCastEnd          -- when the last cast stopped (sound restore timer)
local pendingButtons = false
local hiddenByPlayer = false -- /pfish hide: the bar stays hidden until the pole changes
local lastPole              -- mainIsPole of the last applyButtons
local gearMode             -- "POLE" | "WEAPONS" | nil (what the gear button does now)
local bestLure

local TEST = { skill = { rank = 75, modifier = 25, max = 150 }, lure = 510, castShare = 0.6, castLeft = 12 }

-- Secure attributes: spell, lure macro, gear macro. Out of combat only; in combat they wait for the end.
local function applyButtons()
    if InCombatLockdown() then pendingButtons = true return end
    pendingButtons = false
    local name = fishingName()
    cast:SetAttribute("spell", name)
    cast:SetEnabled(name ~= nil)
    bestLure = Logic.BestLure(countOf)
    lure:SetAttribute("macrotext", Logic.LureMacro(bestLure))
    lure:SetEnabled(bestLure ~= nil)
    local current = readGear()
    local mode, macro = Logic.GearAction(current)
    gearMode = mode
    gear:SetAttribute("macrotext", mode == "WEAPONS" and macro or nil) -- the bar only shows with the pole on
    gear:SetEnabled(mode == "WEAPONS")
    minimapButton:SetAttribute("macrotext", macro)
    minimapButton:SetShown(DB.minimapButton)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", Logic.MinimapPosition(DB, MINIMAP_RADIUS))
    -- The bar follows the pole: shown with it, hidden without it (a /pfish hide lasts until the pole changes).
    if current.mainIsPole ~= lastPole then hiddenByPlayer, lastPole = false, current.mainIsPole end
    window:SetShown(Logic.BarShown(current.mainIsPole, testMode, hiddenByPlayer))
    if not window:IsShown() then Catches.Hide() end
end

-- Just before the pole goes on: remember the weapons in the hands (PreClick runs before the secure action).
local function rememberWeapons()
    if gearMode ~= "POLE" or not DB then return end
    local saved = Logic.WeaponsToSave(readGear())
    if saved then DB.weapons = saved end
end
gear:SetScript("PreClick", rememberWeapons)
minimapButton:SetScript("PreClick", rememberWeapons)

local function paintTexts()
    if not DB then return end
    local current = readGear()
    local skill = testMode and TEST.skill or readSkill()
    if skill then
        local text = L.SKILL:format(skill.rank, skill.max)
        if skill.modifier > 0 then text = text .. L.SKILL_BONUS:format(skill.modifier) end
        skillText:SetText(text)
    else
        skillText:SetText(L.NO_SKILL)
    end
    local left = testMode and TEST.lure or lureLeft(current)
    if left then
        lureText:SetText(L.LURE_ACTIVE:format(Logic.FormatTime(left)))
        lureText:SetTextColor(UI.Color("Text"))
    else
        lureText:SetText((current.mainIsPole or testMode) and L.LURE_NONE or L.NO_POLE)
        lureText:SetTextColor(UI.Color("TextMuted"))
    end
    local key = interactKey()
    if not key then hint:SetText(L.REEL_NO_KEY)
    elseif not softInteractOn() then hint:SetText(L.REEL_SOFT_OFF:format(key))
    else hint:SetText(L.REEL_KEY:format(key)) end
end

local function paintCast(now)
    local remaining, share, warn
    if testMode then
        remaining, share, warn = TEST.castLeft, TEST.castShare, true
    else
        remaining, share, warn = Logic.CastState(now, castStart, castEnd)
    end
    castBar:SetValue(share or 0)
    castBar:SetStatusBarColor(UI.Color(warn and "Warning" or "Accent"))
    local flashing = warn and DB and DB.flashWarning and not DB.collapsed
    flash:SetShown(flashing == true)
    if flashing then
        local alpha = 0.35 + 0.65 * math.abs(math.sin(now * 6))
        for _, edge in ipairs(flash.edges) do edge:SetAlpha(alpha) end
    end
    return remaining ~= nil
end

local function refresh()
    if not DB then return end
    window:ApplyOpacity()
    Catches.Refresh(testMode)
    content:SetShown(not DB.collapsed)
    window:SetHeight(UI.Sizes.HeaderHeight + (DB.collapsed and 0 or CONTENT_HEIGHT + PAD))
    applyButtons()
    paintTexts()
    paintCast(GetTime())
end

-- Sound ------------------------------------------------------------------------------------------------------------

local function readSound()
    local current = {}
    for _, cvar in ipairs(Logic.SOUND_CVARS) do current[cvar] = GetCVar(cvar) end
    return current
end

local function boostSound()
    if not DB.loudSplash then return end
    local backup, values = Logic.SoundPlan(readSound(), DB.soundBackup)
    DB.soundBackup = backup -- saved first: a /reload while fishing still gets the volumes back on login
    for cvar, value in pairs(values) do SetCVar(cvar, value) end
end

local function restoreSound()
    local backup = DB and Logic.CleanBackup(DB.soundBackup)
    if not backup then return end
    for cvar, value in pairs(backup) do SetCVar(cvar, value) end
    DB.soundBackup = nil
end

-- Bite diagnosis (owner 2026-11-20): while on, every event during one cast is recorded and printed when it ends, to
-- find out whether this client sends anything when a fish bites. Off again after one cast.
local diagnose = { on = false, seen = {}, order = {} }
local spy = CreateFrame("Frame")
spy:SetScript("OnEvent", function(_, event)
    if diagnose.seen[event] then return end
    diagnose.seen[event] = GetTime() - (castStart or GetTime())
    diagnose.order[#diagnose.order + 1] = event
end)

local function startDiagnosis()
    diagnose.seen, diagnose.order = {}, {}
    if spy.RegisterAllEvents then spy:RegisterAllEvents() end
end

local DIAGNOSE_MAX = 40
local function finishDiagnosis()
    if spy.UnregisterAllEvents then spy:UnregisterAllEvents() end
    diagnose.on = false
    say("DIAGNOSE_RESULT", #diagnose.order)
    for index, event in ipairs(diagnose.order) do
        if index > DIAGNOSE_MAX then break end
        print(("  %.1f s  %s"):format(diagnose.seen[event], event))
    end
end

-- Ticker: cast bar and flash every frame while casting; lure time and sound restore once a second.
local ticker = CreateFrame("Frame")
local sinceSecond = 0
local SECOND = 1
ticker:SetScript("OnUpdate", function(_, elapsed)
    if not DB then return end
    local now = GetTime()
    if castStart or testMode then paintCast(now) end
    sinceSecond = sinceSecond + elapsed
    if sinceSecond < SECOND then return end
    sinceSecond = 0
    paintTexts()
    if not castStart and Logic.SoundExpired(now, lastCastEnd) then
        restoreSound()
        lastCastEnd = nil
    end
end)

local function isFishing(spellID) return Logic.FISHING_SPELLS[spellID] == true end

local function castStarted(spellID)
    if not isFishing(spellID) then return end
    local _, _, _, startMs, endMs = UnitChannelInfo("player")
    if type(startMs) ~= "number" or type(endMs) ~= "number" then return end
    castStart, castEnd, lastCastEnd = startMs / 1000, endMs / 1000, nil
    boostSound()
    if diagnose.on then startDiagnosis() end
end

local function castStopped(spellID)
    if not isFishing(spellID) or not castStart then return end
    castStart, castEnd, lastCastEnd = nil, nil, GetTime()
    flash:Hide()
    paintCast(GetTime())
    if diagnose.on then finishDiagnosis() end
end

-- Settings -------------------------------------------------------------------------------------------------------

local modal

local function buildSettings()
    modal = UI.CreateModal("PaTiFishSettings", function() return "PaTiFish " .. L.SETTINGS end, 380)
    local scales = {}
    for _, scale in ipairs(Logic.SCALES) do
        scales[#scales + 1] = { value = scale, text = function() return ("%d %%"):format(scale * 100 + 0.5) end }
    end
    modal:AddSection("GENERAL")
    modal:AddRow("LANGUAGE", UI.CreateLanguageDropdown(modal, DB, 170))
    modal:AddRow("SCALE", UI.CreateDropdown(modal, 170, {
        items = function() return scales end,
        get = function() return DB.scale end,
        set = function(scale)
            if InCombatLockdown() then say("COMBAT_LOCKED") return end -- secure children
            DB.scale = scale; window:SetScale(scale)
        end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "LOCK_WINDOW", {
        get = function() return window:IsLocked() end,
        set = function(locked) window:SetLocked(locked) end,
    }))
    UI.AddWindowSettings(modal, window)
    modal:AddSection("FISHING")
    modal:AddControls(UI.CreateCheckbox(modal, "LOUD_SPLASH", {
        get = function() return DB.loudSplash end,
        set = function(on) DB.loudSplash = on; if not on then restoreSound() end end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "MINIMAP_BUTTON", {
        get = function() return DB.minimapButton end,
        set = function(on)
            if InCombatLockdown() then say("COMBAT_LOCKED") return end
            DB.minimapButton = on; refresh()
        end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "FLASH_WARNING", {
        get = function() return DB.flashWarning end,
        set = function(on) DB.flashWarning = on; refresh() end,
    }))
    -- WoW's own setting, changed only by this click: the Interact key then finds the bobber without aiming.
    modal:AddControls(UI.CreateCheckbox(modal, "SOFT_INTERACT", {
        get = function() return softInteractOn() end,
        set = function(on) SetCVar(SOFT_INTERACT, on and "3" or "0"); paintTexts() end,
    }))
    modal:Finish(function()
        if InCombatLockdown() then say("COMBAT_LOCKED") return end
        Logic.RestoreDefaults(DB)
        restoreSound()
        window:ApplyTheme()
        window:ApplyOpacity()
        UI.SetLanguage(DB.language)
        window:SetLocked(DB.locked)
        window:SetScale(DB.scale)
        refresh()
    end)
end

local function openSettings()
    if not modal then buildSettings() end
    modal:Show()
end

-- Commands -------------------------------------------------------------------------------------------------------

-- The window holds secure buttons: showing, hiding and collapsing wait for the end of combat.
local function toggleCollapsed()
    if InCombatLockdown() then say("COMBAT_LOCKED") return end
    DB.collapsed = not DB.collapsed
    refresh()
end

local function setShown(shown, quiet)
    if InCombatLockdown() then if not quiet then say("COMBAT_LOCKED") end return false end
    if shown and not testMode and not readGear().mainIsPole then
        if not quiet then say("NO_POLE_HINT") end
        return false
    end
    hiddenByPlayer = not shown
    window:SetShown(shown)
    if not shown then Catches.Hide() end
    if not shown and not quiet then say("HIDDEN_HINT") end
    return true
end
window.suiteSetShown = function(shown) return setShown(shown, true) end

local function toggleTestMode()
    if InCombatLockdown() then say("COMBAT_LOCKED") return end
    testMode = not testMode
    window:SetTestMode(testMode)
    refresh()
end

local function resetPosition()
    if InCombatLockdown() then say("COMBAT_LOCKED") return end
    DB.point, DB.relativePoint, DB.x, DB.y = nil, nil, nil, nil
    window:Attach(DB, 0, -250)
end

local function printDebug()
    local version, build, _, interface = GetBuildInfo()
    local current = readGear()
    local skill = readSkill()
    print("|cff68caffPaTiFish Debug:|r")
    for _, line in ipairs({
        ("Addon %s %s · PaTiShared UI %s"):format(addonName, addonVersion(), tostring(UI.VERSION)),
        ("WoW %s (build %s, interface %s) · locale %s"):format(tostring(version), tostring(build), tostring(interface),
            GetLocale()),
        ("Fishing spell %s · skill %s"):format(tostring(fishingName()),
            skill and ("%d+%d/%d"):format(skill.rank, skill.modifier, skill.max) or "none"),
        ("Main hand %s · pole subclass name %s"):format(itemFacts(current.main), tostring(poleSubclassName())),
        ("Main hand %s (pole %s) · off hand %s · pole in bags %s · saved weapons %s"):format(tostring(current.main),
            tostring(current.mainIsPole), tostring(current.off), tostring(current.bagPole),
            DB.weapons and ("%s/%s"):format(tostring(DB.weapons.main), tostring(DB.weapons.off)) or "none"),
        ("Lure: best in bags %s · on the pole %s s"):format(bestLure and tostring(bestLure.item) or "none",
            tostring(lureLeft(current))),
        ("Interact key %s · %s %s · sound backup %s · combat %s"):format(tostring(interactKey()), SOFT_INTERACT,
            tostring(GetCVar(SOFT_INTERACT)), DB.soundBackup and "yes" or "no", InCombatLockdown() and "yes" or "no"),
        ("APIs: GetSkillLineInfo %s · GetWeaponEnchantInfo %s · GetItemInfoInstant %s · RegisterAllEvents %s"):format(
            GetSkillLineInfo and "yes" or "no", GetWeaponEnchantInfo and "yes" or "no",
            GetItemInfoInstant and "yes" or "no", spy.RegisterAllEvents and "yes" or "no"),
    }) do print("  " .. line) end
end

local function startDiagnoseCommand()
    diagnose.on = true
    say("DIAGNOSE_ON")
end

local COMMANDS = {
    [""] = function() setShown(not window:IsShown()) end,
    show = function() setShown(true) end,
    hide = function() setShown(false) end,
    lock = function() window:SetLocked(true) end,
    unlock = function() window:SetLocked(false) end,
    reset = resetPosition,
    settings = openSettings,
    test = toggleTestMode,
    debug = printDebug,
    diagnose = startDiagnoseCommand,
    version = function() say("VERSION", addonVersion()) end,
}

SLASH_PATIFISH1 = "/patifish"
SLASH_PATIFISH2 = "/pfish"
SlashCmdList.PATIFISH = function(message)
    local command = COMMANDS[(message or ""):match("^%s*(.-)%s*$"):lower()]
    if command and DB then command() else say("HELP") end
end

-- Key bindings (Bindings.xml): the player may bind the buttons; PaTiFish never binds a key itself.
G.BINDING_HEADER_PATIFISH = "PaTiFish"
G["BINDING_NAME_CLICK PaTiFishCast:LeftButton"] = L.CAST
G["BINDING_NAME_CLICK PaTiFishLure:LeftButton"] = L.APPLY_LURE
G["BINDING_NAME_CLICK PaTiFishMinimap:LeftButton"] = L.BIND_GEAR

window:SetMenu(function()
    if not DB then return {} end
    return {
        { text = "SETTINGS", onClick = openSettings },
        { text = window:IsLocked() and "UNLOCK" or "LOCK",
            onClick = function() window:SetLocked(not window:IsLocked()) end },
        { text = DB.collapsed and "EXPAND" or "COLLAPSE", onClick = toggleCollapsed },
        { text = "TEST_MODE", checked = testMode, onClick = toggleTestMode },
        { text = "HIDE", onClick = function() setShown(false) end },
    }
end)

UI.SetTooltip(cast, function() return { L.CAST, L.CAST_TIP } end)
UI.SetTooltip(lure, function()
    if not bestLure then return { L.APPLY_LURE, L.APPLY_LURE_NONE } end
    return { L.APPLY_LURE, L.APPLY_LURE_TIP:format(bestLure.bonus) }
end)
local function gearTooltip()
    if not InCombatLockdown() then applyButtons() end -- the bags may have changed since the last event
    if gearMode == "WEAPONS" then return { L.EQUIP_WEAPONS, L.EQUIP_WEAPONS_TIP } end
    if gearMode == "POLE" then return { L.EQUIP_POLE, L.EQUIP_POLE_TIP } end
    if readGear().mainIsPole then return { L.EQUIP_WEAPONS, L.NO_WEAPONS_TIP } end
    return { L.EQUIP_POLE, L.GEAR_NONE_TIP }
end
UI.SetTooltip(gear, gearTooltip)
UI.SetTooltip(minimapButton, function()
    local lines = gearTooltip()
    lines[1] = "PaTiFish: " .. lines[1]
    lines[#lines + 1] = L.MINIMAP_DRAG_TIP
    return lines
end)

-- Dragging (right button): the angle follows the cursor; out of combat only (a secure button cannot move in combat).
local function placeMinimapButton()
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", Logic.MinimapPosition(DB, MINIMAP_RADIUS))
end
minimapButton:SetScript("OnDragStart", function(self, button)
    if InCombatLockdown() or not DB then return end
    if button == "LeftButton" and not IsShiftKeyDown() then return end
    GameTooltip:Hide()
    self:SetScript("OnUpdate", function()
        if InCombatLockdown() then self:SetScript("OnUpdate", nil) return end
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local mx, my = Minimap:GetCenter()
        DB.minimapX, DB.minimapY = Logic.ClampOffset(x / scale - mx), Logic.ClampOffset(y / scale - my)
        placeMinimapButton()
    end)
end)
minimapButton:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
UI.SetTooltip(catchesButton, function() return { L.CATCHES, L.CATCHES_TIP } end)

-- Events ---------------------------------------------------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "BAG_UPDATE_DELAYED",
    "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED",
    "UNIT_INVENTORY_CHANGED", "PLAYER_REGEN_ENABLED", "UPDATE_BINDINGS", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP" }) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "PLAYER_LOGIN" then
        PaTiFishDB = Logic.Migrate(PaTiFishDB)
        DB = PaTiFishDB
        restoreSound() -- the last session ended while the sound was boosted
        UI.SetLanguage(DB.language)
        window:Attach(DB, 0, -250) -- first start: bottom centre (owner 2026-11-20)
        window:SetScale(DB.scale)
        Catches.Init(window, function() return DB end)
        refresh()
        return
    end
    if not DB then return end
    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit == "player" then castStarted(spellID) end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if unit == "player" then castStopped(spellID) end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if unit == "player" then refresh() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingButtons then refresh() end
    else
        refresh()
    end
end)
UI.OnLanguageChanged(refresh)
UI.OnThemeChanged(refresh)
