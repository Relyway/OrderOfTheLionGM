-- Order of the Lion Guild Manager v1.7.5
-- Focused keyboard safety hotfix r7. Loaded after Release175R6.lua.
-- Vanilla / OctoWoW / Lua 5.0 compatible. No additional OnUpdate handlers.

local R7 = {
    revision = 7,
    keyboardSafety = true,
}
OTLGM.release175r7 = R7
OTLGM.build = "stable-r7-20260723"

local function SaveAndReleaseGuildChatFocusR7()
    local edit = OTLGM.ui and OTLGM.ui.guildChatEdit
    if not edit then return end
    if OTLGM.SaveGuildChatDraft and OTLGM.GetGuildChatChannel then
        OTLGM:SaveGuildChatDraft(OTLGM:GetGuildChatChannel())
    end
    if edit.ClearFocus then edit:ClearFocus() end
end

-- The whole Guild Chat page must never own keyboard input. In Vanilla clients,
-- EnableKeyboard(true) consumes movement and jump keys even when OnKeyDown
-- ignores them. Only the actual EditBox may capture keys while the player types.
local BaseBuildGuildChatR7 = OTLGM.BuildGuildChatPage
function OTLGM:BuildGuildChatPage(page)
    local result = BaseBuildGuildChatR7(self, page)
    if page then
        if page.EnableKeyboard then page:EnableKeyboard(false) end
        if page.SetScript then page:SetScript("OnKeyDown", nil) end
        if page.SetPropagateKeyboardInput then page:SetPropagateKeyboardInput(true) end
    end
    local edit = self.ui and self.ui.guildChatEdit
    if edit then
        if edit.SetAutoFocus then edit:SetAutoFocus(false) end
        edit:SetScript("OnEscapePressed", SaveAndReleaseGuildChatFocusR7)
    end
    return result
end

-- Pages.lua applies escape handlers after the base UI is built. Override the
-- Guild Chat variant so the first Escape only leaves typing mode and restores
-- character controls instead of also closing the addon window.
function OTLGM:ApplyGuildChatEscapeBehavior()
    local edit = self.ui and self.ui.guildChatEdit
    if not edit then return end
    edit:SetScript("OnEscapePressed", SaveAndReleaseGuildChatFocusR7)
end

-- R5 focused the input automatically whenever Guild/Officer was selected.
-- Preserve focus only when the user was already typing; opening the page or
-- clicking a channel while not typing must leave movement controls untouched.
local BaseSelectGuildChatViewR7 = OTLGM.SelectGuildChatView152
function OTLGM:SelectGuildChatView152(view)
    local hadFocus = self.guildChatEditFocused and true or false
    local result = BaseSelectGuildChatViewR7(self, view)
    local edit = self.ui and self.ui.guildChatEdit
    if edit then
        if hadFocus then
            if edit.SetFocus then edit:SetFocus() end
        else
            if edit.ClearFocus then edit:ClearFocus() end
        end
    end
    return result
end

if OTLGM.RegisterModule then
    OTLGM:RegisterModule("Release175R7", {
        layer = "feature",
        corrective = true,
        revision = 7,
        totalAchievements = 142,
        eventDriven = true,
        noOnUpdate = true,
        keyboardSafety = true,
    })
end
