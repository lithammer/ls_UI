local _, ns = ...
local E, C, M, L, P = ns.E, ns.C, ns.M, ns.L, ns.P
local UF = P:GetModule("UnitFrames")

-- Lua
local _G = getfenv(0)
local m_max = _G.math.max
local m_min = _G.math.min
local next = _G.next
local select = _G.select
local unpack = _G.unpack

-- Blizz
local C_MountJournal = _G.C_MountJournal

--[[ luacheck: globals
	CreateFrame GameTooltip UIParent UnitIsFriend UnitIsUnit
]]

-- Mine
local MOUNTS = {}

for _, id in next, C_MountJournal.GetMountIDs() do
	MOUNTS[select(2, C_MountJournal.GetMountInfoByID(id))] = true
end

local filterFunctions = {
	default = function(self, unit, aura, _, _, _, debuffType, duration, _, caster, isStealable, _, spellID, _, isBossAura)
		local config = self._config and self._config.filter or nil
		if not config then return end

		-- black- and whitelists
		for filter, enabled in next, config.custom do
			if enabled then
				filter = C.db.global.aura_filters[filter]
				if filter and filter[spellID] then
					return filter.state
				end
			end
		end

		local isFriend = UnitIsFriend("player", unit)

		config = isFriend and config.friendly or config.enemy
		if not config then return end

		config = aura.isDebuff and config.debuff or config.buff
		if not config then return end

		-- boss
		isBossAura = isBossAura or E:IsUnitBoss(caster)
		if isBossAura then
			return config.boss
		end

		-- applied by tank
		if caster and E:IsUnitTank(caster) then
			return config.tank
		end

		-- applied by healer
		if caster and E:IsUnitTank(caster) then
			return config.healer
		end

		-- mounts
		if MOUNTS[spellID] then
			return config.mount
		end

		-- self-cast
		if caster and UnitIsUnit(unit, caster) then
			if duration and duration ~= 0 then
				return config.selfcast
			else
				return config.selfcast and config.selfcast_permanent
			end
		end

		-- applied by player
		if aura.isPlayer or (caster and UnitIsUnit(caster, "pet")) then
			if duration and duration ~= 0 then
				return config.player
			else
				return config.player and config.player_permanent
			end
		end

		if isFriend then
			if aura.isDebuff then
				-- dispellable
				if debuffType and E:IsDispellable(debuffType) then
					return config.dispellable
				end
			end
		else
			-- stealable
			if isStealable then
				return config.dispellable
			end
		end

		return config.misc
	end,
	boss = function(self, unit, aura, _, _, _, debuffType, duration, _, caster, isStealable, _, spellID, _, isBossAura)
		local config = self._config and self._config.filter or nil
		if not config then return end

		-- black- and whitelists
		for filter, enabled in next, config.custom do
			if enabled then
				filter = C.db.global.aura_filters[filter]
				if filter and filter[spellID] then
					return filter.state
				end
			end
		end

		local isFriend = UnitIsFriend("player", unit)

		config = isFriend and config.friendly or config.enemy
		if not config then return end

		config = aura.isDebuff and config.debuff or config.buff
		if not config then return end

		-- boss
		isBossAura = isBossAura or E:IsUnitBoss(caster)
		if isBossAura then
			return config.boss
		end

		-- applied by tank
		if caster and E:IsUnitTank(caster) then
			return config.tank
		end

		-- applied by healer
		if caster and E:IsUnitTank(caster) then
			return config.healer
		end

		-- applied by player
		if aura.isPlayer or (caster and UnitIsUnit(caster, "pet")) then
			if duration and duration ~= 0 then
				return config.player
			else
				return config.player and config.player_permanent
			end
		end

		if isFriend then
			if aura.isDebuff then
				-- dispellable
				if debuffType and E:IsDispellable(debuffType) then
					return config.dispellable
				end
			end
		else
			-- stealable
			if isStealable then
				return config.dispellable
			end
		end

		return config.misc
	end,
}

local function button_UpdateTooltip(self)
	GameTooltip:SetUnitAura(self:GetParent().__owner.unit, self:GetID(), self.filter)
end

local function button_OnEnter(self)
	if not self:IsVisible() then return end

	GameTooltip:SetOwner(self, self:GetParent().tooltipAnchor)
	self:UpdateTooltip()
end

local function button_OnLeave()
	GameTooltip:Hide()
end

local function element_CreateAuraIcon(self, index)
	local config = self._config
	if not config then
		self:UpdateConfig()
		config = self._config
	end

	local button = E:CreateButton(self, "$parentAura" .. index, true, true, true)

	button.icon = button.Icon
	button.Icon = nil

	local count = button.Count
	count:SetAllPoints()
	count:SetFontObject("LSFont" .. config.count.size .. (config.count.outline and "_Outline" or ""))
	count:SetJustifyH(config.count.h_alignment)
	count:SetJustifyV(config.count.v_alignment)
	count:SetWordWrap(false)

	if config.count.shadow then
		count:SetShadowOffset(1, -1)
	else
		count:SetShadowOffset(0, 0)
	end

	button.count = count
	button.Count = nil

	button.cd = button.CD
	button.CD = nil

	if button.cd.UpdateConfig then
		button.cd:UpdateConfig(self.cooldownConfig or {})
		button.cd:UpdateFontObject()
	end

	button:SetPushedTexture("")
	button:SetHighlightTexture("")

	local stealable = button.FGParent:CreateTexture(nil, "OVERLAY", nil, 2)
	stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
	stealable:SetTexCoord(2 / 32, 30 / 32, 2 / 32, 30 / 32)
	stealable:SetPoint("TOPLEFT", -1, 1)
	stealable:SetPoint("BOTTOMRIGHT", 1, -1)
	stealable:SetBlendMode("ADD")
	button.stealable = stealable

	local auraType = button.FGParent:CreateTexture(nil, "OVERLAY", nil, 3)
	auraType:SetTexture("Interface\\AddOns\\ls_UI\\assets\\unit-frame-aura-icons")
	auraType:SetPoint(config.type.position, 0, 0)
	auraType:SetSize(config.type.size, config.type.size)
	button.AuraType = auraType

	button.UpdateTooltip = button_UpdateTooltip
	button:SetScript("OnEnter", button_OnEnter)
	button:SetScript("OnLeave", button_OnLeave)

	return button
end

local function element_PostUpdateIcon(self, _, aura, _, _, _, _, debuffType)
	if aura.isDebuff then
		aura.Border:SetVertexColor(E:GetRGB(C.db.global.colors.debuff[debuffType] or C.db.global.colors.debuff.None))

		if self._config.type.debuff_type then
			aura.AuraType:SetTexCoord(unpack(M.textures.aura_icons[debuffType] or M.textures.aura_icons["Debuff"]))
		else
			aura.AuraType:SetTexCoord(unpack(M.textures.aura_icons["Debuff"]))
		end
	else
		aura.Border:SetVertexColor(1, 1, 1)
		aura.AuraType:SetTexCoord(unpack(M.textures.aura_icons["Buff"]))
	end
end

local function element_UpdateConfig(self)
	local unit = self.__owner._unit
	self._config = E:CopyTable(C.db.profile.units[unit].auras, self._config)

	local size = self._config.size_override ~= 0 and self._config.size_override
		or E:Round((C.db.profile.units[unit].width - (self.spacing * (self._config.per_row - 1)) + 2) / self._config.per_row)
	self._config.size = m_min(m_max(size, 24), 64)
end

local function element_UpdateCooldownConfig(self)
	if not self.cooldownConfig then
		self.cooldownConfig = {
			text = {},
		}
	end

	self.cooldownConfig.exp_threshold = C.db.profile.units.cooldown.exp_threshold
	self.cooldownConfig.m_ss_threshold = C.db.profile.units.cooldown.m_ss_threshold
	self.cooldownConfig.text = E:CopyTable(self._config.cooldown.text, self.cooldownConfig.text)

	for i = 1, self.createdIcons do
		if not self[i].cd.UpdateConfig then
			break
		end

		self[i].cd:UpdateConfig(self.cooldownConfig)
		self[i].cd:UpdateFontObject()
	end
end

local function element_UpdateFontObjects(self)
	local config = self._config.count
	local fontObj = "LSFont" .. config.size .. (config.outline and "_Outline" or "")
	local count

	for i = 1, self.createdIcons do
		count = self[i].count
		count:SetFontObject(fontObj)
		count:SetJustifyH(config.h_alignment)
		count:SetJustifyV(config.v_alignment)
		count:SetWordWrap(false)

		if config.shadow then
			count:SetShadowOffset(1, -1)
		else
			count:SetShadowOffset(0, 0)
		end
	end
end

local function element_UpdateAuraTypeIcon(self)
	local config = self._config.type
	local auraType

	for i = 1, self.createdIcons do
		auraType = self[i].AuraType
		auraType:ClearAllPoints()
		auraType:SetPoint(config.position, 0, 0)
		auraType:SetSize(config.size, config.size)
	end
end

local function element_UpdateSize(self)
	local config = self._config

	self.size = config.size
	self.numTotal = config.per_row * config.rows

	self:SetSize(config.size * config.per_row + self.spacing * (config.per_row - 1), config.size * config.rows + self.spacing * (config.rows - 1))
end

local function element_UpdatePoints(self)
	local config = self._config.point1

	self:ClearAllPoints()

	if config.p and config.p ~= "" then
		self:SetPoint(config.p, E:ResolveAnchorPoint(self.__owner, config.anchor), config.rP, config.x, config.y)
	end
end

local function element_UpdateGrowthDirection(self)
	local config = self._config

	self["growth-x"] = config.x_growth
	self["growth-y"] = config.y_growth

	if config.y_growth == "UP" then
		if config.x_growth == "RIGHT" then
			self.initialAnchor = "BOTTOMLEFT"
		else
			self.initialAnchor = "BOTTOMRIGHT"
		end
	else
		if config.x_growth == "RIGHT" then
			self.initialAnchor = "TOPLEFT"
		else
			self.initialAnchor = "TOPRIGHT"
		end
	end
end

local function element_UpdateMouse(self)
	self.disableMouse = self._config.disable_mouse
end

local function element_UpdateColors(self)
	self:ForceUpdate()
end

local function frame_UpdateAuras(self)
	local element = self.Auras
	element:UpdateConfig()
	element:UpdateCooldownConfig()
	element:UpdateSize()
	element:UpdatePoints()
	element:UpdateGrowthDirection()
	element:UpdateAuraTypeIcon()
	element:UpdateFontObjects()
	element:UpdateMouse()

	if element._config.enabled and not self:IsElementEnabled("Auras") then
		self:EnableElement("Auras")
	elseif not element._config.enabled and self:IsElementEnabled("Auras") then
		self:DisableElement("Auras")
	end

	if self:IsElementEnabled("Auras") then
		element:ForceUpdate()
	end
end

function UF:CreateAuras(frame, unit)
	local element = CreateFrame("Frame", nil, frame)
	element:SetSize(48, 48)

	element.CreateIcon = element_CreateAuraIcon
	element.CustomFilter = filterFunctions[unit] or filterFunctions.default
	element.PostUpdateIcon = element_PostUpdateIcon
	element.showDebuffType = true
	element.showStealableBuffs = true
	element.spacing = 4
	element.UpdateAuraTypeIcon = element_UpdateAuraTypeIcon
	element.UpdateColors = element_UpdateColors
	element.UpdateConfig = element_UpdateConfig
	element.UpdateCooldownConfig = element_UpdateCooldownConfig
	element.UpdateFontObjects = element_UpdateFontObjects
	element.UpdateGrowthDirection = element_UpdateGrowthDirection
	element.UpdateMouse = element_UpdateMouse
	element.UpdatePoints = element_UpdatePoints
	element.UpdateSize = element_UpdateSize

	frame.UpdateAuras = frame_UpdateAuras

	return element
end
