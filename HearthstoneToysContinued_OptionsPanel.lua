-- Access the addon namespace
local addonName, addon = ...

addon.OptionsPanel = {}

-- Local reference for the addon display name
local displayName = addon.CONST.ADDON_DISPLAY_NAME

addon.OptionsPanel.optionsCategoryId = nil
addon.xPositionInput = nil
addon.yPositionInput = nil

------------------------------------------------
-- Defaults button (kept from your original)
------------------------------------------------
function addon.OptionsPanel.CreateResetDatabaseButton(parent)
    local resetButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 25)
    resetButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -25, -8)
    resetButton:SetText("Defaults")
    resetButton:SetScript("OnClick", function()
        StaticPopupDialogs["HEARTHSTONETOYSCONTINUED_RESET_CONFIRMATION"] = {
            text = "Are you sure you want to reset all addon settings? This action cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                addon.ResetDatabase()

                -- Best-effort UI refresh after reset (no errors if frames aren't ready)
                if addon.OptionsPanel and addon.OptionsPanel.RefreshUI then
                    addon.OptionsPanel.RefreshUI()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("HEARTHSTONETOYSCONTINUED_RESET_CONFIRMATION")
    end)
end

------------------------------------------------
-- Options Panel Initialize
------------------------------------------------
function addon.OptionsPanel.Initialize()
    if addon.DEBUG then
        addon.DebugPrint("addon.OptionsPanel.Initialize called")
    end

    local optionsPanel = CreateFrame("Frame", addonName .. "OptionsPanel", SettingsPanel or UIParent)
    optionsPanel.name = displayName

    ------------------------------------------------
    -- Header
    ------------------------------------------------
    local header = CreateFrame("Frame", nil, optionsPanel)
    header:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", 0, 0)
    header:SetHeight(72)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(displayName .. " Options")

    addon.OptionsPanel.CreateResetDatabaseButton(header)

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2)
    line:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    line:SetPoint("TOPRIGHT", header, "TOPRIGHT", -16, -8)

    ------------------------------------------------
    -- Main content container ----------------------
    ------------------------------------------------
    local content = CreateFrame("Frame", addonName .. "OptionsContent", optionsPanel)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    content:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", 0, 10)

    ------------------------------------------------
    -- Two-column layout scaffold (nav + pages)
    ------------------------------------------------
    local NAV_WIDTH = 150
    local PAGE_HEIGHT = 500

    local nav = CreateFrame("Frame", nil, content, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", content, "TOPLEFT", 16, 0)
    nav:SetSize(NAV_WIDTH, PAGE_HEIGHT)
    nav:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    nav:SetBackdropColor(0, 0, 0, 0.20)

    local pagesHost = CreateFrame("Frame", nil, content)
    pagesHost:SetPoint("TOPLEFT", nav, "TOPRIGHT", 16, 0)
    pagesHost:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, 0)
    pagesHost:SetHeight(PAGE_HEIGHT)

    local pages = {}
    local function CreatePage(key)
        local p = CreateFrame("Frame", nil, pagesHost)
        p:SetAllPoints(pagesHost)
        p:Hide()
        pages[key] = p
        return p
    end

    local pageGeneral  = CreatePage("General")
    local pageDisplay  = CreatePage("Display")
    local pagePosition = CreatePage("Positioning")
    local pageToys     = CreatePage("IncludedToys")
    local pageAbout    = CreatePage("About")

    local function AddPageTitle(page, text)
        local t = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        t:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
        t:SetText(text)
        return t
    end

    local generalTitle = AddPageTitle(pageGeneral, "General")
    local displayTitle = AddPageTitle(pageDisplay, "Display")
    local posTitle     = AddPageTitle(pagePosition, "Positioning")
    local toysTitle    = AddPageTitle(pageToys, "Included Toys")
    local aboutTitle   = AddPageTitle(pageAbout, "About")

    ------------------------------------------------
    -- Nav items
    ------------------------------------------------
    local navItems = {}
    local SELECTED_ALPHA = 0.25
    local NORMAL_ALPHA   = 0.00

    local function SetNavSelected(selectedKey)
        for key, item in pairs(navItems) do
            if key == selectedKey then
                item.bg:SetAlpha(SELECTED_ALPHA)
                item.text:SetFontObject(GameFontHighlight)
            else
                item.bg:SetAlpha(NORMAL_ALPHA)
                item.text:SetFontObject(GameFontNormal)
            end
        end
    end

    local function ShowPage(key)
        for _, p in pairs(pages) do p:Hide() end
        if pages[key] then
            pages[key]:Show()
            SetNavSelected(key)
        end
    end

    local function CreateNavItem(text, key, yOffset)
        local row = CreateFrame("Button", nil, nav)
        row:SetSize(NAV_WIDTH - 8, 24)
        row:SetPoint("TOPLEFT", nav, "TOPLEFT", 4, yOffset)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        row.bg:SetColorTexture(1, 1, 1, 1)
        row.bg:SetAlpha(NORMAL_ALPHA)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row, "LEFT", 10, 0)
        row.text:SetText(text)

        row:SetScript("OnClick", function() ShowPage(key) end)

        navItems[key] = row
        return row
    end

    CreateNavItem("General",       "General",      -10)
    CreateNavItem("Display",       "Display",      -38)
    CreateNavItem("Positioning",   "Positioning",  -66)
    CreateNavItem("Included Toys", "IncludedToys", -94)
    CreateNavItem("About",         "About",        -122)

    ------------------------------------------------
    -- Helpers (shared)
    ------------------------------------------------
    local function SafeGetDB()
        _G[addon.CONST.DB_NAME] = _G[addon.CONST.DB_NAME] or {}
        _G[addon.CONST.DB_NAME].generalSettings  = _G[addon.CONST.DB_NAME].generalSettings  or {}
        _G[addon.CONST.DB_NAME].specificSettings = _G[addon.CONST.DB_NAME].specificSettings or {}
        _G[addon.CONST.DB_NAME].mainFramePosition = _G[addon.CONST.DB_NAME].mainFramePosition or {}
        _G[addon.CONST.DB_NAME].toySettings = _G[addon.CONST.DB_NAME].toySettings or {}
        return _G[addon.CONST.DB_NAME]
    end

    local function ClampNumber(n, minV, maxV)
        n = tonumber(n)
        if not n then return nil end
        if n < minV then return minV end
        if n > maxV then return maxV end
        return n
    end

    ------------------------------------------------
    -- GENERAL PAGE
    ------------------------------------------------
    do
        local db = SafeGetDB()

        -- Welcome message
        local showWelcomeMessageCheckbox = CreateFrame("CheckButton", nil, pageGeneral, "ChatConfigCheckButtonTemplate")
        showWelcomeMessageCheckbox:SetPoint("TOPLEFT", generalTitle, "BOTTOMLEFT", 20, -12)
        showWelcomeMessageCheckbox:SetChecked(db.generalSettings.showWelcomeMessage)
        showWelcomeMessageCheckbox:SetScript("OnClick", function(self)
            db.generalSettings.showWelcomeMessage = self:GetChecked()
        end)
        addon.generalSettingsCheckbox = showWelcomeMessageCheckbox

        local showWelcomeMessageLabel = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        showWelcomeMessageLabel:SetPoint("LEFT", showWelcomeMessageCheckbox, "RIGHT", 5, 0)
        showWelcomeMessageLabel:SetText("Show Welcome Message")

        -- Flavor message toggle
        local showChatMessageCheckbox = CreateFrame("CheckButton", nil, pageGeneral, "ChatConfigCheckButtonTemplate")
        showChatMessageCheckbox:SetPoint("TOPLEFT", showWelcomeMessageCheckbox, "BOTTOMLEFT", 0, -8)
        showChatMessageCheckbox:SetChecked(db.specificSettings.showChatMessage)
        showChatMessageCheckbox:SetScript("OnClick", function(self)
            db.specificSettings.showChatMessage = self:GetChecked()
        end)
        addon.showChatMessageCheckbox = showChatMessageCheckbox

        local showChatMessageLabel = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        showChatMessageLabel:SetPoint("LEFT", showChatMessageCheckbox, "RIGHT", 5, 0)
        showChatMessageLabel:SetText("Show flavor message when using " .. addon.CONST.ADDON_DISPLAY_NAME)

        -- Sound toggle
        local playSoundWhenFrameShownCheckbox = CreateFrame("CheckButton", nil, pageGeneral, "ChatConfigCheckButtonTemplate")
        playSoundWhenFrameShownCheckbox:SetPoint("TOPLEFT", showChatMessageCheckbox, "BOTTOMLEFT", 0, -8)
        playSoundWhenFrameShownCheckbox:SetChecked(db.generalSettings.playSoundWhenFrameShown)
        playSoundWhenFrameShownCheckbox:SetScript("OnClick", function(self)
            db.generalSettings.playSoundWhenFrameShown = self:GetChecked()
        end)
        addon.playSoundWhenFrameShownCheckbox = playSoundWhenFrameShownCheckbox

        local playSoundWhenFrameShownLabel = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playSoundWhenFrameShownLabel:SetPoint("LEFT", playSoundWhenFrameShownCheckbox, "RIGHT", 5, 0)
        playSoundWhenFrameShownLabel:SetText("Play sound when show/hide " .. addon.CONST.ADDON_DISPLAY_NAME)

        -- Hide until mouseover
        local showButtonOnMouseOverCheckbox = CreateFrame("CheckButton", nil, pageGeneral, "ChatConfigCheckButtonTemplate")
        showButtonOnMouseOverCheckbox:SetPoint("TOPLEFT", playSoundWhenFrameShownCheckbox, "BOTTOMLEFT", 0, -8)
        showButtonOnMouseOverCheckbox:SetChecked(db.specificSettings.showButtonOnMouseOver)
        showButtonOnMouseOverCheckbox:SetScript("OnClick", function(self)
            db.specificSettings.showButtonOnMouseOver = self:GetChecked()
            if addon.UpdateVisibility then
                addon.UpdateVisibility()
            end
        end)
        addon.showButtonOnMouseOverCheckbox = showButtonOnMouseOverCheckbox

        local showButtonOnMouseOverLabel = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        showButtonOnMouseOverLabel:SetPoint("LEFT", showButtonOnMouseOverCheckbox, "RIGHT", 5, 0)
        showButtonOnMouseOverLabel:SetText("Hide button until mouseover")
    end

    ------------------------------------------------
    -- DISPLAY PAGE
    ------------------------------------------------
    do
        local db = SafeGetDB()

        -- Toy buttons position header
        local toyPosHeader = pageDisplay:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        toyPosHeader:SetPoint("TOPLEFT", displayTitle, "BOTTOMLEFT", 20, -16)
        toyPosHeader:SetText("Toy Button Position")

        addon.positions = {"LEFT", "RIGHT", "ABOVE", "BELOW"}

                local positionDropdown = CreateFrame(
            "DropdownButton",
            addon.CONST.ADDON_NAME .. "PositionDropdown",
            pageDisplay,
            "WowStyle1DropdownTemplate"
        )
        positionDropdown:SetPoint(
            "TOPLEFT", toyPosHeader, "BOTTOMLEFT", 20, -10
        )
        positionDropdown:SetWidth(160)
        positionDropdown:SetDefaultText("Left")
        addon.positionDropdown = positionDropdown

        local function IsPositionSelected(position)
            local currentDB = SafeGetDB()
            return (currentDB.specificSettings.toyFramePosition or "LEFT") == position
        end

        local function SetPosition(position)
            local currentDB = SafeGetDB()
            currentDB.specificSettings.toyFramePosition = position
            if addon.UpdateToyButtonPositions then
                addon.UpdateToyButtonPositions()
            end
        end

        positionDropdown:SetupMenu(function(owner, rootDescription)
            for _, position in ipairs(addon.positions) do
                local label = position:sub(1, 1) .. position:sub(2):lower()
                rootDescription:CreateRadio(
                    label, IsPositionSelected, SetPosition, position
                )
            end
        end)

        -- Size header
        local sizeHeader = pageDisplay:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        sizeHeader:SetPoint("TOPLEFT", positionDropdown, "BOTTOMLEFT", -20, -26)
        sizeHeader:SetText("Size Settings")

        addon.sizeSlider = CreateFrame("Slider", addon.CONST.ADDON_NAME .. "SizeSlider", pageDisplay, "OptionsSliderTemplate")
        addon.sizeSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 35, -10)
        addon.sizeSlider:SetMinMaxValues(20, 100)
        addon.sizeSlider:SetValueStep(1)
        addon.sizeSlider:SetObeyStepOnDrag(true)
        addon.sizeSlider:SetWidth(180)
        addon.sizeSlider:SetValue(db.specificSettings.buttonSize or 44)

        _G[addon.sizeSlider:GetName() .. "Low"]:SetText("20")
        _G[addon.sizeSlider:GetName() .. "High"]:SetText("100")

        addon.sizeInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "SizeInput", pageDisplay, "InputBoxTemplate")
        addon.sizeInput:SetPoint("LEFT", addon.sizeSlider, "RIGHT", 20, 0)
        addon.sizeInput:SetSize(50, 20)
        addon.sizeInput:SetJustifyH("CENTER")
        addon.sizeInput:SetAutoFocus(false)
        addon.sizeInput:SetText(tostring(math.floor(db.specificSettings.buttonSize or 44)))
        addon.sizeInput:SetCursorPosition(0)

        local function UpdateButtonSizes(value)
            value = ClampNumber(value, 20, 100)
            if not value then return end

            addon.buttonSize = value
            db.specificSettings.buttonSize = value

            if addon.mainFrame then
                addon.mainFrame:SetSize(value, value)
            end

            if type(addon.CONST.toyButtons) == "table" then
                for _, button in ipairs(addon.CONST.toyButtons) do
                    button:SetSize(value, value)
                end
            end

            if addon.UpdateToyButtonPositions then
                addon.UpdateToyButtonPositions()
            end
        end

        addon.sizeSlider:SetScript("OnValueChanged", function(self, v)
            local newSize = math.floor(v)
            addon.sizeInput:SetText(tostring(newSize))
            UpdateButtonSizes(newSize)
        end)

        addon.sizeInput:SetScript("OnEnterPressed", function(self)
            local inputValue = tonumber(self:GetText())
            inputValue = ClampNumber(inputValue, 20, 100)
            if inputValue then
                addon.sizeSlider:SetValue(inputValue)
            else
                self:SetText(tostring(math.floor(addon.sizeSlider:GetValue())))
            end
            self:ClearFocus()
        end)
    end

    --------------------------------------------------------------------
    -- POSITIONING PAGE
    --------------------------------------------------------------------
    do
        local lockPositionCheckbox = CreateFrame("CheckButton", nil, pagePosition, "ChatConfigCheckButtonTemplate")
        lockPositionCheckbox:SetPoint("TOPLEFT", posTitle, "BOTTOMLEFT", 20, -12)
        lockPositionCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.lockPosition)
        lockPositionCheckbox:SetScript("OnClick", function(self)
            local isLocked = self:GetChecked()
            _G[addon.CONST.DB_NAME].generalSettings.lockPosition = isLocked
            if addon.mainFrame then
                if isLocked then
                    addon.mainFrame:RegisterForDrag()
                else
                    addon.mainFrame:RegisterForDrag("LeftButton")
                end
            end
        end)
        addon.lockPositionCheckbox = lockPositionCheckbox

        local lockPositionLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockPositionLabel:SetPoint("LEFT", lockPositionCheckbox, "RIGHT", 5, 0)
        lockPositionLabel:SetText("Lock Dragging")

        local centerButton = CreateFrame("Button", nil, pagePosition, "UIPanelButtonTemplate")
        centerButton:SetSize(200, 25)
        centerButton:SetText("Move to center of the screen")
        centerButton:SetPoint("TOPLEFT", lockPositionCheckbox, "BOTTOMLEFT", 0, -17)
        centerButton:SetScript("OnClick", function()
            if not addon.mainFrame then return end

            addon.mainFrame:ClearAllPoints()
            addon.mainFrame:SetPoint("CENTER", UIParent, "CENTER")

            _G[addon.CONST.DB_NAME].mainFramePosition.point = "CENTER"
            _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo = nil
            _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = 0
            _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = 0
        end)

        local fineTuneLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fineTuneLabel:SetPoint("TOPLEFT", centerButton, "BOTTOMLEFT", 0, -25)
        fineTuneLabel:SetText("Fine tune button position")

        local xPositionLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        xPositionLabel:SetPoint("TOPLEFT", fineTuneLabel, "BOTTOMLEFT", 20, -10)
        xPositionLabel:SetText("X Position:")

        addon.xPositionInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "xPositionInput", pagePosition, "InputBoxTemplate")
        addon.xPositionInput:SetPoint("TOPLEFT", xPositionLabel, "BOTTOMLEFT", 75, 13)
        addon.xPositionInput:SetSize(75, 15)
        addon.xPositionInput:SetJustifyH("CENTER")
        addon.xPositionInput:SetAutoFocus(false)
        addon.xPositionInput:ClearFocus()
        addon.xPositionInput:SetMaxLetters(6)
        addon.xPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.xOfs or 0))
        addon.xPositionInput:SetCursorPosition(0)
        
        local yPositionLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        yPositionLabel:SetPoint("TOPLEFT", xPositionLabel, "BOTTOMLEFT", 0, -10)
        yPositionLabel:SetText("Y Position:")
        
        addon.yPositionInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "yPositionInput", pagePosition, "InputBoxTemplate")
        addon.yPositionInput:SetPoint("TOPLEFT", yPositionLabel, "BOTTOMLEFT", 75, 13)
        addon.yPositionInput:SetSize(75, 15)
        addon.yPositionInput:SetJustifyH("CENTER")
        addon.yPositionInput:SetAutoFocus(false)
        addon.yPositionInput:ClearFocus()
        addon.yPositionInput:SetMaxLetters(6)
        addon.yPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.yOfs or 0))
        addon.yPositionInput:SetCursorPosition(0)

        addon.xPositionInput:SetScript("OnEnterPressed", function()
            local x = tonumber(addon.xPositionInput:GetText())
            local y = tonumber(addon.yPositionInput:GetText())
            if x and y then
                _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = x
                _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = y
                addon.LoadMainFramePosition()
            end
        end)

        addon.yPositionInput:SetScript("OnEnterPressed", function()
            local x = tonumber(addon.xPositionInput:GetText())
            local y = tonumber(addon.yPositionInput:GetText())
            if x and y then
                _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = x
                _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = y
                addon.LoadMainFramePosition()
            end
        end)

        ------------------------------
        -- Position Presets Section --
        ------------------------------
        local presetNameInput
        local presetsDropdown

        local function InitializePresetsDropdown(owner, rootDescription)
            for presetName in pairs(_G[addon.CONST.DB_NAME].presets or {}) do
                rootDescription:CreateRadio(
                    presetName,
                    function(name)
                        return owner.selectedPresetName == name
                    end,
                    function(name)
                        owner.selectedPresetName = name
                        presetNameInput:SetText(name)
                    end,
                    presetName
                )
            end
        end

        local function ResetPresetSelection()
            presetsDropdown.selectedPresetName = nil
            presetsDropdown:GenerateMenu()
        end

        addon.ResetPresetSelection = ResetPresetSelection

        local function SavePreset(presetName)
            presetName = presetName or (presetNameInput and presetNameInput:GetText())
            if presetName and presetName ~= "" and presetName ~= "Preset Name" then
                if not _G[addon.CONST.DB_NAME].presets then
                    _G[addon.CONST.DB_NAME].presets = {}
                end

                _G[addon.CONST.DB_NAME].presets[presetName] = {
                    point = _G[addon.CONST.DB_NAME].mainFramePosition.point,
                    relativeTo = _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo,
                    relativePoint = _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint,
                    xOfs = _G[addon.CONST.DB_NAME].mainFramePosition.xOfs,
                    yOfs = _G[addon.CONST.DB_NAME].mainFramePosition.yOfs,
                }
                presetNameInput:SetText("")
                ResetPresetSelection()
                presetsDropdown:GenerateMenu()
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: "  .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' saved.")
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Please enter a valid preset name.")
            end
        end

        local function LoadPreset(presetName)
            presetName = presetName or (presetNameInput and presetNameInput:GetText())
            if _G[addon.CONST.DB_NAME].presets and _G[addon.CONST.DB_NAME].presets[presetName] then
                local preset = _G[addon.CONST.DB_NAME].presets[presetName]
                _G[addon.CONST.DB_NAME].mainFramePosition.point = preset.point
                _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo = preset.relativeTo
                _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint = preset.relativePoint
                _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = preset.xOfs
                _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = preset.yOfs
                addon.LoadMainFramePosition()
                presetNameInput:SetText("")
                ResetPresetSelection()
                presetsDropdown:GenerateMenu()
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' loaded.")
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. tostring(presetName) .. "' not found.")
            end
        end

        local function DeletePreset(presetName)
            presetName = presetName or (presetNameInput and presetNameInput:GetText())
            if _G[addon.CONST.DB_NAME].presets and _G[addon.CONST.DB_NAME].presets[presetName] then
                _G[addon.CONST.DB_NAME].presets[presetName] = nil
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' deleted.")
                presetNameInput:SetText("")
                ResetPresetSelection()
                presetsDropdown:GenerateMenu()
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. tostring(presetName) .. "' not found.")
            end
        end

        local presetLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        presetLabel:SetPoint("TOPLEFT", fineTuneLabel, "BOTTOMLEFT", 0, -75)
        presetLabel:SetText("Position Presets")

        -- Row 1: Existing presets
        local presetSelectLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        presetSelectLabel:SetPoint("TOPLEFT", presetLabel, "BOTTOMLEFT", 20, -10)
        presetSelectLabel:SetText("Preset:")

        presetsDropdown = CreateFrame(
            "DropdownButton",
            addon.CONST.ADDON_NAME .. "PresetDropdown",
            pagePosition,
            "WowStyle1DropdownTemplate"
        )
        presetsDropdown:SetPoint(
            "LEFT", presetSelectLabel, "RIGHT", 10, 0
        )
        presetsDropdown:SetWidth(160)
        presetsDropdown:SetDefaultText("Select Preset")
        presetsDropdown:SetupMenu(InitializePresetsDropdown)
        addon.presetsDropdown = presetsDropdown

        local function GetSelectedPresetName()
            return presetsDropdown.selectedPresetName
        end

        local loadPresetButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "LoadPresetButton", pagePosition, "UIPanelButtonTemplate")
        loadPresetButton:SetPoint("LEFT", presetsDropdown, "RIGHT", -6, 2)
        loadPresetButton:SetSize(70, 20)
        loadPresetButton:SetText("Load")
        loadPresetButton:SetScript("OnClick", function()
            local presetName = GetSelectedPresetName()
            if presetName then
                LoadPreset(presetName)
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Select a preset to load.")
            end
        end)

        local deletePresetButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "DeletePresetButton", pagePosition, "UIPanelButtonTemplate")
        deletePresetButton:SetPoint("LEFT", loadPresetButton, "RIGHT", 6, 0)
        deletePresetButton:SetSize(70, 20)
        deletePresetButton:SetText("Delete")
        deletePresetButton:SetScript("OnClick", function()
            local presetName = GetSelectedPresetName()
            if presetName then
                DeletePreset(presetName)
                ResetPresetSelection()
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Select a preset to delete.")
            end
        end)

        -- Row 2: Save / update preset name
        local presetNameLabel = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        presetNameLabel:SetPoint("TOPLEFT", presetSelectLabel, "BOTTOMLEFT", 0, -16)
        presetNameLabel:SetText("New preset name:")

        presetNameInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "PresetNameInput", pagePosition, "InputBoxTemplate")
        presetNameInput:SetPoint("LEFT", presetNameLabel, "RIGHT", 10, 0)
        presetNameInput:SetSize(183, 20)
        presetNameInput:SetAutoFocus(false)
        presetNameInput:SetMaxLetters(20)
        presetNameInput:SetText("")
        presetNameInput:SetJustifyH("CENTER")
        presetNameInput:SetCursorPosition(0)

        local savePresetButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "SavePresetButton", pagePosition, "UIPanelButtonTemplate")
        savePresetButton:SetPoint("LEFT", presetNameInput, "RIGHT", 10, 0)
        savePresetButton:SetSize(70, 20)
        savePresetButton:SetText("Save")
        savePresetButton:SetScript("OnClick", function()
            local presetName = presetNameInput:GetText()
            if addon.DEBUG then
                addon.DebugPrint("Debug: Retrieved presetName = ", presetName)
            end

            if presetName and presetName ~= "" then
                SavePreset(presetName)
                presetNameInput:SetText("")
                presetsDropdown:GenerateMenu()
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Enter a preset name to save.")
            end
        end)

        -- Tiny helper text (optional but helps new users a lot)
        local presetHelp = pagePosition:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        presetHelp:SetPoint("TOPLEFT", presetNameLabel, "BOTTOMLEFT", 0, -8)
        presetHelp:SetWidth(520)
        presetHelp:SetJustifyH("LEFT")
        presetHelp:SetText("Tip: Use the dropdown to select an existing preset to Load/Delete.\nUse Save to create or overwrite a preset by name.")
    end

    ------------------------------------------------
    -- INCLUDED TOYS PAGE (own scroll list)
    ------------------------------------------------
    do
        local toysScroll = CreateFrame("ScrollFrame", nil, pageToys, "UIPanelScrollFrameTemplate")
        toysScroll:SetPoint("TOPLEFT", toysTitle, "BOTTOMLEFT", 0, -24)
        toysScroll:SetPoint("BOTTOMRIGHT", pageToys, "BOTTOMRIGHT", -30, 0)

        local toysContent = CreateFrame("Frame", nil, toysScroll)
        toysContent:SetSize(520, 400)
        toysScroll:SetScrollChild(toysContent)

        local toyListHelp = pageToys:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        toyListHelp:SetPoint("TOPLEFT", toysTitle, "BOTTOMLEFT", 0, -12)
        toyListHelp:SetText("Select which " .. addon.CONST.ADDON_DISPLAY_NAME .. " toys are included.")

        -- checkbox cache
        local toyCheckBoxes = {}

        local function GetEntryName(entry)
            local itemID = entry.id
            local itemType = entry.type

            if itemType == "toy" then
                if C_ToyBox and C_ToyBox.GetToyInfo then
                    local _, toyName = C_ToyBox.GetToyInfo(itemID)
                    return toyName
                end
            elseif itemType == "item" then
                local itemName = C_Item.GetItemInfo(itemID)
                return itemName
            elseif itemType == "spell" then
                if C_Spell and C_Spell.GetSpellName then
                    return C_Spell.GetSpellName(itemID)
                end
            end
            return nil
        end

        local function EnsureToyDefaults(db)
            for _, entry in ipairs(addon.toyList or {}) do
                local itemID = entry.id
                if type(itemID) == "number" and db.toySettings[itemID] == nil then
                    -- same behavior as your main init: true if owned (for toys), else false
                    if entry.type == "toy" then
                        db.toySettings[itemID] = PlayerHasToy(itemID)
                    elseif entry.type == "item" then
                        db.toySettings[itemID] = (C_Item.GetItemCount(itemID) or 0) > 0
                    elseif entry.type == "spell" then
                        db.toySettings[itemID] = C_SpellBook.IsSpellInSpellBook(itemID, Enum.SpellBookSpellBank.Player, false)
                    else
                        db.toySettings[itemID] = false
                    end
                end
            end
        end

        local function RefreshIncludedToysUI()
            local db = SafeGetDB()
            EnsureToyDefaults(db)

            -- Rebuild available list
            if addon.InitializeAvailableToys then
                addon.InitializeAvailableToys()
            end

            -- Hide old checkboxes
            for _, cb in ipairs(toyCheckBoxes) do
                cb:Hide()
            end
            wipe(toyCheckBoxes)

            local y = -6
            local index = 0

            for _, entry in ipairs(addon.CONST.availableToys or {}) do
                local itemID = entry.id
                local itemType = entry.type

                local cb = CreateFrame("CheckButton", nil, toysContent, "InterfaceOptionsCheckButtonTemplate")
                cb:SetPoint("TOPLEFT", toysContent, "TOPLEFT", 8, y)
                cb.Text:SetText("Loading...")
                cb.Text:ClearAllPoints()
                cb.Text:SetPoint("LEFT", cb, "RIGHT", 5, 0)

                cb:SetChecked(db.toySettings[itemID] == true)
                cb:SetScript("OnClick", function(self)
                    if addon.ToggleToyInclusion then
                        addon.ToggleToyInclusion(itemID, self:GetChecked())
                    else
                        -- fallback, just set db (should exist in your addon though)
                        db.toySettings[itemID] = self:GetChecked()
                        if addon.InitializeIncludedToys then addon.InitializeIncludedToys() end
                        if addon.CreateToyButtons then addon.CreateToyButtons() end
                        if addon.UpdateToyButtonPositions then addon.UpdateToyButtonPositions() end
                    end
                end)

                -- Name resolution with a couple retries (matches your original idea)
                local function UpdateName(attemptsLeft)
                    local name = GetEntryName(entry)
                    if name and name ~= "" then
                        cb.Text:SetText(name)
                    else
                        if attemptsLeft > 0 then
                            C_Timer.After(0.5, function() UpdateName(attemptsLeft - 1) end)
                        else
                            cb.Text:SetText("Unknown")
                        end
                    end
                end
                UpdateName(5)

                table.insert(toyCheckBoxes, cb)

                index = index + 1
                y = y - 26
            end

            toysContent:SetHeight(math.max(400, (index * 26) + 20))
        end
    
        -- Expose so other modules can call it if needed
        addon.OptionsPanel.RefreshIncludedToysUI = RefreshIncludedToysUI

        -- Refresh when showing the panel (so beta toy unlock changes show up later too)
        optionsPanel:SetScript("OnShow", function()
            RefreshIncludedToysUI()
        end)
    end

    ------------------------------------------------
    -- ABOUT PAGE
    ------------------------------------------------
    do
        -- Author
        local authorLabel = pageAbout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        authorLabel:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -16)
        authorLabel:SetText("Authors:")

        local authorValue = pageAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        authorValue:SetPoint("LEFT", authorLabel, "RIGHT", 6, 0)
        authorValue:SetText("Wes (fork); Gerlock-ArgentDawn US (original)")

        -- Version (uses addon.CONST.ADDON_VERSION only)
        local versionLabel = pageAbout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        versionLabel:SetPoint("TOPLEFT", authorLabel, "BOTTOMLEFT", 0, -10)
        versionLabel:SetText("Version:")

        local versionValue = pageAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        versionValue:SetPoint("LEFT", versionLabel, "RIGHT", 6, 0)
        versionValue:SetText(tostring(addon.CONST.ADDON_VERSION or "Unknown"))

        -- Info / feedback text
        local helpText = pageAbout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        helpText:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -18)
        helpText:SetWidth(500)
        helpText:SetJustifyH("LEFT")
        helpText:SetText(
            "Independent fork maintained by Wes.\n" ..
            "Based on Hearthstone Toys 1.12.9 by Gerlock.\n\n" ..
            "Downloads and updates:\n" ..
            "https://www.curseforge.com/wow/addons/hearthstone-toys-continued\n\n" ..
            "Original project (credit):\n" ..
            "https://www.curseforge.com/wow/addons/hearthstone-toys\n\n" ..
            "For fork support, see the README supplied with this addon."
        )

        -- Latest changes (ADDON_UPDATES is a single string)
        local changesHeader = pageAbout:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        changesHeader:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -18)
        changesHeader:SetText("Latest Changes")

        local updatesBox = CreateFrame("Frame", nil, pageAbout, "BackdropTemplate")
        updatesBox:SetPoint("TOPLEFT", changesHeader, "BOTTOMLEFT", 0, -10)
        updatesBox:SetSize(431, 220)
        updatesBox:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        updatesBox:SetBackdropColor(0, 0, 0, 0.35)

        local updatesText = updatesBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        updatesText:SetPoint("TOPLEFT", updatesBox, "TOPLEFT", 10, -10)
        updatesText:SetPoint("TOPRIGHT", updatesBox, "TOPRIGHT", -10, -10)
        updatesText:SetJustifyH("LEFT")
        updatesText:SetJustifyV("TOP")

        local updates = addon.CONST.ADDON_UPDATES
        updatesText:SetText((updates and updates ~= "") and updates or "No recent updates listed.")
    end

    ------------------------------------------------
    -- Default page selection
    ------------------------------------------------
    ShowPage("General")

    ------------------------------------------------
    -- RefreshUI helper (used by Defaults)
    ------------------------------------------------
    function addon.OptionsPanel.RefreshUI()
        local db = SafeGetDB()

        if addon.generalSettingsCheckbox then
            addon.generalSettingsCheckbox:SetChecked(db.generalSettings.showWelcomeMessage)
        end
        if addon.showChatMessageCheckbox then
            addon.showChatMessageCheckbox:SetChecked(db.specificSettings.showChatMessage)
        end
        if addon.playSoundWhenFrameShownCheckbox then
            addon.playSoundWhenFrameShownCheckbox:SetChecked(db.generalSettings.playSoundWhenFrameShown)
        end
        if addon.showButtonOnMouseOverCheckbox then
            addon.showButtonOnMouseOverCheckbox:SetChecked(db.specificSettings.showButtonOnMouseOver)
        end
        if addon.lockPositionCheckbox then
            addon.lockPositionCheckbox:SetChecked(db.generalSettings.lockPosition)
        end
        if addon.xPositionInput then
            addon.xPositionInput:SetText(tostring(db.mainFramePosition.xOfs or 0))
        end
        if addon.yPositionInput then
            addon.yPositionInput:SetText(tostring(db.mainFramePosition.yOfs or 0))
        end
        if addon.sizeSlider then
            addon.sizeSlider:SetValue(db.specificSettings.buttonSize or 44)
        end
        if addon.sizeInput then
            addon.sizeInput:SetText(tostring(math.floor(db.specificSettings.buttonSize or 44)))
        end

        if addon.OptionsPanel.RefreshIncludedToysUI then
            addon.OptionsPanel.RefreshIncludedToysUI()
        end
    end

    ------------------------------------------------
    -- Register with Blizzard Settings
    ------------------------------------------------
    local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
    addon.OptionsPanel.optionsCategoryId = category:GetID()
    Settings.RegisterAddOnCategory(category)
end
