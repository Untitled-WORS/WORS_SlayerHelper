--- WORS Slayer Helper Addon
-- Provides location assistance for Slayer tasks

-- Create the main addon frame
local slayerTaskFrame = CreateFrame("Frame", "WORSSlayerTaskFrame", UIParent)
slayerTaskFrame:SetSize(300, 140)  -- Adjust size for more text
slayerTaskFrame:SetPoint("TOPRIGHT", -200, -150)  -- Start in the top-right corner, slightly centered
slayerTaskFrame:SetMovable(true)
slayerTaskFrame:EnableMouse(true)
slayerTaskFrame:RegisterForDrag("LeftButton")
slayerTaskFrame:SetScript("OnDragStart", slayerTaskFrame.StartMoving)
slayerTaskFrame:SetScript("OnDragStop", slayerTaskFrame.StopMovingOrSizing)
slayerTaskFrame:Hide()

local titleText = slayerTaskFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 15, -15)
titleText:SetText("")

-- Create a larger font for the task text without changing its color
local taskText = slayerTaskFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")  -- Keep the original color
taskText:SetTextColor(1, 1, 1)  -- Set text color to white (R, G, B)
taskText:SetFontObject(GameFontNormal)
taskText:SetFont(GameFontNormal:GetFont(), 20, "OUTLINE")  -- Set to default font with size 16
taskText:SetPoint("TOPLEFT", 15, -40)  -- Padding from the left
taskText:SetPoint("TOPRIGHT", -15, -40)  -- Padding from the right
taskText:SetWidth(270)  -- Adjust width for cleaner layout
taskText:SetJustifyH("LEFT")

-- Variables to control text visibility
local showLocationText = true
local showReminderText = true  -- Track visibility of reminder text

-- Define a table that maps creature names (from Slayer tasks) to a list of required items (item ID or name)
local requiredItems = {
    -- Testing remove rats on release 
	--["Rats"] = {"Nose peg", "Earmuffs", "Bag of Salt"},  -- Example creature name and required items
	--["Cave Bugs"] = {"Nose peg", "Earmuffs", "Bag of Salt"},  -- Example creature name and required items
	
	["Lizards"] = 			{"Ice Cooler",},
	["Rockslugs"] = 		{"Bag of Salt",},
	["Mutated Zygomites"] = {"Fungicide",},
	["Mogres"] = 			{"Fishing explosive",},
	["Harpie Bug Swarm"] = 	{"Bug lantern",},
	["Molanisks"] = 		{"Slayer bell",},
	["Dust Devils"] = 		{"Facemask",},
	["Smoke Devils"] = 		{"Facemask",},
	["Banshees"] = 			{"Earmuffs",},
	["Aberrant spectres"] = {"Nose peg",},	
	["Fever Spiders"] = 	{"Slayer gloves",},	
	["Rune dragons"] = 		{"Insulated boots",},	
	["Killerwatts"] = 		{"Insulated boots",},
	["Gargoyles"] = 		{"Rock hammer", "Rock thrownhammer", "Granite hammer"},	
	--Boots of stone *Karuulm Slayer Dungeon.*
	--The boots help to protect the wearer from the extremely hot ground of the  
	["Mutated Zygomites"] = {"Fungicide spray",},
	["Ancient Zygomites"] = {"Fungicide spray",},
	["Wall beasts"] = 		{"Spiny helmet",},
	["Cave horrors"] = 		{"Witchwood icon",},
	["Cockatrices"] = 		{"Mirror shield",},
	["Basilisks"] = 		{"Mirror shield",},
	["Turoths"] = 			{"Slayer's staff", "Leaf-bladed spear"},
	["Kurasks"] = 			{"Slayer's staff", "Leaf-bladed spear"},
}

-- Function to check if an item is in the player's bags or equipped (case-insensitive)
local function IsItemEquippedOrInInventory(itemName)
    -- Convert itemName to lowercase for case-insensitive comparison
    itemName = string.lower(itemName)

    -- Check if the item is equipped
    for i = 1, 19 do  -- Iterate through all equipment slots (1 to 19)
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink and string.find(string.lower(itemLink), itemName) then
            return true
        end
    end

    -- Check if the item is in the bags
    for bag = 0, 4 do  -- Bags 0 to 4 (main bags)
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink and string.find(string.lower(itemLink), itemName) then
                return true
            end
        end
    end

    return false  -- Item not found in inventory or equipped
end


-- Function to check for active Slayer task
local function CheckSlayerTask()
    for i = 1, GetNumQuestLogEntries() do
        local questLogTitle = GetQuestLogTitle(i)

        if questLogTitle then
            -- Match slayer task name
            if string.find(questLogTitle, "Slayer Task -") then
                -- Extract the creature name (task name) after "Slayer Task -"
                local creatureName = string.match(questLogTitle, "Slayer Task %- (.+)")
                if creatureName then
                    -- Check progress
                    local progress, maxProgress = 0, 0
                    local objectiveCount = GetNumQuestLeaderBoards(i)

                    -- Count progress for 'kill' type objectives
                    for j = 1, objectiveCount do
                        local objectiveText, objectiveType, objectiveCompleted, objectiveRequired = GetQuestLogLeaderBoard(j, i)
                        -- Only count 'kill' type objectives
                        if objectiveType == "kill" then
                            if objectiveCompleted then
                                progress = progress + (objectiveRequired or 1)  -- Increment by the required amount if completed
                            end
                            maxProgress = maxProgress + (objectiveRequired or 1)  -- Always add to max progress
                        end
                    end
                    return creatureName, progress, maxProgress, i  -- Return creature name instead of full task name
                end
            end
        end
    end
    return nil, nil, nil, nil
end

-- Function to display the current task, progress, and locations
local function DisplaySlayerTask()
    local creatureName, progress, maxProgress, questIndex = CheckSlayerTask()
    if creatureName then
        -- Prepare task display text for locations
        local taskProgressText = ""
        -- Fetch and display quest objectives and locations
        if questIndex then
            local objectiveCount = GetNumQuestLeaderBoards(questIndex)
            for j = 1, objectiveCount do
                local objectiveText, objectiveType, objectiveCompleted, objectiveRequired = GetQuestLogLeaderBoard(j, questIndex)

                -- Remove "Kill " from the start of the objectiveText
                titleText:SetText("Slayer Task: " .. string.gsub(objectiveText, "^Kill ", ""))
                local currentProgress = objectiveCompleted and objectiveRequired or 0
            end

            -- Display location data for the task if showLocationText is true
            if showLocationText then
                local locations = WORSSlayerTaskData[creatureName]  -- Use creatureName for lookup
                if locations then
                    taskProgressText = taskProgressText .. "  - " .. table.concat(locations, "\n  - ")
                end
            end

            -- Check if the task requires an item and if it's in the player's inventory or equipped
            local items = requiredItems[creatureName]  -- Use creatureName for required items
            if items then
                local missingItems = {}  -- Table to hold all missing items
                local hasAnyItem = false  -- Flag to track if any item is found
                -- Check if the player has at least one of the required items
                for _, item in ipairs(items) do
                    if IsItemEquippedOrInInventory(item) then
                        hasAnyItem = true  -- If any item is found, mark as true
                        break  -- Exit early as we found one item
                    else
                        table.insert(missingItems, "[" .. item .. "]")  -- Add missing item to the list with square brackets
                    end
                end

                -- If none of the items are found, display the reminder text with missing items
                if not hasAnyItem and #missingItems > 0 and showReminderText then
                    taskProgressText = taskProgressText .. "\n|cFFFF0000**Item Required**\n" .. table.concat(missingItems, " / ") .. ""
                end
            end

        else
            taskProgressText = taskProgressText .. "\nNo objectives found!"
        end

        -- Set the task progress text
        taskText:SetText(taskProgressText)

        -- Show the frame
        slayerTaskFrame:Show()

    else  -- Frame is hidden if no task is found
        slayerTaskFrame:Hide()
    end
end

-- Check task every time the quest log is updated
slayerTaskFrame:RegisterEvent("QUEST_LOG_UPDATE")
slayerTaskFrame:SetScript("OnEvent", function(self, event)
    DisplaySlayerTask()
end)

-- Update the UI when an item is moved in/out of the inventory or when equipment is changed
-- Event handling for updates
slayerTaskFrame:RegisterEvent("QUEST_LOG_UPDATE")
slayerTaskFrame:RegisterEvent("BAG_UPDATE")
slayerTaskFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

-- Single script handler for all events
slayerTaskFrame:SetScript("OnEvent", DisplaySlayerTask)


-- Minimap Icon for WORS_SlayerHelper using LibDBIcon and Ace3
local addon = LibStub("AceAddon-3.0"):NewAddon("WORS_SlayerHelper")
WORSSlayerHelperMinimapButton = LibStub("LibDBIcon-1.0", true)
local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("WORS_SlayerHelper", {
    type = "data source",
    text = "Slayer Helper",
    icon = "Interface\\Icons\\slayericon",
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			if WORSSlayerTaskFrame:IsShown() then
				WORSSlayerTaskFrame:Hide()
			else
				WORSSlayerTaskFrame:Show()
			end
		elseif btn == "RightButton" then
			WORSSlayerTaskFrame:Show()
			showLocationText = not showLocationText
			showReminderText = not showReminderText  -- Toggle the reminder text visibility
			DisplaySlayerTask()  -- Update display to reflect the toggled reminder
		end
	end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end
        tooltip:AddLine("Slayer Helper\nLeft-click: Toggle Slayer Helper Window", nil, nil, nil, nil)
        tooltip:AddLine("Right-click: Toggle Location and Reminder Text", nil, nil, nil, nil)
    end,
})

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WORSSlayerHelperMinimapDB", {
        profile = {
            minimap = {
                hide = false,
                minimapPos = 125, -- This is the hardcoded position (in degrees)
            },
        },
    })
    WORSSlayerHelperMinimapButton:Register("WORS_SlayerHelper", miniButton, self.db.profile.minimap)
end