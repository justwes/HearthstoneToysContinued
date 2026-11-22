local addonName = "HearthstoneToysContinued"
local existingToy, newToy = 101, 102
local owned = { [existingToy] = true }
local db = {
    toySettings = { [existingToy] = false, [newToy] = false },
    randomToySettings = { [existingToy] = false, [newToy] = false },
}
_G.HearthstoneToysContinuedDB = db

local function noop() end

local eventFrame
function CreateFrame()
    return {
        RegisterEvent = noop,
        SetScript = function(self, script, handler)
            assert(script == "OnEvent")
            self.OnEvent = handler
            eventFrame = self
        end,
    }
end

function PlayerHasToy(id)
    return owned[id] == true
end

function GetTime()
    return 1
end

function wipe(values)
    for key in pairs(values) do
        values[key] = nil
    end
end

C_Timer = {
    After = function(_, callback)
        callback()
    end,
}
C_ToyBox = {
    GetToyInfo = function(id)
        assert(id == newToy, "Only the newly acquired toy should be announced")
        return id, "Test Hearthstone"
    end,
}

local addon = {
    CONST = {
        ADDON_NAME = addonName,
        ADDON_DISPLAY_NAME = addonName,
        DB_NAME = "HearthstoneToysContinuedDB",
        ADDON_TEXT_COLOR = "",
        RESET_COLOR = "",
        availableToys = {},
    },
    toyList = {
        { id = existingToy, type = "toy" },
        { id = newToy, type = "toy" },
    },
    mainFrame = { SetSize = noop },
    buttonSize = 32,
}

assert(loadfile("HearthstoneToysContinued_Functions.lua"))(addonName, addon)

-- Keep the real acquisition and availability logic. Stub the UI.
addon.LoadMainFramePosition = noop
addon.AddonUpdatedMessage = noop
addon.InitializeIncludedToys = noop
addon.CreateToyFrame = noop
addon.CreateToyButtons = noop
addon.UpdateCooldown = noop
addon.PrintWelcomeMessage = noop
addon.UpdateVisibility = noop

local refreshes, highlights = 0, 0
addon.RefreshUI = function() refreshes = refreshes + 1 end
addon.HighlightIcon = function() highlights = highlights + 1 end

local consolePrint = print
local messages = {}
print = function(message)
    messages[#messages + 1] = message
end

assert(loadfile("HearthstoneToysContinued_EventHandlers.lua"))(addonName, addon)

eventFrame:OnEvent("PLAYER_LOGIN")
assert(not addon.isInitializing, "Startup should complete")
assert(refreshes == 0 and #messages == 0, "Startup should not announce an acquisition")
assert(db.toySettings[existingToy] == false, "Startup should preserve Show")
assert(db.randomToySettings[existingToy] == false, "Startup should preserve Random")

owned[newToy] = true
eventFrame:OnEvent("TOYS_UPDATED")
assert(db.toySettings[newToy] == true, "First acquisition should enable Show")
assert(db.randomToySettings[newToy] == true, "First acquisition should enable Random")
assert(#addon.CONST.availableToys == 2, "Both owned toys should be available")
assert(refreshes == 1 and highlights == 1, "Acquisition should refresh and highlight once")
assert(#messages == 1 and messages[1]:find("New toy acquired: Test Hearthstone", 1, true),
    "Acquisition should announce the new toy once")

db.toySettings[newToy] = false
db.randomToySettings[newToy] = false
eventFrame:OnEvent("TOYS_UPDATED")
assert(db.toySettings[newToy] == false and db.randomToySettings[newToy] == false,
    "A repeat event should preserve the player's choices")
assert(refreshes == 1 and highlights == 1 and #messages == 1,
    "A repeat event should have no acquisition side effects")

consolePrint("Toy acquisition test passed")