-- Declare the addon namespace
HearthstoneToysContinued = {}
local addonName, addon = ...

-- Define a debug flag
addon.DEBUG = false  -- Set to true to enable debug prints

---------------
-- Constants --
---------------
addon.CONST = {
    ADDON_NAME = "HearthstoneToysContinued",
    ADDON_DISPLAY_NAME = "Hearthstone Toys Continued",
    DB_NAME = "HearthstoneToysContinuedDB",
    ADDON_ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Rune_01",
    TOY_FRAME_SHOW_SOUND_ID = 2022070,
    TOY_FRAME_HIDE_SOUND_ID = 2906065,
    ADDON_TEXT_COLOR = "|cFF00a7ff",
    DEBUG_TEXT_COLOR = "|cFFff0000",
    RESET_COLOR = "|r",
    mainFrame,
    toyButtons = {},
    availableToys = {},
    includeToys = {},
    presetNameInput,
    presetsDropdown,
    xPositionInput, yPositionInput,
    UpdateCooldown,
    optionsCategoryId,
        ADDON_VERSION = "1.2.1", -- Update this with each release
        ADDON_UPDATES = "Version 1.2.1\n\n" ..
            "NEW: Hiveborne Hearthstone, Shadeweaver's Hearthstone, and Personal Key to the Arcantina.\n\n" ..
            "NEW: Teleport: Moonglade, Dreamwalk, Death Gate, Zen Pilgrimage, and Teleport: Hall of the Guardian.\n\n" ..
            "NEW: Housing teleport and return travel, with matching icons, tooltips, and cooldowns.\n\n" ..
            "New class travel and housing entries start excluded from random selection. Defaults respects these exclusions.\n\n" ..
            "Version 1.2.0\n\n" ..
            "NEW: Choose separately which Hearthstones appear in the list and which are used randomly.\n\n" ..
            "NEW: Clear column headings for Hearthstone, Show in list, and Random.\n\n" ..
            "Keep Dalaran and Garrison available for manual use without including them in random selection.\n\n" ..
            "Existing selections are preserved when upgrading. Defaults and newly acquired toys enable both selections.",
    WELCOME_MESSAGE = "Type '/hstc' for options. Development maintained by Wes, based on Gerlock's Hearthstone Toys. See the fork README for project and support details.",
}

addon.flavorTextOutputChannel = "private"
addon.requiresTargetForFlavor = false

-- Always track the GCD by spell ID
addon.COOLDOWN_SPELL_ID = 61304

-- Hearthstone shared item CD (keep this for Hearthstone Toys Continued)
addon.COOLDOWN_ITEM_ID = 6948

--------------------------
-- List of toy item IDs --
--------------------------
addon.toyList = {
    {id = 54452, type = "toy"}, -- Ethereal Portal
    {id = 64488, type = "toy"}, -- The Innkeeper's Daughter
    {id = 93672, type = "toy"}, -- Dark Portal
    {id = 110560, type = "toy"}, -- Garrison Hearthstone
    {id = 140192, type = "toy"}, -- Dalaran Hearthstone
    {id = 142542, type = "toy"}, -- Tome of Town Portal
    {id = 162973, type = "toy"}, -- Greatfather Winter's Hearthstone
    {id = 163045, type = "toy"}, -- Headless Horseman's Hearthstone
    {id = 163206, type = "toy"}, -- Weary Spirit Binding
    {id = 165669, type = "toy"}, -- Lunar Elder's Hearthstone
    {id = 165670, type = "toy"}, -- Peddlefeet's Lovely Hearthstone
    {id = 165802, type = "toy"}, -- Noble Gardener's Hearthstone
    {id = 166746, type = "toy"}, -- Fire Eater's Hearthstone
    {id = 166747, type = "toy"}, -- Brewfest Reveler's Hearthstone
    {id = 168907, type = "toy"}, -- Holographic Digitalization Hearthstone
    {id = 172179, type = "toy"}, -- Eternal Traveler's Hearthstone
    {id = 180290, type = "toy"}, -- Night Fae Hearthstone
    {id = 182773, type = "toy"}, -- Necrolord Hearthstone
    {id = 183716, type = "toy"}, -- Venthyr Sinstone
    {id = 184353, type = "toy"}, -- Kyrian Hearthstone
    {id = 188952, type = "toy"}, -- Dominated Hearthstone
    {id = 190196, type = "toy"}, -- Enlightened Hearthstone
    {id = 190237, type = "toy"}, -- Broker Translocation Matrix
    {id = 193588, type = "toy"}, -- Timewalker's Hearthstone
    {id = 200630, type = "toy"}, -- Ohnir Windsage's Hearthstone
    {id = 206195, type = "toy"}, -- Path of the Naaru
    {id = 208704, type = "toy"}, -- Deepdweller's Earthen Hearthstone
    {id = 209035, type = "toy"}, -- Hearthstone of the Flame
    {id = 210455, type = "toy"}, -- Draenic Hologem
    {id = 212337, type = "toy"}, -- Stone of the Hearth
    {id = 228940, type = "toy"}, -- Notorious Thread's Hearthstone
    {id = 236687, type = "toy"}, -- Explosive Hearthstone
    {id = 246565, type = "toy"}, -- Cosmic Hearthstone
    {id = 245970, type = "toy"}, -- P.O.S.T. Master's Express Hearthstone
    {id = 235016, type = "toy"}, -- Redeployment Module
    {id = 265100, type = "toy"}, -- Corewarden’s Hearthstone
    {id = 257736, type = "toy"}, -- Lightcalled Hearthstone
    {id = 263933, type = "toy"}, -- Preyseeker’s Hearthstone
    {id = 263489, type = "toy"}, -- Naaru's Enfold
    {id = 264367, type = "toy"}, -- Mycomancer's Hearthspore
    {id = 281136, type = "toy"}, -- Hiveborne Hearthstone
    {id = 281615, type = "toy"}, -- Shadeweaver's Hearthstone
    {id = 253629, type = "toy"}, -- Personal Key to the Arcantina
    {id = 6948, type = "item"}, -- Default Hearthstone
    {id = 37118, type = "item"}, -- Scroll of Recall
    {id = 44314, type = "item"}, -- Scroll of Recall II
    {id = 44315, type = "item"}, -- Scroll of Recall III
    -- Enable when patch 12.1.7 goes live:
    -- {id = 288912, type = "toy"}, -- Wood-Cursed Hearthstone
    {id = 556, type = "spell"}, -- Astral Recall
    {id = 18960, type = "spell", randomDefault = false}, -- Teleport: Moonglade (Druid)
    {id = 193753, type = "spell", randomDefault = false}, -- Dreamwalk (Druid)
    {id = 50977, type = "spell", randomDefault = false}, -- Death Gate (Death Knight)
    {id = 126892, type = "spell", randomDefault = false}, -- Zen Pilgrimage (Monk)
    {id = 193759, type = "spell", randomDefault = false}, -- Teleport: Hall of the Guardian (Mage)
    {id = 1233637, type = "housing", randomDefault = false}, -- Teleport Home
}

--------------------
-- Flavor Message --
--------------------
addon.FLAVOR_MESSAGES = {
    "A wise mage once said, 'The fireball spell is the best way to say hello!'",
    "Beware the Dark Iron Dwarves. Their brew is stronger than their armor!",
    "The real secret of the Shaman's power is the sound of the totem's beat!",
    "Rogues don’t need a reason to stab people, but it's usually money.",
    "Hunters always know where their prey is, especially when they're hungry.",
    "Priests heal, but they never forget the time you got them killed!",
    "Warriors love their battles, but they secretly crave a good meal.",
    "Paladins are always prepared. They carry extra blessings just in case!",
    "Mages like to keep their spells hot, and their puns even hotter!",
    "Druids are all about nature, but they don’t mind the occasional moonfire!",
    "Druids are one with nature, but they can’t resist a good bear hug!",
    "Mages freeze their enemies, but their jokes are the real cold snap!",
    "Paladins have a hammer for every occasion... and a Light to match!",
    "Warriors live by the sword... and die by the bigger sword.",
    "Priests smite their foes with holy wrath, but they're really just practicing for bingo night.",
    "Rogues vanish, but your wallet vanishes faster!",
    "Shamans summon storms, but they’re the real force of nature!",
    "Hunters’ pets are loyal, but don't ask them to fetch!",
    "Warlocks always have friends in low places... like the Twisting Nether.",
    "Warlocks don’t just summon demons; they have them on speed dial.",
    "When a Warlock says 'let's make a pact,' it's best to read the fine print.",
    "Monks may be zen, but they’ll still knock you out with a keg!",
    "Demon Hunters have vision like no other-just don't ask how they lost their depth perception.",
    "Demon Hunters don't just stare; they glare right through you!",
    "Demon Hunters leap before they look... and it usually works out!",
    "Death Knights don't need a heart to break yours!",
    "Gnomes may be small, but their egos are perfectly sized!",
    "Dwarves believe that anything can be fixed with a hammer... even bad jokes.",
    "Orcs don't need coffee—they wake up ready to smash something.",
    "Tauren always know where the grass is greener. It's their job to find it!",
    "Blood Elves have perfected the art of looking fabulous while judging your fashion sense.",
    "Trolls might seem laid-back, but they take their head-hunting very seriously.",
    "Humans are great diplomats, mostly because they’ve had so much practice apologizing.",
    "Undead don’t need beauty sleep, but it’s still polite not to mention it.",
    "Goblins believe that 'more explosions' is the solution to any problem.",
    "For Goblins, safety regulations are just suggestions—expensive ones!",
    "Even after thousands of years, Night Elves are still trying to figure out why their hair glows at night.",
}

-- Saved variable to store settings
_G[addon.CONST.DB_NAME] = _G[addon.CONST.DB_NAME] or {}
_G[addon.CONST.DB_NAME].generalSettings = _G[addon.CONST.DB_NAME].generalSettings or {}
_G[addon.CONST.DB_NAME].mainFramePosition = _G[addon.CONST.DB_NAME].mainFramePosition or {}
_G[addon.CONST.DB_NAME].specificSettings = _G[addon.CONST.DB_NAME].specificSettings or {}
_G[addon.CONST.DB_NAME].toySettings = _G[addon.CONST.DB_NAME].toySettings or {}
_G[addon.CONST.DB_NAME].presets = _G[addon.CONST.DB_NAME].presets or {}

-- Default settings
addon.defaults = {
    generalSettings = {
        showWelcomeMessage = true,
        playSoundWhenFrameShown = true,
        lockPosition = false,
        version = addon.CONST.ADDON_VERSION,
    },
    mainFramePosition = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = 0,
    },
    specificSettings = {
        showChatMessage = true,
        showButtonOnMouseOver = false,
        toyFramePosition = "LEFT",
        buttonSize = 44,
        reverseClickActions = false,
    },
}

-- Feature-specific notice ID. This is intentionally independent of the addon version.
-- Keep the acknowledgement outside addon.defaults so restoring preferences
-- does not cause an already acknowledged notice to appear again.
local CLICK_CONTROLS_NOTICE_ID = "travel-options-v1"
local CLICK_CONTROLS_POPUP_KEY = "HEARTHSTONETOYSCONTINUED_CLICK_CONTROLS_NOTICE"

StaticPopupDialogs[CLICK_CONTROLS_POPUP_KEY] = {
    text = "|cFF00a7ffHearthstone Toys Continued|r\n\n" ..
        "What's New in 1.2.1\n\n" ..
        "|cFFFFD100More travel options|r\n" ..
        "Added Hiveborne Hearthstone, Shadeweaver's Hearthstone, " ..
        "and Personal Key to the Arcantina.\n\n" ..
        "Added class travel spells and housing teleport with return travel. " ..
        "New class travel and housing entries start excluded from random selection.\n\n" ..
        "|cFFFFD100Also included from 1.2.0|r\n" ..
        "Choose which Hearthstones appear in your list and which can be used randomly.\n\n" ..
        "Keep Dalaran and Garrison available for manual use without including them in random selection.\n\n" ..
        "|cFFFFD100Your existing choices are preserved|r\n" ..
        "Both columns initially match your previous selections when upgrading from before 1.2.0. " ..
        "Change them independently under Included Toys.\n\n" ..
        "Right-click the addon button or type /hstc to open settings.",
    button1 = "Got it!",
    OnAccept = function()
        _G[addon.CONST.DB_NAME].lastSeenFeatureNotice = CLICK_CONTROLS_NOTICE_ID
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Initialize saved variables
function addon.InitializeAddon()
    if addon.DEBUG then
        addon.DebugPrint("addon.InitializeAddon called")
    end
    -- Initialize database using defaults
    for key, value in pairs(addon.defaults) do
        if type(value) == "table" then
            if not _G[addon.CONST.DB_NAME][key] then
                _G[addon.CONST.DB_NAME][key] = {}
            end
            for nestedKey, nestedValue in pairs(value) do
                if _G[addon.CONST.DB_NAME][key][nestedKey] == nil then
                    _G[addon.CONST.DB_NAME][key][nestedKey] = nestedValue
                end
            end
        else
            if _G[addon.CONST.DB_NAME][key] == nil then
                _G[addon.CONST.DB_NAME][key] = value
            end
        end
    end

    -- Set buttonSize to a local variable for easy access
    addon.buttonSize = _G[addon.CONST.DB_NAME].specificSettings.buttonSize

    -- Initialize toySettings with PlayerHasToy validation
    for _, toyListEntry in ipairs(addon.toyList) do
        local itemID = toyListEntry.id
        if type(itemID) == "number" and _G[addon.CONST.DB_NAME].toySettings[itemID] == nil then
            -- Default to true only if the player owns the toy
            _G[addon.CONST.DB_NAME].toySettings[itemID] = PlayerHasToy(itemID)
        end
    end

    -- Copy existing selections into independent random settings once.
    local db = _G[addon.CONST.DB_NAME]
    db.randomToySettings = db.randomToySettings or {}

    for _, entry in ipairs(addon.toyList) do
        local itemID = entry.id

        if db.randomToySettings[itemID] == nil then
            db.randomToySettings[itemID] =
                entry.randomDefault ~= false
                and db.toySettings[itemID] == true
        end
    end

    -- Initialize components
    addon.UIFrames.Initialize()
    addon.OptionsPanel.Initialize()

    -- Display once after initialization, and only mark it seen on acknowledgement.
    -- Delaying avoids competing with the initial UI setup.
    if _G[addon.CONST.DB_NAME].lastSeenFeatureNotice ~= CLICK_CONTROLS_NOTICE_ID then
        C_Timer.After(1, function()
            if _G[addon.CONST.DB_NAME].lastSeenFeatureNotice ~= CLICK_CONTROLS_NOTICE_ID then
                StaticPopup_Show(CLICK_CONTROLS_POPUP_KEY)
            end
        end)
    end

    C_Timer.After(0.2, function()
        -- Register Slash Command
        SLASH_HSTC1 = "/hstc"
        SlashCmdList["HSTC"] = function(msg)
            if addon.OptionsPanel.optionsCategoryId then
                -- Open the options panel using the registered category ID
                Settings.OpenToCategory(addon.OptionsPanel.optionsCategoryId)
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Options panel not registered yet.")
            end
        end
    end)
end
