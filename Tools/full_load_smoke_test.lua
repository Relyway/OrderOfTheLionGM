-- Full package load/build smoke test using a Vanilla-oriented API mock.
if not table.getn then table.getn=function(t) return #t end end
if not table.setn then table.setn=function() end end
if not math.mod then math.mod=function(a,b) return a % b end end
if not unpack then unpack=table.unpack end
local root=arg and arg[1] or "."
local NOW=1700000000
function time() return NOW end
function date(fmt,ts) return "26/07 02:00" end
function GetTime() return NOW end
function debugstack() return "mock" end
function getglobal(name) return rawget(_G,name) end
function setglobal(name,v) _G[name]=v end
function strlower(v) return string.lower(v or "") end
function strupper(v) return string.upper(v or "") end
function strlen(v) return string.len(v or "") end
function format(...) return string.format(...) end

local Frame={}
local frameMeta={__index=function(t,k)
    if Frame[k] then return Frame[k] end
    if type(k)=="string" and string.find(k,"^[A-Z]") then return function() return nil end end
end}
local function NewFrame(parent,name,kind)
    local f=setmetatable({parent=parent,name=name,kind=kind or "Frame",visible=true,scripts={},children={},width=0,height=0,frameLevel=1,mouse=true,keyboard=true,nativeEnabled=true,_text=""},frameMeta)
    if parent and parent.children then table.insert(parent.children,f) end
    if name and name~="" then _G[name]=f end
    return f
end
function Frame:SetScript(k,v) self.scripts[k]=v end
function Frame:GetScript(k) return self.scripts[k] end
function Frame:HookScript(k,v) local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end return v(...) end end
function Frame:Show() self.visible=true if self.scripts.OnShow then local old=this this=self self.scripts.OnShow() this=old end end
function Frame:Hide() self.visible=false if self.scripts.OnHide then local old=this this=self self.scripts.OnHide() this=old end end
function Frame:IsVisible() return self.visible end
function Frame:IsShown() return self.visible end
function Frame:SetText(v) self._text=tostring(v or "") if self.scripts.OnTextChanged then local old=this this=self self.scripts.OnTextChanged() this=old end end
function Frame:GetText() return self._text or "" end
function Frame:SetWidth(v) self.width=tonumber(v) or 0 end
function Frame:SetHeight(v) self.height=tonumber(v) or 0 end
function Frame:GetWidth() return self.width or 0 end
function Frame:GetHeight() return self.height or 0 end
function Frame:GetParent() return self.parent end
function Frame:GetName() return self.name end
function Frame:GetObjectType() return self.kind end
function Frame:SetFrameLevel(v) self.frameLevel=tonumber(v) or 1 end
function Frame:GetFrameLevel() return self.frameLevel or 1 end
function Frame:SetFrameStrata(v) self.strata=v end
function Frame:GetFrameStrata() return self.strata or "MEDIUM" end
function Frame:SetAlpha(v) self.alpha=tonumber(v) or 1 end
function Frame:GetAlpha() return self.alpha or 1 end
function Frame:SetPoint(...) self.point={...} end
function Frame:ClearAllPoints() self.point=nil end
function Frame:SetAllPoints(...) self.allPoints={...} end
function Frame:SetBackdrop(...) self.backdrop={...} end
function Frame:SetBackdropColor(...) self.backdropColor={...} end
function Frame:SetBackdropBorderColor(...) self.backdropBorderColor={...} end
function Frame:GetCenter() return 500,350 end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetScale() return self.scale or 1 end
function Frame:SetScale(v) self.scale=v end
function Frame:GetLeft() return 0 end
function Frame:GetRight() return self.width end
function Frame:GetTop() return self.height end
function Frame:GetBottom() return 0 end
function Frame:CreateTexture(name,layer) return NewFrame(self,name,"Texture") end
function Frame:CreateFontString(name,layer,template) return NewFrame(self,name,"FontString") end
function Frame:GetChildren() return unpack(self.children or {}) end
function Frame:GetRegions() return nil end
function Frame:SetFocus() self.focused=true end
function Frame:ClearFocus() self.focused=nil end
function Frame:HighlightText() end
function Frame:GetStringHeight() local n=1 for _ in string.gmatch(self._text or "","\n") do n=n+1 end return n*12 end
function Frame:GetTextWidth() return string.len(self._text or "")*6 end
function Frame:GetStringWidth() return string.len(self._text or "")*6 end
function Frame:EnableMouse(v) self.mouse=v~=false end
function Frame:IsMouseEnabled() return self.mouse end
function Frame:EnableKeyboard(v) self.keyboard=v~=false end
function Frame:IsKeyboardEnabled() return self.keyboard end
function Frame:Enable() self.nativeEnabled=true end
function Frame:Disable() self.nativeEnabled=false end
function Frame:IsEnabled() return self.nativeEnabled~=false end
function Frame:SetEnabled(v) self.nativeEnabled=v and true or false end
function Frame:SetValue(v) self.value=v end
function Frame:GetValue() return self.value or 0 end
function Frame:SetMinMaxValues(a,b) self.minValue=a self.maxValue=b end
function Frame:GetMinMaxValues() return self.minValue or 0,self.maxValue or 0 end
function Frame:SetChecked(v) self.checked=v end
function Frame:GetChecked() return self.checked end
function Frame:RegisterEvent(v) self.events=self.events or {} self.events[v]=true end
function Frame:UnregisterEvent(v) if self.events then self.events[v]=nil end end
function Frame:RegisterForClicks(...) self.clicks={...} end
function Frame:RegisterForDrag(...) end
function Frame:SetScrollChild(v) self.scrollChild=v end
function Frame:GetVerticalScrollRange() return 0 end
function Frame:GetVerticalScroll() return 0 end
function Frame:SetVerticalScroll() end
function Frame:SetOwner() end
function Frame:AddLine() end
function Frame:AddDoubleLine() end
function Frame:AddMessage(v) self.lastMessage=v end
function Frame:NumLines() return 0 end
function Frame:SetID(v) self.id=v end
function Frame:GetID() return self.id or 0 end
function Frame:SetFont() return true end
function Frame:GetFont() return "Fonts\\FRIZQT__.TTF",12,"" end
function Frame:StartMoving() end
function Frame:StopMovingOrSizing() end
function CreateFrame(kind,name,parent,template) return NewFrame(parent or UIParent,name,kind) end
UIParent=NewFrame(nil,"UIParent","Frame") UIParent.width=1920 UIParent.height=1080
GameTooltip=NewFrame(UIParent,"GameTooltip","GameTooltip")
ItemRefTooltip=NewFrame(UIParent,"ItemRefTooltip","GameTooltip")
ShoppingTooltip1=NewFrame(UIParent,"ShoppingTooltip1","GameTooltip")
ShoppingTooltip2=NewFrame(UIParent,"ShoppingTooltip2","GameTooltip")
DEFAULT_CHAT_FRAME=NewFrame(UIParent,"DEFAULT_CHAT_FRAME","ScrollingMessageFrame")
ChatFrame1=DEFAULT_CHAT_FRAME Minimap=NewFrame(UIParent,"Minimap","Frame") WorldFrame=NewFrame(UIParent,"WorldFrame","Frame")
TradeSkillFrame=NewFrame(UIParent,"TradeSkillFrame","Frame") TradeSkillFrame.visible=false
CraftFrame=NewFrame(UIParent,"CraftFrame","Frame") CraftFrame.visible=false
UISpecialFrames={} SlashCmdList={} StaticPopupDialogs={} SOUNDKIT={} BOOKTYPE_SPELL="spell" MAX_PLAYER_LEVEL=60
RAID_CLASS_COLORS={} NORMAL_FONT_COLOR={r=1,g=1,b=1} HIGHLIGHT_FONT_COLOR={r=1,g=1,b=1} GRAY_FONT_COLOR={r=.5,g=.5,b=.5}
ChatFontNormal={}

function UnitName(unit) if unit=="player" then return "Luck" end return nil end
function UnitClass() return "Priest","PRIEST" end
function UnitLevel() return 60 end
function UnitFactionGroup() return "Alliance" end
function UnitAffectingCombat() return false end
function UnitExists(unit) return unit=="player" end
function GetGuildInfo() return "Order of the Lion","Guild Leader",0 end
function IsGuildLeader() return true end
function GetRealmName() return "OctoWoW" end
function GetLocale() return "enUS" end
function GetCVar(name) if name=="realmName" then return "OctoWoW" end return "1" end
function GetNumGuildMembers() return 2 end
function GetGuildRosterInfo(i)
    if i==1 then return "Luck","Guild Leader",0,60,"Priest","Stormwind","","",true end
    if i==2 then return "Tokmek","Veteran",4,36,"Druid","Stormwind","","",true end
end
function GuildRoster() end
function GetGuildRosterMOTD() return "Welcome" end
function GetGuildInfoText() return "Guild information" end
function GetChannelName(name) return 6,name end
function GetNumPartyMembers() return 0 end
function GetNumRaidMembers() return 0 end
function GetMoney() return 0 end
function GetRealZoneText() return "Stormwind City" end
function GetZoneText() return "Stormwind City" end
function GetSubZoneText() return "Trade District" end
function GetContainerNumSlots() return 0 end
function GetContainerItemLink() return nil end
function GetContainerItemInfo() return nil end
function GetItemInfo() return nil end
function GetInboxNumItems() return 0 end
function GetInboxHeaderInfo() return nil end
function GetNumGuildBankTabs() return 0 end
function GetGuildBankMoney() return 0 end
function CanGuildInvite() return true end
function CanGuildPromote() return true end
function CanGuildDemote() return true end
function CanGuildRemove() return true end
function CanEditMOTD() return true end
function CanEditGuildInfo() return true end
function CanEditPublicNote() return true end
function CanEditOfficerNote() return true end
function CanViewOfficerNote() return true end
MOCK_GUILD_INVITES={}
function GuildInvite(name) table.insert(MOCK_GUILD_INVITES,name) end
function GuildControlSetRank() end
function GuildControlGetRankFlags() return true,true,true,true,true,true,true,true,true,true,true,true,true end
function SendAddonMessage() end
function RegisterAddonMessagePrefix() return true end
function SendChatMessage() end
function PlaySound() end
function ChatFrame_OpenChat() end
function StaticPopup_Show() return NewFrame(UIParent,nil,"Frame") end
function IsModifiedClick() return false end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function GetMouseFocus() return nil end
function GetCursorPosition() return 0,0 end
function GetSpellName() return nil end
function GetNumSpellTabs() return 0 end
function GetSpellTabInfo() return nil end
function GetNumTradeSkills() return 0 end
function GetNumCrafts() return 0 end
function GetTradeSkillLine() return "UNKNOWN",0,0 end
function GetCraftDisplaySkillLine() return "UNKNOWN",0,0 end

-- Missing globals intentionally resolve to nil in the smoke environment.
local toc=assert(io.open(root.."/OrderOfTheLionGM.toc","r"))
local files={}
for line in toc:lines() do
    line=string.gsub(line,"^%s+","") line=string.gsub(line,"%s+$","")
    if line~="" and string.sub(line,1,2)~="##" then table.insert(files,(string.gsub(line,"\\","/"))) end
end
toc:close()
for i=1,table.getn(files) do
    local path=root.."/"..files[i]
    local chunk,err=loadfile(path)
    if not chunk then error("compile "..files[i]..": "..tostring(err)) end
    local ok,problem=pcall(chunk)
    if not ok then error("load "..files[i]..": "..tostring(problem)) end
end
assert(OTLGM and OTLGM.version=="1.7.6","version")
assert(OTLGM.build=="performance-r5-hotfix1-20260726","build")
local ok,problem=pcall(function()
    OTLGM:EnsureDB()
    OTLGM:BuildUI()
    if OTLGM.ui and OTLGM.ui.main then OTLGM.ui.main:Show() end
    local pages={"home","overview","roster","professions","achievements","treasury","pve","guildchat","activity","recruitment","settings"}
    for i=1,table.getn(pages) do if OTLGM.ui.pages and OTLGM.ui.pages[pages[i]] then OTLGM:ShowPage(pages[i]) end end
    OTLGM:RefreshAll()
end)
if not ok then error("UI build/refresh: "..tostring(problem)) end
assert(OTLGM.release176r5 and OTLGM.release176r5.revision==5,"R5 loaded")
assert(OTLGM.release176r5Hotfix and OTLGM.release176r5Hotfix.revision==1,"R5 hotfix loaded")
local liveGuildDb=assert(OTLGM:GetGuildDB(),"guild db")
liveGuildDb.roster=liveGuildDb.roster or {}
liveGuildDb.roster.Tokmek={name="Tokmek",rank="Veteran",rankIndex=4,level=36,class="Druid",zone="Stormwind",online=true,lastSeen=NOW}

-- R5 performance gates remain active in the fully composed addon.
assert(OTLGM:ScheduleMailboxScan176("MAIL_SHOW")==false,"mail scan must stay suppressed")
local hiddenBefore=OTLGM.release176r5.hiddenRefreshesSkipped or 0
OTLGM.ui.main:Hide()
OTLGM:RefreshHomePage()
assert((OTLGM.release176r5.hiddenRefreshesSkipped or 0)>hiddenBefore,"hidden refresh must be skipped")
OTLGM.ui.main:Show()

-- The compact park tab is built, small and positioned lower on the edge.
local parkTab=assert(OTLGM.ui.windowParkTab176,"park tab")
assert(parkTab:GetWidth()==30 and parkTab:GetHeight()==38,"compact park tab dimensions")
assert(parkTab.point and parkTab.point[5]==-176,"lower park tab position")

-- Recent whisper invitation uses the currently displayed row and real guild API.
OTLGM:CaptureRecentWhisper176("Newplayer-Realm","Hello, may I join?")
OTLGM:OpenRecentWhispers176()
local whisperDialog=assert(OTLGM.ui.recentWhisperDialog176,"whisper dialog")
assert(whisperDialog:IsVisible(),"whisper dialog visible")
local modalOverlay=assert(OTLGM.ui.exclusiveModalOverlayR5,"exclusive overlay")
assert(modalOverlay:IsVisible(),"exclusive overlay visible")
assert(modalOverlay.modalShadeScopeH1=="ADDON","modal shade must be limited to addon window")
local inviteButton=assert(whisperDialog.rows176[1].invite176,"invite button")
assert(inviteButton:GetFrameLevel()>modalOverlay:GetFrameLevel(),"whisper invite button above modal shade")
assert(inviteButton.entryR5 and inviteButton.entryR5.name=="Newplayer","invite row binding")
local oldThis=this this=inviteButton inviteButton:GetScript("OnClick")() this=oldThis
assert(MOCK_GUILD_INVITES[1]=="Newplayer","guild invite API called for row player")

-- Treasury has both a per-goal ledger and a full activity window.
OTLGM:CloseExclusiveModalR5()
OTLGM:ShowPage("treasury")
local goalOk=OTLGM:SetTreasuryGoal170("R5_TEST","Guild House",0,1000000,"HOUSE")
assert(goalOk,"treasury goal create")
OTLGM.ui.treasury170.selected="R5_TEST"
OTLGM:RefreshTreasuryPage170(true)
local goalRow=nil
for i=1,table.getn(OTLGM.ui.treasury170.rows or {}) do
    if OTLGM.ui.treasury170.rows[i].goal170 and OTLGM.ui.treasury170.rows[i].goal170.id=="R5_TEST" then goalRow=OTLGM.ui.treasury170.rows[i] break end
end
assert(goalRow and goalRow.ledgerButtonH1 and goalRow.addButtonH1,"every Treasury goal has Ledger and + Gold buttons")
assert(goalRow.ledgerButtonH1:IsEnabled() and goalRow.addButtonH1:IsEnabled(),"per-goal Treasury buttons enabled")

-- Open the contribution dialog through the per-goal button and verify every
-- input/action is raised above the scoped shade.
oldThis=this this=goalRow.addButtonH1 goalRow.addButtonH1:GetScript("OnClick")() this=oldThis
local contributionDialog=assert(OTLGM.ui.treasuryContributionDialog176,"contribution dialog")
assert(contributionDialog:IsVisible(),"per-goal + Gold opens contribution dialog")
assert(contributionDialog.contributor176:GetFrameLevel()>modalOverlay:GetFrameLevel(),"contributor input above modal shade")
assert(contributionDialog.amount176:GetFrameLevel()>modalOverlay:GetFrameLevel(),"amount input above modal shade")
assert(contributionDialog.note176:GetFrameLevel()>modalOverlay:GetFrameLevel(),"note input above modal shade")
assert(contributionDialog.add176:GetFrameLevel()>modalOverlay:GetFrameLevel(),"Add Contribution button above modal shade")
assert(contributionDialog.backdropColor and contributionDialog.backdropColor[4]==1,"contribution dialog is fully opaque")
OTLGM:CloseExclusiveModalR5()

local contributionOk=OTLGM:AddTreasuryContribution176("R5_TEST","Tokmek",50000,"First payment")
assert(contributionOk,"treasury contribution create")
assert(not OTLGM:IsAchievementComplete174("E001"),"recording another member's donation must not reward the officer")
assert(OTLGM:OpenTreasuryGoalLedgerR5("R5_TEST"),"goal ledger opens")
local ledgerDialog=assert(OTLGM.ui.treasuryLedgerDialogR5,"ledger dialog")
assert(ledgerDialog:IsVisible(),"ledger visible")
assert(string.find(ledgerDialog.summaryRowsR5[1].nameR5:GetText(),"Tokmek",1,true),"ledger contributor shown")
assert(string.find(ledgerDialog.summaryRowsR5[1].countR5:GetText(),"Druid",1,true),"ledger shows current contributor class")
assert(string.find(ledgerDialog.summaryRowsR5[1].countR5:GetText(),"Veteran",1,true),"ledger shows current contributor rank")
assert(string.find(ledgerDialog.entryRowsR5[1].textR5:GetText(),"First payment",1,true),"ledger contribution note shown")
assert(string.find(ledgerDialog.entryRowsR5[1].textR5:GetText(),"Druid",1,true),"individual contribution shows current class")
assert(string.find(ledgerDialog.entryRowsR5[1].textR5:GetText(),"Veteran",1,true),"individual contribution shows current rank")

-- A 100 gold contribution recorded for the local player grants all donor tiers
-- to the donor, not to the recording actor field.
local selfContributionOk=OTLGM:AddTreasuryContribution176("R5_TEST","Luck",1000000,"Donor achievement test")
assert(selfContributionOk,"self donor contribution create")
assert(OTLGM:IsAchievementComplete174("E001"),"5g donor achievement")
assert(OTLGM:IsAchievementComplete174("E002"),"25g donor achievement")
assert(OTLGM:IsAchievementComplete174("E003"),"50g donor achievement")
assert(OTLGM:IsAchievementComplete174("E004"),"100g donor achievement")
assert((OTLGM:EnsureAchievements174().counters.treasuryDonatedGoldR5 or 0)>=100,"donor progress stored on donor character")

assert(OTLGM:OpenTreasuryActivityR5(),"activity opens")
local activityDialog=assert(OTLGM.ui.treasuryActivityDialogR5,"activity dialog")
assert(activityDialog:IsVisible() and not ledgerDialog:IsVisible(),"exclusive treasury modal replacement")
assert(table.getn(OTLGM:GetTreasuryActivityR5("CONTRIBUTIONS"))>=1,"contribution appears in activity")

print("FULL_LOAD_R5_SMOKE_TEST_OK files="..tostring(table.getn(files)).." workflows=treasury+whisper+modal+donor-achievements+performance")
