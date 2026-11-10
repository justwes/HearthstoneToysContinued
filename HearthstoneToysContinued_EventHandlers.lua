-- Access the addon namespace
local addonName, addon = ...

-- Ensure the EventHandlers module is part of the addon namespace
addon.EventHandlers = {}

-- Loading-screen-aware suppression
local inLoadingScreen = false
local suppressUntil = 0    -- GetTime()-based deadline after screen closes
local postLoadBuffer = 4   -- seconds; we can tune later

-- Define an initialization in progress flag
addon.isInitializing = true

-- Define a debounce
local toyUpdateDebounceActive = false

----------------------------
-- Function for Player Login
----------------------------
local function PlayerLogin()
    C_Timer.After(1, function()
        addon.LoadMainFramePosition()
        addon.AddonUpdatedMessage()
    end)
    C_Timer.After(2, function()  -- delay
        addon.InitializeAvailableToys()
        addon.InitializeIncludedToys()
        addon.CreateToyFrame()
        addon.CreateToyButtons()
        addon.UpdateToyButtonPositions()
        addon.UpdateCooldown()
        if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end
        addon.mainFrame:SetSize(addon.buttonSize, addon.buttonSize)
        addon.PrintWelcomeMessage()
        C_Timer.After(0.1, addon.UpdateVisibility)
    end)
end

-- Centralized suppression check for TOYS_UPDATED
local function ShouldSuppressToyUpdates()
    if addon.isInitializing then
        return true, "init"
    end
    if inLoadingScreen or GetTime() < suppressUntil then
        local remaining = math.max(0, suppressUntil - GetTime())
        return true, ("loading (remaining=%.2fs)"):format(remaining)
    end
    return false, nil
end

-- Track whether character startup has been initiated
addon.startupInitiated = false

local function StartAddonForCharacter()
    if addon.startupInitiated then
        return
    end

    addon.startupInitiated = true
    addon.isInitializing = true

    C_Timer.After(1, function()
        PlayerLogin()
    end)

    C_Timer.After(2, function()
        addon.isInitializing = false

        if addon.DEBUG then
            addon.DebugPrint("Initialization complete. TOYS_UPDATED events will now be processed.")
        end
    end)
end

------------------
-- Register events
------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TOYS_UPDATED")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addon.CONST.ADDON_NAME then
        -- Your addon is loaded, initialize saved variables here
        addon.InitializeAddon()
        eventFrame:UnregisterEvent("ADDON_LOADED") -- Unregister to prevent redundant calls
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            StartAddonForCharacter()
        end)
    elseif event == "LOADING_SCREEN_ENABLED" then
        inLoadingScreen = true
        -- While loading, block TOYS_UPDATED entirely
        suppressUntil = math.huge

    elseif event == "LOADING_SCREEN_DISABLED" then
        inLoadingScreen = false
        suppressUntil = GetTime() + postLoadBuffer
        if addon.DEBUG then
            addon.DebugPrint(("Loading screen disabled. Buffer=%.1fs; now=%.2f; until=%.2f")
                :format(postLoadBuffer, GetTime(), suppressUntil))
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not addon.startupInitiated then
            C_Timer.After(2, function()
                StartAddonForCharacter()
            end)
            return
        end

        C_Timer.After(4, function()
            addon.UpdateCooldown()
            if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end
            if #addon.CONST.toyButtons == 0 then
                if addon.DEBUG then
                    addon.DebugPrint("PLAYER_ENTERING_WORLD: Rebuilding toy buttons...")
                end
                addon.CreateToyFrame()
                addon.CreateToyButtons()
            end
        end)
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if not addon.startupInitiated then return end

        if addon.DEBUG then print("SPELL_UPDATE_COOLDOWN") end
        addon.UpdateCooldown()
        if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end

    elseif event == "BAG_UPDATE_COOLDOWN" then
        if not addon.startupInitiated then return end

        if addon.DEBUG then print("BAG_UPDATE_COOLDOWN") end
        addon.UpdateCooldown()
        if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end

    elseif event == "TOYS_UPDATED" then
        if not addon.startupInitiated then return end

        local suppress, reason = ShouldSuppressToyUpdates()
        if suppress then
            if addon.DEBUG then addon.DebugPrint("TOYS_UPDATED suppressed: " .. reason) end
            return
        end
        if not toyUpdateDebounceActive then
            toyUpdateDebounceActive = true

            if addon.DEBUG then
                addon.DebugPrint("TOYS_UPDATED: Debounced call scheduled.")
            end

            -- Wait briefly to allow a burst of events to settle
            C_Timer.After(0.5, function()
                toyUpdateDebounceActive = false

                if addon.DEBUG then
                    addon.DebugPrint("TOYS_UPDATED: Executing HandleNewToyAcquisition.")
                end

                addon.HandleNewToyAcquisition()

                -- Retry toyFrame creation if needed
                if #addon.CONST.toyButtons == 0 then
                    if addon.DEBUG then
                        addon.DebugPrint("TOYS_UPDATED: No toy buttons found, retrying CreateToyFrame...")
                    end
                    addon.CreateToyFrame()
                end
            end)
        else
            if addon.DEBUG then
                addon.DebugPrint("TOYS_UPDATED: Skipped due to active debounce.")
            end
        end
    end
end)