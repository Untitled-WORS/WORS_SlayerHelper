--- WORS Slayer Helper Addon
-- Provides location assistance for Slayer tasks

-- print("WORS Slayer Helper Loaded")

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

-- Variable to control location text visibility
local showLocationText = true

-- Function to check for active Slayer task
local function CheckSlayerTask()
    for i = 1, GetNumQuestLogEntries() do
        local questLogTitle = GetQuestLogTitle(i)

        if questLogTitle then
            --print("Checking quest: " .. questLogTitle)  -- Debugging

            -- Match slayer task name
            if string.find(questLogTitle, "Slayer Task -") then
                --print("Slayer Task Found: " .. questLogTitle)  -- Debugging

                -- Extract the task name
                local taskName = string.match(questLogTitle, "Slayer Task %- (.+)")
                if taskName then
                    --print("Extracted Task Name: " .. taskName)  -- Debugging

                    -- Check progress
                    local progress, maxProgress = 0, 0
                    local objectiveCount = GetNumQuestLeaderBoards(i)

                    -- Debugging: output the number of objectives
                    --print("Objective Count: " .. objectiveCount)

                    for j = 1, objectiveCount do
                        local objectiveText, objectiveType, objectiveCompleted, objectiveRequired = GetQuestLogLeaderBoard(j, i)
                        --print("Objective: " .. objectiveText)  -- Debugging
                        --print("Objective Completed: " .. tostring(objectiveCompleted))  -- Debugging
                        --print("Objective Required: " .. tostring(objectiveRequired))  -- Debugging
                        -- Only count 'kill' type objectives
                        if objectiveType == "kill" then
                            if objectiveCompleted then
                                progress = progress + (objectiveRequired or 1)  -- Increment by the required amount if completed
                            end
                            maxProgress = maxProgress + (objectiveRequired or 1)  -- Always add to max progress
                        end
                    end
                    -- Debugging output for progress
                    --print("Progress: " .. progress .. ", Max Progress: " .. maxProgress)
                    return taskName, progress, maxProgress, i  -- Return the quest index too
                else
                    --print("Could not extract task name.")  -- Debugging
                end
            end
        end
    end
    --print("No Slayer Task Found")  -- Debugging
    return nil, nil, nil, nil
end

-- Function to display the current task, progress, and locations
local function DisplaySlayerTask()
    --print("DisplaySlayerTask called")  -- Debugging
    local taskName, progress, maxProgress, questIndex = CheckSlayerTask()
    if taskName then
        --print("Displaying Task: " .. taskName)  -- Debugging
        -- Prepare task display text
        local taskProgressText = " "
        -- if progress and maxProgress then
            -- taskProgressText = string.format("Progress: %d/%d", progress, maxProgress)
        -- end

        -- Show the frame and set the task text
        slayerTaskFrame:Show()
        taskText:SetText(taskProgressText)

        -- Fetch and display quest objectives and locations
        if questIndex then
            local objectiveCount = GetNumQuestLeaderBoards(questIndex)
            for j = 1, objectiveCount do
                local objectiveText, objectiveType, objectiveCompleted, objectiveRequired = GetQuestLogLeaderBoard(j, questIndex)

                -- Remove "Kill " from the start of the objectiveText
                objectiveText = string.gsub(objectiveText, "^Kill ", "")

                local currentProgress = objectiveCompleted and objectiveRequired or 0
                taskText:SetText(taskText:GetText() .. objectiveText)
            end

            -- Display location data for the task if showLocationText is true
            if showLocationText then
                local locations = WORSSlayerTaskData[taskName]
                if locations then
                    taskText:SetText(taskText:GetText() .. "\n  - " .. table.concat(locations, "\n  - "))
                end
            end
        else
            taskText:SetText(taskText:GetText() .. "\nNo objectives found!")
        end
    else  -- Frame is hidden if no task is found
        slayerTaskFrame:Hide()
        --print("No task to display.")  -- Debugging
    end
end

-- Check task every time the quest log is updated
slayerTaskFrame:RegisterEvent("QUEST_LOG_UPDATE")
slayerTaskFrame:SetScript("OnEvent", function(self, event)
    --print("Quest log updated")  -- Debugging
    DisplaySlayerTask()
end)

-- Minimap Icon for WORS_SlayerHelper using LibDBIcon and Ace3
local addon = LibStub("AceAddon-3.0"):NewAddon("WORS_SlayerHelper")
WORSLootMinimapButton = LibStub("LibDBIcon-1.0", true)
local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("WORS_SlayerHelper", {
    type = "data source",
    text = "WORS Slayer Helper",
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
            DisplaySlayerTask()
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end
        tooltip:AddLine("WORS Slayer Helper\n\nLeft-click: Toggle Slayer Helper Window", nil, nil, nil, nil)
        tooltip:AddLine("Right-click: Toggle Location Text", nil, nil, nil, nil)
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
    WORSLootMinimapButton:Register("WORS_SlayerHelper", miniButton, self.db.profile.minimap)
    loadLootTransparency()
end

WORSLootMinimapButton:Show("WORS_SlayerHelper")
