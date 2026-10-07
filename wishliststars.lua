local _, AC = ...
local Stars = {buttons = setmetatable({}, {__mode = "k"}), discover = true, size = 16, cornerOffset = 4, accessMethods = {"IsForbidden", "HasAnyForbiddenAspects", "CanBeAccessedInContext"}, iconKeys = {"icon", "Icon", "IconTexture"}}
AC.WishlistStars = Stars

function Stars:CanAccess(object)
    if not object then return false end
    for _, method in ipairs(self.accessMethods) do
        if type(object[method]) == "function" then
            local ok, value = pcall(object[method], object)
            if not ok or (issecretvalue and issecretvalue(value)) then return false end
            if method == "CanBeAccessedInContext" then
                if not value then return false end
            elseif value then
                return false
            end
        end
    end
    return true
end

function Stars:ItemID(value)
    if type(value) == "number" then return value end
    if type(value) == "string" then return tonumber(string.match(value, "item:(%d+)")) end
end

function Stars:RegisterBaganator()
    local api = Baganator and Baganator.API
    if self.baganatorRegistered or not api or type(api.RegisterCornerWidget) ~= "function" then return end
    api.RegisterCornerWidget("AzerothCompendium: " .. AC:Trans("LID_WISHLIST"), "azerothcompendium_wishlist", function(star, details)
        local itemID
        if type(details) == "table" then itemID = Stars:ItemID(details.itemID or details.itemLink) end
        local texture = itemID and AC:GetWishlistTexture(itemID)
        star:SetTexture(texture)
        return texture ~= nil
    end, function(button)
        local star = button:CreateTexture(nil, "OVERLAY", nil, 7)
        star:SetSize(Stars.size, Stars.size)
        star.padding = -Stars.cornerOffset / 2
        return star
    end, {corner = "top_right", priority = 1}, true)
    self.baganatorRegistered = true
end

function Stars:RefreshBaganator()
    local api = Baganator and Baganator.API
    if self.baganatorRegistered and api and type(api.RequestItemButtonsRefresh) == "function" then
        api.RequestItemButtonsRefresh()
    end
end
function Stars:Resolve(button)
    local name = button:GetName() or ""
    if type(name) ~= "string" then name = "" end
    local parent = button:GetParent()
    if parent and not self:CanAccess(parent) then return end
    local parentName = self:CanAccess(parent) and type(parent.GetName) == "function" and parent:GetName() or ""
    if type(parentName) ~= "string" then parentName = "" end
    if string.match(name, "^GroupLootFrame%d+Item$") or string.match(parentName, "^GroupLootFrame%d+$") then
        return parent and GetLootRollItemLink and parent.rollID and self:ItemID(GetLootRollItemLink(parent.rollID))
    end
    if string.match(name, "^Character.+Slot$") then return self:ItemID(GetInventoryItemLink("player", button:GetID())) end
    if string.match(name, "^EquipmentFlyoutFrameButton%d+$") then
        local location = button.location
        if type(location) ~= "number" or not EquipmentManager_GetItemInfoByLocation then return nil end
        if EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION and location >= EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION then return nil end
        local itemID = EquipmentManager_GetItemInfoByLocation(location)
        return type(itemID) == "number" and itemID or nil
    end
    if string.match(name, "^Inspect.+Slot$") then return self:ItemID(GetInventoryItemLink("target", button:GetID())) end
    if string.match(name, "^BankFrameItem%d+$") and BankButtonIDToInvSlotID then
        return self:ItemID(GetInventoryItemLink("player", BankButtonIDToInvSlotID(button:GetID())))
    end
    if string.match(name, "^LootButton%d+$") then return self:ItemID(GetLootSlotLink(button.slot or button:GetID())) end
    local index = tonumber(string.match(name, "^MerchantItem(%d+)ItemButton$"))
    if index then return self:ItemID(GetMerchantItemLink(index)) end
    index = tonumber(string.match(name, "^MerchantBuyBackItem(%d+)ItemButton$"))
    if index then return self:ItemID(GetBuybackItemLink(index)) end
    index = tonumber(string.match(name, "^TradePlayerItem(%d+)ItemButton$"))
    if index then return self:ItemID(GetTradePlayerItemLink(index)) end
    index = tonumber(string.match(name, "^TradeRecipientItem(%d+)ItemButton$"))
    if index then return self:ItemID(GetTradeTargetItemLink(index)) end
    if string.match(name, "^QuestInfoItem%d+$") and button.type and GetQuestItemLink then
        return self:ItemID(GetQuestItemLink(button.type, button:GetID()))
    end
    if type(button.BGR) == "table" then return self:ItemID(button.BGR.itemID or button.BGR.itemLink) end
    local bag = type(button.GetBagID) == "function" and button:GetBagID() or nil
    if type(bag) == "number" or string.match(name, "^ContainerFrame%d+Item%d+$") then
        local slot
        if type(bag) == "number" then
            slot = type(button.GetSlotID) == "function" and button:GetSlotID() or button:GetID()
        else
            bag = parent and type(parent.GetID) == "function" and parent:GetID()
            slot = type(button.GetID) == "function" and button:GetID()
        end
        if type(bag) ~= "number" or not (bag >= -2147483648 and bag <= 2147483647) or bag ~= math.floor(bag) then return nil end
        if type(slot) ~= "number" or not (slot >= 1 and slot <= 4294967295) or slot ~= math.floor(slot) then return nil end
        local getSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
        if getSlots then
            local slots = getSlots(bag)
            if type(slots) ~= "number" or slot > slots then return nil end
        end
        if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
        if GetContainerItemLink then return self:ItemID(GetContainerItemLink(bag, slot)) end
        return nil
    end
    return self:ItemID(button.itemID or button.itemId or button.itemLink or button.link)
end

function AC:UpdateWishlistStar(button, icon, itemID)
    if not Stars:CanAccess(button) or not Stars:CanAccess(icon) then return end
    local entry = Stars.buttons[button]
    if not entry then
        entry = {}
        Stars.buttons[button] = entry
    end
    entry.icon = icon
    entry.itemID = itemID
    entry.explicit = true
    pcall(Stars.Update, Stars, button, entry)
end

function Stars:Update(button, entry)
    if not AC:GetConfig("WISHLISTENABLED", true) then
        if entry.star and self:CanAccess(entry.star) then entry.star:Hide() end
        return
    end
    if not self:CanAccess(button) or not self:CanAccess(entry.icon) or (entry.star and not self:CanAccess(entry.star)) then return end
    local visible = button:IsVisible()
    if issecretvalue and issecretvalue(visible) then return end
    if not visible then return end
    if self.baganatorRegistered and button.BGR then
        if entry.star then entry.star:Hide() end
        return
    end
    local itemID = entry.itemID
    if not entry.explicit then itemID = self:Resolve(button) end
    if itemID == nil and not entry.explicit then
        entry.misses = (entry.misses or 0) + 1
        if entry.star then entry.star:Hide() end
        return entry.misses >= 8
    end
    entry.misses = nil
    local texture = itemID and AC:GetWishlistTexture(itemID)
    if not entry.star then
        if not texture then return end
        if InCombatLockdown and InCombatLockdown() then return end
        entry.star = button:CreateTexture(nil, "OVERLAY", nil, 7)
        entry.star:SetSize(Stars.size, Stars.size)
        entry.star:SetPoint("TOPRIGHT", entry.icon, "TOPRIGHT", Stars.cornerOffset, Stars.cornerOffset)
    end
    if entry.star then
        entry.star:SetTexture(texture)
        entry.star:SetShown(texture ~= nil)
    end
end

function Stars:Track(button)
    if type(button) ~= "table" or self.buttons[button] or not AC:GetConfig("WISHLISTENABLED", true) then return end
    if not self:CanAccess(button) or not button.GetName or not button.CreateTexture then return end
    if self.baganatorRegistered and button.BGR then return end
    local name = button:GetName()
    local icon
    for i = 1, 4 do
        local candidate
        if i <= 3 then
            candidate = button[self.iconKeys[i]]
        elseif type(name) == "string" then
            candidate = _G[name .. "IconTexture"]
        end
        if type(candidate) == "table" and self:CanAccess(candidate) and candidate.GetObjectType and candidate:GetObjectType() == "Texture" then
            icon = candidate
            break
        end
    end
    if not icon then return end
    self.buttons[button] = {icon = icon}
    self.pending[button] = true
    self:Wake()
    if not self.showHooked[button] and button.HookScript then
        self.showHooked[button] = true
        pcall(button.HookScript, button, "OnShow", self.OnButtonShow)
    end
end

function Stars:Wake()
    if self.watcher then self.watcher:Show() end
end

function Stars.OnButtonShow(button)
    if Stars.buttons[button] then
        Stars.pending[button] = true
        Stars:Wake()
    end
end

function Stars.OnContainerShow()
    Stars.containers = true
    Stars:Wake()
end

function Stars:UpdatePending()
    for button in pairs(self.pending) do
        self.pending[button] = nil
        local entry = self.buttons[button]
        if entry then
            local updated, drop = pcall(self.Update, self, button, entry)
            if (not updated or drop == true) and not entry.explicit then self.buttons[button] = nil end
        end
    end
end

function Stars:Refresh()
    self.full = false
    if AC:GetConfig("WISHLISTENABLED", true) and self.discover and EnumerateFrames then
        self.discover = false
        local frame = EnumerateFrames()
        while frame do
            if self:CanAccess(frame) then pcall(self.Track, self, frame) end
            frame = EnumerateFrames(frame)
        end
    end
    for button, entry in pairs(self.buttons) do
        local updated, drop = pcall(self.Update, self, button, entry)
        if (not updated or drop == true) and not entry.explicit then self.buttons[button] = nil end
    end
    wipe(self.pending)
end

function Stars:TrackChildren(frame)
    if not self:CanAccess(frame) or type(frame.GetChildren) ~= "function" then return end
    for _, child in ipairs({frame:GetChildren()}) do
        pcall(self.Track, self, child)
    end
end

function Stars:TrackContainers()
    for index = 1, 13 do
        local frame = _G["ContainerFrame" .. index]
        if frame and frame:IsShown() then self:TrackChildren(frame) end
    end
    for _, name in ipairs(self.containerFrames) do
        local frame = _G[name]
        if frame and frame:IsShown() then self:TrackChildren(frame) end
    end
end

Stars.containerFrames = {"ContainerFrameCombinedBags", "BankFrame", "BankSlotsFrame", "BankPanel", "ReagentBankFrame"}
Stars.pending = setmetatable({}, {__mode = "k"})
Stars.showHooked = setmetatable({}, {__mode = "k"})
Stars.fallbackInterval = 30
Stars.containerEvents = {BAG_UPDATE_DELAYED = true, BANKFRAME_OPENED = true, PLAYERBANKSLOTS_CHANGED = true}
Stars.itemEvents = {"PLAYER_EQUIPMENT_CHANGED", "MERCHANT_SHOW", "MERCHANT_UPDATE", "LOOT_OPENED", "LOOT_SLOT_CHANGED", "START_LOOT_ROLL", "TRADE_PLAYER_ITEM_CHANGED", "TRADE_TARGET_ITEM_CHANGED", "INSPECT_READY", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "PLAYER_REGEN_ENABLED"}
local watcher = CreateFrame("Frame")
Stars.watcher = watcher
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
for event in pairs(Stars.containerEvents) do
    pcall(watcher.RegisterEvent, watcher, event)
end
for _, event in ipairs(Stars.itemEvents) do
    pcall(watcher.RegisterEvent, watcher, event)
end
watcher:SetScript("OnEvent", function(_, event)
    if Stars.containerEvents[event] then
        Stars.containers = true
        Stars.full = true
        Stars:Wake()
        return
    end
    if event ~= "PLAYER_LOGIN" and event ~= "ADDON_LOADED" then
        Stars.full = true
        Stars:Wake()
        return
    end
    Stars:RegisterBaganator()
    if event == "PLAYER_LOGIN" or IsLoggedIn and IsLoggedIn() then
        Stars.discover = true
        Stars:Wake()
    end
end)
Stars:RegisterBaganator()
watcher:SetScript("OnUpdate", function(sel)
    if not (Stars.full or Stars.containers or Stars.discover or next(Stars.pending)) then
        sel:Hide()
        return
    end
    if not AC:GetConfig("WISHLISTENABLED", true) then
        Stars.full, Stars.containers = false, false
        wipe(Stars.pending)
        sel:Hide()
        return
    end
    if Stars.containers then
        Stars.containers = false
        pcall(Stars.TrackContainers, Stars)
    end
    if Stars.full or Stars.discover then
        Stars:Refresh()
    else
        Stars:UpdatePending()
    end
end)
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(Stars.fallbackInterval, function()
        if not AC:GetConfig("WISHLISTENABLED", true) then return end
        Stars.full = true
        Stars:Wake()
    end)
end
local function OnItemButtonTexture(button)
    if type(button) == "string" then button = _G[button] end
    if type(button) ~= "table" then return end
    if Stars.buttons[button] then
        Stars.pending[button] = true
        Stars:Wake()
    else
        pcall(Stars.Track, Stars, button)
    end
end
if SetItemButtonTexture then hooksecurefunc("SetItemButtonTexture", OnItemButtonTexture) end
if type(ItemButtonMixin) == "table" and type(ItemButtonMixin.SetItemButtonTexture) == "function" then hooksecurefunc(ItemButtonMixin, "SetItemButtonTexture", OnItemButtonTexture) end
for index = 1, 13 do
    local frame = _G["ContainerFrame" .. index]
    if frame and frame.HookScript then frame:HookScript("OnShow", Stars.OnContainerShow) end
end
for _, name in ipairs(Stars.containerFrames) do
    local frame = _G[name]
    if frame and frame.HookScript then frame:HookScript("OnShow", Stars.OnContainerShow) end
end
