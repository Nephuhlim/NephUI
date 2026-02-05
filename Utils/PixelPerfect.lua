--[[
	Pixel-perfect scaling and snapping for UI elements.
	Uses a 768px reference height; scales and rounds values so they align to whole pixels.
]]

local ADDON_NAME, ns = ...
local NephUI = ns.Addon

if not NephUI then
	error("NephUI not found! PixelPerfect.lua must load after Main.lua")
end

local math_min, math_max, math_floor = math.min, math.max, math.floor
local str_format = string.format
local GetPhysicalScreenSize = GetPhysicalScreenSize

-- Reference height used for scale calculation (WoW's traditional UI reference)
local REFERENCE_HEIGHT = 768

-- Clamp bounds for "best" scale (prevents tiny or huge UI)
local SCALE_FLOOR = 0.4
local SCALE_CEIL = 1.15

-- Eyefinity: effective width by physical width threshold (high-res multi-monitor)
local EYEFINITY_THRESHOLDS = {
	{ 9840, 3280 }, { 7680, 2560 }, { 5760, 1920 }, { 5040, 1680 },
	{ 4320, 1440 }, { 4080, 1360 }, { 3840, 1224 },
}

local function effectiveWidthEyefinity(physW, physH, enabled)
	if not enabled or physW < 3840 then return nil end
	if physW >= 4800 and physW < 5760 and physH == 900 then return 1600 end
	for _, row in ipairs(EYEFINITY_THRESHOLDS) do
		local limit, width = row[1], row[2]
		if physW >= limit then return width end
	end
	return nil
end

-- Ultrawide: effective width for common 21:9 / ultrawide resolutions
local function effectiveWidthUltrawide(physW, physH, enabled)
	if not enabled or physW < 2560 then return nil end
	if physW >= 3440 and (physH == 1440 or physH == 1600) then return 2560 end
	if physW >= 2560 and (physH == 1080 or physH == 1200) then return 1920 end
	return nil
end

function NephUI:RefreshGlobalFX()
	local g = _G
	g.GlobalFXDialogModelScene:Hide()
	g.GlobalFXDialogModelScene:Show()
	g.GlobalFXMediumModelScene:Hide()
	g.GlobalFXMediumModelScene:Show()
	g.GlobalFXBackgroundModelScene:Hide()
	g.GlobalFXBackgroundModelScene:Show()
end

function NephUI:IsEyefinity(width, height)
	local enabled = (self.db and self.db.profile and self.db.profile.general and self.db.profile.general.eyefinity)
	return effectiveWidthEyefinity(width, height, enabled)
end

function NephUI:IsUltrawide(width, height)
	local enabled = (self.db and self.db.profile and self.db.profile.general and self.db.profile.general.ultrawide)
	return effectiveWidthUltrawide(width, height, enabled)
end

-- Recompute pixel-snap multiplier so Scale() rounds to whole pixels at current UIParent scale
function NephUI:UIMult()
	local uiscale = (self.uiscale or (UIParent and UIParent.GetScale and UIParent:GetScale()) or self.perfect)
	self.mult = self.perfect / (uiscale or self.perfect)
end

-- Scale value clamped to a safe range for general use
function NephUI:PixelBestSize()
	local p = self.perfect
	if not p then return 1 end
	return math_max(SCALE_FLOOR, math_min(SCALE_CEIL, p))
end

-- Apply display / resolution change: update physical size, resolution string, and reference scale
function NephUI:PixelScaleChanged(event)
	if event == "UI_SCALE_CHANGED" then
		local pw, ph = GetPhysicalScreenSize()
		self.physicalWidth, self.physicalHeight = pw, ph
		self.resolution = str_format("%dx%d", pw, ph)
		self.perfect = REFERENCE_HEIGHT / ph
	end
	if UIParent and UIParent.GetScale then
		self.uiscale = UIParent:GetScale()
	end
	self:UIMult()
	if self.ActionBars and self.ActionBars.RefreshAll then
		self.ActionBars:RefreshAll()
	end
end

-- Apply a scale to UIParent so the entire UI (including other addons) uses this scale.
-- If scale is nil, uses the recommended pixel-perfect scale for the current resolution.
-- Defers to PLAYER_REGEN_ENABLED if in combat to avoid taint.
function NephUI:ApplyGlobalUIScale(scale)
	if not UIParent or not UIParent.SetScale then return end
	local s = (scale and type(scale) == "number") and scale or self:PixelBestSize()
	s = math_max(SCALE_FLOOR, math_min(SCALE_CEIL, s))
	if InCombatLockdown and InCombatLockdown() then
		if not self.__pendingGlobalUIScale then
			self.__pendingGlobalUIScale = s
			local f = CreateFrame("Frame")
			f:RegisterEvent("PLAYER_REGEN_ENABLED")
			f:SetScript("OnEvent", function(frame)
				frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
				if NephUI and NephUI.ApplyGlobalUIScale and not InCombatLockdown() then
					NephUI:ApplyGlobalUIScale(NephUI.__pendingGlobalUIScale)
				end
				NephUI.__pendingGlobalUIScale = nil
			end)
		else
			self.__pendingGlobalUIScale = s
		end
		return
	end
	UIParent:SetScale(s)
	self.uiscale = UIParent:GetScale()
	self:UIMult()
	if self.RefreshGlobalFX then
		self:RefreshGlobalFX()
	end
end

-- Snap a value to the pixel grid so it doesn't blur (same scaling/snapping behavior, different implementation)
function NephUI:Scale(x)
	local m = self.mult
	if m == 1 or x == 0 then
		return x
	end
	local step = (m > 1) and m or (-m)
	local remainder = x % (x < 0 and step or (-step))
	return x - remainder
end

-- Scale a border thickness and round to whole pixels; non-negative (0 = hide border)
function NephUI:ScaleBorder(borderSize)
	local raw = borderSize or 1
	raw = math_floor(raw + 0.5)
	if raw < 0 then raw = 0 end
	local out = self:Scale(raw)
	out = math_floor(out + 0.5)
	if out < 0 then out = 0 end
	return out
end
