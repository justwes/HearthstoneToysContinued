-- Access the addon namespace
local addonName, addon = ...

-- Ensure the Functions module is part of the addon namespace
addon.Functions = {}

-- Housing data arrives through PLAYER_HOUSE_LIST_UPDATED.
addon.housingHomes = {}

local housingEvents = CreateFrame("Frame")

if C_Housing and C_Housing.GetPlayerOwnedHouses then
    housingEvents:RegisterEvent("PLAYER_LOGIN")
    housingEvents:RegisterEvent("PLAYER_HOUSE_LIST_UPDATED")

    local function RefreshHousingButtons(self)
        if not addon.toyFrame then
            return -- Normal startup will build the buttons later.
        end

        if InCombatLockdown() then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end

        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        addon.InitializeAvailableToys()
        addon.InitializeIncludedToys()
        addon.CreateToyButtons()
    end

    housingEvents:SetScript("OnEvent", function(self, event, houseInfos)
        if event == "PLAYER_LOGIN" then
            if C_Housing.HasHousingExpansionAccess() then
                C_Housing.GetPlayerOwnedHouses()
            end
        elseif event == "PLAYER_HOUSE_LIST_UPDATED" then
            addon.housingHomes = houseInfos or {}
            RefreshHousingButtons(self)
        elseif event == "PLAYER_REGEN_ENABLED" then
            RefreshHousingButtons(self)
        end
    end)
end

function addon.GetHousingHome()
    return addon.housingHomes[1]
end

function addon.CanReturnFromHousing()
    local home = addon.GetHousingHome()

    if not home or not C_HousingNeighborhood then
        return false
    end

    return C_HousingNeighborhood.CanReturnAfterVisitingHouse()
        and C_Housing.GetCurrentNeighborhoodGUID() == home.neighborhoodGUID
end

-- Store last known toy ownership state
local lastKnownOwnedToyIDs = {}
local hasToySnapshotInitialized = false

-- Function for Debug Print
function addon.DebugPrint(...)
    if not addon.DEBUG then return end

    local messageParts = {...}
    for i = 1, #messageParts do
        messageParts[i] = tostring(messageParts[i])
    end

    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " ..
          addon.CONST.RESET_COLOR .. addon.CONST.DEBUG_TEXT_COLOR .. "[DEBUG] " ..
          addon.CONST.RESET_COLOR .. table.concat(messageParts, " "))
end

-- Check whether a toy, item, spell, or housing action is available
function addon.IsEntryAvailable(itemID, itemType)
    if itemType == "toy" then
        return PlayerHasToy(itemID)
    elseif itemType == "item" then
        return C_Item.GetItemCount(itemID) > 0
    elseif itemType == "spell" then
        return C_SpellBook.IsSpellInSpellBook(
            itemID, Enum.SpellBookSpellBank.Player, false
        )
    elseif itemType == "housing" then
        return addon.GetHousingHome() ~= nil
    end

    return false
end

-- Function to find Available Toys by filtering toyList
function addon.InitializeAvailableToys()
    wipe(addon.CONST.availableToys)

    for _, entry in ipairs(addon.toyList) do
        if addon.IsEntryAvailable(entry.id, entry.type) then
            table.insert(addon.CONST.availableToys, {
                id = entry.id,
                type = entry.type
            })
        end
    end
end

-- Build the included list from saved settings and entry availability
function addon.InitializeIncludedToys()
    wipe(addon.CONST.includeToys)

    for itemID, isIncluded in pairs(_G[addon.CONST.DB_NAME].toySettings) do
        if isIncluded then
            for _, entry in ipairs(addon.toyList) do
                if entry.id == itemID then
                    local isAvailable

                    if entry.type == "item" then
                        -- Preserve the existing item-information check
                        isAvailable = C_Item.GetItemInfo(itemID) ~= nil
                    else
                        isAvailable = addon.IsEntryAvailable(itemID, entry.type)
                    end

                    if isAvailable then
                        table.insert(addon.CONST.includeToys, itemID)
                    end

                    break
                end
            end
        end
    end
end

-- Function to save position
function addon.SaveMainFramePosition()
    _G[addon.CONST.DB_NAME].mainFramePosition = _G[addon.CONST.DB_NAME].mainFramePosition or {}
    local point, relativeTo, relativePoint, xOfs, yOfs = addon.mainFrame:GetPoint()

    -- Format the offsets to fit within 6 characters (e.g., max 2 decimal places)
    local formattedXOfs = string.format("%.2f", xOfs)
    local formattedYOfs = string.format("%.2f", yOfs)

    _G[addon.CONST.DB_NAME].mainFramePosition.point = point
    _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo = relativeTo and relativeTo:GetName() or "UIParent"
    _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint = relativePoint
    _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = tonumber(formattedXOfs)  -- Ensure it's saved as a number
    _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = tonumber(formattedYOfs)  -- Ensure it's saved as a number

    addon.DebugPrint("Main frame position saved: Point: " .. tostring(point) ..
        ", Relative To: " .. tostring(_G[addon.CONST.DB_NAME].mainFramePosition.relativeTo) ..
        ", Relative Point: " .. tostring(relativePoint) ..
        ", X Offset: " .. tostring(formattedXOfs) ..
        ", Y Offset: " .. tostring(formattedYOfs))

    -- Update the EditBoxes with the truncated values
    if addon.xPositionInput and addon.yPositionInput then
        addon.xPositionInput:SetText(formattedXOfs)
        addon.yPositionInput:SetText(formattedYOfs)
    end
end

-- Function to load position
function addon.LoadMainFramePosition()
    if _G[addon.CONST.DB_NAME].mainFramePosition then
        addon.mainFrame:ClearAllPoints()
        addon.mainFrame:SetPoint(
            _G[addon.CONST.DB_NAME].mainFramePosition.point or "CENTER", 
            _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo or UIParent, 
            _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint or "CENTER", 
            _G[addon.CONST.DB_NAME].mainFramePosition.xOfs or 0, 
            _G[addon.CONST.DB_NAME].mainFramePosition.yOfs or 0
        )
    else
        addon.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if addon.xPositionInput and addon.yPositionInput then
        addon.xPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.xOfs or 0))
        addon.yPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.yOfs or 0))
    end
end

-- Function to clear all the toy buttons
function addon.ClearToyButtons()
    for _, toyActionButton in ipairs(addon.CONST.toyButtons) do
        toyActionButton:Hide()
        toyActionButton:SetParent(nil)
    end
    wipe(addon.CONST.toyButtons) -- Clear the toy buttons table
end

-- Create toy buttons for included toys and items
function addon.CreateToyButtons()
    addon.ClearToyButtons()

    -- Map each entry ID to its type for availability checks
    local entryTypes = {}

    for _, entry in ipairs(addon.toyList) do
        entryTypes[entry.id] = entry.type
    end

    local index = 1

    for _, itemID in ipairs(addon.CONST.includeToys) do
        local itemType = entryTypes[itemID]

        if itemType and addon.IsEntryAvailable(itemID, itemType) then
            local toyActionButton = addon.CreateButton(itemID, addon.toyFrame, index)
            table.insert(addon.CONST.toyButtons, toyActionButton)
            index = index + 1
        end
    end
    addon.UpdateToyButtonPositions() -- Update button positions after creating them

    -- >>> initialize per-button cooldown states
    if addon.UpdateAllToyButtonCooldowns then
        addon.UpdateAllToyButtonCooldowns()
    end
end

-- Function to toggle toy inclusion in the options panel
function addon.ToggleToyInclusion(itemID, isIncluded)
    if addon.DEBUG then
        addon.DebugPrint("ToggleToyInclusion called for", itemID)
    end
    if type(itemID) == "number" then
        _G[addon.CONST.DB_NAME].toySettings[itemID] = isIncluded
        addon.InitializeIncludedToys()
        addon.CreateToyButtons()
    end
end

-- Function to print message if addon has been updated
function addon.AddonUpdatedMessage()
    if _G[addon.CONST.DB_NAME].generalSettings.version ~= addon.CONST.ADDON_VERSION then
        print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Addon has been updated to version " .. addon.CONST.ADDON_VERSION .. ". Updates include: " .. addon.CONST.ADDON_UPDATES)
        _G[addon.CONST.DB_NAME].generalSettings.version = addon.CONST.ADDON_VERSION  -- Update stored version to current version
    end
end

-- Function to display a flavor message
function addon.FlavorMessage()
    local messageCount = #addon.FLAVOR_MESSAGES
    if messageCount == 0 then
        local fallback = "No flavor messages available."
        if addon.flavorTextOutputChannel == "say" then
            C_ChatInfo.SendChatMessage(fallback, "SAY")
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. fallback .. addon.CONST.RESET_COLOR)
        end
        return
    end

    local selectedMessage = addon.FLAVOR_MESSAGES[math.random(1, messageCount)]

    -- If the addon requires a target for flavor messages
    if addon.requiresTargetForFlavor then
        local targetName = UnitName("target")
        if not targetName then
            -- print(addon.CONST.ADDON_TEXT_COLOR .. "No target selected. Cannot send message." .. addon.CONST.RESET_COLOR)
            return
        end
        C_ChatInfo.SendChatMessage(selectedMessage, "SAY", nil, targetName)
    else
        if addon.flavorTextOutputChannel == "say" then
            C_ChatInfo.SendChatMessage(selectedMessage, "SAY")
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. selectedMessage .. addon.CONST.RESET_COLOR)
        end
    end
end

function addon.PrintWelcomeMessage()
    -- Print Welcome Message
    if _G[addon.CONST.DB_NAME].generalSettings.showWelcomeMessage then
        print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. addon.CONST.WELCOME_MESSAGE)
    end
end

-- Safe spell cooldown getter (supports table or multi-return API)
local function GetSpellCooldownSafe(id)
    if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(id)
        if type(a) == "table" then
            local info = a
            local enabled = 0

            -- isEnabled may be a secret value; never test it directly.
            pcall(function()
                if info.isEnabled then
                    enabled = 1
                end
            end)

            return info.startTime or 0, info.duration or 0, enabled, info.modRate
        else
            return a or 0, b or 0, c or 0, d
        end
    end

    return 0, 0, 0, 1
end

-- Function to update the cooldown frame
function addon.UpdateCooldown()
    if not addon.cooldownFrame then
        print(addon.CONST.DEBUG_TEXT_COLOR .. "Cooldown frame not initialized yet!" .. addon.CONST.RESET_COLOR)
        return
    end

    local function normalize(start, dur)
        -- Coerce to numbers
        start = type(start) == "number" and start or 0
        dur   = type(dur)   == "number" and dur   or 0
        -- Convert ms → s if it looks like milliseconds
        if dur > 1000 then
            start = start / 1000
            dur   = dur   / 1000
        end
        return start, dur
    end

    local shown = false

    -- 1) Global Cooldown first
    local spellID = addon.COOLDOWN_SPELL_ID
    if spellID then
        local sStart, sDur, sEnable = GetSpellCooldownSafe(spellID)
        sStart, sDur = normalize(sStart, sDur)

        if addon.DEBUG then
            print(string.format("[GCD] enable=%s dur=%.3f start=%.3f", tostring(sEnable), sDur or 0, sStart or 0))
        end

        if (sEnable == 1 or sEnable == true) and sDur > 0 then
            addon.cooldownFrame:SetCooldown(sStart, sDur)
            shown = true
        end
    end

    -- 2) Fallback to item cooldown if configured and GCD not shown
    if not shown then
        local itemID = addon.COOLDOWN_ITEM_ID
        if itemID and C_Item.GetItemCooldown then
            local iStart, iDur, iEnable = C_Item.GetItemCooldown(itemID)
            iStart, iDur = normalize(iStart, iDur)

            if addon.DEBUG then
                print(string.format("[ItemCD %s] enable=%s dur=%.3f start=%.3f", tostring(itemID), tostring(iEnable), iDur or 0, iStart or 0))
            end

            if (iEnable == 1 or iEnable == true) and iDur > 0 then
                addon.cooldownFrame:SetCooldown(iStart, iDur)
                shown = true
            end
        end
    end

    if not shown then
        addon.cooldownFrame:Clear()
    end
end

-- Function to highlight the icon temporarily
function addon.HighlightIcon()
    if not addon.mainFrame then return end

    local tex = addon.mainFrame.texture or addon.mainFrame:GetNormalTexture()
    if tex then
        tex:SetVertexColor(1, 1, 0.85)
    end

    local glow = addon.mainFrame.customGlow
    if glow then
        glow:Show()
        if glow.customGlowPulse then
            glow.customGlowPulse:Play()
        else
            glow:SetAlpha(0.9)
        end
    end

    C_Timer.After(5, function()
        addon.ResetIconHighlight()
    end)
end

function addon.ResetIconHighlight()
    if not addon.mainFrame then return end

    local tex = addon.mainFrame.texture or addon.mainFrame:GetNormalTexture()
    if tex then
        tex:SetVertexColor(1, 1, 1)
    end

    local glow = addon.mainFrame.customGlow
    if glow then
        if glow.customGlowPulse then
            glow.customGlowPulse:Stop()
        end
        glow:SetAlpha(0)
        glow:Hide()
    end
end

-- Function to Reset the Database to defaults
function addon.ResetDatabase()
    -- Print a confirmation message
    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Resetting database to default settings...")

    -- Reset all saved variables to their defaults
    for key, value in pairs(addon.defaults) do
        if type(value) == "table" then
            -- For nested tables, reset each entry individually
            _G[addon.CONST.DB_NAME][key] = {}
            for nestedKey, nestedValue in pairs(value) do
                _G[addon.CONST.DB_NAME][key][nestedKey] = nestedValue
            end
        else
            -- For non-table values, reset directly
            _G[addon.CONST.DB_NAME][key] = value
        end
    end

    -- Reset toySettings
    _G[addon.CONST.DB_NAME].toySettings = {}
    _G[addon.CONST.DB_NAME].randomToySettings = {}
    for _, toyListEntry in ipairs(addon.toyList) do
        local itemID = toyListEntry.id
        if type(itemID) == "number" then
            _G[addon.CONST.DB_NAME].toySettings[itemID] = true
            _G[addon.CONST.DB_NAME].randomToySettings[itemID] =
                toyListEntry.randomDefault ~= false
        end
    end

    -- Reset presets
    _G[addon.CONST.DB_NAME].presets = {}

    -- Refresh options panel UI
    addon.RefreshUI()

    -- Notify the user of the reset
    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Database reset complete.")
end

-- Function to Refresh the UI when the Database is Reset to defaults
function addon.RefreshUI()
    if addon.DEBUG then
        addon.DebugPrint("addon.RefreshUI called")
    end

    -- Update the General Settings Section
    if addon.generalSettingsCheckbox then
        addon.generalSettingsCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.showWelcomeMessage)
    end
    if addon.showChatMessageCheckbox then
        addon.showChatMessageCheckbox:SetChecked(_G[addon.CONST.DB_NAME].specificSettings.showChatMessage)
    end
    if addon.playSoundWhenFrameShownCheckbox then
        addon.playSoundWhenFrameShownCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown)
    end
    if addon.showButtonOnMouseOverCheckbox then
        addon.showButtonOnMouseOverCheckbox:SetChecked(_G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver)
    end
    addon.UpdateVisibility()

    -- Refresh the Position Settings Section
    if addon.lockPositionCheckbox then
        addon.lockPositionCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.lockPosition)
    end
    addon.mainFrame:RegisterForDrag("LeftButton")  -- Register drag
    if addon.presetsDropdown and addon.ResetPresetSelection then
        addon.ResetPresetSelection()
    end
    addon.LoadMainFramePosition()

    -- Refresh the Toy Button Position Section
        if addon.positionDropdown then
        addon.positionDropdown:GenerateMenu()
    end
    
    -- Refresh Size Settings Section
    if addon.sizeSlider and addon.sizeInput then
        local buttonSize = _G[addon.CONST.DB_NAME].specificSettings.buttonSize or 44
        addon.sizeSlider:SetValue(buttonSize)
        addon.sizeInput:SetText(math.floor(buttonSize))
    end

    -- Rebuild the included toys and their buttons once
    addon.InitializeIncludedToys()
    addon.CreateToyButtons()

    -- Force options panel refresh
    if addon.optionsPanel and addon.optionsPanel:IsShown() then
        addon.optionsPanel:Hide()
        C_Timer.After(0.1, function()
            addon.optionsPanel:Show()
        end)
    end
end

-- Function handle when new toys are acquired
function addon.HandleNewToyAcquisition()
    if addon.DEBUG then
        addon.DebugPrint("addon.HandleNewToyAcquisition called")
    end

    local newlyAcquired = {}
    local currentOwnedToyIDs = {}

    -- Scan owned toys for acquisition changes
    for _, entry in ipairs(addon.toyList) do
        local itemID = entry.id

        if entry.type == "toy" and PlayerHasToy(itemID) then
            currentOwnedToyIDs[itemID] = true

            local isNewlyAcquired = hasToySnapshotInitialized and not lastKnownOwnedToyIDs[itemID]

            -- Auto-enable newly acquired toys so they appear in the toyFrame
            if isNewlyAcquired then
                _G[addon.CONST.DB_NAME].toySettings[itemID] = true
                _G[addon.CONST.DB_NAME].randomToySettings[itemID] =
                    entry.randomDefault ~= false
                table.insert(newlyAcquired, {id = itemID, type = "toy"})
            elseif _G[addon.CONST.DB_NAME].toySettings[itemID] == nil then
                -- First-time DB population for already-owned toys
                _G[addon.CONST.DB_NAME].toySettings[itemID] = true
            end
        end
    end

    -- Detect if there's a difference
    local toysChanged = false
    if hasToySnapshotInitialized then
        for toyID in pairs(currentOwnedToyIDs) do
            if not lastKnownOwnedToyIDs[toyID] then
                toysChanged = true
                break
            end
        end
        if not toysChanged then
            for toyID in pairs(lastKnownOwnedToyIDs) do
                if not currentOwnedToyIDs[toyID] then
                    toysChanged = true
                    break
                end
            end
        end
    else
        -- Do not treat first snapshot as change
        if addon.DEBUG then
            addon.DebugPrint("First toy snapshot initialized, skipping refresh.")
        end
    end

    -- Update snapshot for next comparison
    lastKnownOwnedToyIDs = currentOwnedToyIDs
    hasToySnapshotInitialized = true

    -- Rebuild available toys using current ownership information
    addon.InitializeAvailableToys()

    -- Only refresh UI and print if toys actually changed
    if toysChanged then
        if addon.DEBUG then
            addon.DebugPrint("Toys changed. Refreshing UI.")
        end

        addon.RefreshUI()

        for _, toy in ipairs(newlyAcquired) do
            local _, toyName = C_ToyBox.GetToyInfo(toy.id)
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " ..
                  addon.CONST.RESET_COLOR .. "New toy acquired: " .. (toyName or "Unknown"))
            addon.HighlightIcon()
        end
    elseif addon.DEBUG then
        addon.DebugPrint("No toy changes detected. Skipping refresh.")
    end
end

-- Coerce cooldown values that may be "secret" in Midnight into safe numbers
local function SafeCooldownNumber(v)
    if type(v) == "number" then
        return v
    end

    local n = 0
    pcall(function()
        n = tonumber(v) or 0
    end)
    return n
end

local function SafeCooldownGreaterThanZero(v)
    local ok, result = pcall(function()
        local n = tonumber(v) or 0
        return n > 0
    end)
    return ok and result or false
end

function addon.UpdateToyButtonCooldown(btn)
    if not btn or not btn.cooldown or not btn._cdType or not btn._cdID then return end

    if btn._cdType == "housing" then
        if addon.CanReturnFromHousing() then
            btn.cooldown:Clear()
            return
        end

        local info = C_Housing.GetVisitCooldownInfo()

        if info then
            btn.cooldown:SetCooldown(
                info.startTime,
                info.duration,
                info.modRate
            )
        else
            btn.cooldown:Clear()
        end

        return
    end

    -- SPELL buttons: just use the spell cooldown
    if btn._cdType == "spell" then
        local sStart, sDur = GetSpellCooldownSafe(btn._cdID)
        sStart = SafeCooldownNumber(sStart)
        sDur   = SafeCooldownNumber(sDur)

        if SafeCooldownGreaterThanZero(sDur) then
            btn.cooldown:SetCooldown(sStart, sDur)
        else
            if btn.cooldown.Clear then btn.cooldown:Clear() else btn.cooldown:SetCooldown(0, 0) end
        end
        return
    end

    -- ITEM/TOY buttons: try the item’s cooldown first
    local iStart, iDur = 0, 0
    if C_Item.GetItemCooldown then
        iStart, iDur = C_Item.GetItemCooldown(btn._cdID)
    end
    iStart = SafeCooldownNumber(iStart)
    iDur   = SafeCooldownNumber(iDur)

    if SafeCooldownGreaterThanZero(iDur) then
        btn.cooldown:SetCooldown(iStart or 0, iDur)
        return
    end

    -- Fallback: some toys/items (e.g., Ultrasafe Transporters/portals) expose cooldown only on their spell
    local spellID = btn._spellFromItem
    if spellID == nil then
        local _, sid = C_Item.GetItemSpell(btn._cdID)
        spellID = sid
        btn._spellFromItem = sid or false
        if not sid and C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(btn._cdID)
            if btn.RegisterEvent then btn:RegisterEvent("GET_ITEM_INFO_RECEIVED") end
        end
    end

    if spellID then
        local sStart, sDur = GetSpellCooldownSafe(spellID)
        sStart = SafeCooldownNumber(sStart)
        sDur   = SafeCooldownNumber(sDur)

        if SafeCooldownGreaterThanZero(sDur) then
            btn.cooldown:SetCooldown(sStart, sDur)
            return
        end
    end

    -- Nothing active
    if btn.cooldown.Clear then btn.cooldown:Clear() else btn.cooldown:SetCooldown(0, 0) end
end

function addon.UpdateAllToyButtonCooldowns()
    for _, btn in ipairs(addon.CONST.toyButtons) do
        addon.UpdateToyButtonCooldown(btn)
    end
end
