-- This addon was thrown together in like an hour, so it's not mega pretty
-- Just a simple little addon to export weakauras en masse

local WeakAuras = _G["WeakAuras"]
local addonName, addonTable = ...

-- Frame just for registering events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

-- Set up an event handler, will only be used for chat commands
frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "PLAYER_LOGIN" then
        SLASH_WAE1 = "/wae"
        SlashCmdList["WAE"] = OnChatCommand
    end
end)

-- Define the callback function for your chat command
    function OnChatCommand(msg)
        -- Create frame to display our weakauras and export string
        local WAEOutputFrame = CreateFrame("Frame", "WAEOutput", UIParent, "BasicFrameTemplateWithInset")
        WAEOutputFrame:SetSize(600, 400)
        WAEOutputFrame:SetPoint("CENTER")
        WAEOutputFrame:SetMovable(true)
        WAEOutputFrame:EnableMouse(true)
        WAEOutputFrame:RegisterForDrag("LeftButton")
        WAEOutputFrame:SetScript("OnDragStart", WAEOutputFrame.StartMoving)
        WAEOutputFrame:SetScript("OnDragStop", WAEOutputFrame.StopMovingOrSizing)
    
        -- Create a scroll frame for buttons
        WAEOutputFrame.ButtonScrollFrame = CreateFrame("ScrollFrame", "WAEOutputButtonScroll", WAEOutputFrame, "UIPanelScrollFrameTemplate")
        WAEOutputFrame.ButtonScrollFrame:SetPoint("LEFT", WAEOutputFrame, "LEFT", 10, 0)
        WAEOutputFrame.ButtonScrollFrame:SetSize(200, 400)

        -- Create a frame for buttons inside the scroll frame
        WAEOutputFrame.ButtonFrame = CreateFrame("Frame", "WAEOutputButtonFrame", WAEOutputFrame.ButtonScrollFrame)
        WAEOutputFrame.ButtonFrame:SetSize(200, 1)

        -- Set the scroll frame's scroll child to the button frame
        WAEOutputFrame.ButtonScrollFrame:SetScrollChild(WAEOutputFrame.ButtonFrame)

        -- Create a scroll frame for text
        WAEOutputFrame.TextScrollFrame = CreateFrame("ScrollFrame", "WAEOutputTextScroll", WAEOutputFrame, "UIPanelScrollFrameTemplate")
        WAEOutputFrame.TextScrollFrame:SetPoint("LEFT", WAEOutputFrame.ButtonScrollFrame, "RIGHT", 10, 0)
        WAEOutputFrame.TextScrollFrame:SetPoint("RIGHT", WAEOutputFrame, "RIGHT", -10, 0)
        WAEOutputFrame.TextScrollFrame:SetSize(WAEOutputFrame:GetWidth() - WAEOutputFrame.ButtonScrollFrame:GetWidth() - 30, 400)

        -- Create an edit box for text inside the text scroll frame
        WAEOutputFrame.EditBox = CreateFrame("EditBox", "WAEOutputEditBox", WAEOutputFrame.TextScrollFrame, "InputBoxTemplate")
        WAEOutputFrame.EditBox:SetMultiLine(true)
        WAEOutputFrame.EditBox:SetMaxLetters(99999)
        WAEOutputFrame.EditBox:EnableMouse(true)
        WAEOutputFrame.EditBox:SetAutoFocus(false)
        WAEOutputFrame.EditBox:SetFontObject(ChatFontNormal)
        WAEOutputFrame.EditBox:SetWidth(WAEOutputFrame.TextScrollFrame:GetWidth())
        WAEOutputFrame.EditBox:SetHeight(400)
        WAEOutputFrame.TextScrollFrame:SetScrollChild(WAEOutputFrame.EditBox)
    
        WAEOutputFrame.ButtonScrollFrame:SetScrollChild(WAEOutputFrame.ButtonFrame)
        
        -- Iterate through each displayed WeakAura and create the export buttons
        -- Would like to "Export All" but it'll just crash your game or DC you if you have too many
        -- I'll try to think of a workaround for this later
        WAEOutputFrame.exportButtons = {}
        for auraName, aura in pairs(WeakAurasSaved["displays"]) do
            -- Don't export children groups as exporting the parent will export them too
            local isParent = aura["parent"] == nil
            if isParent then
                -- Create a button for each aura
                local exportButton = CreateFrame("Button", nil, WAEOutputFrame.ButtonFrame, "UIPanelButtonTemplate")
                exportButton:SetText(auraName)
                exportButton:SetWidth(WAEOutputFrame.ButtonScrollFrame:GetWidth() - 20) -- Adjust as needed
                exportButton:SetHeight(25)
                exportButton:SetPoint("TOPLEFT", WAEOutputFrame.ButtonFrame, "TOPLEFT", 0, -30 * (#WAEOutputFrame.exportButtons + 1))
                
                -- Make the button text wrap and truncate "properly"
                local buttonText = exportButton:GetFontString()
                buttonText:SetWidth(exportButton:GetWidth() - 10)
                buttonText:SetNonSpaceWrap(false)
                buttonText:SetMaxLines(2)
                buttonText:SetIndentedWordWrap(false)

                -- Set the button's click handler
                exportButton:SetScript("OnClick", function()
                    local exportStr = DisplayToString(auraName)
                    WAEOutputFrame.EditBox:SetText(auraName .. "\n" .. exportStr .. "\n\n")
                    WAEOutputFrame:Show()
                end)

                -- Add the button to the list of buttons
                table.insert(WAEOutputFrame.exportButtons, exportButton)
            end
        end
    
        WAEOutputFrame:Show()
    end
    