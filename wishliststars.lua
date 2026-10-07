local _, AC = ...
local Stars = {buttons = setmetatable({}, {__mode = "k"}), elapsed = 0, discover = true, size = 16, cornerOffset = 4, accessMethods = {"IsForbidden", "HasAnyForbiddenAspects", "CanBeAccessedInContext"}, iconKeys = {"icon", "Icon", "IconTexture"}}
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
    local texture = itemID and AC:GetWishlistTexture(itemID)
    if not entry.star then
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
    if not AC:GetConfig("WISHLISTENABLED", true) then return end
    if not self:CanAccess(button) or self.buttons[button] or not button.GetName or not button.CreateTexture then return end
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
end

function Stars:Refresh()
    if AC:GetConfig("WISHLISTENABLED", true) and self.discover and EnumerateFrames then
        self.discover = false
        local frame = EnumerateFrames()
        while frame do
            if self:CanAccess(frame) then pcall(self.Track, self, frame) end
            frame = EnumerateFrames(frame)
        end
    end
    for button, entry in pairs(self.buttons) do
        local ok, visible = pcall(button.IsVisible, button)
        if ok and not (issecretvalue and issecretvalue(visible)) and visible == true and self:CanAccess(button) and not pcall(self.Update, self, button, entry) and not entry.explicit then self.buttons[button] = nil end
    end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function(_, event)
    Stars:RegisterBaganator()
    if event == "PLAYER_LOGIN" or IsLoggedIn and IsLoggedIn() then Stars.discover = true end
end)
Stars:RegisterBaganator()
watcher:SetScript("OnUpdate", function(_, elapsed)
    Stars.elapsed = Stars.elapsed + elapsed
    if Stars.elapsed < 0.25 then return end
    Stars.elapsed = 0
    if AC:GetConfig("WISHLISTENABLED", true) then Stars:Refresh() end
end)
if SetItemButtonTexture then
    hooksecurefunc("SetItemButtonTexture", function(button)
        if type(button) == "string" then button = _G[button] end
        pcall(Stars.Track, Stars, button)
    end)
end
