-- Access the addon namespace
local addonName, addon = ...

-- Ensure the UIFrames module is part of the addon namespace
addon.UIFrames = {}

-- Local references
local addonName = addon.CONST.ADDON_DISPLAY_NAME
addon.mainFrame = nil
addon.toyFrame = nil
addon.cooldownFrame = nil

local function PrintNotUsableInCombat()
    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " ..
        addon.CONST.RESET_COLOR .. "Not usable in combat.")
end

function addon.CreateToyFrame()
    if addon.DEBUG then
        -- addon.DebugPrint("CreateToyFrame called")
        addon.DebugPrint("CreateToyFrame: Called from", debugstack(2, 1, 0):match("([^/\\]+%.lua:%d+)"))
    end
    
    -- Destroy the old frame if it exists
    if addon.toyFrame then
        addon.toyFrame:Hide()
        addon.toyFrame:SetParent(nil)
        addon.toyFrame = nil
    end

    -- Recreate the frame
    addon.toyFrame = CreateFrame("Frame", addon.CONST.ADDON_NAME .. "ToyFrame", UIParent, "BackdropTemplate")
    addon.toyFrame:SetSize(#addon.toyList * (addon.buttonSize + 4), addon.buttonSize + 4)
    addon.toyFrame:SetFrameStrata("HIGH")
    addon.toyFrame:SetFrameLevel(100)
    addon.toyFrame:Hide() -- Hide until explicitly shown later

    if addon.DEBUG then
        addon.toyFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        addon.toyFrame:SetBackdropColor(0, 0, 0, 0.8)
        addon.toyFrame:SetBackdropBorderColor(1, 1, 1, 1)
    end
    
    -- Reparent toy buttons to the new frame
    for _, button in ipairs(addon.CONST.toyButtons) do
        button:SetParent(addon.toyFrame)
        button:Show() -- Ensure they're visible
    end

    -- Update layout
    if addon.UpdateToyButtonPositions then
        addon.UpdateToyButtonPositions()
    end
end

-- Function to create the main UI frame
function addon.UIFrames.Initialize()
    if addon.DEBUG then
        addon.DebugPrint("addon.UIFrames.Initialize called")
    end

    --------------------------------------------------------------------
    -- Main visual button (INSECURE wrapper for art/position/cooldown)
    --------------------------------------------------------------------
    addon.mainFrame = CreateFrame("Button", addon.CONST.ADDON_NAME .. "MainFrame", UIParent)
    addon.mainFrame:SetSize(addon.buttonSize, addon.buttonSize)
    addon.mainFrame:SetNormalTexture(addon.CONST.ADDON_ICON_TEXTURE)
    -- Create a simple animated custom glow (replacement for ActionButton_ShowOverlayGlow)
    local function EnsureCustomGlow()
        if not addon.mainFrame or addon.mainFrame.customGlow then return end

        -- Cache the normal texture ref (Hearthstone Toys Continued uses SetNormalTexture)
        addon.mainFrame.texture = addon.mainFrame.texture or addon.mainFrame:GetNormalTexture()

        local glow = addon.mainFrame:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")

        local baseSize = math.max(addon.mainFrame:GetWidth(), addon.mainFrame:GetHeight())
        local glowSize = baseSize * 1.8
        glow:SetSize(glowSize, glowSize)
        glow:SetPoint("CENTER", addon.mainFrame, "CENTER", 0, 0)
        glow:SetTexCoord(0.14, 0.86, 0.14, 0.86)
        glow:SetAlpha(0.0)
        glow:Hide()

        local ag = glow:CreateAnimationGroup()
        ag:SetLooping("REPEAT")

        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.10)
        fadeIn:SetToAlpha(0.90)
        fadeIn:SetDuration(0.35)
        fadeIn:SetOrder(1)

        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(0.90)
        fadeOut:SetToAlpha(0.10)
        fadeOut:SetDuration(0.55)
        fadeOut:SetOrder(2)

        local scaleUp = ag:CreateAnimation("Scale")
        scaleUp:SetScale(1.06, 1.06)
        scaleUp:SetDuration(0.35)
        scaleUp:SetOrder(1)

        local scaleDown = ag:CreateAnimation("Scale")
        scaleDown:SetScale(0.94, 0.94)
        scaleDown:SetDuration(0.55)
        scaleDown:SetOrder(2)

        glow.customGlowPulse = ag
        addon.mainFrame.customGlow = glow
    end

    EnsureCustomGlow()

    addon.mainFrame:SetMovable(true)
    addon.mainFrame:EnableMouse(false) -- IMPORTANT: secureButton will receive hover/click
    addon.mainFrame:SetFrameStrata("MEDIUM")
    addon.mainFrame:SetFrameLevel(100)
    addon.mainFrame:SetPoint(
        "CENTER",
        _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo or UIParent,
        _G[addon.CONST.DB_NAME].mainFramePosition.point,
        _G[addon.CONST.DB_NAME].mainFramePosition.xOfs,
        _G[addon.CONST.DB_NAME].mainFramePosition.yOfs
    )
    addon.mainFrame:Hide()

    --------------------------------------------------------------------
    -- Secure button (receives hover/click and performs configured random action)
    --------------------------------------------------------------------
    addon.secureButton = CreateFrame("Button", nil, addon.mainFrame, "SecureActionButtonTemplate")
    addon.secureButton:SetAllPoints(addon.mainFrame)
    addon.secureButton:RegisterForClicks("AnyDown", "AnyUp")
    addon.secureButton:EnableMouse(true)
    addon.secureButton:RegisterForDrag("LeftButton")

    --------------------------------------------------------------------
    -- Tooltip + mouseover alpha (attach to secureButton since it's hovered)
    --------------------------------------------------------------------
    addon.secureButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()
        GameTooltip:SetText(addon.CONST.ADDON_TEXT_COLOR .. addon.CONST.ADDON_DISPLAY_NAME .. addon.CONST.RESET_COLOR, 1, 1, 1, 1, true)
        local reversed = _G[addon.CONST.DB_NAME].specificSettings.reverseClickActions == true
        if reversed then
            GameTooltip:AddLine("Left-click: Use random toy", 1, 1, 1)
            GameTooltip:AddLine("Shift + Left-click: Toy buttons", 1, 1, 1)
        else
            GameTooltip:AddLine("Left-click: Toy buttons", 1, 1, 1)
            GameTooltip:AddLine("Shift + Left-click: Use random toy", 1, 1, 1)
        end
        GameTooltip:AddLine("Ctrl + Left-click and drag: Move button", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Options panel", 1, 1, 1)
        GameTooltip:Show()

        if _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver then
            addon.mainFrame:SetAlpha(1)
        end
    end)

    addon.secureButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()

        if _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver and not addon.toyFrame:IsShown() then
            addon.mainFrame:SetAlpha(0)
        end
    end)

    --------------------------------------------------------------------
    -- Local state
    --------------------------------------------------------------------
    local randomActionTriggered = false
    local clickAction = nil
    local isDragging = false

    --------------------------------------------------------------------
    -- Random action picker
    --------------------------------------------------------------------
    local function selectRandomAction()
        local actionList = addon.CONST.includeToys

        if #actionList == 0 then
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Action list is empty.")
            return nil, nil
        end

        local randomIndex = math.random(1, #actionList)
        local itemID = actionList[randomIndex]

        local isToy = PlayerHasToy(itemID)
        local isSpell = C_SpellBook.IsSpellInSpellBook(itemID, Enum.SpellBookSpellBank.Player, false)
        local itemCount = C_Item.GetItemCount(itemID)

        if isToy then
            return "toy", itemID
        elseif isSpell then
            return "spell", itemID
        elseif itemCount > 0 then
            return "item", "item:" .. itemID
        else
            return nil, nil
        end
    end

    -- Ctrl always takes priority. Otherwise the setting determines
    -- whether Shift or an unmodified click uses a random Hearthstone.
    local function getClickAction()
        if IsControlKeyDown() then
            return "move"
        end

        local reversed = _G[addon.CONST.DB_NAME].specificSettings.reverseClickActions == true
        if IsShiftKeyDown() ~= reversed then
            return "random"
        end
        return "list"
    end

    -- Clear any previously configured secure action before another click.
    local function clearRandomAction(self)
        self:SetAttribute("type", nil)
        self:SetAttribute("toy", nil)
        self:SetAttribute("spell", nil)
        self:SetAttribute("item", nil)
        randomActionTriggered = false
    end

    --------------------------------------------------------------------
    -- Mouse down: decide action once, with Ctrl taking priority
    --------------------------------------------------------------------
    addon.secureButton:SetScript("OnMouseDown", function(self, button)
        if InCombatLockdown() then
            PrintNotUsableInCombat()
            return
        end

        addon.UpdateCooldown()

        if button == "LeftButton" then
            isDragging = false
            clickAction = getClickAction()
            clearRandomAction(self)

            if clickAction == "move" then
                if not _G[addon.CONST.DB_NAME].generalSettings.lockPosition then
                    addon.mainFrame:StartMoving()
                end
                return
            end

            if clickAction == "random" then
                local actionType, actionID = selectRandomAction()
                if actionType and actionID then
                    self:SetAttribute("type", actionType)
                    self:SetAttribute(actionType, actionID)
                    randomActionTriggered = true
                else
                    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " ..
                        addon.CONST.RESET_COLOR .. "No valid action found.")
                end

                if randomActionTriggered and _G[addon.CONST.DB_NAME].specificSettings.showChatMessage then
                    addon.FlavorMessage()
                end
            end
        elseif button == "RightButton" and not IsShiftKeyDown() then
            Settings.OpenToCategory(addon.OptionsPanel.optionsCategoryId)
        end
    end)

    --------------------------------------------------------------------
    -- Mouse up: finish movement or toggle list, never both
    --------------------------------------------------------------------
    addon.secureButton:SetScript("OnMouseUp", function(self, button)
        if InCombatLockdown() then return end
        if button ~= "LeftButton" then return end

        addon.mainFrame:StopMovingOrSizing()

        if clickAction == "move" then
            addon.SaveMainFramePosition()
            clickAction = nil
            return
        end

        if clickAction == "list" and not isDragging then
            if addon.toyFrame:IsShown() then
                addon.toyFrame:Hide()
                if _G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown then
                    PlaySoundFile(addon.CONST.TOY_FRAME_HIDE_SOUND_ID, "Effects")
                end
            else
                if _G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown then
                    PlaySoundFile(addon.CONST.TOY_FRAME_SHOW_SOUND_ID, "Effects")
                end
                addon.toyFrame:Show()
            end
        end

        clickAction = nil
    end)

    --------------------------------------------------------------------
    -- Drag handlers: Ctrl + Left-drag only
    --------------------------------------------------------------------
    addon.secureButton:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        if clickAction ~= "move" or not IsControlKeyDown() then return end
        if _G[addon.CONST.DB_NAME].generalSettings.lockPosition then return end

        isDragging = true
        addon.mainFrame:StartMoving()
    end)

    addon.secureButton:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        addon.mainFrame:StopMovingOrSizing()
        if clickAction == "move" then
            addon.SaveMainFramePosition()
        end
    end)

    --------------------------------------------------------------------
    -- PostClick: clear secure attributes after random execution
    --------------------------------------------------------------------
    addon.secureButton:SetScript("PostClick", function(self)
        if not randomActionTriggered then return end
        if InCombatLockdown() then
            randomActionTriggered = false
            return
        end
        clearRandomAction(self)
    end)

    --------------------------------------------------------------------
    -- Cooldown overlay (still on mainFrame for visuals)
    --------------------------------------------------------------------
    addon.cooldownFrame = CreateFrame("Cooldown", addon.CONST.ADDON_NAME .. "CooldownFrame", addon.mainFrame, "CooldownFrameTemplate")
    addon.cooldownFrame:SetAllPoints(addon.mainFrame)

    addon.cooldownFrame:SetFrameStrata(addon.mainFrame:GetFrameStrata())
    addon.cooldownFrame:SetFrameLevel(addon.mainFrame:GetFrameLevel() + 5)

    addon.cooldownFrame:SetDrawSwipe(true)
    addon.cooldownFrame:SetDrawEdge(false)
    addon.cooldownFrame:SetSwipeColor(0, 0, 0, 0.7)
end

function addon.UpdateVisibility()
    if addon.DEBUG then
        local trace = debugstack(2, 3, 0)
        addon.DebugPrint("UpdateVisibility: Trace\n" .. trace)
    end

    local showOnMouseover = _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver

    -- Always apply state driver for protected UI conditions
    RegisterStateDriver(addon.mainFrame, "visibility", "[petbattle][overridebar][vehicleui][possessbar][@vehicle,exists] hide; show")

    if showOnMouseover then
        addon.mainFrame:SetAlpha(0)
    else
        addon.mainFrame:SetAlpha(1)
    end
end

-- Function to update toy button positions
function addon.UpdateToyButtonPositions()
    if addon.DEBUG then
        -- addon.DebugPrint("UpdateToyButtonPositions: Called from", debugstack(2, 1, 0):match("([^/\\]+%.lua:%d+)"))
    end

    local toyFramePosition = _G[addon.CONST.DB_NAME].specificSettings.toyFramePosition or "LEFT"
    local buttonSize = _G[addon.CONST.DB_NAME].specificSettings.buttonSize
    local spacing = 3
    local offsetX, offsetY = 0, 0
    
    -- Calculate offsets based on position
    if toyFramePosition == "LEFT" then
        addon.toyFrame:SetPoint("RIGHT", addon.mainFrame, "LEFT", -(buttonSize / 2 + spacing), 0)
        offsetX = buttonSize
    elseif toyFramePosition == "RIGHT" then
        addon.toyFrame:SetPoint("LEFT", addon.mainFrame, "RIGHT", buttonSize / 2 + spacing, 0)
        offsetX = buttonSize
    elseif toyFramePosition == "ABOVE" then
        addon.toyFrame:SetPoint("BOTTOM", addon.mainFrame, "TOP", 0, buttonSize / 2 + spacing)
        offsetY = buttonSize
    elseif toyFramePosition == "BELOW" then
        addon.toyFrame:SetPoint("TOP", addon.mainFrame, "BOTTOM", 0, -(buttonSize / 2 + spacing))
        offsetY = buttonSize
    end

    -- Adjust toyButtons positions based on their index and selected position
    for index, button in ipairs(addon.CONST.toyButtons) do
        local buttonOffsetX, buttonOffsetY = 0, 0

        if toyFramePosition == "LEFT" or toyFramePosition == "RIGHT" then
            buttonOffsetX = (index - 1) * (buttonSize + spacing) + offsetX + 3
            if toyFramePosition == "LEFT" then
                buttonOffsetX = -buttonOffsetX  -- Reverse direction for LEFT position
            end
        elseif toyFramePosition == "ABOVE" or toyFramePosition == "BELOW" then
            buttonOffsetY = (index - 1) * (buttonSize + spacing) + offsetY + 3
            if toyFramePosition == "BELOW" then
                buttonOffsetY = -buttonOffsetY  -- Reverse direction for BELOW position
            end
        end

        button:ClearAllPoints()
        button:SetPoint("CENTER", addon.mainFrame, "CENTER", buttonOffsetX, buttonOffsetY)
    end
end

-- Function to Set the Button Texture
local function SetButtonTexture(toyActionButton, itemID, texture, retries)
    if retries == 0 then
        -- If no retries left, set the default question mark texture
        toyActionButton:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        return
    end

    if texture and texture ~= "" then
        -- If texture is available, set it directly
        toyActionButton:SetNormalTexture(texture)
    else
        -- Retry loading the texture after a short delay
        C_Timer.After(0.7, function()
            local _, _, retryTexture
            if C_ToyBox.GetToyInfo then
                -- Try fetching toy info
                _, _, retryTexture = C_ToyBox.GetToyInfo(itemID)
            elseif C_Spell.GetSpellTexture then
                -- Try fetching spell texture
                retryTexture = C_Spell.GetSpellTexture(itemID)
            elseif C_Item.GetItemInfo then
                -- Try fetching item info
                _, _, retryTexture = C_Item.GetItemInfo(itemID)
            else
                -- No available methods to fetch texture
                retryTexture = nil
            end

            -- Retry setting the button texture with decremented retries
            SetButtonTexture(toyActionButton, itemID, retryTexture, retries - 1)
        end)
    end
end

---------------------------------
-- Function to Create Toy Buttons
---------------------------------
function addon.CreateButton(itemID, parent, index)
    local toyActionButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "Button" .. index, parent, "SecureActionButtonTemplate")
    toyActionButton:SetSize(addon.buttonSize, addon.buttonSize)

    local isToy = PlayerHasToy(itemID)
    local isSpell = C_SpellBook.IsSpellInSpellBook(itemID, Enum.SpellBookSpellBank.Player, false)
    local texture
    local tooltipFunc

    -- Preload texture and setup tooltip function
    if isToy then
        local _, toyName, toyTexture = C_ToyBox.GetToyInfo(itemID)
        texture = toyTexture
        tooltipFunc = function(self)
            if C_Item.GetItemInfo(itemID) then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetToyByItemID(itemID)
                GameTooltip:Show()
            else
                self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            end
        end
        toyActionButton:SetAttribute("type", "toy")
        toyActionButton:SetAttribute("toy", itemID)

        -- >>> store what to use for cooldown
        toyActionButton._cdType = "item"     -- toys use item cooldowns
        toyActionButton._cdID   = itemID

    elseif isSpell then
        local spellName = C_Spell.GetSpellName(itemID)
        texture = C_Spell.GetSpellTexture(itemID)
        tooltipFunc = function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(itemID)
            GameTooltip:Show()
        end
        toyActionButton:SetAttribute("type", "spell")
        toyActionButton:SetAttribute("spell", itemID)

        -- >>> store what to use for cooldown
        toyActionButton._cdType = "spell"
        toyActionButton._cdID   = itemID

    else
        local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
        texture = itemTexture
        tooltipFunc = function(self)
            if C_Item.GetItemInfo(itemID) then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            else
                self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            end
        end
        toyActionButton:SetAttribute("type", "item")
        toyActionButton:SetAttribute("item", "item:" .. itemID)

        -- >>> store what to use for cooldown
        toyActionButton._cdType = "item"
        toyActionButton._cdID   = itemID
    end

    -- Use the SetButtonTexture function with retry logic
    SetButtonTexture(toyActionButton, itemID, texture, 7)

    -- Tooltip handling with caching check
    toyActionButton:SetScript("OnEnter", function(self)
        tooltipFunc(self)
    end)

    toyActionButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Handle delayed tooltip update when item info is received
    toyActionButton:SetScript("OnEvent", function(self, event, receivedItemID)
        if event == "GET_ITEM_INFO_RECEIVED" and receivedItemID == itemID then
            self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
            if self:IsMouseOver() then
                tooltipFunc(self)
            end
        end
    end)

    toyActionButton:SetScript("PostClick", function(self)
        if addon.toyFrame then
            addon.toyFrame:Hide() -- Hide the toy frame
        end
        -- Adjust mainFrame visibility depending on mouseover setting
        if _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver then
            addon.mainFrame:SetAlpha(0)
        else
            addon.mainFrame:SetAlpha(1)
        end
        -- Optional Flavor Message
        if _G[addon.CONST.DB_NAME].specificSettings.showChatMessage then
            addon.FlavorMessage()
        end
    end)

    toyActionButton:RegisterForClicks("AnyDown", "AnyUp")
    toyActionButton:SetFrameStrata("HIGH")
    toyActionButton:SetFrameLevel(101)

    ----------------------------------------------------------------
    -- >>> Add a cooldown overlay on each toyActionButton
    ----------------------------------------------------------------
    local cd = CreateFrame("Cooldown", toyActionButton:GetName() .. "Cooldown", toyActionButton, "CooldownFrameTemplate")
    cd:SetAllPoints(toyActionButton)
    cd:SetFrameStrata(toyActionButton:GetFrameStrata())
    cd:SetFrameLevel(toyActionButton:GetFrameLevel() + 1)
    cd:SetDrawSwipe(true)
    cd:SetDrawEdge(false)
    cd:SetSwipeColor(0, 0, 0, 0.7)
    cd:SetReverse(false)
    cd:SetHideCountdownNumbers(false)
    toyActionButton.cooldown = cd

    -- >>> immediate initial update so the state is right when shown
    if addon.UpdateToyButtonCooldown then
        addon.UpdateToyButtonCooldown(toyActionButton)
    end

    return toyActionButton
end