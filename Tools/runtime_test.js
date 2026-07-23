const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const root = process.argv[2];
if (!root) throw new Error('usage: node runtime_test.js ADDON_ROOT');
const toc = fs.readFileSync(path.join(root,'OrderOfTheLionGM.toc'),'utf8');
const files = toc.split(/\r?\n/).map(x=>x.trim()).filter(x=>x && !x.startsWith('##')).map(x=>x.replace(/\\/g,'/'));

const mock = String.raw`
-- Vanilla-oriented test environment
if not table.getn then table.getn = function(t) return #t end end
if not table.setn then table.setn = function() end end
if not math.mod then math.mod = function(a,b) return a % b end end
if not unpack then unpack = table.unpack end
MOCK_NOW = 1700000000
function time() return MOCK_NOW end
function date(fmt, ts) return os.date(fmt, ts or MOCK_NOW) end
function GetTime() return MOCK_NOW end
function debugstack() return 'mock stack' end
function getglobal(name) return _G[name] end
function setglobal(name, value) _G[name] = value end
function strlower(v) return string.lower(v or '') end
function strupper(v) return string.upper(v or '') end
function strlen(v) return string.len(v or '') end
function format(...) return string.format(...) end

local Frame = {}
local frameMeta = {
  __index = function(t,k)
    local known = Frame[k]
    if known then return known end
    if type(k) == 'string' and string.find(k, '^[A-Z]') then
      return function() return nil end
    end
    return nil
  end
}
local function NewFrame(parent, name, objectType)
  local f = setmetatable({ parent=parent, name=name, objectType=objectType or 'Frame', visible=true, scripts={}, width=0, height=0, value=0, minValue=0, maxValue=0, alpha=1, checked=nil, frameLevel=1, children={}, nativeEnabled=true, mouse=false, keyboard=false, registeredClicks={} }, frameMeta)
  if parent and parent.children then table.insert(parent.children, f) end
  if name and name ~= '' then _G[name] = f end
  return f
end
function Frame:SetScript(name, fn) self.scripts[name]=fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:HookScript(name, fn) self.scripts[name]=fn end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:IsVisible() return self.visible end
function Frame:IsShown() return self.visible end
function Frame:SetText(v) self._text=tostring(v or '') end
function Frame:GetText() return self._text or '' end
function Frame:SetWidth(v) self.width=tonumber(v) or 0 end
function Frame:SetHeight(v) self.height=tonumber(v) or 0 end
function Frame:GetWidth() return self.width or 0 end
function Frame:GetHeight() return self.height or 0 end
function Frame:GetParent() return self.parent end
function Frame:GetName() return self.name end
function Frame:GetObjectType() return self.objectType end
function Frame:SetFrameLevel(v) self.frameLevel=tonumber(v) or 1 end
function Frame:GetFrameLevel() return self.frameLevel or 1 end
function Frame:SetFrameStrata(v) self.frameStrata=v end
function Frame:GetFrameStrata() return self.frameStrata or 'MEDIUM' end
function Frame:SetAlpha(v) self.alpha=tonumber(v) or 1 end
function Frame:GetAlpha() return self.alpha or 1 end
function Frame:SetValue(v) self.value=tonumber(v) or 0 end
function Frame:GetValue() return self.value or 0 end
function Frame:SetMinMaxValues(a,b) self.minValue=a or 0 self.maxValue=b or 0 end
function Frame:GetMinMaxValues() return self.minValue or 0,self.maxValue or 0 end
function Frame:SetChecked(v) self.checked=v end
function Frame:GetChecked() return self.checked end
function Frame:GetCenter() return 500,350 end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetVerticalScrollRange() return 0 end
function Frame:GetVerticalScroll() return self.verticalScroll or 0 end
function Frame:SetVerticalScroll(v) self.verticalScroll=v end
function Frame:GetStringHeight()
  local n=1
  for _ in string.gmatch(self._text or '', '\n') do n=n+1 end
  return math.max(12,n*12)
end
function Frame:GetTextWidth() return string.len(self._text or '')*6 end
function Frame:GetStringWidth() return string.len(self._text or '')*6 end
function Frame:CreateTexture(name, layer) return NewFrame(self,name,'Texture') end
function Frame:CreateFontString(name, layer, template) return NewFrame(self,name,'FontString') end
function Frame:SetTexture(...) self.texture={...} end
function Frame:SetPoint(...) self.point={...} end
function Frame:ClearAllPoints() self.point=nil end
function Frame:SetAllPoints(...) self.allPoints={...} end
function Frame:SetFocus() self.focused170=true end
function Frame:ClearFocus() self.focused170=nil end
function Frame:HighlightText() end
function Frame:HasFocus() return self.focused170 and true or false end
function Frame:AddMessage(text) self.lastMessage=text end
function Frame:AddLine(text) self.lastLine=text end
function Frame:AddDoubleLine(left,right) self.lastLine=tostring(left)..tostring(right) end
function Frame:SetOwner(...) end
function Frame:NumLines() return 0 end
function Frame:GetRegions() return nil end
function Frame:GetChildren() return unpack(self.children or {}) end
function Frame:IsMouseOver() return false end
function Frame:SetScrollChild(child) self.scrollChild=child end
function Frame:EnableMouse(v) self.mouse=v and true or false end
function Frame:IsMouseEnabled() return self.mouse and true or false end
function Frame:EnableKeyboard(v) self.keyboard=v and true or false end
function Frame:IsKeyboardEnabled() return self.keyboard and true or false end
function Frame:EnableMouseWheel(v) self.mouseWheel=v end
function Frame:SetAutoFocus(v) self.autoFocus=v end
function Frame:SetMaxLetters(v) self.maxLetters=v end
function Frame:SetMultiLine(v) self.multiLine=v end
function Frame:SetNumeric(v) self.numeric=v end
function Frame:SetPassword(v) self.password=v end
function Frame:SetFontObject(v) self.fontObject=v end
function Frame:SetJustifyH(v) self.justifyH=v end
function Frame:SetJustifyV(v) self.justifyV=v end
function Frame:RegisterEvent(v) self.events=self.events or {} self.events[v]=true end
function Frame:UnregisterEvent(v) if self.events then self.events[v]=nil end end
function Frame:RegisterForClicks(...) self.registeredClicks={} local a={...} for _,v in ipairs(a) do self.registeredClicks[v]=true end end
function Frame:RegisterForDrag(...) end
function Frame:SetBackdrop(...) end
function Frame:SetBackdropColor(...) end
function Frame:SetBackdropBorderColor(...) end
function Frame:SetVertexColor(...) self.vertex={...} end
function Frame:SetTexCoord(...) end
function Frame:SetBlendMode(...) end
function Frame:SetStatusBarTexture(...) end
function Frame:SetStatusBarColor(...) end
function Frame:SetHighlightTexture(...) end
function Frame:SetNormalTexture(...) end
function Frame:SetPushedTexture(...) end
function Frame:SetDisabledTexture(...) end
function Frame:SetThumbTexture(...) end
function Frame:SetMovable(...) end
function Frame:SetClampedToScreen(...) end
function Frame:SetToplevel(...) end
function Frame:SetScale(v) self.scale=v end
function Frame:GetScale() return self.scale or 1 end
function Frame:StartMoving() end
function Frame:StopMovingOrSizing() end
function Frame:Enable() self.nativeEnabled=true end
function Frame:Disable() self.nativeEnabled=false end
function Frame:IsEnabled() return self.nativeEnabled~=false end
function Frame:SetEnabled(v) self.nativeEnabled=v and true or false end
function Frame:GetFont() return 'Fonts\\FRIZQT__.TTF',12,'' end
function Frame:SetFont(...) end
function Frame:SetTextColor(...) end
function Frame:SetShadowColor(...) end
function Frame:SetShadowOffset(...) end
function Frame:SetNonSpaceWrap(...) end
function Frame:SetWordWrap(...) end
function Frame:SetHyperlinksEnabled(...) end
function Frame:SetHitRectInsets(...) end
function Frame:SetID(v) self.id=v end
function Frame:GetID() return self.id or 0 end
function Frame:SetAttribute(k,v) self[k]=v end
function Frame:GetAttribute(k) return self[k] end
function Frame:GetButtonState() return 'NORMAL' end
function Frame:SetButtonState(...) end
function Frame:LockHighlight() self.locked=true end
function Frame:UnlockHighlight() self.locked=nil end
function CreateFrame(kind, name, parent, template) return NewFrame(parent or UIParent,name,kind or 'Frame') end

UIParent = NewFrame(nil,'UIParent','Frame')
GameTooltip = NewFrame(UIParent,'GameTooltip','GameTooltip')
ItemRefTooltip = NewFrame(UIParent,'ItemRefTooltip','GameTooltip')
ShoppingTooltip1 = NewFrame(UIParent,'ShoppingTooltip1','GameTooltip')
ShoppingTooltip2 = NewFrame(UIParent,'ShoppingTooltip2','GameTooltip')
DEFAULT_CHAT_FRAME = NewFrame(UIParent,'DEFAULT_CHAT_FRAME','ScrollingMessageFrame')
ChatFrame1 = DEFAULT_CHAT_FRAME
TradeSkillFrame = NewFrame(UIParent,'TradeSkillFrame','Frame'); TradeSkillFrame.visible=false
CraftFrame = NewFrame(UIParent,'CraftFrame','Frame'); CraftFrame.visible=false
Minimap = NewFrame(UIParent,'Minimap','Frame')
WorldFrame = NewFrame(UIParent,'WorldFrame','Frame')
UISpecialFrames = {}
SlashCmdList = {}
StaticPopupDialogs = {}
BOOKTYPE_SPELL='spell'
MAX_PLAYER_LEVEL=60
SOUNDKIT={}

function UnitName(unit) if unit=='player' then return 'Luck' end return 'Guildmate' end
function UnitClass(unit) return 'Priest','PRIEST' end
function UnitLevel(unit) return 60 end
function UnitFactionGroup(unit) return 'Alliance' end
function UnitAffectingCombat(unit) return false end
MOCK_GUILD_RANK_INDEX=0
function GetGuildInfo(unit) return 'Order of the Lion',MOCK_GUILD_RANK_INDEX==0 and 'Guild Leader' or 'Officer',MOCK_GUILD_RANK_INDEX end
function GetCVar(name) if name=='realmName' then return 'OctoWoW' end return '1' end
function GetRealmName() return 'OctoWoW' end
function GetLocale() return 'enUS' end
MOCK_ROSTER={}
function GetNumGuildMembers(showOffline) return table.getn(MOCK_ROSTER) end
function GetGuildRosterInfo(index)
  local m=MOCK_ROSTER[index]
  if not m then return nil end
  return m.name,m.rank,m.rankIndex,m.level or 60,m.class or 'Priest',m.zone or 'Stormwind',m.note or '',m.officerNote or '',m.online~=false
end
function GuildRoster() end
function GetGuildRosterMOTD() return 'Welcome' end
function GetGuildInfoText() return 'Guild information' end
function SetGuildRosterMOTD() end
function SetGuildInfoText() end
function GuildInvite() end
MOCK_GUILD_ACTIONS={promote=0,demote=0,remove=0,publicNote=0,officerNote=0}
function GuildUninvite(name) MOCK_GUILD_ACTIONS.remove=MOCK_GUILD_ACTIONS.remove+1 MOCK_GUILD_ACTIONS.last=name end
function GuildPromote(name) MOCK_GUILD_ACTIONS.promote=MOCK_GUILD_ACTIONS.promote+1 MOCK_GUILD_ACTIONS.last=name end
function GuildDemote(name) MOCK_GUILD_ACTIONS.demote=MOCK_GUILD_ACTIONS.demote+1 MOCK_GUILD_ACTIONS.last=name end
function GuildRosterSetPublicNote(index,note) MOCK_GUILD_ACTIONS.publicNote=MOCK_GUILD_ACTIONS.publicNote+1 end
function GuildRosterSetOfficerNote(index,note) MOCK_GUILD_ACTIONS.officerNote=MOCK_GUILD_ACTIONS.officerNote+1 end
function CanGuildInvite() return true end
function CanGuildPromote() return true end
function CanGuildDemote() return true end
function CanGuildRemove() return true end
function CanEditMOTD() return true end
function CanEditGuildInfo() return true end
function CanEditPublicNote() return true end
function CanEditOfficerNote() return true end
function CanViewOfficerNote() return true end
function IsGuildLeader() return MOCK_GUILD_RANK_INDEX==0 end
MOCK_SELECTED_GUILD_RANK=nil
function GuildControlSetRank(index) MOCK_SELECTED_GUILD_RANK=index end
function GuildControlGetNumRanks() return 13 end
MOCK_RANK_FLAGS_ALLOWED=true
function GuildControlGetRankFlags() local v=MOCK_RANK_FLAGS_ALLOWED and true or nil return true,true,true,true,v,v,true,v,true,true,true,true,true end
function GetNumGuildBankTabs() return 0 end
function GetGuildBankMoney() return 0 end
function GetChannelName(name) return 1,name end
MOCK_CHAT_MESSAGES={}
function SendChatMessage(message,channel,language,target) table.insert(MOCK_CHAT_MESSAGES,{message=message,channel=channel,language=language,target=target}) end
MOCK_SENT = {}
function SendAddonMessage(prefix,payload,channel) table.insert(MOCK_SENT,{prefix=prefix,payload=payload,channel=channel}) end
function RegisterAddonMessagePrefix() return true end
function ChatFrame_OpenChat(text) MOCK_CHAT=text end
MOCK_INVITES={}
function InviteByName(name) table.insert(MOCK_INVITES,name) end
function InviteUnit(name) table.insert(MOCK_INVITES,name) end
function ChatEdit_InsertLink(link) MOCK_LINK=link return true end
function SetItemRef(...) end
function DressUpItemLink(...) end
function IsModifiedClick(...) return false end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function GetMouseFocus() return nil end
function GetCursorPosition() return 0,0 end
function ToggleDropDownMenu(...) end
function CloseDropDownMenus() end
function EasyMenu(...) end
function StaticPopup_Show(...) return NewFrame(UIParent,nil,'Frame') end
function PlaySound(...) end
function ReloadUI() end
function IsAddOnLoaded(name) return name=='OrderOfTheLionGM' end
function GetAddOnInfo(name) return name,'Order of the Lion','',true,true end
function GetAddOnMetadata(name,key) if key=='Version' then return '1.7.2' end return nil end
function GetItemInfo(item)
  local id = tonumber(tostring(item):match('item:(%d+)')) or tonumber(item) or 100
  return 'Mock Item '..id,'|cff1eff00|Hitem:'..id..':0:0:0|h[Mock Item]|h|r',2,60,55,'Trade Goods','Parts',20,'','Interface\\Icons\\INV_Misc_Gear_01'
end
function GetItemIcon(item) return 'Interface\\Icons\\INV_Misc_Gear_01' end
function GetTradeSkillLine() return 'Alchemy',300,300 end
function GetNumTradeSkills() return 0 end
function GetTradeSkillInfo() return nil end
function GetTradeSkillItemLink() return nil end
function GetTradeSkillRecipeLink() return nil end
function GetTradeSkillNumReagents() return 0 end
function GetTradeSkillReagentInfo() return nil end
function GetTradeSkillReagentItemLink() return nil end
function GetCraftDisplaySkillLine() return 'Cooking',300,300 end
function GetNumCrafts() return 0 end
function GetCraftInfo() return nil end
function GetCraftItemLink() return nil end
function GetCraftNumReagents() return 0 end
function GetCraftReagentInfo() return nil end
function GetCraftReagentItemLink() return nil end
function GetNumSpellTabs() return 0 end
function GetSpellTabInfo() return nil end
function GetSpellName() return nil end
function GetSpellTexture() return nil end
function GetNumPartyMembers() return 0 end
function GetNumRaidMembers() return 0 end
function IsInGuild() return true end
function MouseIsOver() return false end
function FauxScrollFrame_Update() end
function FauxScrollFrame_GetOffset() return 0 end
function UIDropDownMenu_Initialize() end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_SetSelectedValue() end
function UIDropDownMenu_GetSelectedValue() return nil end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton() end
function SetPortraitToTexture() end
function PanelTemplates_SetNumTabs() end
function PanelTemplates_SetTab() end
`;

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function exec(code, name) {
  let status = lauxlib.luaL_loadbuffer(L, to_luastring(code), null, to_luastring(name));
  if (status !== lua.LUA_OK) throw new Error(`${name} load: ${to_jsstring(lua.lua_tostring(L,-1))}`);
  status = lua.lua_pcall(L,0,lua.LUA_MULTRET,0);
  if (status !== lua.LUA_OK) throw new Error(`${name} runtime: ${to_jsstring(lua.lua_tostring(L,-1))}`);
}
exec(mock,'@mock.lua');
for (const rel of files) {
  const full=path.join(root,rel);
  exec(fs.readFileSync(full,'utf8'),`@${rel}`);
}

const tests = String.raw`
local passed, failed = 0, 0
local function check(name, condition, detail)
  if condition then passed=passed+1
  else failed=failed+1 print('FAIL '..name..': '..tostring(detail or 'condition false')) end
end
local function safe(name, fn)
  local ok, result = pcall(fn)
  check(name, ok, result)
  return ok, result
end
local function effectivelyVisible(frame)
  local current=frame
  while current do
    if current.IsVisible and not current:IsVisible() then return false end
    current=current.GetParent and current:GetParent() or nil
  end
  return true
end
local function simulateClick(frame, mouseButton)
  if not frame then return false,'missing frame' end
  if not effectivelyVisible(frame) then return false,'hidden frame tree' end
  if not frame.mouse then return false,'mouse disabled' end
  if frame.IsEnabled and not frame:IsEnabled() then return false,'native disabled' end
  mouseButton=mouseButton or 'LeftButton'
  local registration=mouseButton=='RightButton' and 'RightButtonUp' or 'LeftButtonUp'
  if not frame.registeredClicks or not frame.registeredClicks[registration] then return false,'click not registered: '..registration end
  local script=frame:GetScript('OnClick')
  if type(script)~='function' then return false,'missing OnClick' end
  this=frame; arg1=mouseButton
  script()
  this=nil; arg1=nil
  return true
end
local function auditInteractiveTree(root)
  local totals={buttons=0,edits=0,missingMouse=0,missingClicks=0,stateMismatch=0,problems={}}
  local function walk(frame)
    local kind=frame.GetObjectType and frame:GetObjectType() or ''
    if kind=='Button' or kind=='CheckButton' then
      local click=frame:GetScript('OnClick')
      if click then
        totals.buttons=totals.buttons+1
        if not frame.mouse then totals.missingMouse=totals.missingMouse+1 table.insert(totals.problems,'button mouse '..tostring(frame:GetName() or frame.labelText or frame._text or frame.objectType)) end
        if not frame.registeredClicks or not frame.registeredClicks.LeftButtonUp then totals.missingClicks=totals.missingClicks+1 end
        local logicalDisabled=(frame.disabled==true) or (frame.enabled156==false)
        if frame.IsEnabled and ((not logicalDisabled) ~= frame:IsEnabled()) then totals.stateMismatch=totals.stateMismatch+1 table.insert(totals.problems,'state '..tostring(frame:GetName() or frame.labelText or frame._text or frame.objectType)) end
      end
    elseif kind=='EditBox' then
      totals.edits=totals.edits+1
      if not frame.otlInteractivePrepared170 then totals.missingMouse=totals.missingMouse+1 table.insert(totals.problems,'edit unprepared '..tostring(frame:GetName() or frame.objectType)) end
    end
    local children={frame:GetChildren()}
    for _,child in ipairs(children) do walk(child) end
  end
  walk(root)
  return totals
end

check('version', OTLGM.version=='1.7.5', OTLGM.version)
check('build-id', OTLGM.build=='stable-r7-20260723', OTLGM.build)
check('schema', OTLGM.schemaVersion==14, OTLGM.schemaVersion)
check('module-count', OTLGM:Count(OTLGM.modules)==27, OTLGM:Count(OTLGM.modules))

OTLGM_DB = 'corrupt-root'
safe('repair-scalar-root', function() OTLGM:EnsureDB() end)
check('root-is-table', type(OTLGM_DB)=='table' and type(OTLGM_DB.settings)=='table' and type(OTLGM_DB.guilds)=='table')
OTLGM_DB = { settings={ notifications={raid='bad'}, guildChatDrafts='bad', customMessages=7, customMessageNames='bad', recruitmentLastSent=false }, guilds={} }
safe('repair-nested-settings', function() OTLGM:EnsureDB() end)
check('nested-settings-tables', type(OTLGM_DB.settings.notifications.raid)=='table' and type(OTLGM_DB.settings.guildChatDrafts)=='table' and type(OTLGM_DB.settings.customMessages)=='table')

OTLGM_DB = { settings={ uiScale='99', networkPacketBudget='50', motionMode170='BAD', recruitmentRotation170='bad' }, guilds={} }
safe('ensure-db', function() OTLGM:EnsureDB() end)
check('clamp-ui-scale', OTLGM_DB.settings.uiScale==1.20, OTLGM_DB.settings.uiScale)
check('clamp-network-budget', OTLGM_DB.settings.networkPacketBudget==8, OTLGM_DB.settings.networkPacketBudget)
check('repair-motion', OTLGM_DB.settings.motionMode170=='FULL', OTLGM_DB.settings.motionMode170)
check('repair-rotation', type(OTLGM_DB.settings.recruitmentRotation170)=='table')

local old = {
  schemaVersion=9,
  roster={ Luck={level=60,class='Priest',rank='Guild Leader',rankIndex=0,lastSeen=MOCK_NOW} },
  log='bad',daily=false,pendingInvites=7,pendingActions='bad', memberFlags='bad', activity='bad', announcementSync='bad',
  detectedVersions={ bad='scalar', good={lastSeen=MOCK_NOW} },
  notificationUnread={PVE=7,CHAT=3},
  crafting={ characters={}, recipes={}, details={ broken='scalar' }, favorites170={ old='scalar' }, iconCache157={items={a='scalar'},names={b='scalar'}}, cacheQueue={x=1}, pendingRecipes={x=1}, syncState={active=true} },
  pve={applicationRetries={x=1},lastMaintenance=1}
}
local ok, migrated = pcall(function() return OTLGM:MigrateGuildDB(old) end)
check('migrate-old-shape', ok, migrated)
check('migrate-schema14', old.schemaVersion==14, old.schemaVersion)
check('migration-foundation', old.migration and old.migration.foundation170==true)
check('reset-notification-counters', old.notificationUnread.PVE==0 and old.notificationUnread.CHAT==0)
check('clear-session-queue', old.crafting.cacheQueue==nil)
check('clear-pve-retries', OTLGM:Count(old.pve.applicationRetries)==0)
check('repair-guild-containers', type(old.log)=='table' and type(old.daily)=='table' and type(old.memberFlags)=='table' and type(old.activity.days)=='table' and type(old.announcementSync)=='table')

-- A current-schema database must still self-heal malformed nested containers.
local currentBad = {
  name='Order of the Lion', realm='OctoWoW', schemaVersion=14, migration={foundation170=true}, roster='bad', log=false, activity={days='bad',allTimePeak='x'},
  announcementSync={requested='x'}, treasury170={goals='bad',deleted=false,history=3},
  crafting={characters={Broken='scalar',Good={professions={BAD='scalar',ALCHEMY={label='Alchemy',recipes='bad'}}}},requests='bad',responses=false,reactions=7,deleted='bad',events=false,details='bad',favorites170='bad',unread='bad',pendingRecipes='bad',syncState='bad'},
  pve={requests='bad',board=false,applications=7,deleted='bad',unread=false,reminded='bad',raids='bad',applicationRetries='bad'}
}
safe('migrate-current-malformed', function() OTLGM:MigrateGuildDB(currentBad) end)
check('current-top-containers-repaired', type(currentBad.roster)=='table' and type(currentBad.log)=='table' and type(currentBad.activity.days)=='table')
check('current-foundation-containers-repaired', type(currentBad.treasury170.goals)=='table' and type(currentBad.treasury170.deleted)=='table' and type(currentBad.treasury170.history)=='table')
local guildKey=OTLGM:GuildKey()
OTLGM_DB.guilds[guildKey]=currentBad
safe('current-crafting-containers-repaired', function() OTLGM:EnsureCraftingDB() end)
check('current-crafting-is-safe', type(currentBad.crafting.characters)=='table' and currentBad.crafting.characters.Broken==nil and type(currentBad.crafting.characters.Good.professions.ALCHEMY.recipes)=='table' and type(currentBad.crafting.requests)=='table' and type(currentBad.crafting.details)=='table' and type(currentBad.crafting.syncState)=='table')
safe('current-pve-containers-repaired', function() OTLGM:EnsurePveDB() end)
check('current-pve-is-safe', type(currentBad.pve.requests)=='table' and type(currentBad.pve.board)=='table' and type(currentBad.pve.raids)=='table' and type(currentBad.pve.applicationRetries)=='table')

local activeDb=OTLGM:GetGuildDB()
activeDb.roster.Luck={name='Luck',level=60,class='Priest',rank='Guild Leader',rankIndex=0,lastSeen=MOCK_NOW}
local backupText
safe('backup-export', function() backupText=OTLGM:ExportBackup() end)
check('backup-v2-header', type(backupText)=='string' and string.find(backupText,'OTLGM_BACKUP_V2',1,true)==1)
local beforeName=activeDb.roster.Luck.name
activeDb.roster.Luck.name='Changed'
local importOk,importMessage=OTLGM:ImportBackup(backupText)
check('backup-import', importOk, importMessage)
check('backup-restores-data', OTLGM:GetGuildDB().roster.Luck.name==beforeName, OTLGM:GetGuildDB().roster.Luck.name)
local preserved=OTLGM:GetGuildDB().roster.Luck.name
local badOk=OTLGM:ImportBackup('OTLGM_BACKUP_V2|broken')
check('bad-backup-rejected', badOk==false)
check('bad-backup-no-data-loss', OTLGM:GetGuildDB().roster.Luck.name==preserved)

safe('build-ui', function() OTLGM:BuildUI() end)
check('ui-built', OTLGM.ui and OTLGM.ui.v15Built==true)
OTLGM.ui.main:Show()
check('experience-built', OTLGM.ui and OTLGM.ui.experience170Built==true)
check('quick-menu-removed', OTLGM.ui.quickMenu170==nil and OTLGM.ui.quickLionButton170==nil)
check('group-finder-list-first', OTLGM.ui.pveGroupForm170 and not OTLGM.ui.pveGroupForm170:IsVisible())
check('favorites-control-built', OTLGM.ui.craftingFavoritesOnly170 ~= nil)
check('treasury-built', OTLGM.ui.treasury170 ~= nil)
check('status-hidden-initially', OTLGM.ui.statusBar and not OTLGM.ui.statusBar:IsVisible())
local annDb172=OTLGM:GetGuildDB()
annDb172.announcements['test-ann-172']={id='test-ann-172',revision=2,createdAt=MOCK_NOW,updatedAt=MOCK_NOW,author='Rangark',title='Test',body='Read receipt',importance='NORMAL',reactions={}}
safe('open-announcement-records-read', function() OTLGM:OpenAnnouncementReader152('test-ann-172') end)
local readers172=OTLGM:GetAnnouncementReaders172('test-ann-172')
check('announcement-read-receipt-local', table.getn(readers172)==1 and readers172[1]=='Luck', table.concat(readers172,','))
check('announcement-readers-button-built', OTLGM.ui.announcementReader152.readersButton172~=nil)
local primaryPages={'home','guildchat','search','pve','roster','professions','activity','treasury','overview','recruitment','history','inactive','settings'}
for _,pageKey in ipairs(primaryPages) do safe('show-page-'..pageKey, function() OTLGM:ShowPage(pageKey) end) end
local interactionAudit=auditInteractiveTree(UIParent)
check('all-script-buttons-mouse-enabled', interactionAudit.missingMouse==0, tostring(interactionAudit.missingMouse)..' '..table.concat(interactionAudit.problems,' | '))
check('all-script-buttons-click-registered', interactionAudit.missingClicks==0, interactionAudit.missingClicks)
check('all-button-native-logical-states-match', interactionAudit.stateMismatch==0, tostring(interactionAudit.stateMismatch)..' '..table.concat(interactionAudit.problems,' | '))
check('interactive-control-count', interactionAudit.buttons>=80 and interactionAudit.edits>=20, tostring(interactionAudit.buttons)..'/'..tostring(interactionAudit.edits))
check('hidden-global-modal-overlay', not (OTLGM.ui.modalOverlay152 and OTLGM.ui.modalOverlay152:IsVisible()))
check('hidden-group-form-shield', not OTLGM.ui.pveGroupFormShield170:IsVisible())
safe('member-mode-refresh', function() OTLGM:SetUIMode('MEMBER') OTLGM:RefreshAll() OTLGM:SetUIMode('AUTO') end)
OTLGM:SetStatus('Temporary',2)
check('status-shows', OTLGM.ui.statusBar:IsVisible() and OTLGM.ui.status:GetText()=='Temporary')
MOCK_NOW=MOCK_NOW+3
OTLGM:ProcessStatus170()
check('status-expires', not OTLGM.ui.statusBar:IsVisible() and OTLGM.ui.status:GetText()=='')

local focus = CreateFrame('EditBox',nil,UIParent)
focus.focused170=true
check('focus-tracker', OTLGM:IsEditBoxFocused170(focus)==true)
focus.focused170=nil; focus.HasFocus=nil
check('focus-no-api', OTLGM:IsEditBoxFocused170(focus)==false)
safe('treasury-refresh-no-hasfocus', function()
  local ui=OTLGM.ui.treasury170
  ui.nameEdit.HasFocus=nil; ui.nameEdit.focused170=nil
  OTLGM:RefreshTreasuryPage170(true)
end)

OTLGM.runtime.transport=nil; OTLGM.runtime.metrics={network={queued=0,sent=0,retried=0,dropped=0,rejected=0}}
check('queue-sync-one', OTLGM:QueuePvePayload('P1^SYNC^abc^1.7.2','GUILD',nil,'pve:sync'))
check('queue-sync-coalesce', OTLGM:QueuePvePayload('P1^SYNC^xyz^1.7.2','GUILD',nil,'pve:sync'))
local depth=OTLGM:GetNetworkQueueDepth()
check('coalesced-depth', depth==1, depth)
check('presence-v2-queue', OTLGM:BroadcastVersion())
local transport172=OTLGM.runtime.transport
local presenceItem172=transport172 and transport172.normal and transport172.normal.items[table.getn(transport172.normal.items)]
check('presence-v2-no-raw-pipe', presenceItem172 and string.find(presenceItem172.wirePayload or '', '|', 1, true)==nil, presenceItem172 and presenceItem172.wirePayload)
check('transport-sanitizes-raw-pipe', OTLGM:QueueNetworkPayload('X^unsafe|pipe','GUILD',nil,2,'test-sanitize'))
local sanitizeItem172=transport172 and transport172.normal and transport172.normal.items[table.getn(transport172.normal.items)]
check('transport-sanitized-payload-shape', sanitizeItem172 and string.find(sanitizeItem172.wirePayload or '', '%7C',1,true)~=nil and string.find(sanitizeItem172.wirePayload or '', '|',1,true)==nil, sanitizeItem172 and sanitizeItem172.wirePayload)
safe('process-queue', function() OTLGM:ProcessNetworkQueue(8) end)
check('wire-sent', table.getn(MOCK_SENT)>=1, table.getn(MOCK_SENT))

OTLGM.runtime.metrics.network.targetedSkipped=0
local skip=OTLGM:HandleAddonMessage('OTLGM','T1^SomeoneElse^P1^SYNC^a^1.7.2','GUILD','Guildmate')
check('targeted-other-is-normal', skip==true)
check('targeted-skip-metric', OTLGM.runtime.metrics.network.targetedSkipped==1, OTLGM.runtime.metrics.network.targetedSkipped)

local max=OTLGM:GetNetworkPayloadLimit('WHISPER','Guildmate')
check('targeted-limit', max>0 and max<250,max)
check('reject-oversize', OTLGM:QueueNetworkPayload(string.rep('x',251),'GUILD',nil,2,'test')==false)

OTLGM:ShowPage('professions')
OTLGM_DB.settings.craftingFavoritesOnly170=true
if OTLGM.ui.qReset156 and OTLGM.ui.qReset156:GetScript('OnClick') then
  this=OTLGM.ui.qReset156
  safe('reset-all-filters-click', function() this=OTLGM.ui.qReset156 OTLGM.ui.qReset156:GetScript('OnClick')() this=nil end)
end
check('favorites-filter-reset', OTLGM_DB.settings.craftingFavoritesOnly170~=true)

-- Search cache keys must include every visible filter state.
OTLGM:InvalidateCraftingSearchCache()
OTLGM.craftingFilterContext153=true
OTLGM_DB.settings.craftingFavoritesOnly170=false
OTLGM_DB.settings.craftingLevelBasis170='ITEM'
OTLGM:GetCraftingSearchResults('', 'ALL')
local builds0=OTLGM.runtime.craftingSearch.builds
OTLGM_DB.settings.craftingFavoritesOnly170=true
OTLGM:GetCraftingSearchResults('', 'ALL')
check('favorites-have-distinct-cache-key', OTLGM.runtime.craftingSearch.builds==builds0+1, OTLGM.runtime.craftingSearch.builds-builds0)
local builds1=OTLGM.runtime.craftingSearch.builds
OTLGM_DB.settings.craftingLevelBasis170='SKILL'
OTLGM:GetCraftingSearchResults('', 'ALL')
check('level-basis-has-distinct-cache-key', OTLGM.runtime.craftingSearch.builds==builds1+1, OTLGM.runtime.craftingSearch.builds-builds1)
OTLGM_DB.settings.craftingFavoritesOnly170=false
OTLGM_DB.settings.craftingLevelBasis170='ITEM'

-- The live-tested compact chat layout must remain the pre-card version.
OTLGM:ShowPage('guildchat')
safe('capture-chat-one', function() OTLGM:CaptureGuildChatMessage('GUILD','Hello Luck, welcome back.','Guildmate') end)
MOCK_NOW=MOCK_NOW+20
safe('capture-chat-two', function() OTLGM:CaptureGuildChatMessage('GUILD','Same author follow-up.','Guildmate') end)
MOCK_NOW=MOCK_NOW+20
safe('capture-chat-three', function() OTLGM:CaptureGuildChatMessage('GUILD','A different author block.','Another') end)
safe('refresh-compact-chat', function() OTLGM_DB.settings.guildChatView='GUILD' OTLGM:RefreshGuildChatPage() end)
local pinVisible, compactRows=false, true
for _,row in ipairs(OTLGM.ui.chatRows or {}) do
  if row.pinButton170 and row.pinButton170:IsVisible() and row.pinButton170.text then pinVisible=true end
  if row.rankButton170 or row.senderButton170 then compactRows=false end
end
check('chat-pin-control-visible', pinVisible)
check('chat-card-redesign-removed', compactRows)
check('chat-column-header-restored', OTLGM.ui.chatListHeader and OTLGM.ui.chatListHeader:IsVisible())
local rightClickSender=nil
for _,row in ipairs(OTLGM.ui.chatRows or {}) do if row:IsVisible() and row.senderButton and row.senderButton:GetScript('OnClick') then rightClickSender=row.senderButton break end end
check('chat-row-right-click-registration-preserved', rightClickSender and rightClickSender.registeredClicks and rightClickSender.registeredClicks.RightButtonUp==true)
local firstVisibleChatRow=nil
for _,row in ipairs(OTLGM.ui.chatRows or {}) do if row:IsVisible() and row.chatData then firstVisibleChatRow=row break end end
check('chat-uses-compact-row-height', firstVisibleChatRow and firstVisibleChatRow:GetHeight()<=50, firstVisibleChatRow and firstVisibleChatRow:GetHeight())
if firstVisibleChatRow and firstVisibleChatRow.pinButton170 then
  local beforePin=OTLGM:IsChatMessagePinned170(firstVisibleChatRow.chatData)
  this=firstVisibleChatRow.pinButton170
  safe('chat-pin-click', function() local ok,problem=simulateClick(firstVisibleChatRow.pinButton170) assert(ok,problem) end)
  check('chat-pin-state-toggles', OTLGM:IsChatMessagePinned170(firstVisibleChatRow.chatData)~=beforePin)
end

-- Permission fallbacks and target-rank rules must drive real roster actions.
local liveDb=OTLGM:GetGuildDB()
liveDb.roster.RightHand={name='RightHand',level=60,class='Mage',rank='Right Hand',rankIndex=1,online=true,lastSeen=MOCK_NOW}
liveDb.roster.Veteran={name='Veteran',level=60,class='Warrior',rank='Veteran',rankIndex=4,online=true,lastSeen=MOCK_NOW}
MOCK_ROSTER={{name='Luck',rank='Guild Leader',rankIndex=0},{name='RightHand',rank='Right Hand',rankIndex=1},{name='Veteran',rank='Veteran',rankIndex=4}}
OTLGM:RefreshSenderRosterCache(true)
safe('presence-v2-inbound', function() assert(OTLGM:HandleAddonMessage('OTLGM','V^1.7.2^stable-r3-20260720','GUILD','RightHand')) end)
local rightPresence172=OTLGM:GetGuildDB().detectedVersions.RightHand
check('presence-v2-stores-build', rightPresence172 and rightPresence172.version=='1.7.2' and rightPresence172.build=='stable-r3-20260720', rightPresence172 and tostring(rightPresence172.version)..'/'..tostring(rightPresence172.build))
safe('presence-legacy-inbound', function() assert(OTLGM:HandleAddonMessage('OTLGM','V|1.7.1','GUILD','Veteran')) end)
check('presence-legacy-still-accepted', OTLGM:GetGuildDB().detectedVersions.Veteran and OTLGM:GetGuildDB().detectedVersions.Veteran.version=='1.7.1')
CanGuildPromote=nil; CanGuildDemote=nil; CanGuildRemove=nil
CanEditPublicNote=nil; CanEditOfficerNote=nil; CanViewOfficerNote=nil
OTLGM.runtime.guildPermissionFlags170=nil
check('guild-leader-permission-fallback', OTLGM:CanPromoteMembers() and OTLGM:CanDemoteMembers() and OTLGM:CanRemoveMembers())
OTLGM:ShowPage('roster')
OTLGM.ui.selectedMember='RightHand'
safe('refresh-right-hand-actions', function() OTLGM:RefreshMemberPanel() end)
check('top-rank-promote-blocked', OTLGM.ui.promoteButton.disabled==true)
check('top-rank-demote-enabled', OTLGM.ui.demoteButton.disabled~=true)
check('top-rank-remove-enabled', OTLGM.ui.removeButton.disabled~=true)
check('roster-note-editboxes-interactive', OTLGM.ui.publicNoteEdit.mouse==true and OTLGM.ui.publicNoteEdit.keyboard==true and OTLGM.ui.officerNoteEdit.mouse==true and OTLGM.ui.officerNoteEdit.keyboard==true)
local savedRequestScan=OTLGM.RequestScan
OTLGM.RequestScan=function() end
this=OTLGM.ui.demoteButton
safe('demote-button-click', function() local ok,problem=simulateClick(OTLGM.ui.demoteButton) assert(ok,problem) end)
OTLGM.RequestScan=savedRequestScan
check('demote-api-called', MOCK_GUILD_ACTIONS.demote==1, MOCK_GUILD_ACTIONS.demote)
OTLGM.ui.selectedMember='Veteran'
safe('refresh-lower-rank-actions', function() OTLGM:RefreshMemberPanel() end)
check('lower-rank-promote-enabled', OTLGM.ui.promoteButton.disabled~=true)
check('lower-rank-demote-enabled', OTLGM.ui.demoteButton.disabled~=true)
check('lower-rank-remove-enabled', OTLGM.ui.removeButton.disabled~=true)
check('normalized-member-lookup', OTLGM:GetMember('Veteran-OctoWoW')==liveDb.roster.Veteran)
this=OTLGM.ui.promoteButton
safe('promote-button-click', function() local ok,problem=simulateClick(OTLGM.ui.promoteButton) assert(ok,problem) end)
check('promote-api-called', MOCK_GUILD_ACTIONS.promote==1, MOCK_GUILD_ACTIONS.promote)
this=OTLGM.ui.removeButton
safe('remove-button-click', function() local ok,problem=simulateClick(OTLGM.ui.removeButton) assert(ok,problem) end)
check('remove-confirm-opens', OTLGM.ui.confirmDialog:IsVisible())
this=OTLGM.ui.confirmDialog.confirm
safe('remove-confirm-click', function() local ok,problem=simulateClick(OTLGM.ui.confirmDialog.confirm) assert(ok,problem) end)
check('remove-api-called', MOCK_GUILD_ACTIONS.remove==1, MOCK_GUILD_ACTIONS.remove)
OTLGM.ui.publicNoteEdit:SetText('public')
OTLGM.ui.officerNoteEdit:SetText('officer')
this=OTLGM.ui.saveNotesButton
safe('save-notes-button-click', function() local ok,problem=simulateClick(OTLGM.ui.saveNotesButton) assert(ok,problem) end)
check('note-apis-called', MOCK_GUILD_ACTIONS.publicNote==1 and MOCK_GUILD_ACTIONS.officerNote==1, tostring(MOCK_GUILD_ACTIONS.publicNote)..'/'..tostring(MOCK_GUILD_ACTIONS.officerNote))
MOCK_GUILD_RANK_INDEX=2
OTLGM.runtime.guildPermissionFlags170=nil
check('officer-rank-flags-fallback', OTLGM:CanPromoteMembers() and OTLGM:CanDemoteMembers() and OTLGM:CanRemoveMembers())
MOCK_RANK_FLAGS_ALLOWED=false
OTLGM.runtime.guildPermissionFlags170=nil
check('rank-flags-deny-actions', not OTLGM:CanPromoteMembers() and not OTLGM:CanDemoteMembers() and not OTLGM:CanRemoveMembers())
MOCK_RANK_FLAGS_ALLOWED=true
MOCK_GUILD_RANK_INDEX=0
OTLGM.runtime.guildPermissionFlags170=nil

OTLGM:ShowPage('pve')
OTLGM_DB.settings.pveSection='GROUPS'
OTLGM:RefreshPvePage()
-- Group Finder opens as a modal composer and remains open on invalid input.
safe('open-group-composer', function() OTLGM:OpenGroupFinderComposer170() end)
check('group-composer-opens', OTLGM.ui.pveGroupForm170:IsVisible() and OTLGM.ui.pveGroupFormShield170:IsVisible())
local shieldLevel=OTLGM.ui.pveGroupFormShield170:GetFrameLevel()
local allAbove=true
local function verifyFrameTree(frame)
  if frame~=OTLGM.ui.pveGroupForm170 and frame:GetFrameLevel()<=shieldLevel then allAbove=false end
  local children={frame:GetChildren()}
  for _,child in ipairs(children) do verifyFrameTree(child) end
end
verifyFrameTree(OTLGM.ui.pveGroupForm170)
check('group-controls-above-modal-shield', allAbove)
check('group-form-captures-mouse', OTLGM.ui.pveGroupForm170.mouse==true)
OTLGM:ProcessExperienceMotion170(0.20)
check('group-form-finishes-visible', OTLGM.ui.pveGroupForm170:GetAlpha()==1, OTLGM.ui.pveGroupForm170:GetAlpha())
this=OTLGM.ui.pveKindButtons.QUEST
safe('group-kind-button-click', function() local ok,problem=simulateClick(OTLGM.ui.pveKindButtons.QUEST) assert(ok,problem) end)
check('group-kind-selection-works', OTLGM_DB.settings.pveRequestKind=='QUEST', OTLGM_DB.settings.pveRequestKind)
this=OTLGM.ui.pveRoleButtons.HEAL
safe('group-role-button-click', function() local ok,problem=simulateClick(OTLGM.ui.pveRoleButtons.HEAL) assert(ok,problem) end)
check('group-role-selection-works', OTLGM_DB.settings.pveRequestRole=='HEAL', OTLGM_DB.settings.pveRequestRole)
this=OTLGM.ui.pveGroupFormShield170
safe('group-shield-close-click', function() local ok,problem=simulateClick(OTLGM.ui.pveGroupFormShield170) assert(ok,problem) end)
check('group-shield-closes-form', not OTLGM.ui.pveGroupForm170:IsVisible() and not OTLGM.ui.pveGroupFormShield170:IsVisible())
safe('reopen-group-composer', function() OTLGM:OpenGroupFinderComposer170() end)
OTLGM.ui.pveRequestActivityEdit:SetText('')
this=OTLGM.ui.pveRequestCreateButton
safe('invalid-group-submit', function() local ok,problem=simulateClick(OTLGM.ui.pveRequestCreateButton) assert(ok,problem) end)
check('invalid-group-keeps-form', OTLGM.ui.pveGroupForm170:IsVisible())
OTLGM.ui.pveRequestActivityEdit:SetText('Blackrock Depths')
OTLGM.ui.pveRequestNoteEdit:SetText('Guild run')
safe('valid-group-submit', function() local ok,problem=simulateClick(OTLGM.ui.pveRequestCreateButton) assert(ok,problem) end)
check('valid-group-closes-form', not OTLGM.ui.pveGroupForm170:IsVisible() and not OTLGM.ui.pveGroupFormShield170:IsVisible())
check('group-created', table.getn(OTLGM:GetPveRequests())>=1, table.getn(OTLGM:GetPveRequests()))

-- Treasury uses gold units even when current progress is zero.
local goalOk,goalResult=OTLGM:SetTreasuryGoal170('TEST_GOAL','Second Guild Tab',0,2000*10000,'BANK')
check('treasury-goal-create', goalOk, goalResult)
safe('treasury-refresh-gold', function() OTLGM:RefreshTreasuryPage170(true) end)
local goldLabel=false
for _,row in ipairs(OTLGM.ui.treasury170.rows or {}) do if row.amount and string.find(row.amount:GetText(),'0g / 2000g',1,true) then goldLabel=true break end end
check('treasury-zero-shown-as-gold', goldLabel)
local treasuryRow=nil
for _,row in ipairs(OTLGM.ui.treasury170.rows or {}) do if row.goal170 and row.goal170.id=='TEST_GOAL' then treasuryRow=row break end end
OTLGM:ShowPage('treasury')
safe('treasury-row-select-click', function() local ok,problem=simulateClick(treasuryRow) assert(ok,problem) end)
check('treasury-row-selected', OTLGM.ui.treasury170.selected=='TEST_GOAL', OTLGM.ui.treasury170.selected)
check('treasury-editboxes-interactive', OTLGM.ui.treasury170.nameEdit.mouse==true and OTLGM.ui.treasury170.nameEdit.keyboard==true and OTLGM.ui.treasury170.currentEdit.mouse==true and OTLGM.ui.treasury170.targetEdit.mouse==true)
safe('treasury-delete-click', function() local ok,problem=simulateClick(OTLGM.ui.treasury170.delete) assert(ok,problem) end)
check('treasury-delete-confirm-opens', OTLGM.ui.confirmDialog:IsVisible())
safe('treasury-delete-confirm-click', function() local ok,problem=simulateClick(OTLGM.ui.confirmDialog.confirm) assert(ok,problem) end)
check('treasury-goal-deleted', OTLGM:GetTreasuryGoal170('TEST_GOAL')==nil)

-- Remote group controls must work for a non-owner through real UI click gates.
local pveDb=OTLGM:EnsurePveDB()
local remote={id='REMOTE_GROUP',rev=1,ts=MOCK_NOW,expires=MOCK_NOW+3600,author='Rangark',level=60,class='DRUID',kind='DUNGEON',activity='Stratholme',role='TANK',maxSize=5,current=1,needTank=0,needHeal=1,needDps=3,status='OPEN',note='test'}
pveDb.requests[remote.id]=remote
OTLGM.ui.pveSelectedRequest=remote.id
OTLGM_DB.settings.pveJoinRole='HEAL'
OTLGM:ShowPage('pve'); OTLGM_DB.settings.pveSection='GROUPS'; OTLGM:RefreshPvePage()
check('remote-group-join-enabled', OTLGM.ui.pveRequestJoinButton.disabled~=true and OTLGM.ui.pveRequestJoinButton:IsEnabled())
local selectedPveRow=nil
for _,row in ipairs(OTLGM.ui.pveRequestRows or {}) do if row:IsVisible() and row.requestData and row.requestData.id==remote.id then selectedPveRow=row break end end
check('pve-row-right-click-registration-preserved', selectedPveRow and selectedPveRow.registeredClicks and selectedPveRow.registeredClicks.RightButtonUp==true)
safe('remote-group-share-click', function() local ok,problem=simulateClick(OTLGM.ui.pveGroupShareButton) assert(ok,problem) end)
check('remote-group-share-sent', table.getn(MOCK_CHAT_MESSAGES)>0 and MOCK_CHAT_MESSAGES[table.getn(MOCK_CHAT_MESSAGES)].channel=='GUILD')
safe('remote-group-whisper-click', function() local ok,problem=simulateClick(OTLGM.ui.pveRequestWhisperButton) assert(ok,problem) end)
check('remote-group-whisper-opened', type(MOCK_CHAT)=='string' and string.find(MOCK_CHAT,'Rangark',1,true)~=nil, MOCK_CHAT)
OTLGM.ui.pveJoinNoteEdit:SetText('healer')
safe('remote-group-join-click', function() local ok,problem=simulateClick(OTLGM.ui.pveRequestJoinButton) assert(ok,problem) end)
local ownRemoteApplication=OTLGM:GetOwnPveApplication(remote.id)
check('remote-group-application-created', ownRemoteApplication and ownRemoteApplication.status=='PENDING')
OTLGM:RefreshPvePage()
safe('remote-group-cancel-click', function() local ok,problem=simulateClick(OTLGM.ui.pveRequestCancelAppButton) assert(ok,problem) end)
check('remote-group-application-cancelled', ownRemoteApplication.status=='CANCELLED', ownRemoteApplication.status)

-- Leader-side applicant controls must accept, invite, decline and whisper.
local ownGroup={id='OWN_GROUP',rev=1,ts=MOCK_NOW,expires=MOCK_NOW+3600,author='Luck',level=60,class='PRIEST',kind='DUNGEON',activity='BRD',role='HEAL',maxSize=5,current=1,needTank=1,needHeal=0,needDps=3,status='OPEN',note=''}
local remoteApp={id='REMOTE_APP',groupId=ownGroup.id,leader='Luck',author='Applicant',level=60,class='WARRIOR',role='TANK',note='ready',status='PENDING',rev=1,ts=MOCK_NOW,expires=MOCK_NOW+3600}
pveDb.requests[ownGroup.id]=ownGroup; pveDb.applications[remoteApp.id]=remoteApp
OTLGM.ui.pveSelectedRequest=ownGroup.id; OTLGM.ui.pveSelectedApplication=remoteApp.id; OTLGM:RefreshPvePage()
check('leader-accept-enabled', OTLGM.ui.pveApplicantAcceptButton.disabled~=true and OTLGM.ui.pveApplicantAcceptButton:IsEnabled())
safe('leader-applicant-whisper-click', function() local ok,problem=simulateClick(OTLGM.ui.pveApplicantWhisperButton) assert(ok,problem) end)
check('leader-applicant-whisper-opened', type(MOCK_CHAT)=='string' and string.find(MOCK_CHAT,'Applicant',1,true)~=nil, MOCK_CHAT)
safe('leader-accept-invite-click', function() local ok,problem=simulateClick(OTLGM.ui.pveApplicantAcceptButton) assert(ok,problem) end)
check('leader-application-accepted', remoteApp.status=='ACCEPTED', remoteApp.status)
check('leader-invite-called', table.getn(MOCK_INVITES)>0 and MOCK_INVITES[table.getn(MOCK_INVITES)]=='Applicant')

safe('refresh-all', function() OTLGM:RefreshAll() end)
local diagnosticsText
safe('diagnostics', function() diagnosticsText=OTLGM:GetDiagnosticsText() return diagnosticsText end)
check('diagnostics-show-permission-source', diagnosticsText and string.find(diagnosticsText,'Guild action permissions:',1,true)~=nil)
check('diagnostics-show-build-id', diagnosticsText and string.find(diagnosticsText,'Build: stable-r7-20260723',1,true)~=nil)
check('diagnostics-show-interaction-audit', diagnosticsText and string.find(diagnosticsText,'UI interactive controls',1,true)~=nil)

print('INTERACTION buttons='..tostring(interactionAudit and interactionAudit.buttons or 0)..' editboxes='..tostring(interactionAudit and interactionAudit.edits or 0)..' missingMouse='..tostring(interactionAudit and interactionAudit.missingMouse or 0)..' missingClicks='..tostring(interactionAudit and interactionAudit.missingClicks or 0)..' stateMismatch='..tostring(interactionAudit and interactionAudit.stateMismatch or 0))
print('RESULT passed='..tostring(passed)..' failed='..tostring(failed))
if failed>0 then error('runtime tests failed: '..failed) end
`;
exec(tests,'@tests.lua');
