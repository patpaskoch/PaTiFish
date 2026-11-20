-- PaTiFish catch log (owner 2026-11-20): everything fished so far with its count, in a small list left of the bar.
-- Counted when a fishing loot slot is really taken (LOOT_SLOT_CLEARED), so a full bag does not count.
local _, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic
local Catches = {}
ns.Catches = Catches

local WIDTH, PAD, LINE, ICON = 210, UI.Spacing.MD, 18, 16
local MAX_ROWS = 15
local getDB -- function → PaTiFishDB (set by Init)

-- Its own window, but no own position or settings: it hangs left of the bar and reads the bar's look (theme,
-- opacity) from PaTiFishDB; locked, so its header never drags it away.
local window = UI.CreateWindow("PaTiFishCatches", "CATCHES", WIDTH, 80)
window:Hide()
local rows = {}

local function row(index)
    if rows[index] then return rows[index] end
    local line = CreateFrame("Frame", nil, window)
    line:SetSize(WIDTH - 2 * PAD, LINE)
    line:SetPoint("TOPLEFT", PAD, -(UI.Sizes.HeaderHeight + UI.Spacing.SM + (index - 1) * LINE))
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(ICON, ICON)
    line.icon:SetPoint("LEFT")
    line.count = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    line.count:SetPoint("RIGHT")
    line.name = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    line.name:SetPoint("LEFT", line.icon, "RIGHT", UI.Spacing.SM, 0)
    line.name:SetPoint("RIGHT", line.count, "LEFT", -UI.Spacing.SM, 0)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    rows[index] = line
    return line
end

local function itemIcon(id)
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
    return GetItemIcon and GetItemIcon(id) or nil
end

local function itemName(id, saved)
    local name = GetItemInfo and GetItemInfo(id)
    return type(name) == "string" and name or saved or ("item:" .. id)
end

local TEST = { [6303] = { name = nil, count = 23 }, [6291] = { name = nil, count = 14 }, [6358] = { count = 3 } }

function Catches.Refresh(testMode)
    local db = getDB and getDB()
    if not db or not window:IsShown() then return end
    local list = Logic.CatchList(testMode and TEST or db.catches)
    local shown = math.min(#list, MAX_ROWS)
    for index = 1, shown do
        local line, entry = row(index), list[index]
        line.icon:SetTexture(itemIcon(entry.id))
        line.name:SetText(itemName(entry.id, entry.name))
        line.count:SetText(tostring(entry.count))
        line:Show()
    end
    local extra = 0
    if #list == 0 then
        local line = row(1)
        line.icon:SetTexture(nil)
        line.name:SetText(L.NO_CATCHES)
        line.count:SetText("")
        line:Show()
        shown = 1
    elseif #list > MAX_ROWS then
        local line = row(MAX_ROWS + 1)
        line.icon:SetTexture(nil)
        line.name:SetText(L.MORE_CATCHES:format(#list - MAX_ROWS))
        line.count:SetText("")
        line:Show()
        extra = 1
    end
    for index = shown + extra + 1, #rows do rows[index]:Hide() end
    window:SetHeight(UI.Sizes.HeaderHeight + 2 * UI.Spacing.SM + (shown + extra) * LINE)
end

function Catches.Toggle(testMode)
    window:SetShown(not window:IsShown())
    Catches.Refresh(testMode)
end

function Catches.Hide() window:Hide() end

-- bar: the main window; db: function returning PaTiFishDB. Called on PLAYER_LOGIN.
function Catches.Init(bar, db)
    getDB = db
    window.db = setmetatable({ locked = true }, { __index = function(_, key) return getDB()[key] end })
    window:ClearAllPoints()
    window:SetPoint("TOPRIGHT", bar, "TOPLEFT", -UI.Spacing.SM, 0)
    window:ApplyTheme()
    window:ApplyOpacity()
    window:SetMenu(function() return { { text = "CLOSE", onClick = function() window:Hide() end } } end)
end

-- Loot ------------------------------------------------------------------------------------------------------------

local pending = {} -- loot slot → { id, name, quantity } of the open fishing loot

local function fishingLoot() return IsFishingLoot ~= nil and IsFishingLoot() == true end

local events = CreateFrame("Frame")
for _, event in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, slot)
    if event == "LOOT_OPENED" then
        pending = {}
        if not fishingLoot() or not GetNumLootItems then return end
        for index = 1, GetNumLootItems() do
            local _, name, quantity = GetLootSlotInfo(index)
            local id = Logic.ItemIdFromLink(GetLootSlotLink and GetLootSlotLink(index))
            if id then pending[index] = { id = id, name = name, quantity = quantity } end
        end
    elseif event == "LOOT_SLOT_CLEARED" then
        local entry = pending[slot]
        local db = getDB and getDB()
        if not entry or not db then return end
        pending[slot] = nil
        if Logic.AddCatch(db.catches, entry.id, entry.name, entry.quantity) then Catches.Refresh(false) end
    else
        pending = {}
    end
end)
