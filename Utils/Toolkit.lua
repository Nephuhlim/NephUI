local ADDON_NAME, ns = ...
local NephUI = ns.Addon

if not NephUI or not NephUI.Scale then
	error("NephUI and NephUI:Scale must be available. Load Toolkit after PixelPerfect.")
end

local _G = _G
local type = type
local next = next
local getmetatable = getmetatable
local hooksecurefunc = hooksecurefunc
local tonumber = tonumber
local pcall = pcall
local CreateFrame = CreateFrame
local EnumerateFrames = EnumerateFrames

-- True if we can safely read/call on this frame (not secure, not forbidden).
local function frame_ok(f)
	if not f then return false end
	if issecurevalue and issecurevalue(f) then return false end
	if f.IsForbidden then
		local ok, forbidden = pcall(f.IsForbidden, f)
		if not ok or forbidden then return false end
	end
	return true
end

-- When Blizzard re-enables pixel snap, clear our marker so we can disable again if needed.
local function on_pixel_snap_enabled(f, snap)
	if not frame_ok(f) then return end
	if f._nephui_no_pixel_snap and snap then
		f._nephui_no_pixel_snap = nil
	end
end

-- Turn off Blizzard's pixel grid on this frame/texture so our global scale controls sharpness.
local function turn_off_pixel_snap(f)
	if not frame_ok(f) or f._nephui_no_pixel_snap then return end
	if f.SetSnapToPixelGrid then
		f:SetSnapToPixelGrid(false)
		if f.SetTexelSnappingBias then f:SetTexelSnappingBias(0) end
	elseif f.GetStatusBarTexture then
		local tex = f:GetStatusBarTexture()
		if type(tex) == "table" and tex.SetSnapToPixelGrid then
			tex:SetSnapToPixelGrid(false)
			if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0) end
		end
	end
	f._nephui_no_pixel_snap = true
end

-- Scale a numeric value via NephUI (pixel rounding).
local function scale(x, no_scale)
	if no_scale or x == nil then return x end
	return NephUI:Scale(x)
end

-- Some frames (e.g. restricted) don't allow GetPoint; detect that.
local function points_restricted(f)
	if not f then return true end
	local ok = pcall(f.GetPoint, f)
	return not ok
end

-- Apply scaled size: (w) or (w, h). If h omitted, square.
local function api_size(f, w, h, ...)
	local sw = NephUI:Scale(w)
	f:SetSize(sw, (h ~= nil and NephUI:Scale(h)) or sw, ...)
end

local function api_width(f, w, ...)
	f:SetWidth(NephUI:Scale(w), ...)
end

local function api_height(f, h, ...)
	f:SetHeight(NephUI:Scale(h), ...)
end

-- SetPoint with numeric args scaled (anchor, relativeTo, relativePoint, x, y).
local function api_point(obj, arg1, arg2, arg3, arg4, arg5, ...)
	if not arg2 then arg2 = obj:GetParent() end
	if type(arg2) == "number" then arg2 = NephUI:Scale(arg2) end
	if type(arg3) == "number" then arg3 = NephUI:Scale(arg3) end
	if type(arg4) == "number" then arg4 = NephUI:Scale(arg4) end
	if type(arg5) == "number" then arg5 = NephUI:Scale(arg5) end
	obj:SetPoint(arg1, arg2, arg3, arg4, arg5, ...)
end

-- Get point by 1-based index or by anchor name (e.g. "TOPLEFT").
local function api_grab_point(obj, index_or_name)
	if type(index_or_name) == "string" then
		local num = tonumber(index_or_name)
		if not num then
			for i = 1, obj:GetNumPoints() do
				local anchor, rel_to, rel_anchor, x, y = obj:GetPoint(i)
				if anchor == index_or_name then
					return anchor, rel_to, rel_anchor, x, y
				end
			end
			return nil
		end
		index_or_name = num
	end
	return obj:GetPoint(index_or_name)
end

-- Nudge existing point by (xAxis, yAxis); optionally clear points first.
local function api_nudge_point(obj, x_axis, y_axis, no_scale, point_index, clear_first)
	x_axis = x_axis or 0
	y_axis = y_axis or 0
	local dx = scale(x_axis, no_scale)
	local dy = scale(y_axis, no_scale)
	local anchor, rel_to, rel_anchor, x_ofs, y_ofs = api_grab_point(obj, point_index)
	if clear_first or points_restricted(obj) then
		obj:ClearAllPoints()
	end
	obj:SetPoint(anchor, rel_to, rel_anchor, x_ofs + dx, y_ofs + dy)
end

-- Set position by absolute x/y offsets for current anchor.
local function api_point_xy(obj, x_ofs, y_ofs, no_scale, point_index, clear_first)
	local x = (x_ofs ~= nil) and (scale(x_ofs, no_scale) or x_ofs) or nil
	local y = (y_ofs ~= nil) and (scale(y_ofs, no_scale) or y_ofs) or nil
	local anchor, rel_to, rel_anchor, cur_x, cur_y = api_grab_point(obj, point_index)
	if clear_first or points_restricted(obj) then
		obj:ClearAllPoints()
	end
	obj:SetPoint(anchor, rel_to, rel_anchor, x or cur_x, y or cur_y)
end

-- Anchor frame outside another (expand by offset).
local function api_set_outside(obj, anchor, x_off, y_off, anchor2, no_scale)
	anchor = anchor or obj:GetParent()
	x_off = x_off or 1
	y_off = y_off or 1
	local x = scale(x_off, no_scale)
	local y = scale(y_off, no_scale)
	if points_restricted(obj) or obj:GetPoint() then
		obj:ClearAllPoints()
	end
	turn_off_pixel_snap(obj)
	obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", -x, y)
	obj:SetPoint("BOTTOMRIGHT", anchor2 or anchor, "BOTTOMRIGHT", x, -y)
end

-- Anchor frame inside another (inset by offset).
local function api_set_inside(obj, anchor, x_off, y_off, anchor2, no_scale)
	anchor = anchor or obj:GetParent()
	x_off = x_off or 1
	y_off = y_off or 1
	local x = scale(x_off, no_scale)
	local y = scale(y_off, no_scale)
	if points_restricted(obj) or obj:GetPoint() then
		obj:ClearAllPoints()
	end
	turn_off_pixel_snap(obj)
	obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, -y)
	obj:SetPoint("BOTTOMRIGHT", anchor2 or anchor, "BOTTOMRIGHT", -x, y)
end

local FRAME_API = {
	Size = api_size,
	Point = api_point,
	Width = api_width,
	Height = api_height,
	PointXY = api_point_xy,
	GrabPoint = api_grab_point,
	NudgePoint = api_nudge_point,
	SetOutside = api_set_outside,
	SetInside = api_set_inside,
}

-- Attach our API to a widget's metatable so new frames get these methods.
local function mixin_api(widget)
	local mt = getmetatable(widget)
	if not mt or not mt.__index then return end
	local idx = mt.__index
	for name, fn in next, FRAME_API do
		if not widget[name] then
			idx[name] = fn
		end
	end
	-- Disable Blizzard pixel snap on Frame/Texture/StatusBar so our scale wins.
	local needs_snap_hooks = idx.SetSnapToPixelGrid or idx.SetStatusBarTexture or idx.SetColorTexture
		or idx.SetVertexColor or idx.CreateTexture or idx.SetTexCoord or idx.SetTexture
	if needs_snap_hooks and not idx._nephui_pixel_snap_done then
		if idx.SetSnapToPixelGrid then hooksecurefunc(idx, "SetSnapToPixelGrid", on_pixel_snap_enabled) end
		if idx.SetStatusBarTexture then hooksecurefunc(idx, "SetStatusBarTexture", turn_off_pixel_snap) end
		if idx.SetColorTexture then hooksecurefunc(idx, "SetColorTexture", turn_off_pixel_snap) end
		if idx.SetVertexColor then hooksecurefunc(idx, "SetVertexColor", turn_off_pixel_snap) end
		if idx.CreateTexture then hooksecurefunc(idx, "CreateTexture", turn_off_pixel_snap) end
		if idx.SetTexCoord then hooksecurefunc(idx, "SetTexCoord", turn_off_pixel_snap) end
		if idx.SetTexture then hooksecurefunc(idx, "SetTexture", turn_off_pixel_snap) end
		idx._nephui_pixel_snap_done = true
	end
end

-- Base frame and common subtypes
local base = CreateFrame("Frame")
mixin_api(base)
mixin_api(base:CreateTexture())
mixin_api(base:CreateFontString())
if base.CreateMaskTexture then
	mixin_api(base:CreateMaskTexture())
end

-- All existing widget types (so future-created frames get the API)
local seen = { Frame = true }
local w = EnumerateFrames()
while w do
	if not w:IsForbidden() then
		local kind = w:GetObjectType()
		if not seen[kind] then
			seen[kind] = true
			mixin_api(w)
		end
	end
	w = EnumerateFrames(w)
end

-- Font objects and ScrollFrame (often don't inherit from base Frame)
if _G.GameFontNormal then
	mixin_api(_G.GameFontNormal)
end
mixin_api(CreateFrame("ScrollFrame"))
