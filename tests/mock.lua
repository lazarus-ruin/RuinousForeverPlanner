TEST_P={}
TEST_LEVEL=26
TEST_GUID='character-A'
TEST_COMBAT=false
TEST_CACHED=true
TEST_BADBAG=false
NUM_BAG_SLOTS=4
SlashCmdList={}
UIParent={}
function UnitClass() return 'Priest','PRIEST',5 end
function UnitGUID() return TEST_GUID end
function UnitLevel() return TEST_LEVEL end
function UnitFactionGroup() return 'Alliance' end
function GetBuildInfo() return '1.60.1','70170','Oct 1',16001 end
function InCombatLockdown() return TEST_COMBAT end
function issecretvalue() return false end
function GetInventoryItemID(_,slot) if slot==5 then return 6682 end end
function GetInventoryItemLink(_,slot) if slot==5 then return 'item:6682' end end
C_Item={
 GetItemInfo=function(v) if TEST_CACHED then
  local id=tonumber(tostring(v):match('item:(%d+)')) or tonumber(v) or 0
  local locs={[253987]='INVTYPE_LEGS',[6682]='INVTYPE_ROBE',[6685]='INVTYPE_SHOULDER',[2042]='INVTYPE_2HWEAPON',[253913]='INVTYPE_HAND',[254001]='INVTYPE_FEET'}
  return 'Cached item '..id,'item:'..id,3,30,id==6682 and 26 or 25,'Armor','Cloth',1,locs[id] or ''
 end end,
 GetItemStats=function(link) return {ITEM_MOD_INTELLECT_SHORT=7,ITEM_MOD_STAMINA_SHORT=4} end,
 RequestLoadItemDataByID=function() TEST_REQUESTS=(TEST_REQUESTS or 0)+1 end
}
C_Container={
 GetContainerNumSlots=function(bag) if TEST_BADBAG then error('blocked') end; return bag==0 and 2 or 0 end,
 GetContainerItemInfo=function(_,slot) if slot==1 then return {itemID=253987,stackCount=1,hyperlink='item:253987'} end end
}
TEST_QUEST_COMPLETED={}
TEST_QUEST_ACTIVE={}
C_QuestLog={
 IsQuestFlaggedCompleted=function(id) return TEST_QUEST_COMPLETED[id]==true end,
 IsOnQuest=function(id) return TEST_QUEST_ACTIVE[id]==true end
}
local methods={}
TEST_TOOLTIP_CALLS={}
function methods:SetOwner(owner,anchor) self.owner=owner; self.anchor=anchor end
function methods:SetHyperlink(link) TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS+1]={'target',link}; if TEST_TOOLTIP_THROW then error('restricted') end; return not TEST_TOOLTIP_DENY end
function methods:SetInventoryItem(unit,slot) TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS+1]={'equipped',unit,slot}; return true end
function methods:SetBagItem(bag,slot) TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS+1]={'bag',bag,slot}; return true end
function methods:SetScript(k,f) self.scripts[k]=f end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:SetText(t) self.text=t end
function methods:GetStringHeight() return 500 end
function methods:GetHeight() return self.height or 400 end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:SetHeight(h) self.height=h end
function methods:Show() local was=self.shown; self.shown=true; if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() local was=self.shown; self.shown=false; if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
for _,k in ipairs({'SetFrameStrata','SetFrameLevel','SetNormalTexture','SetPushedTexture','SetHighlightTexture','RegisterForClicks','ClearAllPoints','SetSize','SetPoint','SetClampedToScreen','SetMovable','EnableMouse','RegisterForDrag','StartMoving','StopMovingOrSizing','SetAllPoints','SetColorTexture','SetScrollChild','SetWidth','SetJustifyH','SetJustifyV','SetSpacing'}) do methods[k]=function() end end
function methods:CreateTexture() return setmetatable({scripts={},events={}}, {__index=methods}) end
function methods:CreateFontString()
 local f=setmetatable({scripts={},events={},parent=self}, {__index=methods});TEST_FONTS=TEST_FONTS or {};TEST_FONTS[#TEST_FONTS+1]=f;return f
end
TEST_FRAMES={}
function CreateFrame(kind,name,parent,template)
 local f=setmetatable({scripts={},events={},shown=true,kind=kind,name=name,parent=parent}, {__index=methods})
 TEST_FRAMES[#TEST_FRAMES+1]=f
 return f
end
local nativeLoadString=loadstring
function loadstring(s) if nativeLoadString then return nativeLoadString(s) end; return load(s) end

function methods:SetSpacing() TEST_BODY=self end
function methods:GetCenter() return 500,400 end

function methods:SetFrameStrata(value) self.strata=value end
function methods:SetFrameLevel(value) self.frameLevel=value end
function methods:SetColorTexture(r,g,b,a) self.alpha=a end

function methods:SetAutoFocus() end
function methods:SetMaxLetters() end
function methods:SetMultiLine(value) self.multiline=value end
function methods:SetFontObject(value) self.fontObject=value end
function methods:GetText() return self.text or '' end
