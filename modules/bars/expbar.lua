local _, ns = ...
local E, C, M, L, P = ns.E, ns.C, ns.M, ns.L, ns.P
local BARS = P:GetModule("Bars")

-- Lua
local _G = _G
local table = _G.table
local unpack = _G.unpack

-- Blizz
local BreakUpLargeNumbers = _G.BreakUpLargeNumbers

-- Mine
local isInit = false
local bar
local mode
local MAX_BARS = 3
local BAR_WIDTH = 1494 / 2
local ARTIFACT_NUM_PURCHASED_RANKS = _G.ARTIFACTS_NUM_PURCHASED_RANKS:gsub("%%d", "|cff%%s%%s|r")
local ARTIFACT_NUM_TRAIT_POINTS = "Trait Points: |cff%s%s|r"
local ARTIFACT_POWER = _G.ARTIFACT_POWER
local BONUS_EXPERIENCE = "Bonus XP: |cff%s%s|r"
local BONUS_HONOR = "Bonus Honor: |cff%s%s|r"
local EXP_BAR_VALUE_TEMPLATE = "%s / |cff%s%s|r"
local EXPERIENCE = "Experience"
local HONOR = _G.HONOR
local HONOR_LEVEL = "Honor Level: |cff%s%s|r"
local LEVEL = _G.LEVEL..": |cff%s%d|r"
local NAME = "Name: |cff%s%s|r"
local PRESTIGE_LEVEL = "Prestige Level: |cff%s%s|r"
local REPUTATION = _G.REPUTATION
local REPUTATION_TEMPLATE = "%s: |cff%s%s|r"

local LAYOUT = {
	[1] = {
		[1] = {
			point = {"TOPLEFT", "LSUIExpBar", "TOPLEFT", 0, 0},
		},
	},
	[2] = {
		[1] = {
			point = {"TOPLEFT", "LSUIExpBar", "TOPLEFT", 0, 0},
		},
		[2] = {
			point = {"TOPLEFT", "LSUIExpBarSegment1", "TOPRIGHT", 0, 0},
		},
	},
	[3] = {
		[1] = {
			point = {"TOPLEFT", "LSUIExpBar", "TOPLEFT", 0, 0},
		},
		[2] = {
			point = {"TOPLEFT", "LSUIExpBarSegment1", "TOPRIGHT", 0, 0},
		},
		[3] = {
			point = {"TOPLEFT", "LSUIExpBarSegment2", "TOPRIGHT", 0, 0},
		},
	},
}

local CFG = {
	point = {"BOTTOM", "UIParent", "BOTTOM", 0, 4},
	mode = "DEFAULT",
}

local function UpdateExperienceBars(self)
	local index = 0

	if _G.C_PetBattles.IsInBattle() then
		for i = 1, 3 do
			if i < _G.C_PetBattles.GetNumPets(1) then
				local level = _G.C_PetBattles.GetLevel(1, i)

				if level and level < 25 then
					index = index + 1

					local name = _G.C_PetBattles.GetName(1, i)
					local rarity = _G.C_PetBattles.GetBreedQuality(1, i)
					local cur, max = _G.C_PetBattles.GetXP(1, i)
					local r, g, b = M.COLORS.XP:GetRGB()
					local hex = M.COLORS.XP:GetHEX()

					self[index].tooltipInfo = {
						header = EXPERIENCE,
						line1 = {
							text = NAME:format(M.COLORS.ITEM_QUALITY[rarity]:GetHEX(), name)
						},
						line2 = {
							text = LEVEL:format(hex, level)
						},
					}

					self[index].Text:SetFormattedText(EXP_BAR_VALUE_TEMPLATE, BreakUpLargeNumbers(cur), hex, BreakUpLargeNumbers(max))

					self[index].Texture.Fill:SetVertexColor(r, g, b)
					self[index].Texture.FillScroll1:SetVertexColor(r, g, b)
					self[index].Texture.FillScroll2:SetVertexColor(r, g, b)

					self[index]:SetMinMaxValues(0, max)
					self[index]:SetValue(cur)
				end
			end
		end
	else
		-- Artefact
		if _G.HasArtifactEquipped() then
			index = index + 1

			local _, _, _, _, totalXP, pointsSpent = _G.C_ArtifactUI.GetEquippedArtifactInfo()
			local points, cur, max = _G.MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP)
			local r, g, b = M.COLORS.ARTIFACT:GetRGB()
			local hex = M.COLORS.ARTIFACT:GetHEX()

			self[index].tooltipInfo = {
				header = ARTIFACT_POWER,
				line1 = {
					text = ARTIFACT_NUM_TRAIT_POINTS:format(hex, points)
				},
				line2 = {
					text = ARTIFACT_NUM_PURCHASED_RANKS:format(hex, pointsSpent)
				},
			}

			self[index].Text:SetFormattedText(EXP_BAR_VALUE_TEMPLATE, BreakUpLargeNumbers(cur), hex, BreakUpLargeNumbers(max))

			self[index].Texture.Fill:SetVertexColor(r, g, b)
			self[index].Texture.FillScroll1:SetVertexColor(r, g, b)
			self[index].Texture.FillScroll2:SetVertexColor(r, g, b)

			self[index]:SetMinMaxValues(0, max)
			self[index]:SetValue(cur)
		end

		-- XP / Honour
		if _G.UnitLevel("player") < _G.MAX_PLAYER_LEVEL then
			if not _G.IsXPUserDisabled() then
				index = index + 1

				local cur, max = _G.UnitXP("player"), _G.UnitXPMax("player")
				local r, g, b = M.COLORS.XP:GetRGB()
				local hex = M.COLORS.XP:GetHEX()

				self[index].tooltipInfo = {
					header = EXPERIENCE,
					line1 = {
						text = LEVEL:format(hex, _G.UnitLevel("player"))
					},
				}

				if _G.GetXPExhaustion() and _G.GetXPExhaustion() > 0 then
					self[index].tooltipInfo.line2 = {
						text = BONUS_EXPERIENCE:format(hex, _G.GetXPExhaustion())
					}
				else
					self[index].tooltipInfo.line2 = nil
				end

				self[index].Text:SetFormattedText(EXP_BAR_VALUE_TEMPLATE, BreakUpLargeNumbers(cur), hex, BreakUpLargeNumbers(max))

				self[index].Texture.Fill:SetVertexColor(r, g, b)
				self[index].Texture.FillScroll1:SetVertexColor(r, g, b)
				self[index].Texture.FillScroll2:SetVertexColor(r, g, b)

				self[index]:SetMinMaxValues(0, max)
				self[index]:SetValue(cur)
			end
		else
			if _G.IsWatchingHonorAsXP() or _G.InActiveBattlefield() or _G.IsInActiveWorldPVP() then
				index = index + 1

				local cur, max = _G.UnitHonor("player"), _G.UnitHonorMax("player")
				local r, g, b = M.COLORS.HONOR:GetRGB()
				local hex = M.COLORS.HONOR:GetHEX()

				self[index].tooltipInfo = {
					header = HONOR,
					line1 = {
						text = HONOR_LEVEL:format(hex, _G.UnitHonorLevel("player")),
					},
					line2 = {
						text = PRESTIGE_LEVEL:format(hex, _G.UnitPrestige("player"))
					},
				}

				if _G.GetHonorExhaustion() and _G.GetHonorExhaustion() > 0 then
					self[index].tooltipInfo.line3.text = BONUS_HONOR:format(hex, _G.GetHonorExhaustion())
				end

				self[index].Text:SetFormattedText(EXP_BAR_VALUE_TEMPLATE, BreakUpLargeNumbers(cur), hex, BreakUpLargeNumbers(max))

				self[index].Texture.Fill:SetVertexColor(r, g, b)
				self[index].Texture.FillScroll1:SetVertexColor(r, g, b)
				self[index].Texture.FillScroll2:SetVertexColor(r, g, b)

				self[index]:SetMinMaxValues(0, max)
				self[index]:SetValue(cur)
			end
		end

		-- Reputation
		local name, standing, repMin, repMax, repCur, factionID = _G.GetWatchedFactionInfo()

		if name then
			index = index + 1

			local _, friendRep, _, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = _G.GetFriendshipReputation(factionID)
			local repTextLevel = _G.GetText("FACTION_STANDING_LABEL"..standing, _G.UnitSex("player"))
			local cur, max

			if friendRep then
				if nextFriendThreshold then
					max, cur = nextFriendThreshold - friendThreshold, friendRep - friendThreshold
				else
					max, cur = 1, 1
				end

				standing = 5
				repTextLevel = friendTextLevel
			else
				max, cur = repMax - repMin, repCur - repMin
			end

			local r, g, b = M.COLORS.REACTION[standing]:GetRGB()
			local hex = M.COLORS.REACTION[standing]:GetHEX()

			self[index].tooltipInfo = {
				header = REPUTATION,
				line1 = {
					text = REPUTATION_TEMPLATE:format(name, hex, repTextLevel)
				},
			}

			self[index].Text:SetFormattedText(EXP_BAR_VALUE_TEMPLATE, BreakUpLargeNumbers(cur), hex, BreakUpLargeNumbers(max))

			self[index].Texture.Fill:SetVertexColor(r, g, b)
			self[index].Texture.FillScroll1:SetVertexColor(r, g, b)
			self[index].Texture.FillScroll2:SetVertexColor(r, g, b)

			self[index]:SetMinMaxValues(0, max)
			self[index]:SetValue(cur)
		end
	end

	for i = 1, MAX_BARS do
		if i <= index then
			self[i]:SetSize(unpack(LAYOUT[index][i].size))
			self[i]:SetPoint(unpack(LAYOUT[index][i].point))
			self[i]:Show()

			self[i].Texture.ScrollAnim:Play()
		else
			self[i]:SetMinMaxValues(0, 1)
			self[i]:SetValue(0)
			self[i]:ClearAllPoints()
			self[i]:Hide()

			self[i].Texture.ScrollAnim:Stop()
		end
	end

	for i = 1, 2 do
		if i <= index - 1 then
			self[i].Sep:Show()
		else
			self[i].Sep:Hide()
		end
	end
end

local function UpdateExpBarSize()
	if mode == "FULLSCREEN" then
		BAR_WIDTH = _G.UIParent:GetWidth()
	elseif mode == "SHORT" then
		BAR_WIDTH = 1062 / 2
	elseif mode == "DEFAULT" then
		BAR_WIDTH = 1494 / 2
	end

	LAYOUT[1][1].size = {BAR_WIDTH / 1, 16 / 2}
	LAYOUT[2][1].size = {BAR_WIDTH / 2, 16 / 2}
	LAYOUT[2][2].size = {BAR_WIDTH / 2, 16 / 2}
	LAYOUT[3][1].size = {BAR_WIDTH / 3, 16 / 2}
	LAYOUT[3][2].size = {BAR_WIDTH / 3, 16 / 2}
	LAYOUT[3][3].size = {BAR_WIDTH / 3, 16 / 2}

	bar:SetSize(BAR_WIDTH, 16 / 2)

	local total = 0

	for i = 1, MAX_BARS do
		if bar[i]:IsShown() then
			total = total + 1
		end
	end

	for i = 1, total do
		bar[i]:SetSize(unpack(LAYOUT[total][i].size))
		bar[i]:SetPoint(unpack(LAYOUT[total][i].point))
	end
end

-- mode: "FULLSCREEN", "DEFAULT", "SHORT"
local function SetExpBarMode(new)
	if new == "FULLSCREEN" or new == "SHORT" then
		mode = new
	else
		mode = "DEFAULT"
	end

	UpdateExpBarSize()
end

local function ExpBar_OnEvent(self, event, ...)
	if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
		local scale = _G.UIParent:GetScale()

		for i = 1, MAX_BARS do
			self[i].Texture.Fill:SetThickness(16 * scale)
			self[i].Texture.FillScroll1:SetThickness(16 * scale)
			self[i].Texture.FillScroll2:SetThickness(16 * scale)
		end

		UpdateExperienceBars(self)
	elseif event == "UNIT_INVENTORY_CHANGED" then
		local unit = ...

		if unit == "player" then
			UpdateExperienceBars(self)
		end
	else
		UpdateExperienceBars(self)
	end
end

local function Segment_OnEnter(self)
	if self.tooltipInfo then
		local quadrant = E:GetScreenQuadrant(bar)
		local p, rP, sign = "BOTTOMLEFT", "TOPLEFT", 1

		if quadrant == "TOPLEFT" or quadrant == "TOP" or quadrant == "TOPRIGHT" then
			p, rP, sign = "TOPLEFT", "BOTTOMLEFT", -1
		end

		_G.GameTooltip:SetOwner(self, "ANCHOR_NONE")
		_G.GameTooltip:SetPoint(p, self, rP, 0, sign * 2)
		_G.GameTooltip:AddLine(self.tooltipInfo.header)
		_G.GameTooltip:AddLine(self.tooltipInfo.line1.text, 1, 1, 1)

		if self.tooltipInfo.line2 then
			_G.GameTooltip:AddLine(self.tooltipInfo.line2.text, 1, 1, 1)
		end

		if self.tooltipInfo.line3 then
			_G.GameTooltip:AddLine(self.tooltipInfo.line3.text, 1, 1, 1)
		end

		_G.GameTooltip:Show()
	end

	self.Text:Show()
end

local function Segment_OnLeave(self)
	_G.GameTooltip:Hide()

	self.Text:Hide()
end

------------
-- PUBLIC --
------------

function BARS:SetExpBarMode(new)
	SetExpBarMode(new)
end

function BARS:EnableExpBarMouse(flag)
	bar:EnableMouse(flag)
end

function BARS:IsExpBarMouseEnabled()
	return bar:IsMouseEnabled()
end

-----------------
-- INITIALISER --
-----------------

function BARS:ExpBar_IsInit()
	return isInit
end

function BARS:ExpBar_Init()
	if not isInit then
		if not C.bars.restricted then
			CFG = C.bars.expbar
		end

		bar = _G.CreateFrame("Frame", "LSUIExpBar", _G.UIParent, "SecureHandlerStateTemplate")
		bar:SetScript("OnEvent", ExpBar_OnEvent)
		-- all
		bar:RegisterEvent("DISPLAY_SIZE_CHANGED")
		bar:RegisterEvent("PET_BATTLE_CLOSE")
		bar:RegisterEvent("PET_BATTLE_OPENING_START")
		bar:RegisterEvent("PLAYER_UPDATE_RESTING")
		bar:RegisterEvent("UI_SCALE_CHANGED")
		bar:RegisterEvent("UPDATE_EXHAUSTION")
		-- honour
		bar:RegisterEvent("HONOR_LEVEL_UPDATE")
		bar:RegisterEvent("HONOR_XP_UPDATE")
		bar:RegisterEvent("ZONE_CHANGED")
		bar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		-- ap
		bar:RegisterEvent("ARTIFACT_XP_UPDATE")
		bar:RegisterEvent("UNIT_INVENTORY_CHANGED")
		-- xp
		bar:RegisterEvent("DISABLE_XP_GAIN")
		bar:RegisterEvent("ENABLE_XP_GAIN")
		bar:RegisterEvent("PET_BATTLE_LEVEL_CHANGED")
		bar:RegisterEvent("PET_BATTLE_XP_CHANGED")
		bar:RegisterEvent("PLAYER_LEVEL_UP")
		bar:RegisterEvent("PLAYER_XP_UPDATE")
		bar:RegisterEvent("UPDATE_EXPANSION_LEVEL")
		-- rep
		bar:RegisterEvent("UPDATE_FACTION")

		local cover = _G.CreateFrame("Frame", nil, bar)
		cover:SetAllPoints()
		cover:SetFrameLevel(bar:GetFrameLevel() + 3)

		local text_parent = _G.CreateFrame("Frame", nil, bar)
		text_parent:SetAllPoints()
		text_parent:SetFrameLevel(bar:GetFrameLevel() + 5)

		local t = bar:CreateTexture(nil, "ARTWORK")
		t:SetAllPoints()
		t:SetTexture("Interface\\Artifacts\\_Artifacts-DependencyBar-BG", true)
		t:SetHorizTile(true)
		t:SetTexCoord(0 / 128, 128 / 128, 4 / 16, 12 / 16)

		local scale = _G.UIParent:GetScale()

		for i = 1, MAX_BARS do
			bar[i] = _G.CreateFrame("StatusBar", "$parentSegment"..i, bar)
			bar[i]:SetFrameLevel(bar:GetFrameLevel() + 1)
			bar[i]:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
			bar[i]:SetStatusBarColor(0, 0, 0, 0)
			bar[i]:SetHitRectInsets(0, 0, -4, -4)
			bar[i]:SetScript("OnEnter", Segment_OnEnter)
			bar[i]:SetScript("OnLeave", Segment_OnLeave)
			E:SmoothBar(bar[i])
			bar[i]:Hide()

			bar[i].Texture = _G.CreateFrame("Frame", nil, bar[i], "LSUILineTemplate")
			bar[i].Texture:SetFrameLevel(bar[i]:GetFrameLevel() + 1)

			bar[i].Texture.Fill:SetThickness(16 * scale)
			bar[i].Texture.Fill:SetStartPoint("LEFT", bar[i]:GetStatusBarTexture())
			bar[i].Texture.Fill:SetStartPoint("RIGHT", bar[i]:GetStatusBarTexture())

			bar[i].Texture.FillScroll1:Show()
			bar[i].Texture.FillScroll1:SetThickness(16 * scale)
			bar[i].Texture.FillScroll1:SetStartPoint("LEFT", bar[i]:GetStatusBarTexture())
			bar[i].Texture.FillScroll1:SetEndPoint("RIGHT", bar[i]:GetStatusBarTexture())

			bar[i].Texture.FillScroll2:Show()
			bar[i].Texture.FillScroll2:SetThickness(16 * scale)
			bar[i].Texture.FillScroll2:SetStartPoint("LEFT", bar[i]:GetStatusBarTexture());
			bar[i].Texture.FillScroll2:SetEndPoint("RIGHT", bar[i]:GetStatusBarTexture());

			local spark = bar[i]:CreateTexture(nil, "ARTWORK", nil, 1)
			spark:SetSize(16, 16)
			spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
			spark:SetBlendMode("ADD")
			spark:SetPoint("CENTER", bar[i]:GetStatusBarTexture(), "RIGHT", 0, 0)

			local text = text_parent:CreateFontString(nil, "OVERLAY", "LS10Font_Outline")
			text:SetAllPoints(bar[i])
			text:SetWordWrap(false)
			text:Hide()
			bar[i].Text = text
		end

		local sep = cover:CreateTexture(nil, "ARTWORK", nil, -7)
		sep:SetPoint("CENTER", bar[1], "RIGHT", 0, 0)
		sep:SetSize(12 / 2, 16 / 2)
		sep:SetTexture("Interface\\AddOns\\ls_UI\\media\\exp-bar")
		sep:SetTexCoord(1 / 32, 13 / 32, 1 / 32, 17 / 32)
		sep:Hide()
		bar[1].Sep = sep

		sep = cover:CreateTexture(nil, "ARTWORK", nil, -7)
		sep:SetPoint("CENTER", bar[2], "RIGHT", 0, 0)
		sep:SetSize(12 / 2, 16 / 2)
		sep:SetTexture("Interface\\AddOns\\ls_UI\\media\\exp-bar")
		sep:SetTexCoord(13 / 32, 25 / 32, 1 / 32, 17 / 32)
		sep:Hide()
		bar[2].Sep = sep

		-- Honour & Rep Hooks
		-- This way I'm able to show honour and reputation bars simultaneously
		local function WatchHonorAsXP(...)
			local _, _, _, value = ...

			if value then
				_G.PlaySound("igMainMenuOptionCheckBoxOff")
				_G.SetWatchingHonorAsXP(false)
			else
				_G.PlaySound("igMainMenuOptionCheckBoxOn")
				_G.SetWatchingHonorAsXP(true)
			end

			UpdateExperienceBars(bar)
		end

		local function InitializePVPTalentsXPBarDropDown(self, level)
			local info = _G.UIDropDownMenu_CreateInfo()

			info.isNotRadio = true
			info.text = _G.SHOW_FACTION_ON_MAINSCREEN
			info.checked = _G.IsWatchingHonorAsXP()
			info.func = WatchHonorAsXP
			_G.UIDropDownMenu_AddButton(info, level)
			table.wipe(info)

			info.notCheckable = true
			info.text = _G.CANCEL
			_G.UIDropDownMenu_AddButton(info, level)
		end

		local function PlayerTalentFramePVPTalentsXPBar_OnClick(self, button)
			if button == "RightButton" then
				_G.UIDropDownMenu_Initialize(self.DropDown, InitializePVPTalentsXPBarDropDown, "MENU")
				_G.ToggleDropDownMenu(1, nil, self.DropDown, self, 310, 12)
			end
		end

		local isHonorBarHooked = false

		_G.hooksecurefunc("TalentFrame_LoadUI", function()
			if not isHonorBarHooked then
				_G.PlayerTalentFramePVPTalents.XPBar:SetScript("OnMouseUp", PlayerTalentFramePVPTalentsXPBar_OnClick)

				isHonorBarHooked = true
			end
		end)

		local function ReputationDetailMainScreenCheckBox_OnClick(self)
			if self:GetChecked() then
				_G.PlaySound("igMainMenuOptionCheckBoxOn")
				_G.SetWatchedFactionIndex(_G.GetSelectedFaction())
			else
				_G.PlaySound("igMainMenuOptionCheckBoxOff")
				_G.SetWatchedFactionIndex(0)
			end

			UpdateExperienceBars(bar)
		end

		_G.ReputationDetailMainScreenCheckBox:SetScript("OnClick", ReputationDetailMainScreenCheckBox_OnClick)

		SetExpBarMode(CFG.mode)

		if not C.bars.restricted then
			bar:SetPoint(unpack(CFG.point))
			E:CreateMover(bar)
			E:SetBarSkin(cover, "HORIZONTAL-M")
		else
			self:ActionBarController_AddWidget(bar, "EXP_BAR")
		end

		-- Finalise
		UpdateExperienceBars(bar)

		isInit = true

		return true
	end
end