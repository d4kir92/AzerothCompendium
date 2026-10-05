local _, AC = ...
local Stars = {buttons = setmetatable({}, {__mode = "k"}), elapsed = 0, discover = true}
AC.WishlistStars = Stars

function Stars:ItemID(value)
    if type(value) == "number" then return value end
    if type(value) == "string" then return tonumber(string.match(value, "item:(%d+)")) end
end

function Stars:RegisterBaganator()
    local api = Baganator and Baganator.API
    if self.baganatorRegistered or not api or type(api.RegisterCornerWidget) ~= "function" then return end
    api.RegisterCornerWidget("AzerothCompendium: " .. AC:Trans("LID_WISHLIST"), "azerothcompendium_wishlist", function(_, details)
        local itemID = type(details) == "table" and Stars:ItemID(details.itemID or details.itemLink)
        return itemID ~= nil and AC:IsWishlisted(itemID)
    end, function(button)
        local star = button:CreateTexture(nil, "OVERLAY", nil, 7)
        star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        star:SetSize(14, 14)
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
    local parentName = parent and type(parent.GetName) == "function" and parent:GetName() or ""
    if type(parentName) ~= "string" then parentName = "" end
    if string.match(name, "^GroupLootFrame%d+Item$") or string.match(parentName, "^GroupLootFrame%d+$") then
        return parent and GetLootRollItemLink and parent.rollID and self:ItemID(GetLootRollItemLink(parent.rollID))
    end
    if string.match(name, "^Character.+Slot$") then return self:ItemID(GetInventoryItemLink("player", button:GetID())) end
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
    local hasBagSlot = type(button.GetBagID) == "function" and type(button.GetSlotID) == "function"
    if hasBagSlot or string.match(name, "^ContainerFrame%d+Item%d+$") then
        local bag, slot
        if hasBagSlot then
            bag, slot = button:GetBagID(), button:GetSlotID()
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
    if not button or not icon then return end
    local entry = Stars.buttons[button]
    if not entry then
        entry = {}
        Stars.buttons[button] = entry
    end
    entry.icon = icon
    entry.itemID = itemID
    entry.explicit = true
    Stars:Update(button, entry)
end

function Stars:Update(button, entry)
    if not button:IsVisible() then return end
    if self.baganatorRegistered and button.BGR then
        if entry.star then entry.star:Hide() end
        return
    end
    local itemID = entry.itemID
    if not entry.explicit then itemID = self:Resolve(button) end
    local listed = itemID and AC:IsWishlisted(itemID) or false
    if not entry.star then
        if InCombatLockdown and InCombatLockdown() then return end
        entry.star = button:CreateTexture(nil, "OVERLAY", nil, 7)
        entry.star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        entry.star:SetSize(14, 14)
        entry.star:SetPoint("TOPRIGHT", entry.icon, "TOPRIGHT", 2, 2)
    end
    if entry.star then entry.star:SetShown(listed) end
end

function Stars:Track(button)
    if not button or self.buttons[button] or not button.GetName or not button.CreateTexture then return end
    if self.baganatorRegistered and button.BGR then return end
    local name = button:GetName()
    local icon = button.icon or button.Icon or button.IconTexture or name and _G[name .. "IconTexture"]
    if not icon or not icon.GetObjectType or icon:GetObjectType() ~= "Texture" then return end
    self.buttons[button] = {icon = icon}
end

function Stars:Refresh()
    if self.discover and EnumerateFrames then
        self.discover = false
        local frame = EnumerateFrames()
        while frame do
            if not frame.IsForbidden or not frame:IsForbidden() then self:Track(frame) end
            frame = EnumerateFrames(frame)
        end
    end
    for button, entry in pairs(self.buttons) do
        if not button.IsForbidden or not button:IsForbidden() then self:Update(button, entry) end
    end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function()
    Stars:RegisterBaganator()
    Stars.discover = true
end)
Stars:RegisterBaganator()
watcher:SetScript("OnUpdate", function(_, elapsed)
    Stars.elapsed = Stars.elapsed + elapsed
    if Stars.elapsed < 0.2 then return end
    Stars.elapsed = 0
    Stars:Refresh()
end)
if SetItemButtonTexture then
    hooksecurefunc("SetItemButtonTexture", function(button)
        if type(button) == "string" then button = _G[button] end
        Stars:Track(button)
    end)
end
