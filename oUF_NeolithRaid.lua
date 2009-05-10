--[[---------------------------------------------------------------------

	oUF_NeolithRaid
	by neolith of EU_Aegwynn
	Based upon oUF_Lily, oUF_Mastiff, oUF_AmnithRaid and countless others

-----------------------------------------------------------------------]]

--[[     files     ]]
local texture		= "Interface\\AddOns\\oUF_NeolithRaid\\textures\\statusbar"
local border		= "Interface\\AddOns\\oUF_NeolithRaid\\textures\\border"
--~ local buffborder	= "Interface\\AddOns\\oUF_NeolithRaid\\textures\\buffborder"		-- not used (yet)
local font			= "Interface\\AddOns\\oUF_NeolithRaid\\fonts\\ABF.ttf"
local overlay		= "Interface\\AddOns\\oUF_NeolithRaid\\textures\\overlay"
local mohighlight	= "Interface\\AddOns\\oUF_NeolithRaid\\textures\\highlight"

--[[     basic setup     ]]
local width			= 64
local height		= 20
local manaheight	= 2
local xheaderoffset	= 10
local yheaderoffset	= 10
local fontsize		= 9

local select = select
local UnitIsPlayer = UnitIsPlayer
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local UnitReactionColor = UnitReactionColor
local UnitReaction = UnitReaction
--~ local FONT = STANDARD_TEXT_FONT		-- declared different font in files section
local strlen = string.len
local substr = string.sub
local ceil = math.ceil


--[[     frame background     ]]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], tile = true, tileSize = 16,		-- background texture
	edgeFile = border, edgeSize = 16,														-- border texture
	insets = {top = 4, left = 4, bottom = 4, right = 4},									-- insets (pixel of border texture from outside to middle)
}

--[[     color metatable (energy bar)     ]]
local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {.31,.45,.63},
		['RAGE'] = {.69,.31,.31},
		['FOCUS'] = {.71,.43,.27},
		['ENERGY'] = {.65,.63,.35},
		['RUNIC_POWER'] = {0,.8,.9},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

--[[     shortname_raid     ]]
oUF.Tags['[shortname_raid]']  = function(u) local name = UnitName(u); if(name) then return name:sub(1, 4) else return '' end end
oUF.TagEvents['[shortname_raid]']   = 'UNIT_NAME_UPDATE'
--~ oUF.Tags['[powertype]'] = function(u) local n,s = UnitPowerType(u) return (s) end			-- commented out because of no powertext

--[[     power type check neo     ]]														-- obsolete
--~ local showMana = function(self, unit)
--~ 	local num, str = UnitPowerType(unit)
--~ 	if num == 0 then
--~ 		return true
--~ 	else
--~ 		return false
--~ 	end
--~ end

--[[     self     ]]
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

--~ 	if(unit == "party" or unit == "partypet") then
--~ 		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
--~ 	elseif(_G[cunit.."FrameDropDown"]) then
--~ 		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
--~ 	end
	if(self.unit:match('^raid')) then
		self.name = unit
		RaidGroupButton_ShowMenu(self)
	end

end

--[[     siValue     ]]
local siValue = function(val)
	if(val >= 1e5) then
		return ("%.1f"):format(val / 1e4):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

--[[     updateName     ]]
--~ local updateName = function(self, event, unit)
--~ 	if(self.unit ~= unit) then return end
--~ 	self.Name:SetTextColor(1, 1, 1)
--~ 	self.Name:SetText(substr(UnitName(unit), 0, 4)) 
--~ end

--[[     health bar function    ]]
local updateHealth = function(self, event, unit, bar, min, max)
	local perc = floor(min/max*100)
	if(not UnitIsConnected(unit)) then
		bar:SetValue(0)
		bar.value:SetText('|cff808080'..'Off')
	elseif(UnitIsDead(unit)) then
		bar.value:SetText('|cff7A0609'..'Dead')
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText('|cff00CAFF'..'Ghost')
	elseif(min==max) then
--~ 		bar.value:SetFormattedText(ShortValue(min))
		bar.value:SetText()
	else
--~ 		bar.value:SetFormattedText(perc)
		bar.value:SetText()
	end

end


--[[     bar styles     ]]
local func = function(settings, self, unit)
	self.colors = colors
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")
	
	--[[ Health Bar ]]
	local hp = CreateFrame"StatusBar"

	hp:SetHeight(height-8)
	hp:SetStatusBarTexture(texture)
	hp.colorTapping = true
  	hp.colorClass = true
	hp.colorReaction = true

	hp.frequentUpdates = true

	hp:SetParent(self)
	hp:SetPoint("TOP", 0, -4)
	hp:SetPoint("LEFT", 4, 0)
	hp:SetPoint("RIGHT", -4, 0)
	
	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hpbg.multiplier = .2

	self:SetBackdrop(backdrop)								-- BACKDROP
	self:SetBackdropColor(0, 0, 0, .7)
	self:SetBackdropBorderColor(.3, .3, .3, 1)
	
	--[[ Health Text ]]
	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetFont(font, fontsize)
	hpp:SetShadowOffset(1, -1)
	hpp:SetTextColor(1, 1, 1)
  	
	hpp:SetPoint("RIGHT", hp, -2, 0)

	hp.bg = hpbg
	hp.value = hpp
	self.Health = hp
--~ 	self.Health.Smooth = true	

	if unit then
		self.Health:SetFrameLevel(1)
	elseif self:GetAttribute('unitsuffix') then
		self.Health:SetFrameLevel(3)
	elseif not unit then
		self.Health:SetFrameLevel(2)
	end

	self.PostUpdateHealth = updateHealth



--~ 	local hpp = hp:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
--~ 	hpp:SetPoint("RIGHT", -2, 0)
--~ 	hpp:SetShadowOffset(1, -1)
--~ 	hpp:SetTextColor(1, 1, 1)
--~ 	self:Tag(hpp, "[amnithstatus]")
--~ 	
--~ 	hp.bg = hpbg

--~ 	self.Health = hp
--~ 	self.Health.colorDisconnected = true
--~ 	self.Health.colorClass = true

	--[[ Mana Bar ]]--[[]]																	-- no workey check for use mana :(
--~ 	if unit:match("oUF_Raid") then
--~ 	if unit then
	local unitInRaid = self:GetParent():GetName():match"oUF_Raid" 
--~ 	local unitInParty = self:GetParent():GetName():match"oUF_Party"
--~ 	local unitIsPartyPet = unit and unit:find('partypet%d')
	
--~ 	if(not UnitIsConnected(unit)) then
--~ 		bar:SetValue(0)
--~ 		bar.value:SetText('|cff808080'..'Off')
--~ 	elseif(UnitIsDead(unit)) then
--~ 		bar.value:SetText('|cff7A0609'..'Dead')
--~ 	elseif(UnitIsGhost(unit)) then
	
	
	
--~ 	if unitInRaid and not (UnitIsConnected(unitInRaid) or UnitIsDead(unitInRaid) or UnitIsGhost(unitInRaid)) then
--~ 	if unitInRaid or unitInParty or unitIsPartyPet then
		if unitInRaid then
		
		local powertype, _ = UnitPowerType(unitInRaid)
		if powertype == 0 then
		
			hp:SetHeight(height-(manaheight+8))
			
			local pp = CreateFrame"StatusBar"
			
			pp:SetHeight(manaheight)
			pp:SetStatusBarTexture(texture)
			pp.colorPower = true
--~ 			pp.colorClass = true
--~ 			pp.colorReaction = true
			
			pp.frequentUpdates = true
			
			pp:SetParent(self)
			pp:SetPoint("BOTTOM", 0, 4)
			pp:SetPoint("LEFT", 4, 0)
			pp:SetPoint("RIGHT", -4, 0)
			
			self.Power = pp
			
--~ 		local hpbg = hp:CreateTexture(nil, "BORDER")
--~ 		hpbg:SetAllPoints(hp)
--~ 		hpbg:SetTexture(texture)
--~ 		hpbg.multiplier = .2
			if unit then
				self.Power:SetFrameLevel(1)
			elseif self:GetAttribute('unitsuffix') then
				self.Power:SetFrameLevel(3)
			elseif not unit then
				self.Power:SetFrameLevel(2)
			end

		end
	end
	
--~ 	local unitInRaid = self:GetParent():GetName():match"oUF_Raid" 
--~ 	for i = 1, 40 do
--~ 		if
--~ 	end
	

	
	
--~ 		local unitInRaid = self:GetParent():GetName():match"oUF_Raid" 
--~ 		if unitInRaid then
--~ 			if not UnitIsConnected(unitInRaid) then
--~ 				hp:SetHeight(height-12)
--~ 			end
--~ 		end




	--[[ Name ]]
	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", hp, 2, 0)
	name:SetJustifyH"LEFT"
	name:SetFont(font, fontsize)
	name:SetTextColor(1, 1, 1)
	name:SetShadowOffset(1, -1)
	self.Info = name
	self:Tag(self.Info,'[shortname_raid]')

	--[[ MouseOverHighlight ]]
	local highlight = self:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints(self)
	highlight:SetBlendMode("ADD")
--~ 	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	highlight:SetPoint ("TOPLEFT",self,"TOPLEFT",2,-2)
	highlight:SetPoint ("BOTTOMRIGHT",self,"BOTTOMRIGHT",-2,2)
	highlight:SetTexture(mohighlight)
	self.Highlight = highlight

	--[[ Range Check ]]
	if (not unit) and (not self:GetAttribute('unitsuffix') == 'target') then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end
	
	--[[ Debuff Highlight ]]
	local dbh = hp:CreateTexture(nil, "OVERLAY")
	dbh:SetAllPoints(self)
	dbh:SetTexture(overlay)
	dbh:SetBlendMode("ADD")
	dbh:SetVertexColor(0,0,0,0) -- set alpha to 0 to hide the texture
	self.DebuffHighlight = dbh

	--[[ Leader Icon ]]
--~ 	if not (self:GetAttribute('unitsuffix') == 'target') then
	if not (self:GetParent():GetName():match'oUF_MainTank') then
	    local leader = hp:CreateTexture(nil, "OVERLAY")
	    leader:SetHeight(14)
	    leader:SetWidth(14)
	    leader:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", -5, -7)
	    leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
	    self.Leader = leader
	end

	--[[ Masterlooter Icon ]]
--~ 	if not (self:GetAttribute('unitsuffix') == 'target') or not (self:GetParent():GetName():match'oUF_MainTank') then
	if not (self:GetParent():GetName():match'oUF_MainTank') then
--~ 	if not (self:GetAttribute('unitsuffix') == 'target') or not (string.find (self:GetParent():GetName(), 'oUF_MainTank')) then
	    local looter = hp:CreateTexture(nil, "OVERLAY")
	    looter:SetHeight(10)
	    looter:SetWidth(10)
	    looter:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", 10, -4)
	    looter:SetTexture"Interface\GroupFrame\UI-Group-MasterLooter"
	    self.MasterLooter = looter
	end

	--[[ RTIs ]]
	if not (string.find (self:GetParent():GetName(), 'oUF_MainTank')) then
		local ricon = hp:CreateTexture(nil, "OVERLAY")
		ricon:SetHeight(11)
		ricon:SetWidth(11)
		if (self:GetAttribute('unitsuffix') == 'target') then
			ricon:SetPoint("LEFT", hp, "RIGHT", 0, 0)
		else
			ricon:SetPoint("RIGHT", hp, "LEFT", 0, 0)
		end
		ricon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
		self.RaidIcon = ricon
	elseif (self:GetAttribute('unitsuffix') == 'target') then
		local ricon = hp:CreateTexture(nil, "OVERLAY")
		ricon:SetHeight(16)
		ricon:SetWidth(16)
		if (self:GetAttribute('unitsuffix') == 'target') then
			ricon:SetPoint("LEFT", hp, "RIGHT", 0, 0)
		else
			ricon:SetPoint("RIGHT", hp, "LEFT", 0, 0)
		end
		ricon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
		self.RaidIcon = ricon
	end
	
	return self


--~ 	self.menu = menu

--~ 	self:EnableMouse(true)
--~ 	self:SetMovable(true)
--~ 	self:SetScript("OnEnter", function(self) UnitFrame_OnEnter(self) end)
--~ 	self:SetScript("OnLeave", function(self) UnitFrame_OnLeave(self) end)

--~ 	self:RegisterForClicks"anyup"
--~ 	self:SetAttribute("*type2", "menu")

--~ 	self:SetHeight(height)

--~ 	local hp = CreateFrame"StatusBar"
--~ 	hp:SetHeight(height)
--~ 	hp:SetStatusBarTexture(texture)
--~ 	hp:SetStatusBarColor(.25, .25, .35)

--~ 	hp:SetParent(self)
--~ 	hp:SetPoint"TOP"
--~ 	hp:SetPoint"LEFT"
--~ 	hp:SetPoint"RIGHT"

--~ 	local hpbg = hp:CreateTexture(nil, "BORDER")
--~ 	hpbg:SetAllPoints(hp)
--~ 	hpbg:SetTexture(0, 0, 0, .5)

--~ 	local hpp = hp:CreateFontString(nil, "OVERLAY")
--~ 	hpp:SetPoint("RIGHT", -2, 0)
--~ 	hpp:SetFont(font, fontsize)--, "OUTLINE")
--~ 	hpp:SetShadowOffset(1, -1)
--~ 	hpp:SetTextColor(1, 1, 1)
--~ 		
--~ 	hp.bg = hpbg
--~ 	hp.value = hpp
--~ 	self.Health = hp
--~ 	self.OverrideUpdateHealth = updateHealth

--~ 	local leader = hp:CreateTexture(nil, "OVERLAY")
--~ 	leader:SetHeight(16)
--~ 	leader:SetWidth(16)
--~ 	leader:SetPoint("CENTER", hp, "CENTER", 0, 10)
--~ 	leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
--~ 	self.Leader = leader

--~ 	local ricon = hp:CreateTexture(nil, "OVERLAY")
--~ 	ricon:SetHeight(16)
--~ 	ricon:SetWidth(16)
--~ 	ricon:SetPoint("LEFT", hp, "LEFT", -5, 10)
--~ 	ricon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
--~ 	self.RaidIcon = ricon

--~ 	local name = hp:CreateFontString(nil, "OVERLAY")
--~ 	name:SetPoint("LEFT", 2, 0)
--~ 	name:SetJustifyH"LEFT"
--~ 	name:SetFont(font, fontsize) --, "OUTLINE")
--~ 	name:SetShadowOffset(1, -1)
--~ 	name:SetTextColor(1, 1, 1)
--~ 	self.Name = name
--~ 	self.UNIT_NAME_UPDATE = updateName

--~ 	if(not unit) then
--~ 		self.Range = true 
--~ 		self.inRangeAlpha = 1.0
--~ 		self.outsideRangeAlpha = 0.5
--~ 	end

--~ 	return self
end

--[[     register style     ]]
oUF:RegisterStyle("oUF_NeolithRaid", setmetatable({
	["initial-width"] = width,
	["initial-height"] = height,
}, {__call = func}))

--[[     spawn frames     ]]
oUF:SetActiveStyle"oUF_NeolithRaid"

local raid = {}
for i = 1, 8 do
	table.insert(raid, oUF:Spawn("header", "oUF_Raid"..i))
	if i == 1 then
		raid[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xheaderoffset, -150)
	elseif i == 3 then
		raid[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xheaderoffset, -(250+yheaderoffset))
	elseif i == 5 then
		raid[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xheaderoffset, -(350+2*yheaderoffset))
	elseif i == 7 then
		raid[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xheaderoffset, -(450+3*yheaderoffset))
	else
		raid[i]:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", xheaderoffset, 0)
	end
	raid[i]:SetManyAttributes("showRaid", true, "groupFilter", i)
	raid[i]:Show()
end

local tank = oUF:Spawn('header', 'oUF_MainTank')
	tank:SetManyAttributes('showRaid', true, 'groupFilter', 'MAINTANK')
	--~ tank:SetPoint('TOPLEFT', raid4, 'TOPRIGHT', xheaderoffset, 0)
	--~ tank:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT',-10, 20)
	tank:SetPoint('TOPLEFT', raid[4], 'TOPRIGHT', (xheaderoffset*2), 0)
	tank:SetAttribute("template", "oUF_NeolithMainTank")
	tank:Show()

--~ local MTTitle = CreateFrame('Frame', 'MTTitle', 'oUFMain_Tank')

--~ 	MTTitle:SetHeight(10)
--~ 	MTTitle:SetWidth(10)
--~ 	MTTitle:SetColor(0.0, 0.0, 0.0, 0.5)
--~ 	MTTitle:SetPoint('BOTTOMLEFT',oUF.units.tank, 'TOPLEFT', 0, 0)
--~ 	MTTitle:Show()

local MTTitle = CreateFrame("Frame",nil,oUF_MainTank)
	MTTitle:SetFrameStrata("BACKGROUND")
	MTTitle:SetWidth(22) -- Set these to whatever height/width is needed 
	MTTitle:SetHeight(14) -- for your Texture
	MTTitle:SetPoint('BOTTOMLEFT', oUF_MainTank, 'TOPLEFT', 2, -1)

local MTTitleTexture = MTTitle:CreateTexture(nil,"BACKGROUND")
	MTTitleTexture:SetTexture(texture)
	MTTitleTexture:SetVertexColor(0.0, 0.0, 0.0, 0.6)
	MTTitleTexture:SetAllPoints(MTTitle)
	MTTitle.texture = MTTitleTexture
--~ 	MTTitle:SetPoint('BOTTOMLEFT', oUF_MainTank, 'TOPLEFT', 4, 0)
	MTTitle:Show()

local MTTitleText = MTTitle:CreateFontString(nil, "OVERLAY")
	MTTitleText:SetPoint("LEFT", MTTitle, 2, 0)
	MTTitleText:SetJustifyH"LEFT"
	MTTitleText:SetFont(font, fontsize)
	MTTitleText:SetTextColor(1, 1, 1)
	MTTitleText:SetText("MTs")
--~ 	MTTitleText:SetShadowOffset(1, -1)

local MTTitleToggle = CreateFrame('Frame')
	MTTitleToggle:RegisterEvent('PLAYER_LOGIN')
	MTTitleToggle:RegisterEvent('RAID_ROSTER_UPDATE')
	MTTitleToggle:RegisterEvent('PARTY_LEADER_CHANGED')
	MTTitleToggle:RegisterEvent('PARTY_MEMBERS_CHANGED')
	
	MTTitleToggle:SetScript('OnEvent', function(self)
		if oUF_MainTankUnitButton1 and oUF_MainTankUnitButton1:IsVisible() then
			MTTitle:Show()
		else
			MTTitle:Hide()
		end
	end)