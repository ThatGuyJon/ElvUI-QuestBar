local E, L, V, P, G = unpack(ElvUI)  -- ElvUI globals
local AB = E:GetModule("ActionBars")  -- ActionBars module
local QB = E:NewModule("QuestBar", "AceEvent-3.0", "AceHook-3.0")  -- Create the module

-- LibStub for plugin registration
local EP = LibStub("LibElvUIPlugin-1.0")

-- Default config values (stored in ElvUI's profile) - QuestBar disabled by default
P["QuestBar"] = {
    enabled = false,  -- Disabled on first load
    maxButtons = 12,
    autoScan = true,
}

-- Set up bar defaults for QuestBar (overrides Bar 10)
AB.barDefaults["bar10"] = {
    page = 10,
    bindButtons = "ELVUIQUESTBARBUTTON",
    conditions = "",
    position = "BOTTOM,UIParent,BOTTOM,0,120",
    enabled = false,
    buttons = 12,
    buttonsPerRow = 12,
    point = "BOTTOMLEFT",
    backdrop = false,
    heightMult = 1,
    widthMult = 1,
    buttonSize = 32,
    buttonHeight = 32,
    buttonSpacing = 2,
    backdropSpacing = 2,
    frameLevel = 1,
    frameStrata = "LOW",
    alpha = 1,
    inheritGlobalFade = false,
    showGrid = false,
    paging = {},
    visibility = "[vehicleui] hide; show",
}

-- Local variables
local incombat = false
local questItems = {}
local isTestMode = false
local itemCount = 0  -- Track item count for updates
local moverTextTimer = nil  -- Timer for updating mover text

-- Function to scan bags for quest items
local function ScanBags()
    if not E.db.QuestBar.autoScan and not isTestMode then return end
    wipe(questItems)
    if isTestMode then
        -- Populate with dummy item IDs for test mode (use real item IDs that exist)
        local testItems = {134414, 135349, 133971, 132089, 133662, 134400, 132620, 133739, 134075, 132761, 133693, 134519}  -- Texture IDs as placeholders
        for i = 1, E.db.QuestBar.maxButtons do
            if testItems[i] then
                table.insert(questItems, {itemID = testItems[i], bag = nil, slot = nil})  -- Dummy data
            end
        end
    else
        -- Scan bags for quest items
        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemID = GetContainerItemID(bag, slot)
                if itemID and GetContainerItemQuestInfo(bag, slot) and GetItemSpell(itemID) then
                    table.insert(questItems, {bag = bag, slot = slot, itemID = itemID})
                end
            end
        end
    end
end

-- Function to update the QuestBar
local function UpdateQuestBar()
    if not E.db.QuestBar.enabled or incombat then return end

    -- Check if ActionBars db is ready
    if not AB.db then
        E:Print("QuestBar: ActionBars db not ready, skipping update.")
        return
    end

    ScanBags()
    local bar = AB.handledBars["bar10"]
    if not bar then
        E:Print("QuestBar: Bar not created, skipping update.")
        return
    end

    local newItemCount = #questItems
    if newItemCount ~= itemCount then
        ClearCursor()

        -- Clear existing actions
        for _, button in ipairs(bar.buttons) do
            if button._state_action then
                PickupAction(button._state_action)
                ClearCursor()
            end
            button:SetAttribute("itemID", nil)
        end

        -- Place new items
        for i = 1, math.min(newItemCount, E.db.QuestBar.maxButtons) do
            local questItem = questItems[i]
            local button = bar.buttons[i]
            if button and button._state_action then
                if isTestMode then
                    -- For test mode, just set a dummy action (no real item)
                    button:SetAttribute("type", "macro")
                    button:SetAttribute("macrotext", "/run print('Test Icon " .. i .. "')")
                else
                    PickupContainerItem(questItem.bag, questItem.slot)
                    PlaceAction(button._state_action)
                    ClearCursor()
                    button:SetAttribute("itemID", questItem.itemID)
                end
            end
        end

        -- Update bar visibility and size
        if not AB.db["bar10"] then
            AB.db["bar10"] = CopyTable(AB.barDefaults["bar10"])
        end
        local bar_db = AB.db["bar10"]
        bar_db.buttons = newItemCount > 0 and math.min(newItemCount, E.db.QuestBar.maxButtons) or 0
        bar_db.visibility = newItemCount == 0 and "hide" or "[vehicleui] hide; show"
        AB:PositionAndSizeBar("bar10")

        itemCount = newItemCount
    end
end



-- Function to create the QuestBar
local function CreateQuestBar()
    if AB.handledBars["bar10"] then return end

    -- Ensure db is initialized (double-check)
    if not AB.db then
        E:Print("QuestBar: ActionBars db not ready, cannot create bar.")
        return
    end
    if not AB.db["bar10"] then
        AB.db["bar10"] = CopyTable(AB.barDefaults["bar10"])
    end

    local bar = AB:CreateBar("bar10")
    AB:PositionAndSizeBar("bar10")
    E:CreateMover(bar, "ElvAB_10", "QuestBar Anchor", nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,bar10")

    -- Hook buttons to prevent dragging quest items
    for _, button in pairs(bar.buttons) do
        button:DisableDragNDrop(true)
    end
end

-- Event handlers
function QB:OnInitialize()
    -- Ensure settings are initialized and saved to ElvUI's SavedVariables
    if not E.db.QuestBar then
        E.db.QuestBar = CopyTable(P.QuestBar)
    end
    
    -- Initialize the bar db now that modules are set up (with retry if needed)
    local function InitBarDb()
        if AB.db then
            if not AB.db["bar10"] then
                AB.db["bar10"] = CopyTable(AB.barDefaults["bar10"])
            end
        else
            E:ScheduleTimer(InitBarDb, 1)  -- Retry in 1 second
        end
    end
    InitBarDb()
    
    -- Register with libElvUIPlugin-1.0
    EP:RegisterPlugin("ElvUI_QuestBar", function()
        -- Add config options here
        E.Options.args.QuestBar = {
            type = "group",
            name = "|cff00ff00QuestBar|r",  -- Green color for the tab name
            order = 100,  -- Position in ElvUI options
            childGroups = "tab",
            args = {
                enable = {
                    order = 1,
                    type = "toggle",
                    name = "Enable QuestBar",
                    desc = "Toggle the QuestBar on/off. This overrides Bar 10.",
                    get = function(info) return E.db.QuestBar.enabled end,
                    set = function(info, value)
                        E.db.QuestBar.enabled = value
                        QB:Toggle()
                    end,
                },
                general = {
                    order = 2,
                    type = "group",
                    name = "General",
                    disabled = function() return not E.db.QuestBar.enabled end,
                    args = {
                        maxButtons = {
                            order = 1,
                            type = "range",
                            name = "Max Buttons",
                            desc = "Maximum number of buttons to show on the QuestBar.",
                            min = 1, max = 12, step = 1,
                            get = function(info) return E.db.QuestBar.maxButtons end,
                            set = function(info, value)
                                E.db.QuestBar.maxButtons = value
                                UpdateQuestBar()
                            end,
                        },
                        autoScan = {
                            order = 2,
                            type = "toggle",
                            name = "Auto-Scan Bags",
                            desc = "Automatically scan bags for quest items on updates.",
                            get = function(info) return E.db.QuestBar.autoScan end,
                            set = function(info, value)
                                E.db.QuestBar.autoScan = value
                                if value then UpdateQuestBar() end
                            end,
                        },
                        scanNow = {
                            order = 3,
                            type = "execute",
                            name = "Scan Bags Now",
                            desc = "Manually scan bags and update the QuestBar.",
                            func = function()
                                isTestMode = false
                                UpdateQuestBar()
                            end,
                        },

                        showTestIcons = {
                            order = 5,
                            type = "execute",
                            name = "Show Test Icons",
                            desc = "Display dummy icons on the QuestBar for testing (overrides bag scan). Icons will disappear after 5 seconds.",
                            func = function()
                                if not AB.handledBars["bar10"] then
                                    CreateQuestBar()
                                end
                                isTestMode = true
                                UpdateQuestBar()
                                E:ScheduleTimer(function()
                                    isTestMode = false
                                    UpdateQuestBar()
                                end, 5)
                            end,
                        },
                        backdrop = {
                            order = 6,
                            type = "toggle",
                            name = "Backdrop",
                            desc = "Enable/disable the backdrop for the QuestBar.",
                            get = function(info) return AB.db["bar10"] and AB.db["bar10"].backdrop end,
                            set = function(info, value)
                                if AB.db["bar10"] then
                                    AB.db["bar10"].backdrop = value
                                    AB:PositionAndSizeBar("bar10")
                                end
                            end,
                        },
                    },
                },
            },
        }

        -- Hide Bar 10 in options if QuestBar is enabled
        if E.db.QuestBar.enabled then
            if E.Options.args.actionbar and E.Options.args.actionbar.args.bar10 then
                E.Options.args.actionbar.args.bar10.hidden = true
                if E.RefreshGUI then E:RefreshGUI() end
            end
        end
    end)
    
    self:RegisterEvent("BAG_UPDATE", function()
        if not self.updatePending then
            self.updatePending = E:ScheduleTimer(function() self.updatePending = nil UpdateQuestBar() end, 0.1)
        else
            E:CancelTimer(self.updatePending)
            self.updatePending = E:ScheduleTimer(function() self.updatePending = nil UpdateQuestBar() end, 0.1)
        end
    end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateQuestBar)
end

function QB:Toggle()
    local db = E.db.QuestBar
    if db.enabled then
        -- Check if ActionBars db is ready
        if not AB.db then
            E:Print("QuestBar: ActionBars db not ready, cannot enable. Try reloading UI (/reload).")
            return
        end

        -- Force the position to QuestBar defaults
        if AB.db["bar10"] then
            AB.db["bar10"].position = AB.barDefaults["bar10"].position
        end

        CreateQuestBar()

        -- Ensure the mover exists
        local bar = AB.handledBars["bar10"]
        if bar and not E.CreatedMovers["ElvAB_10"] then
            E:CreateMover(bar, "ElvAB_10", "QuestBar Anchor", nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,bar10")
        end

        if not AB.db["bar10"] then
            AB.db["bar10"] = CopyTable(AB.barDefaults["bar10"])
        end
        AB.db["bar10"].enabled = true

        -- Hide Bar 10 in ElvUI options
        if E.Options.args.actionbar and E.Options.args.actionbar.args.bar10 then
            E.Options.args.actionbar.args.bar10.hidden = true
            if E.RefreshGUI then E:RefreshGUI() end
        end

        self:RegisterEvent("PLAYER_REGEN_DISABLED", function() incombat = true end)
        self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
            incombat = false
            UpdateQuestBar()
        end)

        if E.CreatedMovers["ElvAB_10"] then
            E:EnableMover("ElvAB_10")
        end

        -- Update mover text to QuestBar Anchor (delayed to ensure text is available after enabling)
        if moverTextTimer then E:CancelTimer(moverTextTimer) end
        moverTextTimer = E:ScheduleTimer(function()
            if E.CreatedMovers["ElvAB_10"] and E.CreatedMovers["ElvAB_10"].text and E.CreatedMovers["ElvAB_10"].text.SetText then
                E.CreatedMovers["ElvAB_10"].text:SetText("QuestBar Anchor")
            end
            moverTextTimer = nil
        end, 0.5)

        UpdateQuestBar()
    else
        self:UnregisterAllEvents()
        local bar = AB.handledBars["bar10"]

        -- Unhide Bar 10 in ElvUI options
        if E.Options.args.actionbar and E.Options.args.actionbar.args.bar10 then
            E.Options.args.actionbar.args.bar10.hidden = false
            if E.RefreshGUI then E:RefreshGUI() end
        end

        if bar and bar.db then
            RegisterStateDriver(bar, "visibility", "hide")
            UnregisterStateDriver(bar, "page")
            if E.CreatedMovers["ElvAB_10"] then
                E:DisableMover("ElvAB_10")
            end
            bar.db.enabled = false
        end

        -- Cancel any pending mover text update
        if moverTextTimer then
            E:CancelTimer(moverTextTimer)
            moverTextTimer = nil
        end

        itemCount = 0
    end
end

function QB:OnEnable()
    if E.db.QuestBar.enabled then
        QB:Toggle()
        -- Hide Bar 10 in ElvUI options after enabling
        if E.Options.args.actionbar and E.Options.args.actionbar.args.bar10 then
            E.Options.args.actionbar.args.bar10.hidden = true
            if E.RefreshGUI then E:RefreshGUI() end
        end
    end
end

function QB:OnDisable()
    QB:Toggle()  -- This will disable it
end