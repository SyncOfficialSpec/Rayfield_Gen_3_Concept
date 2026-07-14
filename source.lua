local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService=game:GetService("TextService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer=Players.LocalPlayer

local useStudio = RunService:IsStudio()

local fsAvailable = writefile and readfile and isfile and isfolder and makefolder

local function readf(path)
	if not fsAvailable then return nil end
	local ok, result = pcall(function()
		if isfile(path) then return readfile(path) end
		return nil
	end)
	if ok then return result end
	return nil
end

local function writef(path, content)
	if not fsAvailable then return false end
	local ok = pcall(writefile, path, content)
	return ok
end

local function mkfolder(path)
	if not fsAvailable then return false end
	local ok = pcall(function()
		if not isfolder(path) then makefolder(path) end
	end)
	return ok
end

local BASE_FOLDER = "Rayfield Gen3"
mkfolder(BASE_FOLDER)

local function fetch(url)
	local ok, result = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(result) == "string" and #result > 0 then
		return result
	end
	local ok2, result2 = pcall(function()
		local req = (syn and syn.request) or request or http_request
		if not req then return nil end
		local response = req({Url = url,Method = "GET"})
		return response and response.Body or nil
	end)
	if ok2 and type(result2) == "string" and #result2 > 0 then
		return result2
	end

	local ok3, result3 = pcall(function()
		return game:GetService("HttpService"):GetAsync(url)
	end)
	if ok3 and type(result3) == "string" and #result3 > 0 then
		return result3
	end
	return nil
end

-- JSON POST through the executor's request function. Returns the response
-- table ({StatusCode, Body, ...}) or nil plus an error string.
local function httpPost(url, headers, bodyTable)
	local req = (syn and syn.request) or request or http_request
	if not req then return nil, "This executor has no request function" end
	local ok, res = pcall(function()
		return req({
			Url = url,
			Method = "POST",
			Headers = headers,
			Body = HttpService:JSONEncode(bodyTable),
		})
	end)
	if not ok then return nil, tostring(res) end
	return res
end

local function guiParent()
	if useStudio then
		return LocalPlayer:WaitForChild("PlayerGui")
	end
	local ok, hui = pcall(function()
		return gethui and gethui() or nil
	end)
	if ok and hui then return hui end
	local ok2 = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent=CoreGui
		probe:Destroy()
	end)
	if ok2 then return CoreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local rgb = Color3.fromRGB

local Theme = {
	Background = rgb(20, 20, 20),
	Card = rgb(31,31, 31),
	CardHover = rgb(39, 39,39),
	CardSelected = rgb(48, 48,48),
	CardInset = rgb(24, 24,24),
	SearchBox = rgb(44, 44, 44),
	Stroke = rgb(255,255, 255),
	TextTitle = rgb(247, 247, 247),
	TextBody = rgb(233, 233, 233),
	TextSub = rgb(152, 152, 152),
	TextMuted = rgb(110,110, 110),
	AccentDark = rgb(54, 104, 80),
	Accent = rgb(70, 168, 120),
	AccentSoft = rgb(104, 210,156),
	Knob = rgb(255, 255, 255),
	KnobOff = rgb(66, 68, 70),
	ToggleTrack = rgb(18, 18, 18),
	BadgeBackground = rgb(240,166, 63),
	BadgeText = rgb(66, 45,15),
	NotifyBackground = rgb(16, 16,16),
}

-- Snapshot of the base palette. Theme/generation switches reset to this, then
-- layer the generation's tint and the chosen color theme back on top (in place,
-- so every closure that captured the Theme table keeps seeing live values).
local BASE_THEME = {}
for k, v in pairs(Theme) do BASE_THEME[k] = v end

-- Build-time geometry/feel per generation. GenStyle holds the ACTIVE values and
-- is read at construction; a generation switch rewrites it then rebuilds the UI.
-- These are the Gen 3 (current concept) defaults.
local GEN3_STYLE = {
	windowCorner = 24,
	cardRadius = 14,
	cardGradient = true,   -- glassy top-to-bottom sheen on cards
	cardStroke = false,    -- flat generations draw a 1px outline instead
	glow = true,           -- radial bloom behind the tab dock + notifications
	windowW = 530, windowH = 550,
	toggleTrackW = 58, toggleTrackH = 26,
	toggleKnobW = 28, toggleKnobH = 20,
	fontKey = "builder",
}
local GenStyle = {}
for k, v in pairs(GEN3_STYLE) do GenStyle[k] = v end

-- Generations are faithful re-skins rendered by the one engine: a geometry
-- override (style) plus a palette tint (theme) plus a font family.
local GENERATIONS = {
	Gen1 = {
		label = "Gen 1", blurb = "Classic. Flatter cards, sharp corners, blue accent.",
		style = {
			windowCorner = 8, cardRadius = 6, cardGradient = false, cardStroke = true,
			glow = false, windowW = 500, windowH = 560,
			toggleTrackW = 46, toggleTrackH = 24, toggleKnobW = 18, toggleKnobH = 18,
			fontKey = "gotham",
		},
		theme = {
			Background = rgb(23, 24, 28), Card = rgb(32, 34, 40), CardHover = rgb(41, 43, 51),
			CardSelected = rgb(49, 52, 62), CardInset = rgb(27, 28, 34), SearchBox = rgb(40, 42, 50),
			Accent = rgb(86, 132, 236), AccentDark = rgb(50, 80, 150), AccentSoft = rgb(128, 168, 246),
			ToggleTrack = rgb(19, 20, 24), KnobOff = rgb(70, 72, 80),
		},
	},
	Gen2 = {
		label = "Gen 2", blurb = "Fanmade. Rounded cards, deep dark, indigo accent.",
		style = {
			windowCorner = 18, cardRadius = 12, cardGradient = false, cardStroke = false,
			glow = false, windowW = 520, windowH = 560,
			toggleTrackW = 52, toggleTrackH = 28, toggleKnobW = 22, toggleKnobH = 22,
			fontKey = "gotham",
		},
		theme = {
			Background = rgb(15, 15, 18), Card = rgb(24, 24, 28), CardHover = rgb(32, 32, 37),
			CardSelected = rgb(40, 40, 46), CardInset = rgb(19, 19, 23), SearchBox = rgb(34, 34, 40),
			Accent = rgb(88, 116, 224), AccentDark = rgb(50, 68, 140), AccentSoft = rgb(128, 152, 240),
			ToggleTrack = rgb(12, 12, 15), KnobOff = rgb(58, 60, 66),
		},
	},
	Gen3 = {
		label = "Gen 3", blurb = "Current concept. Glow, big radius, refined.",
		style = GEN3_STYLE, theme = {},
	},
}
local GEN_ORDER = {"Gen1", "Gen2", "Gen3"}

-- Color themes layered on top of the active generation (mostly the accent).
local THEMES = {
	Default  = {},
	Ocean    = { Accent = rgb(56, 140, 220), AccentDark = rgb(32, 84, 138), AccentSoft = rgb(98, 178, 244) },
	Amber    = { Accent = rgb(240, 158, 58), AccentDark = rgb(150, 96, 30), AccentSoft = rgb(250, 190, 110) },
	Rose     = { Accent = rgb(232, 88, 120), AccentDark = rgb(150, 48, 74), AccentSoft = rgb(246, 136, 162) },
	Emerald  = { Accent = rgb(52, 196, 132), AccentDark = rgb(28, 118, 80), AccentSoft = rgb(120, 224, 176) },
	Amethyst = { Accent = rgb(150, 110, 240), AccentDark = rgb(92, 64, 158), AccentSoft = rgb(186, 158, 250) },
	Midnight = { Accent = rgb(96, 122, 208), AccentDark = rgb(52, 70, 128), AccentSoft = rgb(150, 172, 244),
		Background = rgb(13, 14, 20), Card = rgb(22, 24, 32), CardHover = rgb(30, 32, 42),
		CardSelected = rgb(38, 40, 52), CardInset = rgb(17, 18, 25) },
}
local THEME_ORDER = {"Default", "Ocean", "Amber", "Rose", "Emerald", "Amethyst", "Midnight"}

-- Generation-switch engine state. The heavy functions are defined after the
-- window constructor (which they rebuild); forward-declared here so the
-- constructor's settings menu can call them.
local GEN = { generation = "Gen3", theme = "Default", transparency = 0, acrylic = false, acrylicPrevT = 0, blueprint = nil, windowCell = nil, windowProxy = nil }
local suppressCallbacks = false

-- User-added AI API keys, shared by every AI chat and managed from settings.
-- They stack: chats try them in order and ask before switching when one fails.
local aiKeys = {}
local function maskKey(k)
	k = tostring(k)
	if #k <= 8 then return string.rep("*", #k) end
	return string.sub(k, 1, 4) .. string.rep("*", math.min(8, #k - 8)) .. string.sub(k, -4)
end
local applyStyle, performRebuild, applyFont, persistChoice

local painted = {}

-- Surfaces (cards, the tab dock, etc.) that frost as the window transparency
-- rises, so a see-through menu stays a cohesive glass sheet instead of solid
-- panels floating. Each surface keeps its own base transparency and a factor
-- for how strongly it fades.
local glassSurfaces = {}
local function glassValue(base, factor, t)
	t = tonumber(t) or 0
	return math.clamp(base + (1 - base) * t * factor, base, 0.97)
end
local function registerGlass(inst, base, factor)
	base = base or 0
	factor = factor or 0.6
	table.insert(glassSurfaces, { inst = inst, base = base, factor = factor })
	inst.BackgroundTransparency = glassValue(base, factor, GEN and GEN.transparency or 0)
end

-- Acrylic blur: a near-plane Glass part covering the window's screen region plus
-- a near DepthOfField, so the game behind a see-through window reads as frosted
-- glass. Technique adapted from ImInsane-1337/neverlose-ui (our root ScreenGui
-- ignores the GUI inset, so we project with ViewportPointToRay).
local acrylicCleanup = nil
local function clearAcrylic()
	if acrylicCleanup then
		local fn = acrylicCleanup
		acrylicCleanup = nil
		pcall(fn)
	end
end
local function enableAcrylic(windowFrame)
	clearAcrylic()
	local camera = Workspace.CurrentCamera
	if not camera or not windowFrame then return end

	local part = Instance.new("Part")
	part.Name = "RayfieldAcrylic"
	part.Material = Enum.Material.Glass
	part.Transparency = 0.98
	part.Reflectance = 1
	part.CastShadow = false
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Locked = true
	part.Size = Vector3.new(0.01, 0.01, 0.01)
	part.Color = Color3.fromRGB(0, 0, 0)
	local mesh = Instance.new("BlockMesh")
	mesh.Parent = part
	part.Parent = camera

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Enabled = true
	dof.FarIntensity = 0
	dof.FocusDistance = 0
	dof.InFocusRadius = 1000
	dof.NearIntensity = 1
	dof.Parent = Lighting

	local function planeHit(planePos, normal, origin, dir)
		local v = origin - planePos
		local num = normal.X * v.X + normal.Y * v.Y + normal.Z * v.Z
		local den = normal.X * dir.X + normal.Y * dir.Y + normal.Z * dir.Z
		return origin + (-num / den) * dir
	end

	local conn = RunService.RenderStepped:Connect(function()
		local cam = Workspace.CurrentCamera
		if not cam or not windowFrame.Parent then return end
		if part.Parent ~= cam then part.Parent = cam end
		if not windowFrame.Visible then
			mesh.Offset = Vector3.zero
			mesh.Scale = Vector3.zero
			return
		end
		local c0 = windowFrame.AbsolutePosition
		local c1 = c0 + windowFrame.AbsoluteSize
		local r0 = cam:ViewportPointToRay(c0.X, c0.Y, 1)
		local r1 = cam:ViewportPointToRay(c1.X, c1.Y, 1)
		local origin = cam.CFrame.Position + cam.CFrame.LookVector * (0.05 - cam.NearPlaneZ)
		local normal = cam.CFrame.LookVector
		local p0 = planeHit(origin, normal, r0.Origin, r0.Direction)
		local p1 = planeHit(origin, normal, r1.Origin, r1.Direction)
		p0 = cam.CFrame:PointToObjectSpace(p0)
		p1 = cam.CFrame:PointToObjectSpace(p1)
		mesh.Offset = (p0 + p1) / 2
		mesh.Scale = (p1 - p0) / 0.0101
		part.CFrame = cam.CFrame
	end)

	acrylicCleanup = function()
		pcall(function() conn:Disconnect() end)
		pcall(function() part:Destroy() end)
		pcall(function() dof:Destroy() end)
	end
end

local function paint(inst, prop, key)
	inst[prop] = Theme[key]
	table.insert(painted, {inst,prop, key})
end

local function repaint()
	for _, entry in ipairs(painted) do
		local inst, prop,key = entry[1],entry[2], entry[3]
		if inst and inst.Parent and Theme[key] then
			pcall(function() inst[prop] = Theme[key] end)
		end
	end
end

local function create(class, props, children)
	local inst = Instance.new(class)

	if class == "TextButton" or class == "ImageButton" then
		inst.AutoButtonColor = false
	end
	local parent = nil
	if props then
		for k,v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function round(inst, r)
	return create("UICorner", {CornerRadius = UDim.new(0, r), Parent = inst})
end

local function roundFull(inst)
	return create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = inst})
end

local function padAll(inst, t, r, b, l)
	return create("UIPadding", {
		PaddingTop = UDim.new(0,t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
		Parent = inst,
	})
end

local GLOW_IMAGE = 'rbxassetid://6014261993'

-- The original Rayfield window shadow (asset 5587865193). It only renders via
-- getcustomasset, so we download the PNG once (exactly as Rayfield does) and
-- cache it locally. Falls back to GLOW_IMAGE when unavailable.
local RAYFIELD_SHADOW = { id = "5587865193", asset = nil, tried = false, slice = Rect.new(91, 91, 187, 328) }
local function rayfieldShadow()
	if RAYFIELD_SHADOW.tried then return RAYFIELD_SHADOW.asset end
	RAYFIELD_SHADOW.tried = true
	if not fsAvailable or type(getcustomasset) ~= "function" then return nil end
	pcall(function()
		local folder = BASE_FOLDER .. "/Assets"
		mkfolder(folder)
		local path = folder .. "/" .. RAYFIELD_SHADOW.id .. ".png"
		if not (isfile and isfile(path)) then
			local data = fetch("https://github.com/SiriusSoftwareLtd/Rayfield/blob/main/assets/" .. RAYFIELD_SHADOW.id .. ".png?raw=true")
			if data and #data > 0 then writefile(path, data) end
		end
		if isfile and isfile(path) then
			RAYFIELD_SHADOW.asset = getcustomasset(path)
		end
	end)
	return RAYFIELD_SHADOW.asset
end

-- True radial glow. A core layer plus a wider faint layer give a soft bloom
-- with no hard edge (the shadow slice asset can only draw a rectangle).
local GLOW_RADIAL = 'rbxassetid://8992230677'
local GLOW_LAYERS = {
	{scale = 1.0, fade = 0.0},
	{scale = 1.9, fade = 0.5},
}
local function softGlow(parent, color, trans, spread, z)
	local holder = create("Frame", {
		Name = "Glow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = z or 0,
		Parent = parent,
	})
	for i, L in ipairs(GLOW_LAYERS) do
		local base = math.clamp(trans + (1 - trans) * L.fade, 0, 1)
		local px = spread * L.scale
		local img = create("ImageLabel", {
			Name = "L" .. i,
			Image = GLOW_RADIAL,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, px, 1, px),
			ImageColor3 = color,
			ImageTransparency = base,
			ScaleType = Enum.ScaleType.Stretch,
			ZIndex = z or 0,
			Parent = holder,
		})
		img:SetAttribute("BaseTransparency", base)
	end
	return holder
end
local function glowColor(holder, color)
	for _, ch in ipairs(holder:GetChildren()) do
		if ch:IsA("ImageLabel") then ch.ImageColor3 = color end
	end
end
-- amount: 0 hidden, 1 fully shown (at each layer's base transparency)
local function glowSet(holder, amount, ti)
	if not GenStyle.glow then amount = 0 end
	for _, ch in ipairs(holder:GetChildren()) do
		if ch:IsA("ImageLabel") then
			local base = ch:GetAttribute("BaseTransparency") or 0
			local target = base + (1 - base) * (1 - amount)
			if ti then
				TweenService:Create(ch, ti, {ImageTransparency = target}):Play()
			else
				ch.ImageTransparency = target
			end
		end
	end
end

local FONT_REGULAR = Enum.Font.BuilderSans
local FONT_MEDIUM = Enum.Font.BuilderSansMedium
local FONT_BOLD = Enum.Font.BuilderSansBold

local FONT_SETS
do
	local builderOk = pcall(function() return Enum.Font.BuilderSansMedium end)
	local builder = builderOk
		and { Enum.Font.BuilderSans, Enum.Font.BuilderSansMedium, Enum.Font.BuilderSansBold }
		or  { Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold }
	FONT_SETS = {
		builder = builder,
		gotham = { Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold },
		mono = { Enum.Font.Code, Enum.Font.Code, Enum.Font.Code },
	}
end

-- Every Roblox font, for the settings font picker.
local ALL_FONTS = {}
do
	for _, f in ipairs(Enum.Font:GetEnumItems()) do
		if f.Name ~= "Unknown" then table.insert(ALL_FONTS, f.Name) end
	end
	table.sort(ALL_FONTS)
end

-- Swaps the active font trio. Read at construction, so a generation/font switch
-- takes effect on the next rebuild. Accepts a preset key ("builder"/"gotham"/
-- "mono") or any Enum.Font name (weight variants are auto-detected).
function applyFont(key)
	local set = key and FONT_SETS[key]
	if not set and key then
		local ok, base = pcall(function() return Enum.Font[key] end)
		if ok and base then
			local function variant(suffix)
				local o, f = pcall(function() return Enum.Font[key .. suffix] end)
				return o and f or nil
			end
			local med = variant("Medium") or base
			local bold = variant("Bold") or variant("SemiBold") or med
			set = { base, med, bold }
		end
	end
	set = set or FONT_SETS.builder
	FONT_REGULAR, FONT_MEDIUM, FONT_BOLD = set[1], set[2], set[3]
end
applyFont("builder")

local TI_FAST=TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SMOOTH = TweenInfo.new(0.32,Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TI_MORPH = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function tween(o, ti, props)
	local t = TweenService:Create(o, ti, props)
	t:Play()
	return t
end

local function measureText(text, size,font)
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(1000,100))
	end)
	if ok then return result end
	return Vector2.new(#text * size * 0.5, size)
end

local function measureWrapped(text,size, font, width)
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(width, 100000))
	end)
	if ok then return math.ceil(result.Y) end
	local perLine = math.max(1, math.floor(width / (size * 0.55)))
	return math.ceil(#text / perLine) * (size + 3)
end

local function parsenum(s)
	s = tostring(s)
	local i, j = s:find("%-?%d[%d,]*%.?%d*")
	if not i then return nil end
	local numStr = s:sub(i, j)
	return tonumber((numStr:gsub(",",""))), s:sub(1, i - 1), s:sub(j + 1),numStr
end

local function commafy(s)
	local sign = ""
	if s:sub(1,1) == "-" then sign = "-"; s = s:sub(2) end
	s = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if s:sub(1, 1) == "," then s = s:sub(2) end
	return sign .. s
end

local function catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

local function countingValue(label, initial)
	local token = 0
	local current = initial ~= nil and parsenum(initial) or nil
	return function(newValue)
		local targetN, prefix, suffix, targetNumStr = parsenum(newValue)
		if not targetN then
			label.Text = tostring(newValue)
			current = nil
			return
		end
		local decimals = 0
		local dot=targetNumStr:find("%.")
		if dot then decimals = #targetNumStr - dot end
		local hasComma = targetNumStr:find(",") ~= nil
		local startN = current or targetN
		token = token + 1
		local myToken = token
		local function fmt(n)
			local str = decimals > 0 and string.format("%." .. decimals .. "f", n) or tostring(math.floor(n + 0.5))
			if hasComma then str = commafy(str) end
			return prefix .. str .. suffix
		end
		if startN == targetN then
			label.Text = fmt(targetN)
			current=targetN
			return
		end
		local duration = math.clamp(math.abs(targetN - startN) * 0.02, 0.35, 0.9)
		task.spawn(function()
			local elapsed = 0
			while elapsed < duration do
				if myToken ~= token then return end
				local dt = task.wait()
				elapsed = math.min(elapsed + dt, duration)
				local a = 1 - (1 - elapsed / duration) ^ 3
				label.Text = fmt(startN + (targetN - startN) * a)
			end
			if myToken == token then
				label.Text = fmt(targetN)
				current=targetN
			end
		end)
	end
end

local function odometerValue(label, initial)
	label.TextTransparency = 1
	local font, size, color = label.Font, label.TextSize,label.TextColor3
	local cellH = TextService:GetTextSize("0", size, font, Vector2.new(2000,2000)).Y

	local digWidths, digitW = {}, 0
	for d = 0, 9 do
		local w = math.ceil(TextService:GetTextSize(tostring(d), size, font, Vector2.new(2000, 2000)).X)
		digWidths[d] = w
		digitW = math.max(digitW, w)
	end

	local row = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = label.AnchorPoint,
		Position = label.Position,
		Size = UDim2.new(0, 0, 0, cellH),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = label.ZIndex,
		Parent = label.Parent,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})

	local token = 0
	local prevDigits = {}
	local function digitsOf(s)
		local t = {}
		for ch in s:gmatch("%d") do t[#t + 1] = ch end
		return t
	end

	local function setVal(newValue, animate)
		local targetN, prefix, suffix, targetNumStr = parsenum(newValue)
		if not targetN then
			row.Visible = false
			label.TextTransparency = 0
			label.Text = tostring(newValue)
			prevDigits = {}
			return
		end
		label.Text = ""
		row.Visible = true
		local decimals=0
		local dot = targetNumStr:find("%.")
		if dot then decimals = #targetNumStr - dot end
		local hasComma = targetNumStr:find(",") ~= nil
		local function fmt(n)
			local str = decimals > 0 and string.format("%." .. decimals .. "f",n) or tostring(math.floor(n + 0.5))
			if hasComma then str = commafy(str) end
			return prefix .. str .. suffix
		end
		local targetStr = fmt(targetN)
		token = token + 1

		local tDigits = digitsOf(targetStr)
		local nT, nP = #tDigits,#prevDigits
		for _, ch in ipairs(row:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end

		local digitIndex, order=0, 0
		local strips = {}
		for i = 1, #targetStr do
			local chr = targetStr:sub(i, i)
			order = order + 1
			if chr:match("%d") then
				digitIndex = digitIndex + 1
				local posFromRight = nT - digitIndex
				local pIdx = nP - posFromRight
				local startD = (pIdx >= 1 and prevDigits[pIdx]) and tonumber(prevDigits[pIdx]) or 0
				local targetD = tonumber(chr)
				local cell = create("Frame",{
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(digWidths[targetD], cellH),
					ClipsDescendants = true,
					LayoutOrder = order,
					ZIndex = row.ZIndex,
					Parent = row,
				})
				local strip = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5,0),
					Size = UDim2.fromOffset(digitW,10 * cellH),
					Position=UDim2.new(0.5, 0, 0, -startD * cellH),
					ZIndex = row.ZIndex,
					Parent = cell,
				})
				for d = 0, 9 do
					create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(0, d * cellH),
						Size = UDim2.fromOffset(digitW, cellH),
						Font = font,
						TextSize = size,
						TextColor3 = color,
						Text = tostring(d),
						TextXAlignment=Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = row.ZIndex,
						Parent = strip,
					})
				end
				strips[#strips + 1] = { strip = strip, startD = startD, targetD = targetD, posFromRight = posFromRight }
			else
				local w = math.ceil(TextService:GetTextSize(chr, size, font, Vector2.new(2000,2000)).X)
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(math.max(w, 3), cellH),
					Font = font,
					TextSize = size,
					TextColor3 = color,
					Text = chr,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					LayoutOrder = order,
					ZIndex = row.ZIndex,
					Parent = row,
				})
			end
		end

		prevDigits = tDigits
		local maxR = math.max(1, nT - 1)
		for _,s in ipairs(strips) do
			local dest = UDim2.new(0.5, 0,0, -s.targetD * cellH)
			if animate == false or s.startD == s.targetD then
				s.strip.Position = dest
			else
				local frac = s.posFromRight / maxR
				local duration = 0.26 + 0.22 * (1 - frac)
				tween(s.strip,TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = dest })
			end
		end
	end

	if initial ~= nil then setVal(initial, false) end
	return setVal
end

local Icons = nil
local pendingIcons = {}

local ICON_ALIASES = {
	["house"] = {"home"},
	["home"] = {"house"},
	["chart-no-axes-column"] = {"bar-chart-3", "bar-chart"},
	["chart-no-axes-column-increasing"] = {"bar-chart-3", "bar-chart"},
	["chart-column"] = {"bar-chart-2"},
	["chart-bar"] = {"bar-chart-horizontal"},
	["chart-line"] = {"line-chart"},
	["triangle-alert"] = {"alert-triangle"},
	["circle-alert"] = {"alert-circle"},
	["circle-check"] = {"check-circle", "check-circle-2"},
	["circle-x"] = {"x-circle"},
	["circle-help"] = {"help-circle"},
	["square-check"] = {"check-square"},
	["square-pen"] = {"pen-square", "edit"},
	["ellipsis"] = {"more-horizontal"},
	["ellipsis-vertical"] = {"more-vertical"},
	["wand-sparkles"] = {"wand-2"},
	["trash"] = {"trash-2"},
	["maximize"] = {"maximize-2"},
	["minimize"] = {"minimize-2"},
	["grip"] = {"grip-horizontal"},
	["user-round"] = {"user-circle-2", "user"},
	["users-round"] = {"users"},
	["loader-pinwheel"] = {"loader"},
	["loader-circle"] = {"loader-2"},
	["key"] = {"key-round"},
	["key-round"] = {"key"},
}

local warnedIcons = {}

local function getLucide(name)
	if not Icons then return nil end
	local sized = Icons["48px"]
	if not sized then return nil end
	name=string.lower(name)
	local entry = sized[name]
	if not entry then
		local aliases = ICON_ALIASES[name]
		if aliases then
			for _, alias in ipairs(aliases) do
				entry = sized[alias]
				if entry then break end
			end
		end
	end
	if not entry then return nil end
	if type(entry[1]) ~= "number" then return nil end
	return {
		id = entry[1],
		size = Vector2.new(entry[2][1], entry[2][2]),
		offset = Vector2.new(entry[3][1], entry[3][2]),
	}
end


local function loadIcons()

	local okMod, bundled = pcall(function()
		local RS = game:GetService("ReplicatedStorage")
		local iconMod = RS:FindFirstChild("RayfieldGen3Icons")
		if iconMod and iconMod:IsA("ModuleScript") then
			return require(iconMod)
		end
		return nil
	end)
	if okMod and type(bundled) == "table" and bundled["48px"] then
		Icons = bundled
		return
	end

	local cachePath = BASE_FOLDER .. "/icons_cache.lua"
	local source = readf(cachePath)
	local fresh = false
	if not source then
		source = fetch("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
		fresh = true
	end
	if not source then return end
	local ok, result = pcall(function()
		local chunk = loadstring(source)
		return chunk and chunk() or nil
	end)
	if ok and type(result) == "table" and result["48px"] then
		Icons = result
		if fresh then
			writef(cachePath, source)
		end
	elseif not fresh then

		source = fetch("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
		if source then
			local ok2,result2=pcall(function()
				local chunk = loadstring(source)
				return chunk and chunk() or nil
			end)
			if ok2 and type(result2) == "table" and result2["48px"] then
				Icons = result2
				writef(cachePath, source)
			end
		end
	end
end

loadIcons()

local function flushPendingIcons()
	if not Icons then return end
	for _, entry in ipairs(pendingIcons) do
		if entry.img and entry.img.Parent then
			local asset = nil
			for _, name in ipairs(entry.names) do
				asset = getLucide(name)
				if asset then break end
			end
			if asset then
				entry.img.Image = "rbxassetid://" .. tostring(asset.id)
				entry.img.ImageRectSize = asset.size
				entry.img.ImageRectOffset = asset.offset
				if entry.onApplied then entry.onApplied() end
			end
		end
	end
	pendingIcons = {}
end

if not Icons then
	task.spawn(function()
		for _=1, 12 do
			task.wait(2.5)
			loadIcons()
			if Icons then
				flushPendingIcons()
				return
			end
		end
	end)
end

local function applyLucide(img, names, onApplied)
	if type(names) == "string" then names = {names} end
	if Icons then
		for _,name in ipairs(names) do
			local asset = getLucide(name)
			if asset then
				img.Image = "rbxassetid://" .. tostring(asset.id)
				img.ImageRectSize = asset.size
				img.ImageRectOffset = asset.offset
				if onApplied then onApplied() end
				return true
			end
		end
		local wanted=names[1]
		if not warnedIcons[wanted] then
			warnedIcons[wanted] = true
			warn("Rayfield Gen3 | Unknown icon \"" .. tostring(wanted) .. "\"");
		end
		return false
	end
	table.insert(pendingIcons, {img = img, names = names, onApplied = onApplied})
	return false
end


local function makeIcon(parent, icon,size, color3, transparency)
	if icon == nil or icon == 0 or icon == "" then return nil end
	local img = create("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ImageColor3 = color3 or Theme.TextTitle,
		ImageTransparency = transparency or 0,
		Parent = parent,
	})
	if type(icon) == "number" then
		img.Image = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" then
		if string.find(icon, "rbxasset") or string.find(icon, "://") then
			img.Image = icon
		else
			applyLucide(img, icon);
		end
	end
	return img
end

local RayfieldLibrary = {
	Flags = {},
	Theme = Theme,
}

local Connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Connections, c)
	return c
end

local rootGui = nil
local notifyStack = nil
local destroyed = false

local function ensureRoot()
	if rootGui and rootGui.Parent then return rootGui end
	rootGui = create("ScreenGui", {
		Name = "RayfieldGen3",
		DisplayOrder = 100000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(rootGui) end
	end)
	rootGui.Parent = guiParent()

	notifyStack = create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(300,900),
		Parent = rootGui,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = notifyStack,
	})
	return rootGui
end

local notifyOrder = 0

function RayfieldLibrary:Notify(data)
	data=data or {}
	ensureRoot();
	notifyOrder = notifyOrder + 1

	local hasIcon = data.Image ~= nil and data.Image ~= "" and data.Image ~= 0
	local NOTIFY_W, ICON_BOX=300, 32
	local textX = hasIcon and 70 or 18
	local textWidth = NOTIFY_W - textX - 14

	local titleText = data.Title or "Notification"
	local bodyText = data.Content or ""
	local titleH = measureWrapped(titleText, 16, FONT_BOLD, textWidth)
	local bodyH = bodyText ~= "" and measureWrapped(bodyText,15, FONT_MEDIUM, textWidth) or 0

	local fullH = math.max(15 + titleH + (bodyH > 0 and (2 + bodyH) or 0) + 14, 60)

	local holder = create("Frame", {
		Name = titleText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 0),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})
	local glow = softGlow(holder, Color3.fromRGB(0, 0,0), 0.72, 18, 0)
	glowSet(glow, 0)

	local card = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		BackgroundColor3=Theme.NotifyBackground,
		Parent = holder,
	})
	round(card, 20)

	local cardStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Parent = card})

	if hasIcon then
		local icon = makeIcon(card, data.Image, ICON_BOX, Theme.TextTitle)
		if icon then
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 20,0.5, 0)
		end
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textX,15),
		Size = UDim2.new(0, textWidth, 0, titleH),
		Font=FONT_BOLD,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = titleText,
		TextColor3 = Theme.TextTitle,
		Parent = card,
	})
	if bodyH > 0 then
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(textX, 15 + titleH + 2),
			Size = UDim2.new(0, textWidth, 0,bodyH),
			Font = FONT_MEDIUM,
			TextSize = 15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = bodyText,
			TextColor3 = Theme.TextSub,
			Parent = card,
		})
	end

	local clicker = create("TextButton",{
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = card,
	})

	local paused = false
	local dismissed = false
	clicker.MouseEnter:Connect(function() paused = true end)
	clicker.MouseLeave:Connect(function() paused = false end)

	local GROW=TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local FADE=TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local function dismiss()
		if dismissed then return end
		dismissed = true

		tween(card, FADE, {GroupTransparency = 1})
		tween(cardStroke, FADE, {Transparency = 1})
		glowSet(glow, 0, FADE)
		task.wait(0.2)
		tween(holder, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)})
		task.wait(0.55)
		holder:Destroy()
	end

	clicker.MouseButton1Click:Connect(function()
		task.spawn(dismiss)
	end)

	task.defer(function()

		tween(holder, GROW, {Size = UDim2.new(1, 0, 0, fullH)})
		task.wait(0.15)
		tween(card, FADE, {GroupTransparency = 0})
		tween(cardStroke, FADE, {Transparency = 0.94})
		task.wait(0.05)
		glowSet(glow, 1, TweenInfo.new(0.3, Enum.EasingStyle.Exponential));

		local duration = data.Duration or math.min(math.max(#bodyText * 0.1 + 2.5, 3), 10)
		local elapsed=0
		while elapsed < duration and not dismissed do
			local dt = task.wait(0.1)
			if not paused then elapsed = elapsed + dt end
		end
		dismiss()
	end)
end

-- Centered modal dialog. Use for confirmations ("Are you sure?") and for a
-- Terms/agreement gate the user must accept before continuing.
--   Rayfield:Dialog({ Title=, Content=, Options={ {Text=, Primary=, Callback=} } })
function RayfieldLibrary:Dialog(data)
	data = data or {}
	ensureRoot()
	local options = data.Options
	if type(options) ~= "table" or #options == 0 then
		options = { { Text = data.AcceptText or "OK" } }
	end

	local function textOn(c)
		local l = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
		return l > 0.6 and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(245, 245, 245)
	end

	local overlay = create("Frame", {
		Name = "Dialog",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 500,
		Parent = rootGui,
	})
	create("TextButton", {
		BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 500, Parent = overlay,
	})

	-- soft drop shadow so the panel floats (no border), same Rayfield asset
	local dlgShadow = rayfieldShadow()
	local DLG_SHADOW_PAD = dlgShadow and 55 or 23
	local shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(470, 120),
		Image = dlgShadow or GLOW_IMAGE,
		ImageColor3 = Color3.fromRGB(20, 20, 20),
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = dlgShadow and RAYFIELD_SHADOW.slice or Rect.new(49, 49, 450, 450),
		ZIndex = 500,
		Parent = overlay,
	})

	-- CanvasGroup so the exit can fade the whole card at once. GroupTransparency
	-- stays 0 during open (tweening it while AutomaticSize settles caused the old
	-- glitch); the entrance is Visible + UIScale, revealed one frame after layout.
	local card = create("CanvasGroup", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(430, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 0,
		Visible = false,
		ZIndex = 501,
		Parent = overlay,
	})
	paint(card, "BackgroundColor3", "Background")
	round(card, math.max(18, GenStyle.windowCorner))
	local dlgScale = create("UIScale", { Scale = 0.92, Parent = card })
	local function syncShadow()
		local s = card.AbsoluteSize
		shadow.Size = UDim2.fromOffset(s.X + DLG_SHADOW_PAD * 2, s.Y + DLG_SHADOW_PAD * 2)
	end
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncShadow)
	task.defer(syncShadow)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
		Parent = card,
	})
	padAll(card, 22, 24, 22, 24)

	local closed = false
	local function close()
		if closed then return end
		closed = true
		-- size is settled by now, so fading the group is safe (no layout glitch)
		tween(overlay, TI_FAST, { BackgroundTransparency = 1 })
		tween(shadow, TI_FAST, { ImageTransparency = 1 })
		tween(card, TI_FAST, { GroupTransparency = 1 })
		tween(dlgScale, TI_FAST, { Scale = 0.95 })
		task.delay(0.16, function() overlay:Destroy() end)
		if type(data.OnClose) == "function" then
			task.spawn(data.OnClose)
		end
	end

	-- title row: close (x) on the left, then the title
	local titleRow = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 1, ZIndex = 501, Parent = card,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
		Parent = titleRow,
	})
	local closeBtn = create("TextButton", {
		BackgroundTransparency = 1, Text = "",
		Size = UDim2.fromOffset(26, 26), LayoutOrder = 1, ZIndex = 502, Parent = titleRow,
	})
	do
		local xi = makeIcon(closeBtn, "x", 22, Theme.TextSub)
		if xi then xi.AnchorPoint = Vector2.new(0.5, 0.5); xi.Position = UDim2.fromScale(0.5, 0.5); xi.ZIndex = 502 end
		closeBtn.MouseEnter:Connect(function() if xi then tween(xi, TI_FAST, { ImageColor3 = Theme.TextTitle }) end end)
		closeBtn.MouseLeave:Connect(function() if xi then tween(xi, TI_FAST, { ImageColor3 = Theme.TextSub }) end end)
		closeBtn.MouseButton1Click:Connect(close)
	end
	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 26),
		Font = FONT_BOLD, TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = data.Title or "Are you sure?",
		LayoutOrder = 2, ZIndex = 501, Parent = titleRow,
	})
	paint(title, "TextColor3", "TextTitle")

	if data.Content and data.Content ~= "" then
		local body = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = FONT_MEDIUM, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Text = data.Content,
			LayoutOrder = 2, ZIndex = 501, Parent = card,
		})
		paint(body, "TextColor3", "TextSub")
	end

	-- button row: equal-width pill buttons filling the card
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 48),
		LayoutOrder = 3, ZIndex = 501, Parent = card,
	})
	local gap = 10
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap),
		Parent = row,
	})
	local n = #options
	local adj = math.floor(gap * (n - 1) / n + 0.5)

	for i, opt in ipairs(options) do
		local isCustom = opt.Color ~= nil or opt.Primary == true
		-- neutral buttons use a theme surface so they tint with the active theme
		local bg = opt.Color or (opt.Primary and Theme.Accent) or Theme.CardSelected
		local btn = create("TextButton", {
			Size = UDim2.new(1 / n, -adj, 1, 0),
			Text = "",
			BackgroundColor3 = bg,
			LayoutOrder = i, ZIndex = 502, Parent = row,
		})
		roundFull(btn)
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = FONT_BOLD, TextSize = 16,
			Text = opt.Text or "OK",
			TextColor3 = isCustom and textOn(bg) or Theme.TextTitle,
			ZIndex = 502, Parent = btn,
		})
		btn.MouseEnter:Connect(function()
			tween(btn, TI_FAST, { BackgroundColor3 = bg:Lerp(Color3.new(1, 1, 1), 0.1) })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, TI_FAST, { BackgroundColor3 = bg })
		end)
		btn.MouseButton1Click:Connect(function()
			close()
			if type(opt.Callback) == "function" then
				task.spawn(function()
					local ok, err = pcall(opt.Callback)
					if not ok then warn("Rayfield Gen3 | Dialog callback error: " .. tostring(err)) end
				end)
			end
		end)
	end

	-- smooth entrance: reveal one frame after the layout settles, then a quick
	-- scale-up with the dim and shadow fading in alongside
	task.defer(function()
		if closed then return end
		card.Visible = true
		tween(overlay, TI_MED, { BackgroundTransparency = 0.5 })
		tween(shadow, TI_MED, { ImageTransparency = 0.35 })
		tween(dlgScale, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 })
	end)
	return { Close = close }
end

local function showAccountToast()
	if not LocalPlayer then return end
	ensureRoot()
	notifyOrder = notifyOrder + 1

	local wrapper = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(0,240,0,58),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})
	local pill = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0,54),
		Position = UDim2.fromOffset(280, 0),
		BackgroundColor3 = Theme.NotifyBackground,
	})
	roundFull(pill)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = pill})
	create("UIGradient",{
		Rotation = 90,
		Color=ColorSequence.new(Color3.fromRGB(255,255, 255), Color3.fromRGB(170, 170, 170)),
		Parent = pill,
	})
	padAll(pill, 6, 20, 6, 6)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = pill,
	})

	local avatar = create("ImageLabel", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.fromOffset(42, 42),
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48",
		LayoutOrder = 1,
		Parent = pill,
	})
	roundFull(avatar)

	local textCol=create("Frame",{
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = pill,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0,0, 14),
		Position = UDim2.fromOffset(0, 9),
		Font = FONT_MEDIUM,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Signed in as",
		TextColor3 = Theme.TextSub,
		Parent = textCol,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0,0, 16),
		Position = UDim2.fromOffset(0, 25),
		Font = FONT_BOLD,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = LocalPlayer.DisplayName or LocalPlayer.Name,
		TextColor3 = Theme.TextTitle,
		Parent = textCol,
	})

	pill.Parent = wrapper
	tween(pill,TI_MORPH, {Position = UDim2.fromOffset(0, 0)})
	task.delay(4, function()
		tween(pill, TI_SMOOTH, {Position = UDim2.fromOffset(280, 0)})
		task.wait(0.25)
		tween(wrapper, TI_MED, {Size = UDim2.new(0, 240, 0,0)})
		task.wait(0.26)
		wrapper:Destroy()
	end)
end

local function runKeySystem(Settings)
	local keySettings = Settings.KeySettings or {}
	local fileName = keySettings.FileName or "Key"
	local keyPath = BASE_FOLDER .. "/" .. fileName .. ".txt"

	local keys = {}
	local rawKey = keySettings.Key or {}
	if type(rawKey) == "string" then rawKey = {rawKey} end

	if keySettings.GrabKeyFromSite then
		for _, url in ipairs(rawKey) do
			local body = fetch(tostring(url))
			if body then
				body = string.gsub(body, "%s+$", "")
				body = string.gsub(body,"^%s+","")
				table.insert(keys, body)
			end
		end
	else
		for _, k in ipairs(rawKey) do
			table.insert(keys, tostring(k))
		end
	end

	local function isValid(candidate)
		candidate = string.gsub(tostring(candidate),"^%s+", "")
		candidate = string.gsub(candidate, "%s+$", "")
		for _, k in ipairs(keys) do
			if candidate == k then return true end
		end
		return false
	end

	if #keys == 0 then
		warn("Rayfield Gen3 | Key system enabled but no keys resolved, skipping")
		return true
	end

	if keySettings.SaveKey then
		local saved = readf(keyPath)
		if saved and isValid(saved) then
			return true
		end
	end

	ensureRoot()

	local overlay = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0,0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		ZIndex = 50,
		Parent = rootGui,
	})
	tween(overlay, TI_MED, {BackgroundTransparency = 0.45})

	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5,0.52),
		Size = UDim2.fromOffset(360, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background,
		ZIndex = 51,
		Parent = overlay,
	})
	round(card, 20)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = card})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255,255, 255), Color3.fromRGB(160, 160, 160)),
		Parent = card,
	})
	padAll(card, 24,22, 22,22)
	create("UIListLayout",{
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = card,
	})

	local well = create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.fromOffset(52,52),
		LayoutOrder = 1,
		Parent = card,
	})
	roundFull(well)
	local keyIcon = makeIcon(well, "key-round", 26,Theme.TextTitle)
	if keyIcon then
		keyIcon.AnchorPoint = Vector2.new(0.5,0.5)
		keyIcon.Position = UDim2.fromScale(0.5, 0.5)
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1,0, 0, 0),
		Font = FONT_BOLD,
		TextSize = 20,
		TextWrapped = true,
		Text = keySettings.Title or Settings.Name or "Key System",
		TextColor3 = Theme.TextTitle,
		LayoutOrder = 2,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0,0,0),
		Font = FONT_MEDIUM,
		TextSize = 14,
		TextWrapped = true,
		Text = keySettings.Subtitle or "Enter your key to continue",
		TextColor3 = Theme.TextSub,
		LayoutOrder = 3,
		Parent = card,
	})
	if keySettings.Note and keySettings.Note ~= "" then
		create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = FONT_REGULAR,
			TextSize = 13,
			TextWrapped = true,
			Text = keySettings.Note,
			TextColor3 = Theme.TextMuted,
			LayoutOrder = 4,
			Parent = card,
		})
	end

	local boxHolder = create("Frame", {
		BackgroundColor3 = Theme.CardInset,
		Size = UDim2.new(1,0, 0, 44),
		LayoutOrder = 5,
		Parent = card,
	})
	round(boxHolder, 12)
	local boxStroke = create("UIStroke", {Color = Color3.fromRGB(255,255, 255), Transparency = 0.88, Parent = boxHolder})
	local box = create("TextBox",{
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14,0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = FONT_MEDIUM,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Key",
		PlaceholderColor3 = Theme.TextMuted,
		Text = "",
		ClearTextOnFocus = false,
		TextColor3 = Theme.TextBody,
		Parent = boxHolder,
	})

	local submit = create("TextButton", {
		BackgroundColor3 = Theme.TextTitle,
		Size = UDim2.new(1,0, 0, 44),
		Font = FONT_BOLD,
		TextSize = 15,
		Text = "Unlock",
		TextColor3 = Color3.fromRGB(12, 12, 12),
		AutoButtonColor = false,
		LayoutOrder = 6,
		Parent = card,
	})
	round(submit,12)
	submit.MouseEnter:Connect(function()
		tween(submit, TI_FAST, {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
	end)
	submit.MouseLeave:Connect(function()
		tween(submit, TI_FAST, {BackgroundColor3 = Theme.TextTitle})
	end)

	card.Position = UDim2.fromScale(0.5, 0.56)
	tween(card, TI_MORPH, {Position = UDim2.fromScale(0.5, 0.5)})

	local passed=false

	local function shake()
		tween(boxStroke, TweenInfo.new(0.1),{Color = Color3.fromRGB(224,90,90),Transparency = 0.2})
		local base = card.Position
		local seq = {8, -7, 5, -3, 0}
		task.spawn(function()
			for _, dx in ipairs(seq) do
				tween(card, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(base.X.Scale, dx, base.Y.Scale, 0),
				})
				task.wait(0.05)
			end
			task.wait(0.4)
			tween(boxStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88})
		end)
	end

	local function attempt()
		if isValid(box.Text) then
			passed = true
			if keySettings.SaveKey then
				writef(keyPath, box.Text)
			end
			tween(card, TI_MED, {Position = UDim2.fromScale(0.5, 0.54)})
			tween(overlay,TI_MED, {BackgroundTransparency = 1})
			task.wait(0.22)
			overlay:Destroy()
		else
			shake()
		end
	end

	submit.MouseButton1Click:Connect(function() task.spawn(attempt) end)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then task.spawn(attempt) end
	end)

	repeat task.wait() until passed or destroyed or not overlay.Parent
	return passed
end

local function _constructWindow(Settings)
	Settings = Settings or {}
	ensureRoot()

	if Settings.KeySystem then
		local ok = runKeySystem(Settings)
		if not ok then
			warn("Rayfield Gen3 | Key system was not passed")
			return nil
		end
	end

	local configEnabled = false
	local configFolder = BASE_FOLDER
	local configFile = "Config"
	if type(Settings.ConfigurationSaving) == "table" and Settings.ConfigurationSaving.Enabled then
		configEnabled = fsAvailable
		configFolder = Settings.ConfigurationSaving.FolderName or configFolder
		configFile = Settings.ConfigurationSaving.FileName or configFile
	end
	if configEnabled then mkfolder(configFolder) end

	local savePending = false
	local function saveConfiguration()
		if not configEnabled or destroyed then return end
		if savePending then return end
		savePending = true
		task.delay(0.6, function()
			savePending = false
			if destroyed then return end
			local out = {}
			for flag, element in pairs(RayfieldLibrary.Flags) do
				if element.Type == "Toggle" or element.Type == "Checkbox" or element.Type == "Slider" or element.Type == "Input" then
					out[flag] = element.CurrentValue
				elseif element.Type == "Dropdown" then
					out[flag] = element.CurrentOption
				elseif element.Type == "Keybind" then
					out[flag] = element.CurrentKeybind
				elseif element.Type == "ColorPicker" then
					local c = element.Color
					out[flag] = {R = math.floor(c.R * 255 + 0.5), G = math.floor(c.G * 255 + 0.5), B = math.floor(c.B * 255 + 0.5)}
				elseif element.Type == "GradientPicker" then
					out[flag] = element:Serialize()
				end
			end
			writef(configFolder .. "/" .. configFile .. ".json", HttpService:JSONEncode(out))
		end)
	end

	task.spawn(function()
		if not fsAvailable or not LocalPlayer then return end
		local path = BASE_FOLDER .. "/lastuser.txt"
		local last = readf(path)
		local current = tostring(LocalPlayer.UserId)
		writef(path, current)
		if last ~= nil and last ~= current then
			task.wait(0.5)
			showAccountToast()
		end
	end)

	local WINDOW_W, WINDOW_H = GenStyle.windowW, GenStyle.windowH
	if typeof(Settings.Size) == "UDim2" then
		WINDOW_W = Settings.Size.X.Offset > 0 and Settings.Size.X.Offset or WINDOW_W
		WINDOW_H = Settings.Size.Y.Offset > 0 and Settings.Size.Y.Offset or WINDOW_H
	elseif type(Settings.Size) == "table" then
		WINDOW_W = tonumber(Settings.Size[1]) or WINDOW_W
		WINDOW_H = tonumber(Settings.Size[2]) or WINDOW_H
	end
	WINDOW_W = math.clamp(WINDOW_W, 360, 900)
	WINDOW_H = math.clamp(WINDOW_H, 320, 760)
	local HEADER_H = 76
	local PILL_H = 62

	local pillNameText = Settings.Name or "Rayfield"
	local pillTextW = math.max(
		measureText(pillNameText, 16, FONT_BOLD).X,
		measureText("Tap to show",13, FONT_MEDIUM).X
	)
	local PILL_W = math.clamp(12 + 44 + 12 + math.ceil(pillTextW) + 26, 180,340)

	local shownPosition = UDim2.new(0.5,0, 0.5, -math.floor((WINDOW_H + 18) / 2))

	local root = create("Frame", {
		Name = "WindowRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = shownPosition,
		Size = UDim2.fromOffset(WINDOW_W,WINDOW_H + 18),
		Parent = rootGui,
	})

	local rfShadow = rayfieldShadow()
	local SHADOW_PAD = rfShadow and 55 or 18
	local shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -SHADOW_PAD),
		Size = UDim2.fromOffset(WINDOW_W + SHADOW_PAD * 2, WINDOW_H + SHADOW_PAD * 2),
		Image = rfShadow or GLOW_IMAGE,
		ImageColor3 = Color3.fromRGB(20, 20, 20),
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = rfShadow and RAYFIELD_SHADOW.slice or Rect.new(49, 49, 450, 450),
		ZIndex = 0,
		Parent = root,
	})

	local window = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = root,
	})
	paint(window, "BackgroundColor3", "Background")
	window.BackgroundTransparency = GEN.transparency
	if GEN.acrylic then enableAcrylic(window) end
	local windowCorner = round(window, GenStyle.windowCorner)

	local windowStroke=create("UIStroke",{Color = Color3.fromRGB(255, 255, 255), Transparency = 0.93, Thickness = 1, Parent = window})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.75),
		}),
		Parent = windowStroke,
	})
	create("UIGradient",{
		Rotation=90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 148, 148)),
		}),
		Parent = window,
	})

	local main = create("CanvasGroup", {
		Name = "Main",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		GroupTransparency = 1,
		Parent=window,
	})

	local handle = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, WINDOW_H + 12),
		Size = UDim2.fromOffset(130, 4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Parent = root,
	})
	roundFull(handle)

	connect(window:GetPropertyChangedSignal("Size"), function()
		local size=window.Size
		handle.Position=UDim2.new(0.5, 0, 0,size.Y.Offset + 12)
		shadow.Size = UDim2.fromOffset(size.X.Offset + SHADOW_PAD * 2, size.Y.Offset + SHADOW_PAD * 2)
	end)

	local pillContent = create("CanvasGroup", {
		Name = "PillContent",
		BackgroundTransparency = 1,
		Size=UDim2.fromOffset(PILL_W, PILL_H),
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 10,
		Parent = window,
	})
	do

		local placedIcon = makeIcon(pillContent, "eye", 30, Theme.TextTitle)
		if placedIcon then
			placedIcon.AnchorPoint=Vector2.new(0.5,0.5)
			placedIcon.Position = UDim2.new(0, 31, 0.5, 0)
		else
			create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0, 31, 0.5,0),
				Size = UDim2.fromOffset(30, 30),
				Font = FONT_BOLD,
				TextSize = 20,
				Text = string.upper(string.sub(pillNameText, 1, 1)),
				TextColor3 = Theme.TextTitle,
				Parent = pillContent,
			})
		end

		local col = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 65, 0.5, -17),
			Size = UDim2.new(1,-91,0, 34),
			Parent = pillContent,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 17),
			Font = FONT_BOLD,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = pillNameText,
			TextColor3=Theme.TextTitle,
			Parent = col,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 0,14),
			Font = FONT_MEDIUM,
			TextSize = 13,
			TextXAlignment=Enum.TextXAlignment.Left,
			Text = "Tap to show",
			TextColor3 = Theme.TextSub,
			Parent = col,
		})
	end

	local pillButton = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 12,
		Parent=window,
	})

	local header = create("Frame",{
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		Parent = main,
	})

	local titleRow = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(24, 13),
		Size=UDim2.new(0, 0,0, 27),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection=Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 11),
		Parent = titleRow,
	})

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = FONT_BOLD,
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text=Settings.Name or "Rayfield",
		LayoutOrder = 1,
		Parent = titleRow,
	})
	paint(titleLabel, "TextColor3", "TextTitle")

	if Settings.Badge then
		local badgeText = type(Settings.Badge) == "table" and (Settings.Badge.Text or "") or tostring(Settings.Badge)
		local badgeIcon = type(Settings.Badge) == "table" and Settings.Badge.Icon or nil
		local badge = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0,0, 26),
			LayoutOrder = 2,
			Parent = titleRow,
		})
		paint(badge, "BackgroundColor3", "BadgeBackground")
		roundFull(badge)
		padAll(badge, 0, 12,0, 11)
		create("UIListLayout",{
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0,6),
			Parent = badge,
		})
		if badgeIcon then
			local ic = makeIcon(badge, badgeIcon, 14, Theme.BadgeText)
			if ic then ic.LayoutOrder = 1 end
		end
		local bt = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0,0, 1,0),
			Font = FONT_BOLD,
			TextSize = 13,
			Text = badgeText,
			LayoutOrder = 2,
			Parent = badge,
		})
		paint(bt,"TextColor3", "BadgeText")
	end

	local subtitleLabel = create("TextLabel",{
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(24, 42),
		Size = UDim2.new(0,0,0, 15),
		Font=FONT_MEDIUM,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = Settings.Subtitle or "Rayfield Gen3",
		Parent = header,
	})
	paint(subtitleLabel, "TextColor3", "TextSub")

	local buttonRow = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1, -16, 0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0,30),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = buttonRow,
	})

	local function headerButton(order,lucideNames)
		local btn = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromOffset(30, 30),
			LayoutOrder = order,
			Parent = buttonRow,
		})
		local icon = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5,0.5),
			Size = UDim2.fromOffset(19,19),
			ImageColor3 = Theme.TextSub,
			Parent = btn,
		})
		applyLucide(icon, lucideNames)
		btn.MouseEnter:Connect(function()
			tween(icon, TI_FAST, {ImageColor3=Theme.TextTitle})
		end)
		btn.MouseLeave:Connect(function()
			tween(icon, TI_FAST,{ImageColor3 = Theme.TextSub})
		end)
		return btn, icon
	end

	local searchButton, searchButtonIcon = headerButton(1, {"text-search", "search"})
	local settingsButton, settingsButtonIcon = headerButton(2, {"settings"})
	local minimizeButton,minimizeIcon = headerButton(3, {"minus"})
	local closeButton = headerButton(4,{"x"})

	local body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14,HEADER_H),
		Size = UDim2.new(1,-28,1, -HEADER_H - 14),
		Parent = main,
	})

	local TABBAR_H = 48
	local tabBar = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0, TABBAR_H),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		Parent = body,
	})

	local tabStyle = (Settings.TabStyle == "Accent") and "Accent" or "White"
	local tabAccent = Settings.TabAccent or Theme.Accent
	local function shade(c, f)
		if f >= 0 then
			return Color3.new(c.R + (1 - c.R) * f, c.G + (1 - c.G) * f, c.B + (1 - c.B) * f)
		end
		f = 1 + f
		return Color3.new(c.R * f, c.G * f, c.B * f)
	end

	local function pillTextColor()
		if tabStyle ~= "Accent" then return Color3.fromRGB(28, 28, 28) end
		local lum = 0.299 * tabAccent.R + 0.587 * tabAccent.G + 0.114 * tabAccent.B
		return lum > 0.62 and Color3.fromRGB(24, 24, 24) or Color3.fromRGB(255, 255, 255)
	end
	local dockTrack = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 44),
		BackgroundColor3 = Theme.CardInset,
		BackgroundTransparency = 0.25,
		Parent = tabBar,
	})
	roundFull(dockTrack)
	-- the dock is decorative, so fade it strongly as the window turns glassy
	registerGlass(dockTrack, 0.25, 1.15)
	local dockIndicator = create("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(0, 36),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = dockTrack,
	})
	roundFull(dockIndicator)
	local dockIndicatorGrad = create("UIGradient", {
		Rotation = 105,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(224, 224, 224)),
		Parent = dockIndicator,
	})
	local dockGlowHost = create("Frame", {
		Name = "DockGlowHost",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(80, 36),
		Position = UDim2.fromOffset(0, TABBAR_H / 2 + 1),
		ZIndex = 2,
		Parent = body,
	})
	local dockGlow = softGlow(dockGlowHost, tabAccent, 0.72, 14, 2)
	glowSet(dockGlow, 0)
	local dockButtons = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 3,
		Parent = dockTrack,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = dockButtons,
	})
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = dockButtons,
	})

	local searchHolder = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, TABBAR_H + 8),
		Size=UDim2.new(1,0, 0, 0),
		Parent = body,
	})
	local searchCard = create("Frame", {
		Size = UDim2.new(1, 0, 0,40),
		BackgroundTransparency = 0.35,
	})
	paint(searchCard,"BackgroundColor3", "SearchBox")
	round(searchCard,12)
	searchCard.Parent = searchHolder
	local searchIconHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 40),
		Parent = searchCard,
	})
	do
		local sIcon = makeIcon(searchIconHolder, "text-search", 18,Theme.TextSub)
		if sIcon then
			sIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			sIcon.Position = UDim2.fromScale(0.5, 0.5)
		end
	end
	local searchBox = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Font = FONT_MEDIUM,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Search",
		PlaceholderColor3 = Theme.TextMuted,
		Text = "",
		ClearTextOnFocus = false,
		Parent = searchCard,
	})
	paint(searchBox, "TextColor3", "TextBody")

	local pagesHolder = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TABBAR_H + 10),
		Size = UDim2.new(1, 0, 1,-(TABBAR_H + 10)),
		Parent = body,
	})

	local Window = {}
	local tabs = {}
	local currentTab = nil
	local settingsOpen = false
	local settingsEntry = nil
	local hidden = false
	local minimized = false
	local searchOpen = false
	local morphing = false
	local storedPosition = nil
	local unlockCursor = false

	connect(RunService.RenderStepped,function()
		if unlockCursor and not hidden and not destroyed then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end)

	local function layoutSearch(open)
		searchOpen = open
		local sh = open and 48 or 0
		tween(searchHolder, TI_MED, {Size = UDim2.new(1, 0, 0, open and 40 or 0)})
		tween(pagesHolder, TI_MED, {
			Position = UDim2.fromOffset(0, TABBAR_H + 10 + sh),
			Size = UDim2.new(1, 0, 1, -(TABBAR_H + 10 + sh)),
		})
		tween(searchButtonIcon, TI_FAST, {ImageColor3 = open and Theme.TextTitle or Theme.TextSub})
		if open then
			task.delay(0.12, function() searchBox:CaptureFocus() end)
		else
			searchBox.Text = ""
			searchBox:ReleaseFocus()
		end
	end

	local function currentPage()
		if settingsOpen and settingsEntry then return settingsEntry.Page end
		return currentTab and currentTab.Page or nil
	end

	local function applySearchFilter(query)
		local page = currentPage()
		if not page then return end
		query = string.lower(query or "")
		for _, item in ipairs(page:GetChildren()) do
			if item:IsA("GuiObject") then
				local searchName = item:GetAttribute("SearchName")
				local structural = item:GetAttribute("Structural")
				local composite = item:GetAttribute("Composite")
				if item:GetAttribute("DemandHidden") then
					-- hidden via :SetVisible(false); the search never re-shows it
					item.Visible = false
				elseif query == "" then
					item.Visible = true
				elseif structural then
					item.Visible = false
				elseif composite then

					local matched = false
					for _, d in ipairs(item:GetDescendants()) do
						local sn = d:GetAttribute("SearchName")
						if sn and string.find(string.lower(sn), query,1, true) then
							matched=true
							break
						end
					end
					item.Visible=matched
				elseif searchName then
					item.Visible = string.find(string.lower(searchName), query, 1, true) ~= nil
				end
			end
		end
	end

	connect(searchBox:GetPropertyChangedSignal("Text"), function()
		applySearchFilter(searchBox.Text)
	end)

	searchButton.MouseButton1Click:Connect(function()
		layoutSearch(not searchOpen)
		if not searchOpen then applySearchFilter("") end
	end)

	local function buildPage()
		local pageWrapper = create("CanvasGroup", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = 0,
			Visible = false,
			Parent = pagesHolder,
		})

		local fadeGrad = create("UIGradient",{
			Rotation = 90,
			Parent = pageWrapper,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(0, 0, 0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
			BorderSizePixel = 0,
			Parent = pageWrapper,
		})
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = page,
		})
		padAll(page, 2,5, 16, 1)

		local EDGE = 0.05
		local function updateFade()
			local vh = page.AbsoluteWindowSize.Y
			if vh <= 0 then return end
			local pos = page.CanvasPosition.Y
			local maxScroll = math.max(0, page.AbsoluteCanvasSize.Y - vh)
			local topT = math.clamp(pos / 24, 0, 1)
			local botT = math.clamp((maxScroll - pos) / 24, 0, 1)
			if topT <= 0.001 and botT <= 0.001 then
				fadeGrad.Transparency = NumberSequence.new(0)
			else
				fadeGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, topT),
					NumberSequenceKeypoint.new(EDGE, 0),
					NumberSequenceKeypoint.new(1 - EDGE,0),
					NumberSequenceKeypoint.new(1, botT),
				})
			end
		end
		page:GetPropertyChangedSignal("CanvasPosition"):Connect(updateFade)
		page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateFade);
		page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateFade)
		task.defer(updateFade)
		return page,pageWrapper
	end

	local function showPage(entry)
		for _, other in ipairs(tabs) do
			if other ~= entry then other.Wrapper.Visible = false end
		end
		if settingsEntry and settingsEntry ~= entry then
			settingsEntry.Wrapper.Visible = false
		end
		local wrapper = entry.Wrapper
		wrapper.Visible = true
		wrapper.GroupTransparency = 1
		wrapper.Position = UDim2.fromOffset(0, 12)
		tween(wrapper,TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{GroupTransparency = 0})
		tween(wrapper, TweenInfo.new(0.32,Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)})
	end

	local TI_DOCK = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	local function moveIndicator(animate)
		local target = (not settingsOpen) and currentTab or nil
		if not target or not target.Pill then
			tween(dockIndicator, TI_FAST, {BackgroundTransparency = 1})
			glowSet(dockGlow, 0, TI_FAST)
			return
		end
		local btn = target.Pill
		local x = btn.AbsolutePosition.X - dockTrack.AbsolutePosition.X
		local goalPos = UDim2.fromOffset(x, 4)
		local goalSize = UDim2.fromOffset(btn.AbsoluteSize.X, 36)
		local glowAmount = tabStyle == "Accent" and 1 or 0
		local hostX = btn.AbsolutePosition.X - body.AbsolutePosition.X + btn.AbsoluteSize.X / 2
		local hostPos = UDim2.fromOffset(hostX, TABBAR_H / 2 + 1)
		local hostSize = UDim2.fromOffset(btn.AbsoluteSize.X, 36)
		if animate then
			tween(dockIndicator, TI_DOCK, {Position = goalPos, Size = goalSize, BackgroundTransparency = 0})
			tween(dockGlowHost, TI_DOCK, {Position = hostPos, Size = hostSize})
			glowSet(dockGlow, glowAmount, TI_DOCK)
		else
			dockIndicator.Position = goalPos
			dockIndicator.Size = goalSize
			dockIndicator.BackgroundTransparency = 0
			dockGlowHost.Position = hostPos
			dockGlowHost.Size = hostSize
			glowSet(dockGlow, glowAmount)
		end
	end

	local function applyTabStyle()
		if tabStyle == "Accent" then
			dockIndicatorGrad.Color = ColorSequence.new(shade(tabAccent, 0.24), shade(tabAccent, -0.32))
			glowColor(dockGlow, tabAccent)
		else
			dockIndicatorGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(224, 224, 224))
		end
	end
	applyTabStyle()

	local function styleTabPills()
		local activeColor = pillTextColor()
		for _,other in ipairs(tabs) do
			local active = (not settingsOpen) and other == currentTab
			tween(other.PillLabel, TI_FAST, {TextColor3 = active and activeColor or Theme.TextSub})
			if other.PillIcon then
				tween(other.PillIcon, TI_FAST, {ImageColor3 = active and activeColor or Theme.TextSub})
			end
		end
		moveIndicator(true)
		tween(settingsButtonIcon, TI_FAST,{ImageColor3 = settingsOpen and Theme.TextTitle or Theme.TextSub, Rotation = settingsOpen and 90 or 0})
	end

	local function selectTab(tab)
		if currentTab == tab and not settingsOpen then return end
		settingsOpen = false
		currentTab = tab
		styleTabPills()
		showPage(tab)
		if searchOpen then
			searchBox.Text = ""
			applySearchFilter("")
		end
	end

	local elementOrder = 0
	local function nextOrder()
		elementOrder = elementOrder + 1
		return elementOrder
	end

	local function runCallback(callback, ...)
		if type(callback) ~= "function" then return end
		if suppressCallbacks then return end
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("Rayfield Gen3 | Callback error: " .. tostring(err))
			RayfieldLibrary:Notify({Title = "Callback Error", Content=tostring(err), Duration = 4, Image = "triangle-alert"})
		end
	end

	local function cardBase(card)
		round(card, GenStyle.cardRadius)
		registerGlass(card)
		if GenStyle.cardGradient then
			create("UIGradient", {
				Rotation = 90,
				Color=ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 226, 226)),
				Parent = card,
			})
		end
		if GenStyle.cardStroke then
			local st = create("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.9,
				Thickness = 1,
				Parent = card,
			})
			paint(st, "Color", "Stroke")
		end
	end

	local function makeCard(page, name, icon, height)
		local card = create("Frame", {
			Size = UDim2.new(1, 0, 0, height or 50),
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		card:SetAttribute("SearchName", name or "")
		paint(card, "BackgroundColor3", "Card")
		cardBase(card)

		local textX = 17
		if icon then
			local ic = makeIcon(card, icon, 18, Theme.TextTitle, 0.04)
			if ic then
				ic.AnchorPoint = Vector2.new(0, 0.5)
				ic.Position = UDim2.new(0, 16,0.5, 0)
				textX = 44
			end
		end
		local label = create("TextLabel",{
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, textX, 0.5, 0),
			Size = UDim2.new(1,-textX - 16, 0, 18),
			Font = FONT_MEDIUM,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = name or "",
			Parent = card,
		})
		paint(label, "TextColor3", "TextBody")
		return card, label, textX
	end

	local function makeDescription(page, card,text)
		if not text or text == "" then return nil end
		local desc = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -30, 0, 0),
			Font = FONT_REGULAR,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = text,
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		desc:SetAttribute("SearchName", (card:GetAttribute("SearchName") or "") .. " " .. text)
		padAll(desc, 0, 0, 5, 16)
		paint(desc, "TextColor3", "TextMuted");
		return desc
	end

	local function hoverable(card, base, hover)
		card.MouseEnter:Connect(function()
			tween(card, TI_FAST, {BackgroundColor3=hover or Theme.CardHover})
		end)
		card.MouseLeave:Connect(function()
			tween(card, TI_FAST, {BackgroundColor3 = base or Theme.Card})
		end)
	end

	-- Lockable element: an overlay that dims the card and swallows input, with a
	-- lock glyph. Fades in and out. Returns setLocked(state).
	local function lockOverlay(card, startLocked)
		local shield, lk
		local locked = false
		local function setLocked(state)
			state = state and true or false
			if state == locked then return end
			locked = state
			if state then
				if not shield then
					shield = create("TextButton", {
						Name = "LockShield",
						BackgroundColor3 = Theme.Background,
						BackgroundTransparency = 1,
						AutoButtonColor = false,
						Text = "",
						Size = UDim2.fromScale(1, 1),
						ZIndex = 40,
						Parent = card,
					})
					round(shield, GenStyle.cardRadius)
					lk = makeIcon(shield, "lock", 14, Theme.TextSub)
					if lk then
						lk.AnchorPoint = Vector2.new(1, 0.5)
						lk.Position = UDim2.new(1, -14, 0.5, 0)
						lk.ZIndex = 41
						lk.ImageTransparency = 1
					end
				end
				shield.Visible = true
				tween(shield, TI_SMOOTH, { BackgroundTransparency = 0.45 })
				if lk then tween(lk, TI_SMOOTH, { ImageTransparency = 0 }) end
			elseif shield then
				tween(shield, TI_SMOOTH, { BackgroundTransparency = 1 })
				if lk then tween(lk, TI_SMOOTH, { ImageTransparency = 1 }) end
				task.delay(0.34, function() if not locked and shield then shield.Visible = false end end)
			end
		end
		if startLocked then setLocked(true) end
		return setLocked
	end

	local tipLabel = nil
	local tipOwner = nil
	local function ensureTip()
		if tipLabel and tipLabel.Parent then return tipLabel end
		tipLabel = create("TextLabel", {
			Name = "Tooltip",
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			TextColor3 = Color3.fromRGB(24, 24, 24),
			Font = FONT_MEDIUM,
			TextSize = 13,
			TextWrapped = true,
			Visible = false,
			ZIndex = 100000,
			Parent = ensureRoot(),
		})
		round(tipLabel, 6)
		padAll(tipLabel, 5, 9, 5, 9)
		create("UISizeConstraint", {MaxSize = Vector2.new(230, math.huge), Parent = tipLabel})
		return tipLabel
	end

	local function tipFor(card, text)
		if not text or text == "" then return end
		local hovering = false
		card.MouseEnter:Connect(function()
			hovering = true
			tipOwner = card
			task.delay(0.4, function()
				if not hovering or tipOwner ~= card or not card.Parent then return end
				local tip = ensureTip()
				tip.Text = text
				tip.Visible = true
				tip.TextTransparency = 1
				tip.BackgroundTransparency = 1
				task.wait()
				if not hovering or tipOwner ~= card then
					tip.Visible = false
					return
				end
				local m = UserInputService:GetMouseLocation()
				local cam = workspace.CurrentCamera
				local vw = cam and cam.ViewportSize.X or 1920
				local half = tip.AbsoluteSize.X / 2
				local cx = math.clamp(m.X, half + 4, vw - half - 4)
				local cy = m.Y - 10
				tip.Position = UDim2.fromOffset(cx, cy + 6)
				tween(tip, TI_SMOOTH, {TextTransparency = 0, BackgroundTransparency = 0, Position = UDim2.fromOffset(cx, cy)})
			end)
		end)
		card.MouseLeave:Connect(function()
			hovering = false
			if tipOwner == card then tipOwner = nil end
			if tipLabel then tipLabel.Visible = false end
		end)
	end


	local function buildTabAPI(page, compact)
		local Tab = {}
		Tab.Page=page

		local function descFor(card, text)
			if compact then return nil end
			return makeDescription(page, card, text)
		end

		function Tab:CreateSection(sectionName)
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1,0, 0, 30),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural", true)
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint=Vector2.new(0, 1),
				Position = UDim2.new(0,10, 1, -3),
				Size = UDim2.new(1, -20, 0, 16),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = sectionName or "",
				Parent = holder,
			})
			paint(label, "TextColor3","TextSub")
			local SectionValue = {}
			function SectionValue:Set(newName)
				label.Text = newName
			end
			return SectionValue
		end

		function Tab:CreateDivider()
			local holder = create("Frame",{
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 8),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural",true)
			create("Frame", {
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -12,0,1),
				BackgroundColor3 = Color3.fromRGB(255, 255,255),
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
				Parent = holder,
			})
			local DividerValue = {}
			function DividerValue:Set(visible)
				holder.Visible = visible
			end
			return DividerValue
		end

		-- Invisible vertical gap between elements
		function Tab:CreateSpacer(height)
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, math.clamp(tonumber(height) or 12, 2, 300)),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural", true)
			local SpacerValue = {}
			function SpacerValue:Set(newHeight)
				holder.Size = UDim2.new(1, 0, 0, math.clamp(tonumber(newHeight) or 12, 2, 300))
			end
			return SpacerValue
		end

		function Tab:CreateLabel(text, icon, color, _ignoreTheme)
			local card, label = makeCard(page, text, icon, 46)
			card.BackgroundTransparency = 0.5
			if color and typeof(color) == "Color3" then
				label.TextColor3 = color
			else
				label.TextColor3 = Theme.TextSub
			end
			local LabelValue = {}
			function LabelValue:Set(newText, _newIcon,newColor)
				label.Text = newText or label.Text
				if newColor and typeof(newColor) == "Color3" then
					label.TextColor3 = newColor
				end
				card:SetAttribute("SearchName", newText or "")
			end
			return LabelValue
		end

		function Tab:CreateParagraph(ParagraphSettings)
			ParagraphSettings = ParagraphSettings or {}
			local card = create("Frame",{
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0, 0,0),
				LayoutOrder = nextOrder(),
				Parent=page,
			})
			card:SetAttribute("SearchName", (ParagraphSettings.Title or "") .. " " .. (ParagraphSettings.Content or ""))
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			padAll(card, 14, 17, 14, 17)
			create("UIListLayout",{
				FillDirection=Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = card,
			})
			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = FONT_BOLD,
				TextSize = 16,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = ParagraphSettings.Title or "",
				LayoutOrder = 1,
				Parent = card,
			})
			paint(title, "TextColor3", "TextTitle")
			local content = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = FONT_REGULAR,
				TextSize=14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = ParagraphSettings.Content or "",
				LayoutOrder = 2,
				Parent = card,
			})
			paint(content,"TextColor3", "TextSub")
			local ParagraphValue = {}
			function ParagraphValue:Set(newSettings)
				newSettings = newSettings or {}
				title.Text = newSettings.Title or title.Text
				content.Text = newSettings.Content or content.Text
				card:SetAttribute("SearchName", title.Text .. " " .. content.Text)
			end
			return ParagraphValue
		end

		function Tab:CreateFAQ(FAQSettings)
			FAQSettings = FAQSettings or {}
			local FAQValue = {Items = {}}
			local closers = {}
			for _, item in ipairs(FAQSettings.Items or {}) do
				local question = item.Question or ""
				local answer = item.Answer or ""
				local card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 54),
					LayoutOrder = nextOrder(),
					ClipsDescendants = true,
					Parent = page,
				})
				card:SetAttribute("SearchName", question .. " " .. answer)
				paint(card, "BackgroundColor3", "Card")
				cardBase(card)
				hoverable(card)
				local qLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(17, 0),
					Size = UDim2.new(1, -60, 0, 54),
					Font = FONT_MEDIUM,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = question,
					Parent = card,
				})
				paint(qLabel, "TextColor3", "TextTitle")
				local plus = makeIcon(card, "plus", 16, Theme.TextSub, 0.15)
				plus.AnchorPoint = Vector2.new(1, 0.5)
				plus.Position = UDim2.new(1, -16, 0, 27)
				local aLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(17, 54),
					Size = UDim2.new(1, -34, 0, 0),
					Font = FONT_REGULAR,
					TextSize = 14,
					TextWrapped = true,
					TextTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Text = answer,
					Parent = card,
				})
				paint(aLabel, "TextColor3", "TextSub")
				local open = false
				local function setOpen(state)
					if open == state then return end
					open = state
					if open then
						local ah = measureWrapped(answer, 14, FONT_REGULAR, math.max(card.AbsoluteSize.X - 40, 50))
						aLabel.Size = UDim2.new(1, -34, 0, ah + 4)
						aLabel.Position = UDim2.fromOffset(17, 58)
						tween(card, TI_MORPH, {Size = UDim2.new(1, 0, 0, 54 + ah + 16)})
						tween(plus, TI_MORPH, {Rotation = 135, ImageColor3 = Theme.AccentSoft, ImageTransparency = 0})
						tween(aLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0.1, Position = UDim2.fromOffset(17, 50)})
					else
						tween(card, TI_MORPH, {Size = UDim2.new(1, 0, 0, 54)})
						tween(plus, TI_MORPH, {Rotation = 0, ImageColor3 = Theme.TextSub, ImageTransparency = 0.15})
						tween(aLabel, TI_FAST, {TextTransparency = 1})
					end
				end
				closers[#closers + 1] = function() setOpen(false) end
				local function openExclusive()
					for _, c in ipairs(closers) do c() end
					setOpen(true)
				end
				local clicker = create("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					Size = UDim2.fromScale(1, 1),
					Parent = card,
				})
				clicker.MouseButton1Click:Connect(function()
					if open then setOpen(false) else openExclusive() end
				end)
				FAQValue.Items[#FAQValue.Items + 1] = {
					Open = openExclusive,
					Close = function() setOpen(false) end,
				}
			end
			return FAQValue
		end

		function Tab:CreateStat(StatSettings)
			StatSettings = StatSettings or {}
			if compact then
				local card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 50),
					LayoutOrder = nextOrder(),
					Parent = page,
				})
				card:SetAttribute("SearchName", StatSettings.Name or "")
				card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				round(card, 14)
				create("UIGradient", {
					Rotation = 165,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0,Color3.fromRGB(88, 152,122)),
						ColorSequenceKeypoint.new(0.55,Color3.fromRGB(46,94, 75)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 52, 42)),
					}),
					Parent = card,
				})
				local textX=16
				if StatSettings.Icon then
					local ic = makeIcon(card, StatSettings.Icon, 18, Color3.fromRGB(240, 252, 246))
					if ic then
						ic.AnchorPoint = Vector2.new(0, 0.5)
						ic.Position=UDim2.new(0, 15, 0.5,0)
						textX = 42
					end
				end
				local nameLabel = create("TextLabel",{
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0,0.5),
					Position=UDim2.new(0, textX, 0.5, 0),
					Size = UDim2.new(0.55, -textX, 0, 18),
					Font = FONT_BOLD,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate=Enum.TextTruncate.AtEnd,
					TextColor3 = Color3.fromRGB(244, 253,248),
					Text = StatSettings.Name or "",
					Parent = card,
				})
				local rightLabel=create("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -16, 0.5, 0),
					Size = UDim2.new(0.4, -16, 0, 18),
					Font = FONT_BOLD,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Text = tostring(StatSettings.Value or StatSettings.Delta or ""),
					Parent = card,
				})
				local StatValue = {}
				local lastValue = StatSettings.Value
				local lastDelta = StatSettings.Delta
				local rightSet = odometerValue(rightLabel,lastValue or lastDelta)
				function StatValue:Set(newSettings)
					newSettings = newSettings or {}
					if newSettings.Name then nameLabel.Text = newSettings.Name end
					if newSettings.Value ~= nil then lastValue = newSettings.Value end
					if newSettings.Delta ~= nil then lastDelta = newSettings.Delta end
					rightSet(lastValue or lastDelta or "")
				end
				return StatValue
			end

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 96),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", StatSettings.Name or "")
			card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			round(card, 14)
			create("UIGradient",{
				Rotation = 165,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,Color3.fromRGB(88, 152,122)),
					ColorSequenceKeypoint.new(0.5,Color3.fromRGB(46, 94, 75)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 52, 42)),
				}),
				Parent = card,
			})

			local topX = 17
			if StatSettings.Icon then
				local ic = makeIcon(card, StatSettings.Icon, 21,Color3.fromRGB(238, 252, 245))
				if ic then
					ic.Position = UDim2.fromOffset(16, 14)
					topX = 46
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(topX, 15),
				Size = UDim2.new(1, -topX - 16, 0,20),
				Font = FONT_BOLD,
				TextSize=17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3=Color3.fromRGB(242, 252, 247),
				Text = StatSettings.Name or "",
				Parent = card,
			})
			local valueLabel = create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0,17,1, -12),
				Size = UDim2.new(0.6, 0, 0, 28),
				Font = FONT_BOLD,
				TextSize = 25,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = tostring(StatSettings.Value or ""),
				Parent = card,
			})
			local deltaLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -17, 1, -15),
				Size = UDim2.new(0.35, 0, 0, 18),
				Font = FONT_BOLD,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Color3.fromRGB(202,242, 221),
				Text = tostring(StatSettings.Delta or ""),
				Parent = card,
			})
			local setValue = odometerValue(valueLabel,StatSettings.Value)
			local StatValue = {}
			function StatValue:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then nameLabel.Text = newSettings.Name end
				if newSettings.Value ~= nil then setValue(newSettings.Value) end
				if newSettings.Delta ~= nil then deltaLabel.Text = tostring(newSettings.Delta) end
			end
			return StatValue
		end

		local chartPalette = {rgb(150, 222, 186), rgb(70, 168, 120), rgb(44, 108, 80), rgb(26, 62, 47), rgb(214, 240, 226)}

		local function chartShell(settings, h)
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, h),
				LayoutOrder = nextOrder(),
				ClipsDescendants = true,
				Parent = page,
			})
			card:SetAttribute("SearchName", settings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			local textX = 17
			if settings.Icon then
				local ic = makeIcon(card, settings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16, 13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, 13),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font = FONT_BOLD,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = settings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3", "TextTitle")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -17, 0, 11),
				Size = UDim2.new(0.4, 0, 0, 22),
				Font = FONT_BOLD,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextTitle")
			return card, nameLabel, valueLabel
		end

		local function replayOnVisible(card, entrance)
			local function chainVisible()
				local a = card
				while a and not a:IsA("ScreenGui") do
					if a:IsA("GuiObject") and not a.Visible then return false end
					a = a.Parent
				end
				return true
			end
			task.defer(function()
				local node = card.Parent
				while node and not node:IsA("ScreenGui") do
					if node:IsA("GuiObject") then
						local nn = node
						nn:GetPropertyChangedSignal("Visible"):Connect(function()
							if nn.Visible and chainVisible() then task.defer(entrance) end
						end)
					end
					node = node.Parent
				end
				if chainVisible() then entrance() end
			end)
		end

		local function lineSeg(parent, x1, y1, x2, y2, thick, z)
			local s = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				ZIndex = z or 2,
				Parent = parent,
			})
			roundFull(s)
			local dx, dy = x2 - x1, y2 - y1
			s.Position = UDim2.fromOffset(x1 + dx / 2, y1 + dy / 2)
			s.Size = UDim2.fromOffset(math.ceil(math.sqrt(dx * dx + dy * dy)) + 1, thick)
			s.Rotation = math.deg(math.atan2(dy, dx))
			return s
		end

		function Tab:CreateChart(ChartSettings)
			ChartSettings = ChartSettings or {}
			local points = {}
			for _, v in ipairs(ChartSettings.Points or {}) do
				local n = tonumber(v)
				if n then points[#points + 1] = n end
			end
			if #points == 0 then points = {0, 0} end
			if #points == 1 then points = {points[1], points[1]} end
			local prefix = ChartSettings.Prefix or ""
			local suffix = ChartSettings.Suffix or ""
			local decimals = ChartSettings.Decimals or 0
			local filled = ChartSettings.Filled ~= false
			local smooth = ChartSettings.Smooth == true
			local showDots = ChartSettings.Dots == true or (ChartSettings.Dots == nil and not smooth)
			local maxPoints = ChartSettings.MaxPoints or math.max(#points, 12)

			local cardH = compact and 118 or 152
			local plotTop = compact and 38 or 44
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, cardH),
				LayoutOrder = nextOrder(),
				ClipsDescendants = true,
				Parent = page,
			})
			card:SetAttribute("SearchName", ChartSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)

			local textX = 17
			if ChartSettings.Icon then
				local ic = makeIcon(card, ChartSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16, compact and 11 or 13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, compact and 11 or 13),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font = FONT_BOLD,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ChartSettings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3", "TextTitle")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -17, 0, compact and 9 or 11),
				Size = UDim2.new(0.4, 0, 0, 22),
				Font = FONT_BOLD,
				TextSize = compact and 17 or 20,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextTitle")

			local plot = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, plotTop),
				Size = UDim2.new(1, -34, 1, -plotTop - 14),
				Parent = card,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			local hairline = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.82,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.new(0, 1, 1, 0),
				Visible = false,
				ZIndex = 2,
				Parent = plot,
			})

			local fillHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = plot,
			})
			local segHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
				Parent = plot,
			})
			local segCanvas = create("Frame", {
				BackgroundTransparency = 1,
				Parent = segHolder,
			})
			local dotHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 4,
				Parent = plot,
			})

			local dots, segs, cols, colTargets = {}, {}, {}, {}
			local xsCache, ysCache = {}, {}
			local hoverIdx = nil

			local function fmt(n)
				local str = decimals > 0 and string.format("%." .. decimals .. "f", n) or tostring(math.floor(n + 0.5))
				return prefix .. commafy(str) .. suffix
			end
			local setValue = odometerValue(valueLabel, fmt(points[#points]))

			local function redraw(animate)
				local w, h = plot.AbsoluteSize.X, plot.AbsoluteSize.Y
				if w < 24 or h < 24 then return end
				segCanvas.Size = UDim2.fromOffset(w, h)
				local n = #points
				local lo, hi = points[1], points[1]
				for _, v in ipairs(points) do
					if v < lo then lo = v end
					if v > hi then hi = v end
				end
				local range = hi - lo
				if range == 0 then range = math.max(math.abs(hi), 1) end
				local edgePad = (smooth and 3 or 4) / 2 + 1.5
				for i = 1, n do
					xsCache[i] = edgePad + (i - 1) / (n - 1) * (w - edgePad * 2)
					ysCache[i] = math.floor(10 + (1 - (points[i] - lo) / range) * (h - 22) + 0.5)
				end
				for i = #xsCache, n + 1, -1 do
					xsCache[i] = nil
					ysCache[i] = nil
				end

				local rxs, rys = xsCache, ysCache
				if smooth and n >= 3 then
					rxs, rys = {}, {}
					for i = 1, n - 1 do
						local x0 = xsCache[i > 1 and i - 1 or 1]
						local y0 = ysCache[i > 1 and i - 1 or 1]
						local x1, y1 = xsCache[i], ysCache[i]
						local x2, y2 = xsCache[i + 1], ysCache[i + 1]
						local x3 = xsCache[i + 2] or x2
						local y3 = ysCache[i + 2] or y2
						local sub = math.clamp(math.ceil((x2 - x1) / 3), 8, 36)
						for tstep = 0, sub - 1 do
							local a = tstep / sub
							rxs[#rxs + 1] = catmull(x0, x1, x2, x3, a)
							rys[#rys + 1] = math.clamp(catmull(y0, y1, y2, y3, a), 2, h - 2)
						end
					end
					rxs[#rxs + 1] = xsCache[n]
					rys[#rys + 1] = ysCache[n]
				end
				local rn = #rxs

				for i = #dots, n + 1, -1 do
					dots[i]:Destroy()
					dots[i] = nil
				end
				for i = #segs, rn, -1 do
					segs[i]:Destroy()
					segs[i] = nil
				end

				for i = 1, n do
					local d = dots[i]
					local fresh = not d
					if fresh then
						d = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromOffset(10, 10),
							ZIndex = 4,
							Parent = dotHolder,
						})
						paint(d, "BackgroundColor3", "Knob")
						roundFull(d)
						d.Visible = showDots
						dots[i] = d
					end
					local target = UDim2.fromOffset(xsCache[i], ysCache[i])
					if fresh then
						d.Position = target
						if animate then
							d.Size = UDim2.fromOffset(0, 0)
							task.delay(0.12, function()
								tween(d, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(10, 10)})
							end)
						end
					elseif animate then
						tween(d, TI_MORPH, {Position = target})
					else
						d.Position = target
					end
				end

				for i = 1, rn - 1 do
					local s = segs[i]
					local fresh = not s
					if fresh then
						s = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BorderSizePixel = 0,
							ZIndex = 3,
							Parent = segCanvas,
						})
						paint(s, "BackgroundColor3", "AccentSoft")
						roundFull(s)
						segs[i] = s
					end
					local dx = rxs[i + 1] - rxs[i]
					local dy = rys[i + 1] - rys[i]
					local len = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
					local ov = smooth and 3 or 4
					local cxx, cyy = rxs[i] + dx / 2, rys[i] + dy / 2
					if rn == 2 then
						ov = 0
					elseif i == 1 or i == rn - 1 then
						local push = (i == 1 and ov or -ov) / 4
						cxx = cxx + dx / len * push
						cyy = cyy + dy / len * push
						ov = ov / 2
					end
					local props = {
						Position = UDim2.fromScale(cxx / w, cyy / h),
						Size = UDim2.fromOffset(math.ceil(len + ov), 3),
						Rotation = math.deg(math.atan2(dy, dx)),
					}
					if animate and not fresh then
						tween(s, TI_MORPH, props)
					else
						s.Position = props.Position
						s.Size = props.Size
						s.Rotation = props.Rotation
					end
				end

				if filled then
					local colW = 3
					local fillX = rxs[1]
					local count = math.max(math.ceil((rxs[rn] - fillX) / colW), 1)
					for i = #cols, count + 1, -1 do
						cols[i]:Destroy()
						cols[i] = nil
					end
					local seg = 1
					for c = 1, count do
						local f = cols[c]
						local fresh = not f
						if fresh then
							f = create("Frame", {
								AnchorPoint = Vector2.new(0, 1),
								BorderSizePixel = 0,
								BackgroundTransparency = 0.12,
								Parent = fillHolder,
							})
							paint(f, "BackgroundColor3", "AccentDark")
							create("UIGradient", {
								Rotation = 90,
								Transparency = NumberSequence.new(0, 0.78),
								Parent = f,
							})
							cols[c] = f
						end
						local left = fillX + (c - 1) * colW
						local cw = math.min(colW, rxs[rn] - left)
						local cx = left + cw / 2
						while seg < rn - 1 and rxs[seg + 1] < cx do seg = seg + 1 end
						local x1, x2 = rxs[seg], rxs[seg + 1]
						local a = math.clamp((cx - x1) / math.max(x2 - x1, 1), 0, 1)
						local y = rys[seg] + (rys[seg + 1] - rys[seg]) * a
						local props = {
							Position = UDim2.fromOffset(left, h - 1),
							Size = UDim2.fromOffset(math.max(cw, 1), math.max(h - 1 - y, 0)),
						}
						colTargets[c] = props.Size
						if animate and not fresh then
							tween(f, TI_MORPH, props)
						else
							f.Position = props.Position
							f.Size = props.Size
						end
					end
				end
			end

			local function applyHover(i)
				if hoverIdx == i then return end
				if hoverIdx and dots[hoverIdx] then
					dots[hoverIdx].Size = UDim2.fromOffset(10, 10)
					dots[hoverIdx].BackgroundColor3 = Theme.Knob
					dots[hoverIdx].Visible = showDots
				end
				hoverIdx = i
				local d = i and dots[i]
				if d then
					d.Size = UDim2.fromOffset(14, 14)
					d.BackgroundColor3 = Theme.AccentSoft
					d.Visible = true
					hairline.Position = UDim2.fromOffset(xsCache[i], 0)
					hairline.Visible = true
					setValue(fmt(points[i]))
				else
					hairline.Visible = false
					setValue(fmt(points[#points]))
				end
			end

			card.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				if #xsCache < 2 then return end
				local rx = input.Position.X - plot.AbsolutePosition.X
				local best, bestDist = nil, math.huge
				for i = 1, #points do
					local dist = math.abs((xsCache[i] or 0) - rx)
					if dist < bestDist then
						best, bestDist = i, dist
					end
				end
				applyHover(best)
			end)
			card.MouseLeave:Connect(function()
				applyHover(nil)
			end)

			local animToken = 0
			local function entrance()
				if #dots == 0 then return end
				animToken = animToken + 1
				local my = animToken
				local w = plot.AbsoluteSize.X
				if w < 24 then return end
				local D = 0.75
				segHolder.ClipsDescendants = true
				segHolder.Size = UDim2.new(0, 0, 1, 0)
				tween(segHolder, TweenInfo.new(D, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
				task.delay(D + 0.1, function()
					if my == animToken then
						segHolder.ClipsDescendants = false
						segHolder.Size = UDim2.fromScale(1, 1)
					end
				end)
				for i, d in ipairs(dots) do
					if not showDots then break end
					d.Size = UDim2.fromOffset(0, 0)
					local at = math.clamp((xsCache[i] or 0) / w, 0, 1)
					task.delay(at * D * 0.62, function()
						if my ~= animToken then return end
						tween(d, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(10, 10)})
					end)
				end
				for c, f in ipairs(cols) do
					local target = colTargets[c] or f.Size
					f.Size = UDim2.fromOffset(target.X.Offset, 0)
					local at = math.clamp(((c - 0.5) * 3) / w, 0, 1)
					task.delay(at * D * 0.62 + 0.05, function()
						if my ~= animToken then return end
						tween(f, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = target})
					end)
				end
			end

			local function chainVisible()
				local a = card
				while a and not a:IsA("ScreenGui") do
					if a:IsA("GuiObject") and not a.Visible then return false end
					a = a.Parent
				end
				return true
			end

			plot:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				redraw(false)
			end)
			task.defer(function()
				redraw(false)
				local node = card.Parent
				while node and not node:IsA("ScreenGui") do
					if node:IsA("GuiObject") then
						local n = node
						n:GetPropertyChangedSignal("Visible"):Connect(function()
							if n.Visible and chainVisible() then
								task.defer(entrance)
							end
						end)
					end
					node = node.Parent
				end
				if chainVisible() then entrance() end
			end)

			local Chart = {}
			function Chart:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then
					nameLabel.Text = newSettings.Name
					card:SetAttribute("SearchName", newSettings.Name)
				end
				if newSettings.Points then
					local fresh = {}
					for _, v in ipairs(newSettings.Points) do
						local nv = tonumber(v)
						if nv then fresh[#fresh + 1] = nv end
					end
					if #fresh == 0 then fresh = {0, 0} end
					if #fresh == 1 then fresh = {fresh[1], fresh[1]} end
					while #fresh > maxPoints do table.remove(fresh, 1) end
					if hoverIdx then applyHover(nil) end
					points = fresh
					setValue(fmt(points[#points]))
					redraw(true)
				end
			end
			local function ripple(i)
				local x, y = xsCache[i], ysCache[i]
				if not x or not y then return end
				local r = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(12, 12),
					BackgroundColor3 = Theme.AccentSoft,
					BackgroundTransparency = 0.55,
					ZIndex = 3,
					Parent = dotHolder,
				})
				roundFull(r)
				tween(r, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1})
				task.delay(0.65, function() r:Destroy() end)
			end

			function Chart:Push(v)
				local nv = tonumber(v)
				if not nv then return end
				if hoverIdx then applyHover(nil) end
				points[#points + 1] = nv
				while #points > maxPoints do table.remove(points, 1) end
				setValue(fmt(points[#points]))
				redraw(true)
				task.delay(0.16, function() ripple(#points) end)
			end
			function Chart:Replay()
				if hoverIdx then applyHover(nil) end
				entrance()
			end
			return Chart
		end

		function Tab:CreateBarChart(ChartSettings)
			ChartSettings = ChartSettings or {}
			local function parsePoints(list)
				local v, l = {}, {}
				for _, item in ipairs(list or {}) do
					if type(item) == "table" then
						local nv = tonumber(item.Value)
						if nv then
							v[#v + 1] = nv
							l[#v] = item.Label
						end
					else
						local nv = tonumber(item)
						if nv then v[#v + 1] = nv end
					end
				end
				if #v == 0 then v = {0} end
				return v, l
			end
			local vals, labs = parsePoints(ChartSettings.Points)
			local prefix = ChartSettings.Prefix or ""
			local suffix = ChartSettings.Suffix or ""
			local decimals = ChartSettings.Decimals or 0
			local maxPoints = ChartSettings.MaxPoints or math.max(#vals, 12)
			local hasLabels = next(labs) ~= nil

			local card, nameLabel, valueLabel = chartShell(ChartSettings, hasLabels and 168 or 152)
			local plot = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 44),
				Size = UDim2.new(1, -34, 1, hasLabels and -74 or -58),
				Parent = card,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			local barHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Parent = plot,
			})

			local bars, barTargets, labelInsts = {}, {}, {}
			local hoverIdx = nil
			local function fmt(n)
				local str = decimals > 0 and string.format("%." .. decimals .. "f", n) or tostring(math.floor(n + 0.5))
				return prefix .. commafy(str) .. suffix
			end
			local setValue = odometerValue(valueLabel, fmt(vals[#vals]))

			local function redraw(animate)
				local w, h = plot.AbsoluteSize.X, plot.AbsoluteSize.Y
				if w < 24 or h < 24 then return end
				local n = #vals
				local hi = 0
				for _, v in ipairs(vals) do hi = math.max(hi, v) end
				if hi <= 0 then hi = 1 end
				for i = #bars, n + 1, -1 do
					bars[i]:Destroy()
					bars[i] = nil
					barTargets[i] = nil
				end
				for i = #labelInsts, n + 1, -1 do
					labelInsts[i]:Destroy()
					labelInsts[i] = nil
				end
				local slot = w / n
				local barW = math.max(6, math.min(46, math.floor(slot * 0.72)))
				for i = 1, n do
					local b = bars[i]
					local fresh = not b
					if fresh then
						b = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 1),
							BorderSizePixel = 0,
							ZIndex = 2,
							Parent = barHolder,
						})
						paint(b, "BackgroundColor3", "Accent")
						round(b, 6)
						create("UIGradient", {
							Rotation = 90,
							Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(178, 178, 178)),
							Parent = b,
						})
						bars[i] = b
					end
					local bh = math.max(3, math.floor(math.max(vals[i], 0) / hi * (h - 12)))
					local props = {
						Position = UDim2.fromOffset(math.floor(slot * (i - 0.5) + 0.5), h - 1),
						Size = UDim2.fromOffset(barW, bh),
					}
					barTargets[i] = props.Size
					if fresh then
						b.Position = props.Position
						if animate then
							b.Size = UDim2.fromOffset(barW, 0)
							tween(b, TI_MORPH, {Size = props.Size})
						else
							b.Size = props.Size
						end
					elseif animate then
						tween(b, TI_MORPH, props)
					else
						b.Position = props.Position
						b.Size = props.Size
					end
					if hasLabels then
						local lab = labelInsts[i]
						if not lab then
							lab = create("TextLabel", {
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(0.5, 0),
								Size = UDim2.fromOffset(math.floor(slot), 12),
								Font = FONT_MEDIUM,
								TextSize = 11,
								TextTruncate = Enum.TextTruncate.AtEnd,
								Parent = plot,
							})
							paint(lab, "TextColor3", "TextMuted")
							labelInsts[i] = lab
						end
						lab.Position = UDim2.new(0, math.floor(slot * (i - 0.5) + 0.5), 1, 3)
						lab.Text = labs[i] or ""
					end
				end
			end

			local function applyHover(i)
				if hoverIdx == i then return end
				if hoverIdx and bars[hoverIdx] then
					bars[hoverIdx].BackgroundColor3 = Theme.Accent
				end
				hoverIdx = i
				if i and bars[i] then
					bars[i].BackgroundColor3 = Theme.AccentSoft
					setValue(fmt(vals[i]))
				else
					setValue(fmt(vals[#vals]))
				end
			end

			card.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				local w = plot.AbsoluteSize.X
				if w < 24 or #vals == 0 then return end
				local rx = input.Position.X - plot.AbsolutePosition.X
				local i = math.clamp(math.floor(rx / (w / #vals)) + 1, 1, #vals)
				applyHover(i)
			end)
			card.MouseLeave:Connect(function()
				applyHover(nil)
			end)

			local animToken = 0
			local function entrance()
				if #bars == 0 then return end
				animToken = animToken + 1
				local my = animToken
				for i, b in ipairs(bars) do
					local target = barTargets[i] or b.Size
					b.Size = UDim2.fromOffset(target.X.Offset, 0)
					task.delay(0.04 + (i - 1) * 0.05, function()
						if my ~= animToken then return end
						tween(b, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = target})
					end)
				end
			end

			plot:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				redraw(false)
			end)
			task.defer(function() redraw(false) end)
			replayOnVisible(card, entrance)

			local Chart = {}
			function Chart:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then
					nameLabel.Text = newSettings.Name
					card:SetAttribute("SearchName", newSettings.Name)
				end
				if newSettings.Points then
					if hoverIdx then applyHover(nil) end
					vals, labs = parsePoints(newSettings.Points)
					while #vals > maxPoints do
						table.remove(vals, 1)
						table.remove(labs, 1)
					end
					setValue(fmt(vals[#vals]))
					redraw(true)
				end
			end
			function Chart:Push(v, label)
				local nv = tonumber(v)
				if not nv then return end
				if hoverIdx then applyHover(nil) end
				vals[#vals + 1] = nv
				labs[#vals] = label
				while #vals > maxPoints do
					table.remove(vals, 1)
					table.remove(labs, 1)
				end
				setValue(fmt(vals[#vals]))
				redraw(true)
			end
			function Chart:Replay()
				if hoverIdx then applyHover(nil) end
				entrance()
			end
			return Chart
		end

		function Tab:CreateStackedChart(ChartSettings)
			ChartSettings = ChartSettings or {}
			local series = {}
			for _, s in ipairs(ChartSettings.Series or {}) do
				series[#series + 1] = tostring(s)
			end
			local colors = {}
			for i = 1, math.max(#series, 1) do
				colors[i] = (ChartSettings.Colors and ChartSettings.Colors[i]) or chartPalette[(i - 1) % #chartPalette + 1]
			end
			local function parseRows(list)
				local out = {}
				for _, r in ipairs(list or {}) do
					local vals = {}
					for _, v in ipairs(r.Values or {}) do
						vals[#vals + 1] = math.max(tonumber(v) or 0, 0)
					end
					out[#out + 1] = {name = r.Name or "", values = vals}
				end
				if #out == 0 then out = {{name = "", values = {1}}} end
				return out
			end
			local rowsData = parseRows(ChartSettings.Rows)
			local prefix = ChartSettings.Prefix or ""
			local suffix = ChartSettings.Suffix or ""

			local cardH = 78 + #rowsData * 34
			local card, nameLabel, valueLabel = chartShell(ChartSettings, cardH)
			local legend = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 40),
				Size = UDim2.new(1, -34, 0, 18),
				Parent = card,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 14),
				Parent = legend,
			})
			for i, s in ipairs(series) do
				local item = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					LayoutOrder = i,
					Parent = legend,
				})
				local chip = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(10, 10),
					BackgroundColor3 = colors[i],
					BorderSizePixel = 0,
					Parent = item,
				})
				roundFull(chip)
				local nm = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 16, 0.5, 0),
					Size = UDim2.new(0, 0, 0, 14),
					Font = FONT_MEDIUM,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = s,
					Parent = item,
				})
				paint(nm, "TextColor3", "TextSub")
			end
			local rowsHolder = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 66),
				Size = UDim2.new(1, -34, 1, -80),
				Parent = card,
			})

			local rowInsts = {}
			local segMap = {}
			local hoverKey = nil
			local function fmt(n)
				return prefix .. commafy(tostring(math.floor(n + 0.5))) .. suffix
			end

			local function rebuildRows()
				for _, inst in ipairs(rowInsts) do inst:Destroy() end
				rowInsts = {}
				segMap = {}
				for i, r in ipairs(rowsData) do
					local rf = create("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(0, (i - 1) * 34),
						Size = UDim2.new(1, 0, 0, 28),
						Parent = rowsHolder,
					})
					local nm = create("TextLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.fromOffset(76, 14),
						Font = FONT_MEDIUM,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = r.name,
						Parent = rf,
					})
					paint(nm, "TextColor3", "TextBody")
					local track = create("Frame", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 84, 0.5, 0),
						Size = UDim2.new(1, -84, 0, 22),
						Parent = rf,
					})
					local barc = create("Frame", {
						BackgroundTransparency = 1,
						ClipsDescendants = true,
						Size = UDim2.new(0, 0, 1, 0),
						Parent = track,
					})
					round(barc, 6)
					rowInsts[i] = rf
					segMap[i] = {track = track, container = barc, segs = {}}
				end
			end

			local function redraw(animate)
				local hi = 0
				for _, r in ipairs(rowsData) do
					local t = 0
					for _, v in ipairs(r.values) do t = t + v end
					r.total = t
					hi = math.max(hi, t)
				end
				if hi <= 0 then hi = 1 end
				for i, r in ipairs(rowsData) do
					local m = segMap[i]
					if m then
						local trackW = m.track.AbsoluteSize.X
						if trackW < 10 then trackW = 300 end
						local contW = math.floor(trackW * r.total / hi + 0.5)
						local props = {Size = UDim2.new(0, contW, 1, 0)}
						if animate then
							tween(m.container, TI_MORPH, props)
						else
							m.container.Size = props.Size
						end
						for _, sg in ipairs(m.segs) do sg:Destroy() end
						m.segs = {}
						local x = 0
						for k, v in ipairs(r.values) do
							local segW = math.floor(v / math.max(r.total, 0.0001) * contW + 0.5)
							if k == #r.values then segW = contW - x end
							local sg = create("Frame", {
								Position = UDim2.fromOffset(x, 0),
								Size = UDim2.new(0, segW, 1, 0),
								BackgroundColor3 = colors[k] or chartPalette[1],
								BorderSizePixel = 0,
								Parent = m.container,
							})
							m.segs[k] = sg
							x = x + segW
						end
					end
				end
			end

			local function applyHover(key)
				if hoverKey and (not key or key[1] ~= hoverKey[1] or key[2] ~= hoverKey[2]) then
					local m = segMap[hoverKey[1]]
					local sg = m and m.segs[hoverKey[2]]
					if sg then sg.BackgroundColor3 = colors[hoverKey[2]] or chartPalette[1] end
					hoverKey = nil
					valueLabel.Text = ""
				end
				if key then
					local m = segMap[key[1]]
					local sg = m and m.segs[key[2]]
					local v = rowsData[key[1]] and rowsData[key[1]].values[key[2]]
					if sg and v then
						hoverKey = key
						sg.BackgroundColor3 = (colors[key[2]] or chartPalette[1]):Lerp(Color3.fromRGB(255, 255, 255), 0.22)
						valueLabel.Text = fmt(v)
					end
				end
			end

			card.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				local ry = input.Position.Y - rowsHolder.AbsolutePosition.Y
				local i = math.floor(ry / 34) + 1
				local m = segMap[i]
				if not m then
					applyHover(nil)
					return
				end
				local rx = input.Position.X - m.container.AbsolutePosition.X
				if rx < 0 or rx > m.container.AbsoluteSize.X then
					applyHover(nil)
					return
				end
				local x = 0
				for k, sg in ipairs(m.segs) do
					x = x + sg.AbsoluteSize.X
					if rx <= x then
						applyHover({i, k})
						return
					end
				end
				applyHover(nil)
			end)
			card.MouseLeave:Connect(function()
				applyHover(nil)
			end)

			local animToken = 0
			local function entrance()
				animToken = animToken + 1
				local my = animToken
				for i, m in ipairs(segMap) do
					local target = m.container.Size
					m.container.Size = UDim2.new(0, 0, 1, 0)
					task.delay(0.05 + (i - 1) * 0.09, function()
						if my ~= animToken then return end
						tween(m.container, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = target})
					end)
				end
			end

			rowsHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				redraw(false)
			end)
			rebuildRows()
			task.defer(function() redraw(false) end)
			replayOnVisible(card, entrance)

			local Chart = {}
			function Chart:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then
					nameLabel.Text = newSettings.Name
					card:SetAttribute("SearchName", newSettings.Name)
				end
				if newSettings.Rows then
					applyHover(nil)
					rowsData = parseRows(newSettings.Rows)
					rebuildRows()
					redraw(true)
				end
			end
			function Chart:Replay()
				applyHover(nil)
				entrance()
			end
			return Chart
		end

		function Tab:CreateButton(ButtonSettings)
			ButtonSettings = ButtonSettings or {}
			local card, label
			if compact then

				card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 50),
					LayoutOrder = nextOrder(),
					Parent = page,
				})
				card:SetAttribute("SearchName", ButtonSettings.Name or "")
				paint(card, "BackgroundColor3", "Card")
				cardBase(card)
				local center = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1,0),
					Parent = card,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0,9),
					Parent = center,
				})
				if ButtonSettings.Icon then
					local ic = makeIcon(center, ButtonSettings.Icon, 18, Theme.TextTitle, 0.04)
					if ic then ic.LayoutOrder = 1 end
				end
				label = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize=Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					Font = FONT_MEDIUM,
					TextSize = 16,
					Text = ButtonSettings.Name or "",
					LayoutOrder = 2,
					Parent = center,
				})
				paint(label, "TextColor3", "TextBody")
			else
				card, label = makeCard(page,ButtonSettings.Name,ButtonSettings.Icon, 50)
				descFor(card, ButtonSettings.Description)
				tipFor(card, ButtonSettings.Tooltip)
			end
			hoverable(card)
			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				tween(card, TweenInfo.new(0.07,Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.CardSelected})
				task.delay(0.09,function()
					tween(card, TI_MED, {BackgroundColor3 = Theme.Card})
				end)
				runCallback(ButtonSettings.Callback)
			end)
			local setLocked = lockOverlay(card, ButtonSettings.Locked)
			local ButtonValue = {}
			function ButtonValue:Set(newName)
				label.Text = newName
				card:SetAttribute("SearchName", newName or "")
			end
			function ButtonValue:SetLocked(state) setLocked(state and true or false) end
			return ButtonValue
		end

		function Tab:CreateToggle(ToggleSettings)
			ToggleSettings = ToggleSettings or {}
			local card, tLabel = makeCard(page,ToggleSettings.Name, ToggleSettings.Icon, 50)
			descFor(card, ToggleSettings.Description)
			tipFor(card, ToggleSettings.Tooltip)
			hoverable(card)

			local track = create("Frame", {
				AnchorPoint=Vector2.new(1, 0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.fromOffset(GenStyle.toggleTrackW, GenStyle.toggleTrackH),
			})
			paint(track, "BackgroundColor3", "ToggleTrack")
			roundFull(track)
			local trackStroke = create("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.84,
				Parent = track,
			})
			track.Parent = card

			local knobOnX = -(GenStyle.toggleKnobW + 3)
			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(GenStyle.toggleKnobW, GenStyle.toggleKnobH),
				BackgroundColor3 = Theme.KnobOff,
			})
			roundFull(knob)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(255, 255,255), Color3.fromRGB(196, 196, 196)),
				Parent = knob,
			})
			knob.Parent = track

			local Toggle = {
				Type = "Toggle",
				CurrentValue = ToggleSettings.CurrentValue == true,
				Card = card,
			}

			local function render(animate)
				local on = Toggle.CurrentValue
				local info = animate and TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out) or TweenInfo.new(0)
				tween(knob, info, {
					Position = on and UDim2.new(1, knobOnX, 0.5, 0) or UDim2.new(0, 3,0.5, 0),
					BackgroundColor3 = on and Theme.Accent or Theme.KnobOff,
				})
			end
			render(false)

			local clicker = create("TextButton",{
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1,1),
				Parent = card,
			})

			-- Locking a toggle hides the switch and reveals a lock glyph in its
			-- place, all animated. Clicks are ignored while locked.
			local lockIcon = makeIcon(card, "lock", 16, Theme.TextSub)
			if lockIcon then
				lockIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				lockIcon.Position = UDim2.new(1, -15 - math.floor(GenStyle.toggleTrackW / 2), 0.5, 0)
				lockIcon.ImageTransparency = 1
			end
			local locked = false
			local function setLocked(state)
				state = state and true or false
				if state == locked then return end
				locked = state
				tween(track, TI_SMOOTH, { BackgroundTransparency = state and 1 or 0 })
				tween(trackStroke, TI_SMOOTH, { Transparency = state and 1 or 0.84 })
				tween(knob, TI_SMOOTH, { BackgroundTransparency = state and 1 or 0 })
				if lockIcon then tween(lockIcon, TI_SMOOTH, { ImageTransparency = state and 0 or 1 }) end
				if tLabel then tween(tLabel, TI_SMOOTH, { TextTransparency = state and 0.45 or 0 }) end
			end

			clicker.MouseButton1Click:Connect(function()
				if locked then return end
				Toggle.CurrentValue = not Toggle.CurrentValue
				render(true)
				runCallback(ToggleSettings.Callback, Toggle.CurrentValue)
				saveConfiguration()
			end)

			function Toggle:Set(value)
				Toggle.CurrentValue = value == true
				render(true)
				runCallback(ToggleSettings.Callback, Toggle.CurrentValue)
				saveConfiguration()
			end

			function Toggle:SetLocked(state) setLocked(state) end
			if ToggleSettings.Locked then setLocked(true) end

			if ToggleSettings.Flag then
				Toggle.Flag = ToggleSettings.Flag
				RayfieldLibrary.Flags[ToggleSettings.Flag] = Toggle
			end
			return Toggle
		end

		function Tab:CreateCheckbox(CheckboxSettings)
			CheckboxSettings = CheckboxSettings or {}
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", CheckboxSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			descFor(card, CheckboxSettings.Description)
			tipFor(card, CheckboxSettings.Tooltip)
			hoverable(card)

			local box = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 15, 0.5, 0),
				Size = UDim2.fromOffset(26, 26),
				BackgroundColor3 = Theme.ToggleTrack,
			})
			round(box, 8)
			local boxStroke = create("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.84,
				Parent = box,
			})
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(255, 255,255), Color3.fromRGB(196, 196, 196)),
				Parent = box,
			})
			box.Parent = card

			local check = makeIcon(box, "check", 18, Color3.fromRGB(26, 26, 26), 1)
			check.AnchorPoint = Vector2.new(0.5, 0.5)
			check.Position = UDim2.fromScale(0.5, 0.5)
			check.Size = UDim2.fromOffset(10, 10)

			local label = create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 53, 0.5, 0),
				Size = UDim2.new(1, -69, 0, 18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = CheckboxSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3", "TextBody")

			local Checkbox = {
				Type = "Checkbox",
				CurrentValue = CheckboxSettings.CurrentValue == true,
			}

			local function render(animate)
				local on = Checkbox.CurrentValue
				local info = animate and TI_SMOOTH or TweenInfo.new(0)
				tween(box, info, {BackgroundColor3 = on and Theme.Knob or Theme.ToggleTrack})
				tween(boxStroke, info, {Transparency = on and 1 or 0.84})
				if on then
					if animate then check.Size = UDim2.fromOffset(10, 10) end
					tween(check, info, {ImageTransparency = 0, Size = UDim2.fromOffset(18, 18)})
				else
					tween(check, animate and TI_FAST or TweenInfo.new(0), {ImageTransparency = 1, Size = UDim2.fromOffset(10, 10)})
				end
			end
			render(false)

			local clicker = create("TextButton",{
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1,1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				Checkbox.CurrentValue = not Checkbox.CurrentValue
				render(true)
				runCallback(CheckboxSettings.Callback, Checkbox.CurrentValue)
				saveConfiguration()
			end)

			function Checkbox:Set(value)
				Checkbox.CurrentValue = value == true
				render(true)
				runCallback(CheckboxSettings.Callback, Checkbox.CurrentValue)
				saveConfiguration()
			end

			if CheckboxSettings.Flag then
				Checkbox.Flag = CheckboxSettings.Flag
				RayfieldLibrary.Flags[CheckboxSettings.Flag] = Checkbox
			end
			return Checkbox
		end

		function Tab:CreateCopyButton(CopySettings)
			CopySettings = CopySettings or {}
			local card, label = makeCard(page, CopySettings.Name, CopySettings.Icon, 50)
			descFor(card, CopySettings.Description)
			tipFor(card, CopySettings.Tooltip)
			hoverable(card)

			local well = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(30, 30),
				BackgroundColor3 = Theme.Knob,
			})
			round(well, 9)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(255, 255,255), Color3.fromRGB(196, 196, 196)),
				Parent = well,
			})
			well.Parent = card

			local wellScale = create("UIScale", {Parent = well})

			local copyIcon = makeIcon(well, "copy", 16, Color3.fromRGB(26, 26, 26), 0)
			copyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			copyIcon.Position = UDim2.fromScale(0.5, 0.5)
			local checkIcon = makeIcon(well, "check", 16, Color3.fromRGB(26, 26, 26), 1)
			checkIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			checkIcon.Position = UDim2.fromScale(0.5, 0.5)
			checkIcon.Size = UDim2.fromOffset(10, 10)

			local CopyValue = {
				CurrentValue = tostring(CopySettings.Text or CopySettings.Value or ""),
			}

			local copied = false
			local function copyToClipboard(text)
				return pcall(function()
					if type(setclipboard) == "function" then
						setclipboard(text)
					elseif type(toclipboard) == "function" then
						toclipboard(text)
					elseif type(writeclipboard) == "function" then
						writeclipboard(text)
					elseif type(Clipboard) == "table" and type(Clipboard.set) == "function" then
						Clipboard.set(text)
					else
						error("clipboard is not available")
					end
				end)
			end

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				if copied then return end
				local ok = copyToClipboard(CopyValue.CurrentValue)
				if not ok then
					warn("Rayfield Gen3 | Copy failed, no clipboard function available")
					return
				end
				copied = true
				tween(wellScale, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.85})
				task.delay(0.09, function()
					tween(wellScale, TI_SMOOTH, {Scale = 1})
				end)
				tween(copyIcon, TI_FAST, {ImageTransparency = 1, Size = UDim2.fromOffset(10, 10)})
				tween(checkIcon, TI_SMOOTH, {ImageTransparency = 0, Size = UDim2.fromOffset(16, 16)})
				runCallback(CopySettings.Callback, CopyValue.CurrentValue)
				task.delay(2, function()
					if not well.Parent then return end
					copied = false
					tween(checkIcon, TI_FAST, {ImageTransparency = 1, Size = UDim2.fromOffset(10, 10)})
					tween(copyIcon, TI_SMOOTH, {ImageTransparency = 0, Size = UDim2.fromOffset(16, 16)})
				end)
			end)

			function CopyValue:Set(newText)
				CopyValue.CurrentValue = tostring(newText or "")
			end
			function CopyValue:SetName(newName)
				label.Text = newName or ""
				card:SetAttribute("SearchName", newName or "")
			end
			return CopyValue
		end

		function Tab:CreateFlipButton(FlipSettings)
			FlipSettings = FlipSettings or {}
			local frontText = FlipSettings.Front or FlipSettings.Name or "Front"
			local backText = FlipSettings.Back or frontText

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				LayoutOrder = nextOrder(),
				ClipsDescendants = true,
				Parent = page,
			})
			card:SetAttribute("SearchName", frontText .. " " .. backText)
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			descFor(card, FlipSettings.Description)
			tipFor(card, FlipSettings.Tooltip)

			local function makeFace(text, dark)
				local layer = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Parent = card,
				})
				local lbl = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = FONT_MEDIUM,
					TextSize = 16,
					Text = text,
					Parent = layer,
				})
				if dark then
					lbl.TextColor3 = Color3.fromRGB(28, 28, 28)
				else
					paint(lbl, "TextColor3", "TextBody")
				end
				return layer, lbl
			end
			local frontLayer, frontLabel = makeFace(frontText, false)
			local backLayer, backLabel = makeFace(backText, true)
			backLayer.Position = UDim2.fromScale(0, -1)

			local flipped = false
			local function render(state)
				if flipped == state then return end
				flipped = state
				tween(frontLayer, TI_MORPH, {Position = state and UDim2.fromScale(0, 1) or UDim2.fromScale(0, 0)})
				tween(backLayer, TI_MORPH, {Position = state and UDim2.fromScale(0, 0) or UDim2.fromScale(0, -1)})
				tween(card, TI_MORPH, {BackgroundColor3 = state and Theme.Knob or Theme.Card})
			end
			card.MouseEnter:Connect(function() render(true) end)
			card.MouseLeave:Connect(function() render(false) end)

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				runCallback(FlipSettings.Callback)
			end)

			local FlipValue = {}
			function FlipValue:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Front then
					frontLabel.Text = newSettings.Front
				end
				if newSettings.Back then
					backLabel.Text = newSettings.Back
				end
				card:SetAttribute("SearchName", frontLabel.Text .. " " .. backLabel.Text)
			end
			return FlipValue
		end

		function Tab:CreateRippleButton(ButtonSettings)
			ButtonSettings = ButtonSettings or {}
			local card, label = makeCard(page, ButtonSettings.Name, ButtonSettings.Icon, 50)
			descFor(card, ButtonSettings.Description)
			tipFor(card, ButtonSettings.Tooltip)
			hoverable(card)

			local rippleClip = create("CanvasGroup", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 4,
				Parent = card,
			})
			round(rippleClip, 14)

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 5,
				Parent = card,
			})
			clicker.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				local rx = math.clamp(input.Position.X - card.AbsolutePosition.X, 0, card.AbsoluteSize.X)
				local ry = math.clamp(input.Position.Y - card.AbsolutePosition.Y, 0, card.AbsoluteSize.Y)
				local circle = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(rx, ry),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.88,
					Parent = rippleClip,
				})
				roundFull(circle)
				local span = math.max(card.AbsoluteSize.X, card.AbsoluteSize.Y) * 2.2
				tween(circle, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(span, span),
					BackgroundTransparency = 1,
				})
				task.delay(0.6, function()
					circle:Destroy()
				end)
			end)
			clicker.MouseButton1Click:Connect(function()
				runCallback(ButtonSettings.Callback)
			end)

			local ButtonValue = {}
			function ButtonValue:Set(newName)
				label.Text = newName
				card:SetAttribute("SearchName", newName or "")
			end
			return ButtonValue
		end

		function Tab:CreateProgressBar(ProgressSettings)
			ProgressSettings = ProgressSettings or {}
			local maxValue = ProgressSettings.MaxValue or 100
			local card, label, textX = makeCard(page, ProgressSettings.Name, ProgressSettings.Icon, 50)
			descFor(card, ProgressSettings.Description)
			tipFor(card, ProgressSettings.Tooltip)
			hoverable(card)
			label.Size = UDim2.new(0.42, -textX, 0, 18)

			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(42, 16),
				Font = FONT_REGULAR,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextSub")

			local track = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -66, 0.5, 0),
				Size = UDim2.new(0.4, 0, 0, 10),
				BackgroundColor3 = Color3.fromRGB(47, 47, 47),
			})
			roundFull(track)
			track.Parent = card

			local fill = create("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = track,
			})
			roundFull(fill)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentDark),
					ColorSequenceKeypoint.new(1, Theme.Accent),
				}),
				Parent = fill,
			})

			local Progress = {CurrentValue = 0}
			local function apply(value, animate)
				value = math.clamp(tonumber(value) or 0, 0, maxValue)
				Progress.CurrentValue = value
				local frac = maxValue > 0 and value / maxValue or 0
				valueLabel.Text = ProgressSettings.Suffix
					and (tostring(math.floor(value + 0.5)) .. ProgressSettings.Suffix)
					or (tostring(math.floor(frac * 100 + 0.5)) .. "%")
				local goal = UDim2.new(frac, 0, 1, 0)
				if animate then
					tween(fill, TI_SMOOTH, {Size = goal})
				else
					fill.Size = goal
				end
			end
			apply(ProgressSettings.CurrentValue or 0, false)

			function Progress:Set(value)
				apply(value, true)
			end
			return Progress
		end

		function Tab:CreateScrollHint(HintSettings)
			HintSettings = HintSettings or {}
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("SearchName", HintSettings.Text or "")

			local center = create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Parent = holder,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
				Parent = center,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Font = FONT_MEDIUM,
				TextSize = 15,
				Text = HintSettings.Text or "Scroll to see more",
				LayoutOrder = 1,
				Parent = center,
			})
			paint(lbl, "TextColor3", "TextBody")

			local arrowWell = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(16, 24),
				LayoutOrder = 2,
				Parent = center,
			})
			local arrow = makeIcon(arrowWell, HintSettings.Icon or "arrow-down", 16, Theme.TextBody, 0.1)
			if arrow then
				arrow.AnchorPoint = Vector2.new(0.5, 0)
				arrow.Position = UDim2.new(0.5, 0, 0, 0)
				tween(arrow, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
					Position = UDim2.new(0.5, 0, 0, 7),
				})
			end

			local Hint = {}
			function Hint:Set(newText)
				lbl.Text = newText or lbl.Text
				holder:SetAttribute("SearchName", lbl.Text)
			end
			return Hint
		end

		function Tab:CreatePinnedList(ListSettings)
			ListSettings = ListSettings or {}
			local ITEM_H, GAP, HEADER_H = 54, 8, 20
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			local header = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, HEADER_H),
				Font = FONT_MEDIUM,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = ListSettings.Title or "All Items",
				Parent = holder,
			})
			paint(header, "TextColor3", "TextSub")
			create("UIPadding", {PaddingLeft = UDim.new(0, 4), Parent = header})

			local List = {}
			local items = {}
			local itemsByName = {}
			local pinSerial = 0

			local function relayout(animate)
				local pinned, unpinned = {}, {}
				for _, item in ipairs(items) do
					table.insert(item.Pinned and pinned or unpinned, item)
				end
				table.sort(pinned, function(x, y) return x.PinStamp < y.PinStamp end)
				local y = 0
				local function place(inst, h)
					local goal = UDim2.fromOffset(0, y)
					if animate then
						tween(inst, TI_MORPH, {Position = goal})
					else
						inst.Position = goal
					end
					y = y + h + GAP
				end
				for _, item in ipairs(pinned) do
					place(item.Card, ITEM_H)
				end
				place(header, HEADER_H)
				for _, item in ipairs(unpinned) do
					place(item.Card, ITEM_H)
				end
				holder.Size = UDim2.new(1, 0, 0, math.max(0, y - GAP))
			end

			local function makeItem(cfg, index)
				local card = create("Frame", {
					Size = UDim2.new(1, 0, 0, ITEM_H),
					Parent = holder,
				})
				card:SetAttribute("SearchName", cfg.Name or "")
				paint(card, "BackgroundColor3", "Card")
				cardBase(card)
				hoverable(card)

				local textX = 16
				if cfg.Icon then
					local well = create("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 12, 0.5, 0),
						Size = UDim2.fromOffset(32, 32),
						BackgroundColor3 = Theme.CardInset,
						Parent = card,
					})
					round(well, 9)
					local ic = makeIcon(well, cfg.Icon, 16, Theme.TextTitle, 0.04)
					if ic then
						ic.AnchorPoint = Vector2.new(0.5, 0.5)
						ic.Position = UDim2.fromScale(0.5, 0.5)
					end
					textX = 54
				end

				local title = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(textX, 10),
					Size = UDim2.new(1, -textX - 56, 0, 17),
					Font = FONT_MEDIUM,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = cfg.Name or "",
					Parent = card,
				})
				paint(title, "TextColor3", "TextBody")
				local sub = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(textX, 28),
					Size = UDim2.new(1, -textX - 56, 0, 15),
					Font = FONT_REGULAR,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = cfg.Description or "",
					Parent = card,
				})
				paint(sub, "TextColor3", "TextSub")

				local pinBtn = create("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(30, 30),
					BackgroundColor3 = Theme.CardSelected,
					BackgroundTransparency = 1,
					Text = "",
					Parent = card,
				})
				roundFull(pinBtn)
				local pinIcon = makeIcon(pinBtn, "pin", 14, Theme.TextTitle, 1)
				if pinIcon then
					pinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
					pinIcon.Position = UDim2.fromScale(0.5, 0.5)
				end

				local item = {
					Name = cfg.Name or ("Item " .. index),
					Pinned = false,
					PinStamp = 0,
					Order = index,
					Card = card,
				}
				local function refreshPin()
					local show = item.Pinned
					tween(pinBtn, TI_FAST, {BackgroundTransparency = show and 0.25 or 1})
					if pinIcon then
						tween(pinIcon, TI_FAST, {ImageTransparency = show and 0.1 or 1})
					end
				end
				local function setPinned(state, silent)
					if item.Pinned == state then return end
					item.Pinned = state
					if state then
						pinSerial = pinSerial + 1
						item.PinStamp = pinSerial
					end
					relayout(true)
					refreshPin()
					tween(card, TweenInfo.new(0.07, Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.CardSelected})
					task.delay(0.14, function()
						tween(card, TI_MED, {BackgroundColor3 = Theme.Card})
					end)
					if not silent then
						runCallback(ListSettings.Callback, item.Name, state)
					end
				end
				item.SetPinned = setPinned

				pinBtn.MouseButton1Click:Connect(function()
					setPinned(not item.Pinned)
				end)
				card.MouseEnter:Connect(function()
					tween(pinBtn, TI_FAST, {BackgroundTransparency = 0.25})
					if pinIcon then
						tween(pinIcon, TI_FAST, {ImageTransparency = 0.1})
					end
				end)
				card.MouseLeave:Connect(refreshPin)

				table.insert(items, item)
				itemsByName[item.Name] = item
			end

			for i, cfg in ipairs(ListSettings.Items or {}) do
				makeItem(cfg, i)
			end
			for i, cfg in ipairs(ListSettings.Items or {}) do
				if cfg.Pinned and items[i] then
					items[i].Pinned = true
					pinSerial = pinSerial + 1
					items[i].PinStamp = pinSerial
				end
			end
			relayout(false)

			function List:Pin(name, state)
				local item = itemsByName[name]
				if item then
					item.SetPinned(state ~= false)
				end
			end
			function List:GetPinned()
				local out = {}
				for _, item in ipairs(items) do
					if item.Pinned then
						table.insert(out, item.Name)
					end
				end
				return out
			end
			return List
		end

		function Tab:CreateCursorTag(TagSettings)
			TagSettings = TagSettings or {}
			local scope = TagSettings.Scope or "Area"
			local offX = (TagSettings.Offset and TagSettings.Offset.X) or 14
			local offY = (TagSettings.Offset and TagSettings.Offset.Y) or 18

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, TagSettings.Height or 110),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", TagSettings.Text or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)

			local hint = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Font = FONT_REGULAR,
				TextSize = 14,
				TextTransparency = 0.35,
				Text = TagSettings.Hint or "Move your mouse over this area",
				Parent = card,
			})
			paint(hint, "TextColor3", "TextSub")

			local region, chipParent
			if scope == "Screen" then
				region = nil
				chipParent = ensureRoot()
			elseif scope == "Window" then
				local node = page
				while node.Parent and not node.Parent:IsA("ScreenGui") do
					node = node.Parent
				end
				region = node
				chipParent = node
			else
				region = card
				chipParent = card
			end

			local chip = create("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				TextColor3 = Color3.fromRGB(24, 24, 24),
				Font = FONT_MEDIUM,
				TextSize = 12,
				Text = TagSettings.Text or "Tag",
				Visible = false,
				TextTransparency = 1,
				BackgroundTransparency = 1,
				ZIndex = 5000,
				Parent = chipParent,
			})
			round(chip, 6)
			padAll(chip, 4, 8, 4, 8)

			local shown = false
			local enabled = TagSettings.Enabled ~= false
			local hideToken = 0
			local function showChip()
				if not enabled then return end
				hideToken = hideToken + 1
				shown = true
				chip.Visible = true
				tween(chip, TI_FAST, {TextTransparency = 0, BackgroundTransparency = 0})
			end
			local function hideChip()
				hideToken = hideToken + 1
				local myToken = hideToken
				shown = false
				tween(chip, TI_FAST, {TextTransparency = 1, BackgroundTransparency = 1})
				task.delay(0.16, function()
					if hideToken == myToken and not shown then
						chip.Visible = false
					end
				end)
			end
			local function moveTo(px, py)
				local base = chipParent.AbsolutePosition
				local bounds = chipParent.AbsoluteSize
				local cw = math.max(chip.AbsoluteSize.X, 24)
				local ch = math.max(chip.AbsoluteSize.Y, 16)
				local x = math.clamp(px - base.X + offX, 2, math.max(2, bounds.X - cw - 2))
				local y = math.clamp(py - base.Y + offY, 2, math.max(2, bounds.Y - ch - 2))
				tween(chip, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.fromOffset(x, y),
				})
			end

			if region then
				region.InputChanged:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
					moveTo(input.Position.X, input.Position.Y)
				end)
				region.MouseEnter:Connect(showChip)
				region.MouseLeave:Connect(hideChip)
			else
				connect(UserInputService.InputChanged, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
					if not shown then showChip() end
					moveTo(input.Position.X, input.Position.Y)
				end)
			end

			local Tag = {}
			function Tag:Set(newText)
				chip.Text = newText or chip.Text
			end
			function Tag:SetEnabled(state)
				state = state ~= false
				if enabled == state then return end
				enabled = state
				if not enabled then
					hideChip()
				end
			end
			return Tag
		end

		function Tab:CreateShimmerLabel(ShimmerSettings)
			ShimmerSettings = ShimmerSettings or {}
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, ShimmerSettings.Height or 34),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("SearchName", ShimmerSettings.Text or "")
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Font = ShimmerSettings.Bold and FONT_BOLD or FONT_MEDIUM,
				TextSize = ShimmerSettings.TextSize or 20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = ShimmerSettings.Text or "Shimmer",
				Parent = holder,
			})
			local grad = create("UIGradient", {
				Offset = Vector2.new(-1, 0),
				Rotation = ShimmerSettings.Rotation or 8,
				Parent = lbl,
			})

			local spread = math.clamp(ShimmerSettings.Spread or 0.2, 0.05, 0.45)
			local speed = math.clamp(ShimmerSettings.Speed or 1.4, 0.3, 6)
			local rest = ShimmerSettings.Rest or 0.35

			local function rebuild()
				local base = Color3.fromRGB(110, 110, 110)
				local glow = Color3.fromRGB(190, 190, 190)
				local core = Color3.fromRGB(255, 255, 255)
				local lo = 0.5 - spread
				local hi = 0.5 + spread
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, base),
					ColorSequenceKeypoint.new(math.max(0.001, lo), base),
					ColorSequenceKeypoint.new(0.5 - spread * 0.4, glow),
					ColorSequenceKeypoint.new(0.5, core),
					ColorSequenceKeypoint.new(0.5 + spread * 0.4, glow),
					ColorSequenceKeypoint.new(math.min(0.999, hi), base),
					ColorSequenceKeypoint.new(1, base),
				})
			end
			rebuild()

			task.spawn(function()
				while grad.Parent do
					grad.Offset = Vector2.new(-1, 0)
					local t = tween(grad, TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(1, 0)})
					t.Completed:Wait()
					task.wait(rest)
				end
			end)

			local Shimmer = {}
			function Shimmer:Set(newText)
				lbl.Text = newText or lbl.Text
				holder:SetAttribute("SearchName", lbl.Text)
			end
			function Shimmer:SetSpeed(newSpeed)
				speed = math.clamp(tonumber(newSpeed) or speed, 0.3, 6)
			end
			function Shimmer:SetSpread(newSpread)
				spread = math.clamp(tonumber(newSpread) or spread, 0.05, 0.45)
				rebuild()
			end
			return Shimmer
		end

		function Tab:CreateSegmentedPicker(PickerSettings)
			PickerSettings = PickerSettings or {}
			local options = {}
			for i, opt in ipairs(PickerSettings.Options or {}) do
				if type(opt) == "string" then
					options[i] = {Name = opt}
				else
					options[i] = {Name = opt.Name or ("Option " .. i), Subs = opt.Options}
				end
			end
			if #options == 0 then
				options = {{Name = "A"}, {Name = "B"}}
			end

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 58),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", PickerSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			descFor(card, PickerSettings.Description)
			tipFor(card, PickerSettings.Tooltip)

			local track = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -20, 0, 42),
				BackgroundColor3 = Theme.CardInset,
				Parent = card,
			})
			roundFull(track)

			local indicator = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 2,
				Parent = track,
			})
			roundFull(indicator)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(224, 224, 224)),
				Parent = indicator,
			})

			local Picker = {CurrentOption = nil, CurrentSub = nil}
			local selMain = 1
			local segs = {}

			local function geometry()
				local n = #options
				local rects = {}
				local sel = options[selMain]
				if sel.Subs then
					local wSel = n == 1 and 1 or 0.62
					local wOther = n == 1 and 0 or (1 - wSel) / (n - 1)
					local x = 0
					for i = 1, n do
						local w = (i == selMain) and wSel or wOther
						rects[i] = {x = x, w = w}
						x = x + w
					end
				else
					for i = 1, n do
						rects[i] = {x = (i - 1) / n, w = 1 / n}
					end
				end
				return rects
			end

			local function relayout(animate)
				local rects = geometry()
				local r = rects[selMain]
				local goalPos = UDim2.new(r.x, 4, 0, 4)
				local goalSize = UDim2.new(r.w, -8, 1, -8)
				if animate then
					tween(indicator, TI_MORPH, {Position = goalPos, Size = goalSize})
				else
					indicator.Position = goalPos
					indicator.Size = goalSize
				end
				for i, seg in ipairs(segs) do
					local rect = rects[i]
					local pos = UDim2.new(rect.x, 0, 0, 0)
					local size = UDim2.new(rect.w, 0, 1, 0)
					if animate then
						tween(seg.Zone, TI_MORPH, {Position = pos, Size = size})
					else
						seg.Zone.Position = pos
						seg.Zone.Size = size
					end
					local isSel = i == selMain
					local hasSubsOpen = isSel and options[i].Subs ~= nil
					tween(seg.Label, TI_MED, {
						TextTransparency = hasSubsOpen and 1 or 0,
						TextColor3 = isSel and Color3.fromRGB(28, 28, 28) or Theme.TextSub,
					})
					if seg.SubHolder then
						seg.SubHolder.Visible = true
						for _, s in ipairs(seg.SubLabels) do
							tween(s, TI_MED, {TextTransparency = hasSubsOpen and 0 or 1})
						end
						tween(seg.SubIndicator, TI_MED, {BackgroundTransparency = hasSubsOpen and 0 or 1})
						if not hasSubsOpen then
							task.delay(0.28, function()
								if selMain ~= i then seg.SubHolder.Visible = false end
							end)
						end
					end
				end
			end

			local function report(silent)
				local opt = options[selMain]
				Picker.CurrentOption = opt.Name
				Picker.CurrentSub = opt.Subs and opt.Subs[segs[selMain].SubSel] or nil
				if not silent then
					runCallback(PickerSettings.Callback, Picker.CurrentOption, Picker.CurrentSub)
				end
			end

			for i, opt in ipairs(options) do
				local zone = create("Frame", {
					BackgroundTransparency = 1,
					ZIndex = 3,
					Parent = track,
				})
				local label = create("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = FONT_MEDIUM,
					TextSize = 14,
					TextColor3 = Theme.TextSub,
					Text = opt.Name,
					ZIndex = 4,
					Parent = zone,
				})
				local seg = {Zone = zone, Label = label, SubSel = 1}
				label.MouseButton1Click:Connect(function()
					if selMain ~= i then
						selMain = i
						relayout(true)
						report()
					end
				end)
				if opt.Subs then
					local subHolder = create("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 6, 0, 6),
						Size = UDim2.new(1, -12, 1, -12),
						Visible = false,
						ZIndex = 5,
						Parent = zone,
					})
					local subIndicator = create("Frame", {
						BackgroundColor3 = Color3.fromRGB(28, 28, 28),
						BackgroundTransparency = 1,
						ZIndex = 5,
						Parent = subHolder,
					})
					roundFull(subIndicator)
					seg.SubHolder = subHolder
					seg.SubIndicator = subIndicator
					seg.SubLabels = {}
					local m = #opt.Subs
					local function subGoal()
						return UDim2.new((seg.SubSel - 1) / m, 0, 0, 0), UDim2.new(1 / m, 0, 1, 0)
					end
					for j, subName in ipairs(opt.Subs) do
						local sbtn = create("TextButton", {
							BackgroundTransparency = 1,
							Position = UDim2.new((j - 1) / m, 0, 0, 0),
							Size = UDim2.new(1 / m, 0, 1, 0),
							Font = FONT_MEDIUM,
							TextSize = 13,
							TextColor3 = Color3.fromRGB(28, 28, 28),
							TextTransparency = 1,
							Text = subName,
							ZIndex = 6,
							Parent = subHolder,
						})
						seg.SubLabels[j] = sbtn
						sbtn.MouseButton1Click:Connect(function()
							if selMain ~= i then return end
							seg.SubSel = j
							local p, s = subGoal()
							tween(subIndicator, TI_MORPH, {Position = p, Size = s})
							for k, other in ipairs(seg.SubLabels) do
								tween(other, TI_MED, {TextColor3 = k == j and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 28)})
							end
							report()
						end)
					end
					local p, s = subGoal()
					subIndicator.Position = p
					subIndicator.Size = s
					seg.SubLabels[seg.SubSel].TextColor3 = Color3.fromRGB(255, 255, 255)
				end
				segs[i] = seg
			end

			local function findMain(name)
				for i, opt in ipairs(options) do
					if opt.Name == name then return i end
				end
			end
			if PickerSettings.CurrentOption then
				local want = PickerSettings.CurrentOption
				local mainName = type(want) == "table" and want[1] or want
				local subName = type(want) == "table" and want[2] or nil
				local mi = findMain(mainName)
				if mi then
					selMain = mi
					if subName and options[mi].Subs then
						for j, s in ipairs(options[mi].Subs) do
							if s == subName then segs[mi].SubSel = j end
						end
						local m = #options[mi].Subs
						segs[mi].SubIndicator.Position = UDim2.new((segs[mi].SubSel - 1) / m, 0, 0, 0)
						segs[mi].SubIndicator.Size = UDim2.new(1 / m, 0, 1, 0)
						for k, other in ipairs(segs[mi].SubLabels) do
							other.TextColor3 = k == segs[mi].SubSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 28)
						end
					end
				end
			end
			relayout(false)
			report(true)

			function Picker:Set(mainName, subName)
				local mi = findMain(mainName)
				if not mi then return end
				selMain = mi
				if subName and options[mi].Subs then
					for j, s in ipairs(options[mi].Subs) do
						if s == subName then segs[mi].SubSel = j end
					end
					local m = #options[mi].Subs
					tween(segs[mi].SubIndicator, TI_MORPH, {
						Position = UDim2.new((segs[mi].SubSel - 1) / m, 0, 0, 0),
						Size = UDim2.new(1 / m, 0, 1, 0),
					})
					for k, other in ipairs(segs[mi].SubLabels) do
						tween(other, TI_MED, {TextColor3 = k == segs[mi].SubSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 28)})
					end
				end
				relayout(true)
				report()
			end
			return Picker
		end

		function Tab:CreateSlider(SliderSettings)
			SliderSettings = SliderSettings or {}
			local range = SliderSettings.Range or {0, 100}
			local increment = SliderSettings.Increment or 1
			local suffix = SliderSettings.Suffix or ""

			local card = create("Frame",{
				Size = UDim2.new(1, 0, 0,compact and 78 or 60),
				LayoutOrder = nextOrder(),
				Parent=page,
			})
			card:SetAttribute("SearchName",SliderSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			descFor(card,SliderSettings.Description)
			tipFor(card, SliderSettings.Tooltip)

			local textX = 17
			if SliderSettings.Icon then
				local ic = makeIcon(card, SliderSettings.Icon, 18,Theme.TextTitle,0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16,13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, compact and 13 or 11),
				Size = UDim2.new(compact and 0.56 or 0.48,-textX, 0,18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = SliderSettings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3","TextBody")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = compact and Vector2.new(1, 0) or Vector2.new(0, 0),
				Position = compact and UDim2.new(1, -16, 0, 15) or UDim2.fromOffset(textX, 32),
				Size = UDim2.new(compact and 0.4 or 0.48, compact and -16 or -textX,0, 16),
				Font = FONT_REGULAR,
				TextSize = 13,
				TextXAlignment = compact and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextSub")

			-- Gen 2 fanmade look: a chunky track, an accent-gradient fill and a
			-- solid white pill knob.
			local track
			if compact then
				track = create("Frame", {
					Position = UDim2.fromOffset(15, 46),
					Size = UDim2.new(1,-30, 0, 16),
					BackgroundColor3 = Color3.fromRGB(47, 47, 47),
				})
			else
				track = create("Frame",{
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -17, 0.5, 0),
					Size = UDim2.new(0.46,0,0, 16),
					BackgroundColor3 = Color3.fromRGB(47, 47, 47),
				})
			end
			roundFull(track)
			track.Parent = card

			local fill = create("Frame", {
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255,255),
				Parent = track,
			})
			roundFull(fill)

			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentDark),
					ColorSequenceKeypoint.new(1, Theme.Accent),
				}),
				Parent = fill,
			})

			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5,0,0.5, 0),
				Size = UDim2.fromOffset(48, 26),
				ZIndex = 3,
			})
			paint(knob, "BackgroundColor3", "Knob")
			roundFull(knob)
			knob.Parent = track

			local Slider = {
				Type = "Slider",
				CurrentValue = SliderSettings.CurrentValue or range[1],
				Card = card,
			}

			local function fmt(v)
				local text
				if increment % 1 == 0 then
					text = tostring(math.floor(v + 0.5))
				else
					text = string.format("%.2f", v)
					text = string.gsub(text, "%.?0+$", "")
				end
				if suffix ~= "" then
					return text .. " " .. suffix
				end
				return text
			end

			local function render(animate)
				local alpha = 0
				if range[2] ~= range[1] then
					alpha = (Slider.CurrentValue - range[1]) / (range[2] - range[1])
				end
				alpha = math.clamp(alpha,0, 1)
				local inset = 0.11
				local shown = inset + alpha * (1 - 2 * inset)
				local info = animate and TI_SMOOTH or TweenInfo.new(0)
				tween(fill, info,{Size = UDim2.new(shown,0, 1, 0)})
				tween(knob,info, {Position = UDim2.new(shown, 0, 0.5, 0)})
				valueLabel.Text = fmt(Slider.CurrentValue)
			end

			local function setFromAlpha(alpha)
				local raw = range[1] + alpha * (range[2] - range[1])
				local snapped = range[1] + math.floor((raw - range[1]) / increment + 0.5) * increment
				snapped = math.clamp(snapped, range[1], range[2])
				if math.abs(snapped - Slider.CurrentValue) > 1e-9 then
					Slider.CurrentValue = snapped
					render(true)
					runCallback(SliderSettings.Callback,snapped)
					saveConfiguration()
				end
			end

			local dragging = false
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(math.clamp(alpha, 0, 1))
				end
			end)
			track.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			connect(UserInputService.InputChanged,function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(math.clamp(alpha, 0,1))
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					dragging = false
				end
			end)

			render(false)

			function Slider:Set(value)
				Slider.CurrentValue = math.clamp(value, range[1], range[2])
				render(true)
				runCallback(SliderSettings.Callback,Slider.CurrentValue)
				saveConfiguration()
			end

			if SliderSettings.Flag then
				Slider.Flag = SliderSettings.Flag
				RayfieldLibrary.Flags[SliderSettings.Flag] = Slider
			end
			return Slider
		end

		function Tab:CreateInput(InputSettings)
			InputSettings = InputSettings or {}
			local card = makeCard(page,InputSettings.Name,InputSettings.Icon, 50)
			descFor(card, InputSettings.Description)
			tipFor(card, InputSettings.Tooltip)
			hoverable(card)

			local boxHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1,-13, 0.5, 0),
				Size = UDim2.fromOffset(172, 32),
				Parent = card,
			})
			paint(boxHolder, "BackgroundColor3", "CardHover")
			round(boxHolder, 10)
			local boxStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88, Parent = boxHolder})

			local box = create("TextBox", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 1, 0),
				Position = UDim2.fromOffset(10, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				PlaceholderText = InputSettings.PlaceholderText or "Input",
				PlaceholderColor3 = Theme.TextMuted,
				Text = InputSettings.CurrentValue or "",
				ClearTextOnFocus = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = boxHolder,
			})
			paint(box, "TextColor3", "TextBody")

			local Input = {
				Type = "Input",
				CurrentValue = InputSettings.CurrentValue or "",
			}

			box.Focused:Connect(function()
				tween(boxStroke, TI_FAST,{Transparency = 0.5})
			end)
			box.FocusLost:Connect(function()
				tween(boxStroke, TI_FAST,{Transparency = 0.88})
				Input.CurrentValue = box.Text
				runCallback(InputSettings.Callback,box.Text)
				if InputSettings.RemoveTextAfterFocusLost then
					box.Text = ""
				end
				saveConfiguration()
			end)

			function Input:Set(text)
				box.Text = text or ""
				Input.CurrentValue = box.Text
				runCallback(InputSettings.Callback, box.Text)
				saveConfiguration()
			end

			if InputSettings.Flag then
				Input.Flag = InputSettings.Flag
				RayfieldLibrary.Flags[InputSettings.Flag] = Input
			end
			return Input
		end

		function Tab:CreateDropdown(DropdownSettings)
			DropdownSettings = DropdownSettings or {}
			local options = DropdownSettings.Options or {}
			local multiple = DropdownSettings.MultipleOptions == true

			local current = DropdownSettings.CurrentOption
			if type(current) == "string" then current = {current} end
			if type(current) ~= "table" then current = {} end
			if not multiple and #current > 1 then
				current = {current[1]}
			end

			local wrapper = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			wrapper:SetAttribute("SearchName", DropdownSettings.Name or "")

			local card = create("Frame",{
				Size = UDim2.new(1,0, 0, 50),
				Parent = wrapper,
			})
			paint(card, "BackgroundColor3", "Card");
			cardBase(card)
			hoverable(card)

			local textX = 17
			if DropdownSettings.Icon then
				local ic = makeIcon(card,DropdownSettings.Icon, 18,Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16,0.5, 0)
					textX = 44
				end
			end
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position=UDim2.new(0,textX, 0.5, 0),
				Size = UDim2.new(0.5, -textX, 0,18),
				Font = FONT_MEDIUM,
				TextSize=16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = DropdownSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3","TextBody")

			local chevron = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1,0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ImageColor3 = Theme.TextSub,
				Parent = card,
			})
			applyLucide(chevron, {"chevron-down"})

			-- search icon: click to reveal the search bar inside the open list
			local searchBtn = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -38, 0.5, 0),
				Size = UDim2.fromOffset(26, 26),
				ZIndex = 3,
				Parent = card,
			})
			local searchIcon = makeIcon(searchBtn, "search", 16, Theme.TextSub)
			if searchIcon then
				searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				searchIcon.Position = UDim2.fromScale(0.5, 0.5)
				searchIcon.ZIndex = 3
			end

			local currentLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint=Vector2.new(1, 0.5),
				Position=UDim2.new(1, -62, 0.5, 0),
				Size = UDim2.new(0.4, -62, 0, 16),
				Font=FONT_MEDIUM,
				TextSize=14,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "",
				Parent = card,
			})
			paint(currentLabel, "TextColor3", "TextSub")

			local OPTION_H = 42
			local SEARCH_H = 40
			local GAP = 6
			local MAX_LIST = 240

			local listHolder = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 56),
				Size = UDim2.new(1,0, 0, 0),
				CanvasSize=UDim2.new(0, 0, 0,0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 0,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Visible = false,
				Parent = wrapper,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, GAP),
				Parent = listHolder,
			})

			local searchRow = create("Frame", {
				Size = UDim2.new(1, 0, 0, SEARCH_H),
				BackgroundTransparency = 0.35,
				LayoutOrder = 1,
				Visible = false, -- opened by the search icon in the header
				Parent = listHolder,
			})
			paint(searchRow, "BackgroundColor3","SearchBox")
			round(searchRow,12)
			do
				local sIcon = makeIcon(searchRow, "text-search",16, Theme.TextSub)
				if sIcon then
					sIcon.AnchorPoint = Vector2.new(0,0.5)
					sIcon.Position = UDim2.new(0, 13, 0.5, 0)
				end
			end
			local optionSearch = create("TextBox",{
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(38, 0),
				Size=UDim2.new(1, -46,1, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				PlaceholderText = "Search " .. (DropdownSettings.Name or "Dropdown"),
				PlaceholderColor3 = Theme.TextMuted,
				Text = "",
				ClearTextOnFocus = false,
				Parent = searchRow,
			})
			paint(optionSearch, "TextColor3", "TextBody")

			local Dropdown = {
				Type = "Dropdown",
				CurrentOption = current,
				Card = card,
			}

			local open = false
			local searchOn = false
			local optionRows = {}

			local function isSelected(option)
				for _, v in ipairs(Dropdown.CurrentOption) do
					if v == option then return true end
				end
				return false
			end

			local placeholder = DropdownSettings.Placeholder or "None"
			local function refreshCurrentLabel()
				local n = #Dropdown.CurrentOption
				if n == 0 then
					currentLabel.Text = placeholder
				elseif n == 1 then
					currentLabel.Text = tostring(Dropdown.CurrentOption[1])
				else
					currentLabel.Text = tostring(n) .. " selected"
				end
			end

			local function visibleListHeight()
				local count = 0
				for _, row in ipairs(optionRows) do
					if row.frame.Visible then count = count + 1 end
				end
				local h = (searchOn and (SEARCH_H + GAP) or 0) + count * (OPTION_H + GAP)
				return math.min(h, MAX_LIST)
			end

			local DROP_OPEN = TweenInfo.new(0.34, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local DROP_CLOSE = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			local function setOpen(value)
				open = value
				tween(chevron, DROP_OPEN, {Rotation = open and 180 or 0})
				if open then
					listHolder.Visible = true
					-- slide the list down from a couple pixels up while it grows, for a softer reveal
					listHolder.Position = UDim2.fromOffset(0, 52)
					tween(listHolder, DROP_OPEN, {Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, visibleListHeight())})
				else
					tween(listHolder, DROP_CLOSE, {Position = UDim2.fromOffset(0, 52)})
					local t = tween(listHolder, DROP_CLOSE, {Size = UDim2.new(1, 0, 0, 0)})
					t.Completed:Connect(function()
						if not open then listHolder.Visible = false; listHolder.Position = UDim2.fromOffset(0, 56) end
					end)
					searchOn = false
					searchRow.Visible = false
					if searchIcon then searchIcon.ImageColor3 = Theme.TextSub end
					optionSearch.Text = ""
				end
			end

			-- the search icon reveals the search bar (opening the list if needed)
			local function setSearch(on)
				searchOn = on and true or false
				searchRow.Visible = searchOn
				if searchIcon then searchIcon.ImageColor3 = searchOn and Theme.Accent or Theme.TextSub end
				if searchOn then
					if not open then setOpen(true) end
					task.defer(function() if searchOn and searchRow.Parent then optionSearch:CaptureFocus() end end)
				else
					optionSearch.Text = ""
				end
				if open then
					tween(listHolder, TI_FAST, { Size = UDim2.new(1, 0, 0, visibleListHeight()) })
				end
			end
			searchBtn.MouseButton1Click:Connect(function()
				setSearch(not searchOn)
			end)

			local function renderRows()
				for _, row in ipairs(optionRows) do
					if not row.isSection then
						local selected = isSelected(row.option)
						row.frame.BackgroundColor3 = selected and Theme.CardSelected or Theme.CardInset
						row.check.Visible = selected
						row.label.Position = UDim2.new(0, selected and 44 or 17, 0.5, 0)
						row.label.TextColor3 = selected and Theme.TextTitle or Theme.TextSub
					end
				end
			end

			local function choose(option)
				if multiple then
					if isSelected(option) then
						for i, v in ipairs(Dropdown.CurrentOption) do
							if v == option then
								table.remove(Dropdown.CurrentOption, i)
								break
							end
						end
					else
						table.insert(Dropdown.CurrentOption, option)
					end
				else
					Dropdown.CurrentOption = {option}
				end
				renderRows();
				refreshCurrentLabel()
				runCallback(DropdownSettings.Callback, Dropdown.CurrentOption);
				saveConfiguration()
				if not multiple then
					task.delay(0.12,function() setOpen(false) end)
				end
			end

			local function buildRows()
				for _, row in ipairs(optionRows) do
					row.frame:Destroy()
				end
				optionRows = {}
				for i, option in ipairs(options) do
					if type(option) == "table" and option.Section then
						-- non-selectable section header inside the list
						local header = create("Frame", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 26),
							LayoutOrder = i + 1,
							Parent = listHolder,
						})
						local hlbl = create("TextLabel", {
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(0, 1),
							Position = UDim2.new(0, 14, 1, -4),
							Size = UDim2.new(1, -20, 0, 14),
							Font = FONT_BOLD,
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Left,
							Text = string.upper(tostring(option.Section)),
							Parent = header,
						})
						paint(hlbl, "TextColor3", "TextMuted")
						table.insert(optionRows, {frame = header, isSection = true})
					else
					local row = create("Frame", {
						Size = UDim2.new(1, 0, 0, OPTION_H),
						LayoutOrder = i + 1,
						Parent = listHolder,
					})
					round(row, 12)
					local check = create("ImageLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 15, 0.5, 0),
						Size = UDim2.fromOffset(18, 18),
						ImageColor3 = Theme.TextTitle,
						Visible = false,
						Parent = row,
					})
					applyLucide(check, {"square-check", "check-square", "check"});
					local optionLabel = create("TextLabel",{
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0,17, 0.5, 0),
						Size = UDim2.new(1, -62, 0,16),
						Font = FONT_MEDIUM,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = tostring(option),
						Parent = row,
					})
					local rowButton = create("TextButton", {
						BackgroundTransparency = 1,
						Text = "",
						Size = UDim2.fromScale(1, 1),
						Parent = row,
					})
					local entry = {frame = row, label = optionLabel, check = check, option = option}
					rowButton.MouseEnter:Connect(function()
						if not isSelected(option) then
							tween(row, TI_FAST,{BackgroundColor3 = Theme.CardHover})
						end
					end)
					rowButton.MouseLeave:Connect(function()
						tween(row, TI_FAST, {BackgroundColor3 = isSelected(option) and Theme.CardSelected or Theme.CardInset})
					end)
					rowButton.MouseButton1Click:Connect(function()
						choose(option)
					end)
					table.insert(optionRows,entry)
					end
				end
				renderRows()
			end

			connect(optionSearch:GetPropertyChangedSignal("Text"), function()
				local q = string.lower(optionSearch.Text)
				for _, row in ipairs(optionRows) do
					if row.isSection then
						row.frame.Visible = q == ""
					else
						row.frame.Visible = q == "" or string.find(string.lower(tostring(row.option)), q,1, true) ~= nil
					end
				end
				if open then
					tween(listHolder,TI_FAST, {Size = UDim2.new(1, 0, 0, visibleListHeight())})
				end
			end)

			local clicker = create("TextButton",{
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			buildRows()
			refreshCurrentLabel()

			function Dropdown:Set(newOption)
				if type(newOption) == "string" then newOption = {newOption} end
				if type(newOption) ~= "table" then newOption = {} end
				if not multiple and #newOption > 1 then newOption = {newOption[1]} end
				Dropdown.CurrentOption = newOption
				renderRows()
				refreshCurrentLabel()
				runCallback(DropdownSettings.Callback, Dropdown.CurrentOption)
				saveConfiguration()
			end

			function Dropdown:Refresh(newOptions)
				options = newOptions or {}
				local kept = {}
				for _, v in ipairs(Dropdown.CurrentOption) do
					for _,o in ipairs(options) do
						if o == v then
							table.insert(kept, v)
							break
						end
					end
				end
				Dropdown.CurrentOption = kept
				buildRows()
				refreshCurrentLabel()
				if open then
					tween(listHolder,TI_FAST,{Size = UDim2.new(1, 0, 0, visibleListHeight())})
				end
			end

			-- Clear the selection so the dropdown shows its placeholder again.
			function Dropdown:Reset()
				Dropdown.CurrentOption = {}
				renderRows()
				refreshCurrentLabel()
				runCallback(DropdownSettings.Callback, Dropdown.CurrentOption)
				saveConfiguration()
			end

			local setLocked = lockOverlay(card, DropdownSettings.Locked)
			function Dropdown:SetLocked(state) setLocked(state and true or false) end

			if DropdownSettings.Flag then
				Dropdown.Flag=DropdownSettings.Flag
				RayfieldLibrary.Flags[DropdownSettings.Flag] = Dropdown
			end
			return Dropdown
		end

		function Tab:CreateKeybind(KeybindSettings)
			KeybindSettings = KeybindSettings or {}
			local card = makeCard(page, KeybindSettings.Name, KeybindSettings.Icon, 50)
			descFor(card, KeybindSettings.Description)
			tipFor(card, KeybindSettings.Tooltip)
			hoverable(card)

			local keyHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1,-13, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(34, 30),
			})
			paint(keyHolder, "BackgroundColor3", "CardHover")
			round(keyHolder, 10)
			local keyStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255,255),Transparency = 0.88, Parent = keyHolder})
			keyHolder.Parent = card
			local keyLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 18, 1, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				Text = KeybindSettings.CurrentKeybind or "Key",
				Parent = keyHolder,
			})
			paint(keyLabel, "TextColor3","TextBody")
			padAll(keyHolder, 0, 9, 0, 9)

			local Keybind = {
				Type = "Keybind",
				CurrentKeybind = KeybindSettings.CurrentKeybind or "Key",
			}

			local listening = false
			local holdActive = false

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				listening = true
				keyLabel.Text = "..."
				tween(keyStroke, TI_FAST, {Transparency = 0.4})
			end)

			connect(UserInputService.InputBegan,function(input, processed)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
						listening = false
						tween(keyStroke, TI_FAST,{Transparency = 0.88})
						if input.KeyCode == Enum.KeyCode.Escape then
							keyLabel.Text = Keybind.CurrentKeybind
							return
						end
						Keybind.CurrentKeybind = input.KeyCode.Name
						keyLabel.Text = input.KeyCode.Name
						if KeybindSettings.CallOnChange then
							runCallback(KeybindSettings.Callback, input.KeyCode.Name)
						end
						saveConfiguration()
					end
					return
				end
				if processed then return end
				if KeybindSettings.CallOnChange then return end
				if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Keybind.CurrentKeybind then
					if KeybindSettings.HoldToInteract then
						holdActive = true
						runCallback(KeybindSettings.Callback, true)
					else
						runCallback(KeybindSettings.Callback)
					end
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if holdActive and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Keybind.CurrentKeybind then
					holdActive = false
					runCallback(KeybindSettings.Callback, false)
				end
			end)

			function Keybind:Set(newKeybind)
				Keybind.CurrentKeybind = newKeybind
				keyLabel.Text = newKeybind or "Key"
				if KeybindSettings.CallOnChange then
					runCallback(KeybindSettings.Callback, newKeybind)
				end
				saveConfiguration()
			end

			if KeybindSettings.Flag then
				Keybind.Flag = KeybindSettings.Flag
				RayfieldLibrary.Flags[KeybindSettings.Flag] = Keybind
			end
			return Keybind
		end

		function Tab:CreateColorPicker(ColorPickerSettings)
			ColorPickerSettings=ColorPickerSettings or {}
			local color = ColorPickerSettings.Color or Color3.fromRGB(255, 255, 255)

			local COLLAPSED_H = 50
			local EXPANDED_H = 210
			local SV_W, SV_H, SV_CY = 180, 110, 116
			local HUE_CY = 188
			local EXPO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local EXPO_FAST = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, COLLAPSED_H),
				ClipsDescendants = true,
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", ColorPickerSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			hoverable(card)

			local textX = 17
			if ColorPickerSettings.Icon then
				local ic = makeIcon(card, ColorPickerSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16, 0, 25)
					textX = 44
				end
			end
			local label = create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, textX, 0, 25),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font=FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ColorPickerSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3", "TextBody")

			local ColorPicker = {
				Type = "ColorPicker",
				Color = color,
			}

			local h, s, v = color:ToHSV()
			local open = false
			local push, refresh

			local sv = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 25),
				Size = UDim2.fromOffset(42, 26),
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Parent = card,
			})
			round(sv, 9)
			create("UIStroke", {Color = Theme.Stroke, Transparency = 0.85, Parent = sv})
			local svGlow = softGlow(sv, color, 0.4, 30, 0)
			local glowOn = ColorPickerSettings.Glow ~= false
			if not glowOn then glowSet(svGlow, 0) end

			local satOverlay = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})
			round(satOverlay, 9)
			create("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Parent = satOverlay,
			})
			local valOverlay = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})
			round(valOverlay, 9)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
				Parent = valOverlay,
			})
			local svPoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = color,
				Visible = false,
				Parent = sv,
			})
			roundFull(svPoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = svPoint})

			local display = create("Frame", {
				BackgroundColor3 = color,
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})
			round(display, 9)

			local svHit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})

			local hueBar = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 25),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Parent = card,
			})
			roundFull(hueBar)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
				Parent = hueBar,
			})
			local huePoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Visible = false,
				Parent = hueBar,
			})
			roundFull(huePoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = huePoint})
			local hueHit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = hueBar,
			})

			local revealers = {}
			local function addReveal(inst, prop, shown)
				table.insert(revealers, {inst = inst, prop = prop, shown = shown})
				inst[prop] = 1
			end
			local sliders = {}
			local function addSlide(inst, x, openY, closedY)
				table.insert(sliders, {inst = inst, x = x, openY = openY, closedY = closedY})
				inst.Position = UDim2.new(0, x, 0, closedY)
			end

			local function makeField(letter, boxX, y, boxW, initial)
				local box = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(boxW, 30),
					BackgroundTransparency = 1,
					Parent = card,
				})
				paint(box, "BackgroundColor3", "CardInset")
				round(box, 8)
				local st = create("UIStroke", {Color = Theme.Stroke, Transparency = 1, Parent = box})
				local inset = 10
				if letter then
					local lab = create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(10, 0),
						Size = UDim2.new(0, 12, 1, 0),
						Font = FONT_MEDIUM,
						TextSize = 12,
						Text = letter,
						TextTransparency = 1,
						Parent = box,
					})
					paint(lab, "TextColor3", "TextMuted")
					addReveal(lab, "TextTransparency", 0)
					inset = 26
				end
				local tb = create("TextBox", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, inset, 0, 0),
					Size = UDim2.new(1, -inset - 6, 1, 0),
					Font = FONT_MEDIUM,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ClearTextOnFocus = false,
					Text = initial,
					TextTransparency = 1,
					Parent = box,
				})
				paint(tb, "TextColor3", "TextBody")
				addReveal(box, "BackgroundTransparency", 0)
				addReveal(st, "Transparency", 0.85)
				addReveal(tb, "TextTransparency", 0)
				addSlide(box, boxX, y, y + 16)
				tb.Focused:Connect(function()
					tween(st, TI_FAST, {Color = Theme.Accent, Transparency = 0.25})
				end)
				tb.FocusLost:Connect(function()
					tween(st, TI_FAST, {Color = Theme.Stroke, Transparency = 0.85})
				end)
				return tb
			end

			local hexTb = makeField(nil, 16, 70, 168, "#FFFFFF")
			local rTb = makeField("R", 16, 112, 52, "255")
			local gTb = makeField("G", 74, 112, 52, "255")
			local bTb = makeField("B", 132, 112, 52, "255")

			local preview = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(168, 32),
				BackgroundColor3 = color,
				BackgroundTransparency = 1,
				Parent = card,
			})
			round(preview, 10)
			local previewStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 1, Parent = preview})
			addReveal(preview, "BackgroundTransparency", 0)
			addReveal(previewStroke, "Transparency", 0.85)
			addSlide(preview, 16, 155, 171)

			local presetColors = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(255, 59, 48),
				Color3.fromRGB(255, 159, 10),
				Color3.fromRGB(255, 214, 10),
				Color3.fromRGB(52, 199, 89),
				Color3.fromRGB(10, 132, 255),
				Color3.fromRGB(191, 90, 242),
			}
			for idx, presetColor in ipairs(presetColors) do
				local dot = create("TextButton", {
					Text = "",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = presetColor,
					BackgroundTransparency = 1,
					Parent = card,
				})
				roundFull(dot)
				local dotStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 1, Parent = dot})
				addReveal(dot, "BackgroundTransparency", 0)
				addReveal(dotStroke, "Transparency", 0.8)
				addSlide(dot, 25 + (idx - 1) * 25, 188, 204)
				dot.MouseEnter:Connect(function()
					if open then tween(dot, TI_FAST, {Size = UDim2.fromOffset(22, 22)}) end
				end)
				dot.MouseLeave:Connect(function()
					tween(dot, TI_FAST, {Size = UDim2.fromOffset(18, 18)})
				end)
				dot.MouseButton1Click:Connect(function()
					if not open then return end
					h, s, v = presetColor:ToHSV()
					refresh()
					push(true)
				end)
			end

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})

			push = function(fire)
				local c = Color3.fromHSV(h, s, v)
				ColorPicker.Color = c
				if fire then
					runCallback(ColorPickerSettings.Callback, c)
					saveConfiguration()
				end
			end

			refresh = function()
				local hueColor = Color3.fromHSV(h, 1, 1)
				sv.BackgroundColor3 = hueColor
				local c = Color3.fromHSV(h, s, v)
				display.BackgroundColor3 = c
				svPoint.BackgroundColor3 = c
				svPoint.Position = UDim2.new(s, 0, 1 - v, 0)
				huePoint.BackgroundColor3 = hueColor
				huePoint.Position = UDim2.new(h, 0, 0.5, 0)
				preview.BackgroundColor3 = c
				glowColor(svGlow, c)
				ColorPicker.Color = c
				local r = math.floor(c.R * 255 + 0.5)
				local g = math.floor(c.G * 255 + 0.5)
				local b = math.floor(c.B * 255 + 0.5)
				if not rTb:IsFocused() then rTb.Text = tostring(r) end
				if not gTb:IsFocused() then gTb.Text = tostring(g) end
				if not bTb:IsFocused() then bTb.Text = tostring(b) end
				if not hexTb:IsFocused() then hexTb.Text = string.format("#%02X%02X%02X", r, g, b) end
			end

			local function setOpen(state)
				if state == open then return end
				open = state
				if open then
					tween(card, EXPO, {Size = UDim2.new(1, 0, 0, EXPANDED_H)})
					tween(clicker, EXPO, {Size = UDim2.new(1, 0, 0, COLLAPSED_H)})
					tween(sv, EXPO_FAST, {Size = UDim2.fromOffset(18, 15)})
					task.delay(0.09, function()
						if open then
							tween(sv, EXPO, {Position = UDim2.new(1, -16, 0, SV_CY), Size = UDim2.fromOffset(SV_W, SV_H)})
						end
					end)
					tween(display, EXPO, {BackgroundTransparency = 1})
					svPoint.Visible = true
					huePoint.Visible = true
					tween(hueBar, EXPO, {Position = UDim2.new(1, -16, 0, HUE_CY), Size = UDim2.fromOffset(SV_W, 14), BackgroundTransparency = 0})
					for _, r in ipairs(revealers) do tween(r.inst, EXPO, {[r.prop] = r.shown}) end
					for _, sl in ipairs(sliders) do tween(sl.inst, EXPO, {Position = UDim2.new(0, sl.x, 0, sl.openY)}) end
				else
					tween(card, EXPO, {Size = UDim2.new(1, 0, 0, COLLAPSED_H)})
					tween(clicker, EXPO, {Size = UDim2.fromScale(1, 1)})
					tween(sv, EXPO, {Position = UDim2.new(1, -16, 0, 25), Size = UDim2.fromOffset(42, 26)})
					tween(display, EXPO, {BackgroundTransparency = 0})
					svPoint.Visible = false
					huePoint.Visible = false
					tween(hueBar, EXPO, {Position = UDim2.new(1, -16, 0, 25), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1})
					for _, r in ipairs(revealers) do tween(r.inst, EXPO, {[r.prop] = 1}) end
					for _, sl in ipairs(sliders) do tween(sl.inst, EXPO, {Position = UDim2.new(0, sl.x, 0, sl.closedY)}) end
				end
			end
			clicker.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			local svDragging = false
			local function svFromInput(px, py)
				local ax = math.clamp((px - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
				local ay = math.clamp((py - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
				s = ax
				v = 1 - ay
				refresh()
				push(true)
			end
			svHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = true
					svFromInput(input.Position.X, input.Position.Y)
				end
			end)

			local hueDragging = false
			local function hueFromInput(px)
				h = math.clamp((px - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
				refresh()
				push(true)
			end
			hueHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					hueDragging = true
					hueFromInput(input.Position.X)
				end
			end)

			connect(UserInputService.InputChanged, function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					if svDragging then svFromInput(input.Position.X, input.Position.Y) end
					if hueDragging then hueFromInput(input.Position.X) end
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = false
					hueDragging = false
				end
			end)

			hexTb.FocusLost:Connect(function()
				local txt = string.gsub(hexTb.Text, "#", "")
				local rr, gg, bb = string.match(txt, "^(%x%x)(%x%x)(%x%x)$")
				if rr then
					h, s, v = Color3.fromRGB(tonumber(rr, 16), tonumber(gg, 16), tonumber(bb, 16)):ToHSV()
					refresh()
					push(true)
				else
					refresh()
				end
			end)
			local function commitRGB()
				local base = Color3.fromHSV(h, s, v)
				local rr = math.clamp(math.floor(tonumber(rTb.Text) or (base.R * 255 + 0.5)), 0, 255)
				local gg = math.clamp(math.floor(tonumber(gTb.Text) or (base.G * 255 + 0.5)), 0, 255)
				local bb = math.clamp(math.floor(tonumber(bTb.Text) or (base.B * 255 + 0.5)), 0, 255)
				h, s, v = Color3.fromRGB(rr, gg, bb):ToHSV()
				refresh()
				push(true)
			end
			rTb.FocusLost:Connect(commitRGB)
			gTb.FocusLost:Connect(commitRGB)
			bTb.FocusLost:Connect(commitRGB)

			function ColorPicker:Set(newColor)
				h, s, v = newColor:ToHSV()
				refresh()
			end

			function ColorPicker:SetGlow(state)
				glowOn = state ~= false
				glowSet(svGlow, glowOn and 1 or 0, TI_FAST)
			end

			if ColorPickerSettings.Flag then
				ColorPicker.Flag = ColorPickerSettings.Flag
				RayfieldLibrary.Flags[ColorPickerSettings.Flag] = ColorPicker
			end

			refresh()
			return ColorPicker
		end

		function Tab:CreateGradientPicker(GradientSettings)
			GradientSettings = GradientSettings or {}
			local COLLAPSED_H = 50
			local EXPANDED_H = 256
			local SV_W, SV_H, SV_CY = 180, 76, 176
			local HUE_CY = 228
			local EXPO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local EXPO_FAST = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local MAX_STOPS = 12

			local stops = {}
			local function addStopRaw(pos, color)
				local hh, ss, vv = color:ToHSV()
				table.insert(stops, {Pos = math.clamp(pos, 0, 1), H = hh, S = ss, V = vv})
			end
			local function loadFromSequence(seq)
				stops = {}
				for _, kp in ipairs(seq.Keypoints) do
					addStopRaw(kp.Time, kp.Value)
				end
			end
			if typeof(GradientSettings.Color) == "ColorSequence" then
				loadFromSequence(GradientSettings.Color)
			elseif type(GradientSettings.Colors) == "table" and #GradientSettings.Colors >= 2 then
				local n = #GradientSettings.Colors
				for i, c in ipairs(GradientSettings.Colors) do
					if typeof(c) == "Color3" then addStopRaw((i - 1) / (n - 1), c) end
				end
			end
			if #stops < 2 then
				stops = {}
				addStopRaw(0, Color3.fromRGB(74, 178, 124))
				addStopRaw(1, Color3.fromRGB(70, 130, 220))
			end

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, COLLAPSED_H),
				ClipsDescendants = true,
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", GradientSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			hoverable(card)

			local textX = 17
			if GradientSettings.Icon then
				local ic = makeIcon(card, GradientSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16, 0, 25)
					textX = 44
				end
			end
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, textX, 0, 25),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = GradientSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3", "TextBody")

			local GradientPicker = {Type = "GradientPicker"}
			local selIdx = 1
			local open = false
			local push, refresh, refreshSelection
			local handleFrames = {}
			local railDragIdx = nil

			local function buildSequence()
				local sorted = {}
				for _, st in ipairs(stops) do table.insert(sorted, st) end
				table.sort(sorted, function(a, b) return a.Pos < b.Pos end)
				local kps = {}
				local lastT = -1
				for _, st in ipairs(sorted) do
					local t = math.clamp(st.Pos, 0, 1)
					if t <= lastT then t = math.min(1, lastT + 0.0012) end
					lastT = t
					table.insert(kps, ColorSequenceKeypoint.new(t, Color3.fromHSV(st.H, st.S, st.V)))
				end
				if kps[1].Time > 0 then
					table.insert(kps, 1, ColorSequenceKeypoint.new(0, kps[1].Value))
				end
				if kps[#kps].Time < 1 then
					table.insert(kps, ColorSequenceKeypoint.new(1, kps[#kps].Value))
				end
				local ok, seq = pcall(ColorSequence.new, kps)
				if ok then return seq end
				return ColorSequence.new(kps[1].Value, kps[#kps].Value)
			end

			-- collapsed swatch that morphs into the full preview bar
			local previewBar = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 25),
				Size = UDim2.fromOffset(46, 26),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = card,
			})
			round(previewBar, 9)
			local previewGrad = create("UIGradient", {Parent = previewBar})
			create("UIStroke", {Color = Theme.Stroke, Transparency = 0.85, Parent = previewBar})
			local pvGlow = softGlow(previewBar, Color3.fromHSV(stops[1].H, stops[1].S, stops[1].V), 0.4, 30, 0)
			local glowOn = GradientSettings.Glow ~= false
			if not glowOn then glowSet(pvGlow, 0) end

			-- stops rail
			local rail = create("TextButton", {
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 116),
				Size = UDim2.new(1, -32, 0, 24),
				AutoButtonColor = false,
				Parent = card,
			})
			paint(rail, "BackgroundColor3", "CardInset")
			round(rail, 8)
			create("UIStroke", {Color = Theme.Stroke, Transparency = 0.9, Parent = rail})

			-- SV square (edits the selected stop)
			local sv = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, SV_CY),
				Size = UDim2.fromOffset(SV_W, SV_H),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = card,
			})
			round(sv, 10)
			create("UIStroke", {Color = Theme.Stroke, Transparency = 0.85, Parent = sv})
			local satOverlay = create("Frame", {BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.fromScale(1, 1), Parent = sv})
			round(satOverlay, 10)
			create("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
				Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
				Parent = satOverlay,
			})
			local valOverlay = create("Frame", {BackgroundColor3 = Color3.fromRGB(0, 0, 0), Size = UDim2.fromScale(1, 1), Parent = sv})
			round(valOverlay, 10)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
				Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
				Parent = valOverlay,
			})
			local svPoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = sv,
			})
			roundFull(svPoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = svPoint})
			local svHit = create("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = sv})

			-- hue bar
			local hueBar = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, HUE_CY),
				Size = UDim2.fromOffset(SV_W, 14),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = card,
			})
			roundFull(hueBar)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
				Parent = hueBar,
			})
			local huePoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.fromRGB(255, 0, 0),
				Parent = hueBar,
			})
			roundFull(huePoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = huePoint})
			local hueHit = create("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = hueBar})

			-- left column buttons
			local function makeBtn(text, iconPath, y)
				local btn = create("TextButton", {
					Text = "",
					AnchorPoint = Vector2.new(0, 0),
					Position = UDim2.new(0, 16, 0, y),
					Size = UDim2.fromOffset(150, 34),
					AutoButtonColor = false,
					Parent = card,
				})
				paint(btn, "BackgroundColor3", "CardInset")
				round(btn, 9)
				local row = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					Parent = btn,
				})
				create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 7), Parent = row})
				local ic = makeIcon(row, iconPath, 15, Theme.TextBody, 0)
				if ic then ic.LayoutOrder = 1 end
				local lbl = create("TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Font = FONT_MEDIUM, TextSize = 13, Text = text, LayoutOrder = 2, Parent = row})
				paint(lbl, "TextColor3", "TextBody")
				btn.MouseEnter:Connect(function() if open then tween(btn, TI_FAST, {BackgroundColor3 = Theme.CardSelected}) end end)
				btn.MouseLeave:Connect(function() tween(btn, TI_FAST, {BackgroundColor3 = Theme.CardInset}) end)
				return btn
			end
			local addBtn = makeBtn("Add stop", "plus", 138)
			local removeBtn = makeBtn("Remove stop", "trash-2", 178)

			local clicker = create("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = card})

			local function colorAt(pos)
				local sorted = {}
				for _, st in ipairs(stops) do table.insert(sorted, st) end
				table.sort(sorted, function(a, b) return a.Pos < b.Pos end)
				local lo, hi = sorted[1], sorted[#sorted]
				for i = 1, #sorted - 1 do
					if pos >= sorted[i].Pos and pos <= sorted[i + 1].Pos then
						lo, hi = sorted[i], sorted[i + 1]
						break
					end
				end
				local t = (hi.Pos == lo.Pos) and 0 or (pos - lo.Pos) / (hi.Pos - lo.Pos)
				local c1 = Color3.fromHSV(lo.H, lo.S, lo.V)
				local c2 = Color3.fromHSV(hi.H, hi.S, hi.V)
				return c1:Lerp(c2, math.clamp(t, 0, 1))
			end

			refreshSelection = function()
				for i, hd in ipairs(handleFrames) do
					local isSel = i == selIdx
					tween(hd, TI_FAST, {Size = UDim2.fromOffset(isSel and 21 or 16, isSel and 21 or 16)})
					local st = hd:FindFirstChildOfClass("UIStroke")
					if st then
						tween(st, TI_FAST, {Color = isSel and Theme.Accent or Color3.fromRGB(255, 255, 255), Thickness = isSel and 3 or 2.5})
					end
				end
			end

			refresh = function()
				previewGrad.Color = buildSequence()
				glowColor(pvGlow, colorAt(0.5))
				local st = stops[selIdx]
				local hueColor = Color3.fromHSV(st.H, 1, 1)
				sv.BackgroundColor3 = hueColor
				svPoint.BackgroundColor3 = Color3.fromHSV(st.H, st.S, st.V)
				svPoint.Position = UDim2.new(st.S, 0, 1 - st.V, 0)
				huePoint.BackgroundColor3 = hueColor
				huePoint.Position = UDim2.new(st.H, 0, 0.5, 0)
				for i, hd in ipairs(handleFrames) do
					if stops[i] then
						hd.BackgroundColor3 = Color3.fromHSV(stops[i].H, stops[i].S, stops[i].V)
						hd.Position = UDim2.new(stops[i].Pos, 0, 0.5, 0)
					end
				end
				GradientPicker.Value = buildSequence()
			end

			push = function(fire)
				GradientPicker.Value = buildSequence()
				if fire then
					runCallback(GradientSettings.Callback, GradientPicker.Value)
					saveConfiguration()
				end
			end

			local function makeHandle(i)
				local hd = create("TextButton", {
					Text = "",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(stops[i].Pos, 0, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					BackgroundColor3 = Color3.fromHSV(stops[i].H, stops[i].S, stops[i].V),
					AutoButtonColor = false,
					ZIndex = 3,
					Parent = rail,
				})
				round(hd, 5)
				create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2.5, Parent = hd})
				hd.InputBegan:Connect(function(input)
					if not open then return end
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						selIdx = i
						railDragIdx = i
						refreshSelection()
						refresh()
					end
				end)
				return hd
			end
			local function rebuildHandles()
				for _, hd in ipairs(handleFrames) do hd:Destroy() end
				handleFrames = {}
				for i = 1, #stops do
					handleFrames[i] = makeHandle(i)
				end
				refreshSelection()
			end
			rebuildHandles()

			rail.MouseButton1Click:Connect(function()
				if not open then return end
				if #stops >= MAX_STOPS then return end
				local rel = math.clamp((UserInputService:GetMouseLocation().X - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
				addStopRaw(rel, colorAt(rel))
				selIdx = #stops
				rebuildHandles()
				refresh()
				push(true)
			end)

			addBtn.MouseButton1Click:Connect(function()
				if not open or #stops >= MAX_STOPS then return end
				addStopRaw(0.5, colorAt(0.5))
				selIdx = #stops
				rebuildHandles()
				refresh()
				push(true)
			end)
			removeBtn.MouseButton1Click:Connect(function()
				if not open or #stops <= 2 then return end
				table.remove(stops, selIdx)
				selIdx = math.max(1, selIdx - 1)
				rebuildHandles()
				refresh()
				push(true)
			end)

			local function setOpen(state)
				if state == open then return end
				open = state
				if open then
					tween(card, EXPO, {Size = UDim2.new(1, 0, 0, EXPANDED_H)})
					tween(clicker, EXPO, {Size = UDim2.new(1, 0, 0, COLLAPSED_H)})
					tween(previewBar, EXPO, {Position = UDim2.new(1, -16, 0, 77), Size = UDim2.new(1, -32, 0, 30)})
				else
					tween(card, EXPO, {Size = UDim2.new(1, 0, 0, COLLAPSED_H)})
					tween(clicker, EXPO, {Size = UDim2.fromScale(1, 1)})
					tween(previewBar, EXPO, {Position = UDim2.new(1, -16, 0, 25), Size = UDim2.fromOffset(46, 26)})
				end
			end
			clicker.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			local svDragging = false
			local function svFromInput(px, py)
				local ax = math.clamp((px - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
				local ay = math.clamp((py - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
				stops[selIdx].S = ax
				stops[selIdx].V = 1 - ay
				refresh()
				push(true)
			end
			svHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = true
					svFromInput(input.Position.X, input.Position.Y)
				end
			end)
			local hueDragging = false
			local function hueFromInput(px)
				stops[selIdx].H = math.clamp((px - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
				refresh()
				push(true)
			end
			hueHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					hueDragging = true
					hueFromInput(input.Position.X)
				end
			end)

			connect(UserInputService.InputChanged, function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					if svDragging then svFromInput(input.Position.X, input.Position.Y) end
					if hueDragging then hueFromInput(input.Position.X) end
					if railDragIdx and stops[railDragIdx] then
						stops[railDragIdx].Pos = math.clamp((input.Position.X - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
						refresh()
						push(true)
					end
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = false
					hueDragging = false
					railDragIdx = nil
				end
			end)

			function GradientPicker:Set(data)
				if typeof(data) == "ColorSequence" then
					loadFromSequence(data)
				elseif type(data) == "table" then
					stops = {}
					for _, e in ipairs(data) do
						if e.Color and typeof(e.Color) == "Color3" then
							addStopRaw(e.Pos or e.T or 0, e.Color)
						elseif e.R then
							addStopRaw(e.T or e.Pos or 0, Color3.fromRGB(e.R, e.G or 0, e.B or 0))
						end
					end
				end
				if #stops < 2 then
					stops = {}
					addStopRaw(0, Color3.fromRGB(74, 178, 124))
					addStopRaw(1, Color3.fromRGB(70, 130, 220))
				end
				selIdx = math.clamp(selIdx, 1, #stops)
				rebuildHandles()
				refresh()
			end
			function GradientPicker:Serialize()
				local out = {}
				for _, st in ipairs(stops) do
					local c = Color3.fromHSV(st.H, st.S, st.V)
					table.insert(out, {T = st.Pos, R = math.floor(c.R * 255 + 0.5), G = math.floor(c.G * 255 + 0.5), B = math.floor(c.B * 255 + 0.5)})
				end
				return out
			end
			function GradientPicker:SetGlow(state)
				glowOn = state ~= false
				glowSet(pvGlow, glowOn and 1 or 0, TI_FAST)
			end

			if GradientSettings.Flag then
				GradientPicker.Flag = GradientSettings.Flag
				RayfieldLibrary.Flags[GradientSettings.Flag] = GradientPicker
			end

			refresh()
			return GradientPicker
		end




		function Tab:CreateRow()
			local rowFrame = create("Frame",{
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			rowFrame:SetAttribute("Composite", true)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment=Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = rowFrame,
			})
			local function recompute()
				local kids = {}
				for _, c in ipairs(rowFrame:GetChildren()) do
					if c:IsA("GuiObject") then table.insert(kids, c) end
				end
				local n = #kids
				if n == 0 then return end
				local adj = math.floor(8 * (n - 1) / n + 0.5)
				for _, c in ipairs(kids) do
					c.Size=UDim2.new(1 / n, -adj, 0, c.Size.Y.Offset)
				end
			end
			rowFrame.ChildAdded:Connect(function()
				task.defer(recompute);
			end)
			return buildTabAPI(rowFrame, true)
		end

		function Tab:CreateColumns(count)
			count = math.clamp(count or 2, 1, 4)
			local container = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			container:SetAttribute("Composite", true)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0,10),
				Parent = container,
			})
			local apis = {}
			local adj = math.floor(10 * (count - 1) / count + 0.5)
			for i = 1, count do
				local column = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1 / count, -adj,0, 0),
					LayoutOrder = i,
					Parent = container,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder=Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0,8),
					Parent = column,
				})
				table.insert(apis, buildTabAPI(column, true))
			end
			return table.unpack(apis)
		end

		-- Hold-to-confirm button: fill sweeps across while held; fires only if
		-- held the full duration. Safer than a tap for risky actions.
		function Tab:CreateHoldButton(HoldSettings)
			HoldSettings = HoldSettings or {}
			local duration = math.clamp(tonumber(HoldSettings.Duration) or 1.5, 0.2, 10)
			local card, label = makeCard(page, HoldSettings.Name, HoldSettings.Icon, 50)
			descFor(card, HoldSettings.Description or "Press and hold to confirm.")
			tipFor(card, HoldSettings.Tooltip)
			hoverable(card)

			-- CanvasGroup so the sweeping fill is clipped to the card's rounded
			-- corners (ClipsDescendants ignores UICorner, a CanvasGroup does not).
			local fillClip = create("CanvasGroup", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
				Parent = card,
			})
			round(fillClip, GenStyle.cardRadius)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 0, 1, 0),
				ZIndex = 0,
				Parent = fillClip,
			})
			if label then label.ZIndex = 2 end

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
				Parent = card,
			})

			local holding, token = false, 0
			local function reset(animate)
				tween(fill, animate and TI_MED or TweenInfo.new(0), {Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0.55})
			end
			clicker.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					holding = true
					token += 1
					local myToken = token
					tween(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 1)})
					task.delay(duration, function()
						if holding and myToken == token then
							holding = false
							tween(fill, TI_FAST, {BackgroundTransparency = 0.2})
							task.delay(0.14, function() reset(true) end)
							runCallback(HoldSettings.Callback)
						end
					end)
				end
			end)
			local function releaseInput(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if holding then
						holding = false
						token += 1
						reset(true)
					end
				end
			end
			clicker.InputEnded:Connect(releaseInput)
			clicker.MouseLeave:Connect(function()
				if holding then holding = false; token += 1; reset(true) end
			end)

			local HoldValue = {}
			function HoldValue:Set(newName) label.Text = newName; card:SetAttribute("SearchName", newName or "") end
			return HoldValue
		end

		-- Changelog / update log: a titled list of entries, each with a colored
		-- tag ([+] add, [-] remove, [~] change, [*] note).
		function Tab:CreateChangelog(LogSettings)
			LogSettings = LogSettings or {}
			local muted = Color3.fromRGB(150, 152, 160)
			local TAGS = {
				["+"] = { color = Color3.fromRGB(110, 192, 142), word = "ADDED" },
				["-"] = { color = Color3.fromRGB(214, 120, 120), word = "REMOVED" },
				["~"] = { color = Color3.fromRGB(220, 180, 112), word = "CHANGED" },
				["!"] = { color = Color3.fromRGB(122, 166, 226), word = "FIXED" },
				["*"] = { color = muted, word = "NOTE" },
			}

			-- refined release-notes panel: a header, a hairline, then a timeline
			-- of entries with a small node dot, small-caps category, and body text
			local card = create("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", (LogSettings.Title or "changelog"))
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			padAll(card, 17, 20, 16, 20)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 14),
				Parent = card,
			})

			-- header: title on the left, a quiet version / date on the right
			local head = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				LayoutOrder = 1,
				Parent = card,
			})
			local htitle = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0.6, 0, 1, 0),
				Font = FONT_BOLD,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = LogSettings.Title or "Update Log",
				Parent = head,
			})
			paint(htitle, "TextColor3", "TextTitle")
			local metaParts = {}
			if LogSettings.Version then table.insert(metaParts, tostring(LogSettings.Version)) end
			if LogSettings.Date then table.insert(metaParts, tostring(LogSettings.Date)) end
			if #metaParts > 0 then
				local meta = create("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0.4, 0, 1, 0),
					Font = FONT_MEDIUM,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = table.concat(metaParts, "  \u{00B7}  "),
					Parent = head,
				})
				paint(meta, "TextColor3", "TextSub")
			end
			create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.92,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				Parent = card,
			})

			for i, e in ipairs(LogSettings.Entries or {}) do
				local etype = (type(e) == "table" and (e.Type or e.Tag)) or "*"
				local text = (type(e) == "table" and e.Text) or tostring(e)
				local m = TAGS[etype] or TAGS["*"]
				local word = (type(e) == "table" and e.Label) or m.word

				local row = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = i + 2,
					Parent = card,
				})
				row:SetAttribute("SearchName", text)
				-- The body is top-aligned; its first line is centered at ~LINE/2.
				-- The dot and category are centered on that same line so all three
				-- align, and multi-line entries keep wrapping cleanly below.
				local LINE = 18
				-- timeline node dot, on the first line
				local dot = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 4, 0, LINE / 2),
					Size = UDim2.fromOffset(7, 7),
					BackgroundColor3 = m.color,
					BorderSizePixel = 0,
					Parent = row,
				})
				roundFull(dot)
				-- small-caps category, quietly colored
				create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 0),
					Size = UDim2.new(0, 74, 0, LINE),
					Font = FONT_BOLD,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					Text = string.upper(tostring(word)),
					TextColor3 = m.color:Lerp(muted, 0.35),
					Parent = row,
				})
				-- body text, top-aligned so the first line sits in the LINE box
				local lbl = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(100, 0),
					Size = UDim2.new(1, -100, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Font = FONT_MEDIUM,
					TextSize = 14,
					LineHeight = 1.28,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					Text = text,
					Parent = row,
				})
				paint(lbl, "TextColor3", "TextBody")
			end

			local LogValue = {}
			return LogValue
		end

		-- Collapsible section: a clickable header that folds a container of
		-- elements. Returns a Tab-like API you add elements into.
		function Tab:CreateCollapsibleSection(SectionSettings)
			SectionSettings = SectionSettings or {}
			local name = SectionSettings.Name or SectionSettings.Title or "Section"
			local open = SectionSettings.Open ~= false

			local header, hlabel = makeCard(page, name, SectionSettings.Icon, 42)
			header.BackgroundTransparency = 0.4
			if hlabel then hlabel.Font = FONT_BOLD end
			hoverable(header)
			local chevron = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ImageColor3 = Theme.TextSub,
				Parent = header,
			})
			applyLucide(chevron, {"chevron-down"})
			local hclick = create("TextButton", {
				BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = header,
			})

			local content = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			content:SetAttribute("Composite", true)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = content,
			})

			local function apply(animate)
				if open then
					content.Visible = true
					content.AutomaticSize = Enum.AutomaticSize.Y
				else
					content.AutomaticSize = Enum.AutomaticSize.None
					content.Size = UDim2.new(1, 0, 0, 0)
					content.Visible = false
				end
				tween(chevron, animate and TI_MED or TweenInfo.new(0), {Rotation = open and 0 or -90})
			end
			apply(false)
			hclick.MouseButton1Click:Connect(function()
				open = not open
				apply(true)
			end)

			local api = buildTabAPI(content, false)
			function api:SetOpen(state) open = state and true or false; apply(true) end
			function api:Toggle() open = not open; apply(true) end
			function api:IsOpen() return open end
			return api
		end

		-- A spoiler. Hides its content (text and/or nested elements) behind a
		-- blur-ish cover; the user taps the cover to reveal it, and taps the eye
		-- to hide it again. Pass Text for a quick text spoiler, or add elements
		-- to the returned container to hide a whole group.
		function Tab:CreateSpoiler(SpoilerSettings)
			SpoilerSettings = SpoilerSettings or {}
			local name = SpoilerSettings.Name or SpoilerSettings.Title or "Spoiler"
			local revealed = SpoilerSettings.Revealed == true

			local card = create("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", name .. " " .. tostring(SpoilerSettings.Text or ""))
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			padAll(card, 12, 12, 12, 14)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 9),
				Parent = card,
			})

			-- header: label on the left, an eye toggle on the right
			local header = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 1,
				Parent = card,
			})
			local hlabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, -30, 0, 18),
				Font = FONT_MEDIUM,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = name,
				Parent = header,
			})
			paint(hlabel, "TextColor3", "TextBody")
			local eyeBtn = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(24, 24),
				Parent = header,
			})
			local eyeIcon = makeIcon(eyeBtn, "eye-off", 17, Theme.TextSub)
			if eyeIcon then
				eyeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				eyeIcon.Position = UDim2.fromScale(0.5, 0.5)
			end

			-- content lives in a wrapper the cover can overlay exactly
			local wrap = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = 2,
				Parent = card,
			})
			local content = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				ZIndex = 1,
				Parent = wrap,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = content,
			})

			-- optional inline spoiler text
			if SpoilerSettings.Text and SpoilerSettings.Text ~= "" then
				local txt = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					Font = FONT_REGULAR,
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = SpoilerSettings.Text,
					LayoutOrder = 1,
					ZIndex = 1,
					Parent = content,
				})
				paint(txt, "TextColor3", "TextBody")
			end

			-- container for nested elements (elements build into this frame)
			local inner = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = 2,
				ZIndex = 1,
				Parent = content,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = inner,
			})

			-- the cover: a CanvasGroup so we can fade the whole thing at once.
			-- It sits on top of the content and swallows clicks while hidden.
			local cover = create("CanvasGroup", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.CardInset,
				GroupTransparency = 0,
				ZIndex = 4,
				Parent = wrap,
			})
			paint(cover, "BackgroundColor3", "CardInset")
			round(cover, GenStyle.cardRadius)
			local coverStroke = create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1, Parent = cover })
			paint(coverStroke, "Color", "Stroke")
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(216, 216, 216)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.92),
					NumberSequenceKeypoint.new(1, 0.98),
				}),
				Parent = cover,
			})
			-- centered "tap to reveal" hint
			local hint = create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(180, 20),
				ZIndex = 5,
				Parent = cover,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = hint,
			})
			local hintIcon = makeIcon(hint, "eye", 14, Theme.TextSub)
			if hintIcon then hintIcon.LayoutOrder = 1; hintIcon.ZIndex = 5 end
			local hintLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 20),
				Font = FONT_MEDIUM,
				TextSize = 13,
				Text = SpoilerSettings.RevealText or "Tap to reveal",
				LayoutOrder = 2,
				ZIndex = 5,
				Parent = hint,
			})
			paint(hintLabel, "TextColor3", "TextSub")
			local coverBtn = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 6,
				Parent = cover,
			})

			local revealEpoch = 0
			local function apply(state, animate)
				revealed = state and true or false
				if eyeIcon then applyLucide(eyeIcon, revealed and "eye" or "eye-off") end
				if revealed then
					coverBtn.Active = false
					if animate then
						revealEpoch = revealEpoch + 1
						local e = revealEpoch
						tween(cover, TI_MED, { GroupTransparency = 1 })
						task.delay(0.3, function()
							if e == revealEpoch and revealed then cover.Visible = false end
						end)
					else
						cover.GroupTransparency = 1
						cover.Visible = false
					end
				else
					revealEpoch = revealEpoch + 1
					coverBtn.Active = true
					cover.Visible = true
					if animate then
						cover.GroupTransparency = 1
						tween(cover, TI_MED, { GroupTransparency = 0 })
					else
						cover.GroupTransparency = 0
					end
				end
			end
			apply(revealed, false)

			coverBtn.MouseButton1Click:Connect(function() apply(true, true) end)
			eyeBtn.MouseButton1Click:Connect(function() apply(not revealed, true) end)

			local api = buildTabAPI(inner, false)
			api.Card = card
			function api:Reveal() apply(true, true) end
			function api:Hide() apply(false, true) end
			function api:Toggle() apply(not revealed, true) end
			function api:IsRevealed() return revealed end
			function api:SetText(t)
				for _, child in ipairs(content:GetChildren()) do
					if child:IsA("TextLabel") then child.Text = tostring(t or ""); break end
				end
			end
			return api
		end

		-- Built-in AI chat. Works out of the box through a free, rate-limited
		-- provider (no API key needed). Users can plug in their own
		-- OpenAI-compatible keys; keys stack, and when one fails the chat asks
		-- before switching to the next.
		function Tab:CreateAIChat(ChatSettings)
			ChatSettings = ChatSettings or {}
			local HEIGHT = math.clamp(tonumber(ChatSettings.Height) or 300, 220, 480)
			local sysPrompt = ChatSettings.SystemPrompt
				or "You are a concise assistant inside a Roblox script menu. Answer briefly and helpfully. Keep answers under 80 words unless asked for more."
			local model = ChatSettings.Model or "gpt-4o-mini"
			local endpoint = ChatSettings.Endpoint or "https://api.openai.com/v1/chat/completions"
			local freeModel = ChatSettings.FreeModel or "openai-fast"
			local gameAware = ChatSettings.GameAware ~= false
			local extraContext = ChatSettings.Context
			-- per-chat keys from the constructor; global keys (added in settings)
			-- are appended at request time so both stack
			local ownKeys = {}
			if type(ChatSettings.Keys) == "table" then
				for _, k in ipairs(ChatSettings.Keys) do
					if type(k) == "string" and #k > 0 then table.insert(ownKeys, k) end
				end
			end
			local function allKeys()
				local t = {}
				for _, k in ipairs(ownKeys) do t[#t + 1] = k end
				for _, k in ipairs(aiKeys) do t[#t + 1] = k end
				return t
			end
			local keyCursor = 1      -- position in the current key list
			local forcedFree = false -- true after the user chooses the free provider
			local lastKeyCount = -1  -- adding/removing keys re-enables keyed mode
			local history = {}
			local busy = false
			local sendTimes = {}

			-- in-game actions the AI may trigger (script author wires the callbacks)
			local actions = {}
			if type(ChatSettings.Actions) == "table" then
				for _, a in ipairs(ChatSettings.Actions) do
					if type(a) == "table" and type(a.Name) == "string" and type(a.Callback) == "function" then
						table.insert(actions, { Name = a.Name, Description = tostring(a.Description or ""), Callback = a.Callback })
					end
				end
			end

			-- live game context so the AI actually knows where it is
			local cachedGameName
			local function gameName()
				if cachedGameName then return cachedGameName end
				local ok, info = pcall(function()
					return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
				end)
				cachedGameName = (ok and type(info) == "table" and info.Name) or nil
				return cachedGameName
			end
			if gameAware then task.spawn(gameName) end -- warm the cache before the first question

			local function buildGameContext()
				local parts = {}
				if gameAware then
					pcall(function()
						local gn = gameName()
						table.insert(parts, "Game: " .. (gn or "unknown") .. " (PlaceId " .. tostring(game.PlaceId) .. ")")
						if LocalPlayer then
							table.insert(parts, "Local player: " .. LocalPlayer.Name)
							if LocalPlayer.Team then table.insert(parts, "Team: " .. tostring(LocalPlayer.Team.Name)) end
						end
						local names = {}
						for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
						table.insert(parts, "Players in server (" .. #names .. "): " .. table.concat(names, ", "))
						local ch = LocalPlayer and LocalPlayer.Character
						local hum = ch and ch:FindFirstChildOfClass("Humanoid")
						if hum then
							table.insert(parts, string.format("Health %d/%d, WalkSpeed %d, JumpPower %d",
								math.floor(hum.Health), math.floor(hum.MaxHealth), math.floor(hum.WalkSpeed), math.floor(hum.JumpPower or 0)))
						end
						local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
						if hrp then
							local pos = hrp.Position
							table.insert(parts, string.format("Position (%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z))
						end
					end)
				end
				if type(extraContext) == "function" then
					local ok, extra = pcall(extraContext)
					if ok and type(extra) == "string" and #extra > 0 then table.insert(parts, extra) end
				elseif type(extraContext) == "string" and #extraContext > 0 then
					table.insert(parts, extraContext)
				end
				if #parts == 0 then return nil end
				return "Live game state right now (use it to answer):\n" .. table.concat(parts, "\n")
			end

			local function actionPrompt()
				if #actions == 0 then return nil end
				local lines = { "You can run in-game actions when the user asks you to do something. Available actions:" }
				for _, a in ipairs(actions) do
					table.insert(lines, "- " .. a.Name .. (a.Description ~= "" and (": " .. a.Description) or ""))
				end
				table.insert(lines, 'To run one, put [ACTION:name arguments] on its own in your reply plus one short confirmation sentence. Only use listed actions, never invent one.')
				return table.concat(lines, "\n")
			end

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, HEIGHT),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", ChatSettings.Name or "AI Chat")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)

			-- header: bot icon, title, provider hint
			local headIcon = makeIcon(card, "bot", 18, Theme.TextTitle, 0.04)
			if headIcon then
				headIcon.AnchorPoint = Vector2.new(0, 0.5)
				headIcon.Position = UDim2.fromOffset(16, 23)
			end
			local headLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(44, 13),
				Size = UDim2.new(1, -160, 0, 20),
				Font = FONT_BOLD,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ChatSettings.Name or "AI Chat",
				Parent = card,
			})
			paint(headLabel, "TextColor3", "TextTitle")
			local providerLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -16, 0, 16),
				Size = UDim2.new(0, 110, 0, 14),
				Font = FONT_MEDIUM,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = (#allKeys() > 0) and "key 1" or "built in",
				Parent = card,
			})
			paint(providerLabel, "TextColor3", "TextMuted")

			-- messages
			local INPUT_H = 40
			-- CanvasGroup + gradient so the messages fade out at the scroll edges
			local msgsWrap = create("CanvasGroup", {
				BackgroundTransparency = 1,
				GroupTransparency = 0,
				Position = UDim2.fromOffset(12, 44),
				Size = UDim2.new(1, -24, 1, -44 - INPUT_H - 20),
				Parent = card,
			})
			local msgsFade = create("UIGradient", { Rotation = 90, Parent = msgsWrap })
			local msgs = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 0,
				BorderSizePixel = 0,
				Parent = msgsWrap,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = msgs,
			})
			padAll(msgs, 2, 4, 6, 2)

			local FADE_EDGE = 0.06
			local function updateMsgFade()
				local vh = msgs.AbsoluteWindowSize.Y
				if vh <= 0 then return end
				local pos = msgs.CanvasPosition.Y
				local maxScroll = math.max(0, msgs.AbsoluteCanvasSize.Y - vh)
				local topT = math.clamp(pos / 22, 0, 1)
				local botT = math.clamp((maxScroll - pos) / 22, 0, 1)
				if topT <= 0.001 and botT <= 0.001 then
					msgsFade.Transparency = NumberSequence.new(0)
				else
					msgsFade.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, topT),
						NumberSequenceKeypoint.new(FADE_EDGE, 0),
						NumberSequenceKeypoint.new(1 - FADE_EDGE, 0),
						NumberSequenceKeypoint.new(1, botT),
					})
				end
			end
			msgs:GetPropertyChangedSignal("CanvasPosition"):Connect(updateMsgFade)
			msgs:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateMsgFade)
			msgs:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateMsgFade)
			task.defer(updateMsgFade)

			local msgOrder = 0
			local function scrollBottom()
				task.defer(function()
					if msgs.Parent then
						msgs.CanvasPosition = Vector2.new(0, math.max(0, msgs.AbsoluteCanvasSize.Y - msgs.AbsoluteSize.Y))
					end
					task.defer(updateMsgFade)
				end)
			end

			local function textOnAccent()
				local c = Theme.Accent
				local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
				return lum > 0.6 and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(245, 245, 245)
			end

			-- one chat bubble; user bubbles sit right in accent, AI bubbles left
			-- minimal markdown -> RichText so model replies render nicely
			local function mdToRich(t)
				t = tostring(t)
				t = t:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
				t = t:gsub("%*%*([^\n*]+)%*%*", "<b>%1</b>")
				t = t:gsub("([^%*])%*([^\n*]+)%*([^%*])", "%1<i>%2</i>%3")
				t = t:gsub("`([^\n`]+)`", "<b>%1</b>")
				return t
			end

			local function addBubble(text, isUser, muted)
				msgOrder += 1
				local row = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 10),
					LayoutOrder = msgOrder,
					Parent = msgs,
				})
				local bubble = create("Frame", {
					AnchorPoint = Vector2.new(isUser and 1 or 0, 0),
					Position = isUser and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundColor3 = isUser and Theme.Accent or Theme.CardHover,
					Parent = row,
				})
				round(bubble, 12)
				padAll(bubble, 8, 12, 8, 12)
				local scale = create("UIScale", { Scale = 0.86, Parent = bubble })
				local label = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					Size = UDim2.new(0, 0, 0, 0),
					Font = FONT_MEDIUM,
					TextSize = 14,
					LineHeight = 1.15,
					RichText = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					TextTransparency = 1,
					Text = mdToRich(text),
					TextColor3 = isUser and textOnAccent() or (muted and Theme.TextMuted or Theme.TextBody),
					Parent = bubble,
				})
				create("UISizeConstraint", { MaxSize = Vector2.new(300, math.huge), Parent = label })
				tween(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
				tween(label, TI_MED, { TextTransparency = 0 })
				scrollBottom()
				local B = {}
				function B.setText(t, asMuted)
					label.Text = mdToRich(t)
					label.TextColor3 = isUser and textOnAccent() or (asMuted and Theme.TextMuted or Theme.TextBody)
					scrollBottom()
				end
				return B
			end

			-- input row: rounded box plus a circular accent send button
			local inputHolder = create("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 14, 1, -12),
				Size = UDim2.new(1, -14 - 14 - INPUT_H - 8, 0, INPUT_H - 4),
				Parent = card,
			})
			paint(inputHolder, "BackgroundColor3", "CardInset")
			roundFull(inputHolder)
			create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Parent = inputHolder })
			local box = create("TextBox", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				PlaceholderText = ChatSettings.Placeholder or "Ask anything",
				PlaceholderColor3 = Theme.TextMuted,
				Text = "",
				ClearTextOnFocus = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = inputHolder,
			})
			paint(box, "TextColor3", "TextBody")
			local sendBtn = create("TextButton", {
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -14, 1, -14),
				Size = UDim2.fromOffset(INPUT_H - 4, INPUT_H - 4),
				Text = "",
				BackgroundColor3 = Theme.Accent,
				Parent = card,
			})
			roundFull(sendBtn)
			local sendIcon = makeIcon(sendBtn, "arrow-up", 18, textOnAccent())
			if sendIcon then
				sendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				sendIcon.Position = UDim2.fromScale(0.5, 0.5)
			end

			-- context the model sees
			local function buildMessages()
				local out = { { role = "system", content = sysPrompt } }
				local gc = buildGameContext()
				if gc then table.insert(out, { role = "system", content = gc }) end
				local ap = actionPrompt()
				if ap then table.insert(out, { role = "system", content = ap }) end
				for _, m in ipairs(history) do table.insert(out, m) end
				return out
			end

			-- pull the reply out of a response body, and never mistake a provider
			-- error payload ({"error":...}, "Queue full", ...) for an answer
			local function parseChatBody(body)
				if type(body) ~= "string" or #body == 0 then return nil, "empty response" end
				local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
				if ok and type(data) == "table" then
					if data.error ~= nil then
						local msg = type(data.error) == "table" and (data.error.message or "provider error") or tostring(data.error)
						if string.find(string.lower(msg), "queue full") then msg = "the free AI is busy" end
						return nil, msg
					end
					local content = data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content
					if type(content) == "string" and #content > 0 then return content end
					return nil, "empty response"
				end
				-- plain-text reply; reject bodies that are obviously error blobs
				local low = string.lower(body)
				if string.find(body, '"error"', 1, true) or string.find(low, "queue full", 1, true) then
					return nil, "the free AI is busy"
				end
				return body
			end

			local function keyedRequest(key)
				local res, rerr = httpPost(endpoint, {
					["Content-Type"] = "application/json",
					["Authorization"] = "Bearer " .. key,
				}, { model = model, messages = buildMessages(), max_tokens = 350, temperature = 0.7 })
				if not res then return nil, rerr or "request failed", false end
				local code = tonumber(res.StatusCode or res.status_code) or 0
				if code == 401 or code == 402 or code == 403 or code == 429 then
					return nil, "HTTP " .. code, true -- key problem: exhausted/invalid/rate limited
				end
				if code < 200 or code >= 300 then return nil, "HTTP " .. code, false end
				return parseChatBody(res.Body)
			end

			local function freePost(withModel)
				local res, rerr = httpPost("https://text.pollinations.ai/openai", {
					["Content-Type"] = "application/json",
				}, { model = withModel, messages = buildMessages(), private = true })
				if not res then return nil, rerr or "request failed" end
				local code = tonumber(res.StatusCode or res.status_code) or 0
				if code < 200 or code >= 300 then
					local _, perr = parseChatBody(res.Body or "")
					return nil, perr or ("HTTP " .. code)
				end
				return parseChatBody(res.Body)
			end

			local function freeRequest()
				local altModel = freeModel ~= "openai" and "openai" or "mistral"
				-- primary model, one backoff retry (queue-full clears quickly), then the alternate
				local plan = {
					{ model = freeModel },
					{ model = freeModel, wait = 2.5 },
					{ model = altModel },
				}
				local lastErr = "the free AI service is unreachable"
				for _, step in ipairs(plan) do
					if step.wait then task.wait(step.wait) end
					local reply, err = freePost(step.model)
					if reply then return reply end
					if err then lastErr = err end
				end
				-- plain GET last resort: compact transcript in the prompt
				local lines = { sysPrompt }
				local gc = buildGameContext()
				if gc then table.insert(lines, gc) end
				for _, m in ipairs(history) do
					table.insert(lines, (m.role == "user" and "User: " or "Assistant: ") .. m.content)
				end
				table.insert(lines, "Assistant:")
				local raw = fetch("https://text.pollinations.ai/" .. HttpService:UrlEncode(table.concat(lines, "\n")))
				if raw then
					local reply, err = parseChatBody(raw)
					if reply then return reply end
					if err then lastErr = err end
				end
				return nil, lastErr
			end

			-- blocking yes/no through the dialog. Closing with the X counts as no,
			-- and a 30s timeout closes the dialog and counts as no.
			local function askSwitch(title, content, yesText)
				if not msgs.Parent then return false end -- UI is gone, never resurrect a dialog
				local result = nil
				local handle = RayfieldLibrary:Dialog({
					Title = title,
					Content = content,
					OnClose = function()
						if result == nil then result = false end
					end,
					Options = {
						{ Text = "Cancel", Callback = function() result = false end },
						{ Text = yesText, Primary = true, Callback = function() result = true end },
					},
				})
				local t0 = os.clock()
				while result == nil and os.clock() - t0 < 30 do task.wait(0.1) end
				if result == nil and handle then pcall(handle.Close) end
				return result == true
			end

			local function pushHistory(role, content)
				table.insert(history, { role = role, content = content })
				while #history > 10 do table.remove(history, 1) end
			end

			-- bumped by Clear(); in-flight replies from an older epoch are dropped
			local chatEpoch = 0

			local function send(text)
				text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if text == "" then return end
				if busy then
					addBubble("One message at a time, please.", false, true)
					return
				end
				-- adding/removing keys re-enables keyed mode from the top
				local kcount = #allKeys()
				if kcount ~= lastKeyCount then
					lastKeyCount = kcount
					forcedFree = false
					keyCursor = 1
				end
				local usingKeys = (not forcedFree) and kcount > 0
				providerLabel.Text = usingKeys and ("key " .. keyCursor) or "built in"

				-- rate limit (tighter on the free provider)
				local now = os.clock()
				local minGap = usingKeys and 1.5 or 4
				local perMin = usingKeys and 20 or 8
				for i = #sendTimes, 1, -1 do
					if now - sendTimes[i] > 60 then table.remove(sendTimes, i) end
				end
				if (#sendTimes > 0 and now - sendTimes[#sendTimes] < minGap) or #sendTimes >= perMin then
					addBubble("Slow down a little, then try again.", false, true)
					return
				end
				table.insert(sendTimes, now)

				busy = true
				box.Text = ""
				addBubble(text, true)
				pushHistory("user", text)

				local thinking = addBubble("\u{00B7}", false, true)
				local thinkAlive = true
				local myEpoch = chatEpoch
				task.spawn(function()
					local i = 0
					local frames = { "\u{00B7}", "\u{00B7}\u{00B7}", "\u{00B7}\u{00B7}\u{00B7}" }
					while thinkAlive and msgs.Parent and chatEpoch == myEpoch do
						i = i % 3 + 1
						thinking.setText(frames[i], true)
						task.wait(0.35)
					end
				end)

				task.spawn(function()
					local reply, err
					while true do
						if not msgs.Parent or chatEpoch ~= myEpoch then break end -- UI gone or cleared
						local kl = allKeys()
						if usingKeys and kl[keyCursor] then
							local keyFail
							reply, err, keyFail = keyedRequest(kl[keyCursor])
							if reply or not keyFail then break end
							if not msgs.Parent or chatEpoch ~= myEpoch then break end -- cleared/destroyed while requesting
							if keyCursor < #kl then
								if askSwitch("API key " .. keyCursor .. " failed",
									"That key returned " .. tostring(err) .. ". Switch to key " .. (keyCursor + 1) .. " and retry?",
									"Switch") then
									keyCursor += 1
									providerLabel.Text = "key " .. keyCursor
								else break end
							else
								if askSwitch("All API keys failed",
									"The last key returned " .. tostring(err) .. ". Use the free built-in AI instead?",
									"Use free") then
									usingKeys = false
									forcedFree = true
									providerLabel.Text = "built in"
								else break end
							end
						else
							reply, err = freeRequest()
							break
						end
					end
					thinkAlive = false
					busy = false
					-- drop the reply if the chat was cleared or destroyed meanwhile
					if not msgs.Parent or chatEpoch ~= myEpoch then return end
					if reply then
						reply = tostring(reply):gsub("^%s+", ""):gsub("%s+$", "")
						-- run any [ACTION:name args] the model emitted, then strip them
						local ran = {}
						if #actions > 0 then
							reply = reply:gsub("%[ACTION:%s*([%w_%-]+)%s*([^%]]*)%]", function(aname, aargs)
								for _, a in ipairs(actions) do
									if string.lower(a.Name) == string.lower(aname) then
										table.insert(ran, a.Name)
										task.spawn(function()
											local ok, aerr = pcall(a.Callback, (aargs:gsub("^%s+", "")):gsub("%s+$", ""))
											if not ok then warn("Rayfield Gen3 | AI action error: " .. tostring(aerr)) end
										end)
										break
									end
								end
								return ""
							end)
							reply = reply:gsub("%s+$", ""):gsub("^%s+", "")
						end
						if reply == "" then reply = "Done." end
						thinking.setText(reply, false)
						pushHistory("assistant", reply)
						if #ran > 0 then
							addBubble("Ran: " .. table.concat(ran, ", "), false, true)
						end
					else
						thinking.setText("Could not reply: " .. tostring(err or "unknown error"), true)
					end
				end)
			end

			sendBtn.MouseButton1Click:Connect(function()
				tween(sendBtn, TweenInfo.new(0.07, Enum.EasingStyle.Quad), { BackgroundColor3 = Theme.AccentSoft })
				task.delay(0.09, function() tween(sendBtn, TI_MED, { BackgroundColor3 = Theme.Accent }) end)
				send(box.Text)
			end)
			box.FocusLost:Connect(function(enterPressed)
				if enterPressed then send(box.Text) end
			end)

			if ChatSettings.Greeting ~= false then
				addBubble(type(ChatSettings.Greeting) == "string" and ChatSettings.Greeting or "Hi! Ask me anything.", false)
			end

			local AIChat = { Type = "AIChat" }
			function AIChat:Ask(text) send(text) end
			function AIChat:AddKey(key)
				if type(key) == "string" and #key > 0 then
					table.insert(ownKeys, key)
					forcedFree = false -- prefer keys again
					providerLabel.Text = "key 1"
				end
			end
			function AIChat:Clear()
				chatEpoch += 1 -- invalidates any in-flight reply
				history = {}
				busy = false
				for _, c in ipairs(msgs:GetChildren()) do
					if c:IsA("GuiObject") then c:Destroy() end
				end
				msgOrder = 0
			end
			function AIChat:SetSystemPrompt(p)
				if type(p) == "string" then sysPrompt = p end
			end
			function AIChat:RegisterAction(name, description, callback)
				if type(name) == "string" and type(callback) == "function" then
					table.insert(actions, { Name = name, Description = tostring(description or ""), Callback = callback })
				end
			end
			function AIChat:SetContext(ctx)
				extraContext = ctx
			end
			return AIChat
		end

		-- Elements on demand: every factory's handle gains :SetVisible(state) so
		-- scripts can reveal or hide elements dynamically (e.g. a dropdown choice
		-- showing extra options). We diff the page's children around the factory
		-- call, so an element's card AND its description row hide together.
		do
			local names = {}
			for name, fn in pairs(Tab) do
				if type(fn) == "function" and string.sub(name, 1, 6) == "Create" then
					table.insert(names, name)
				end
			end
			for _, name in ipairs(names) do
				local fn = Tab[name]
				Tab[name] = function(selfArg, ...)
					local before = {}
					for _, c in ipairs(page:GetChildren()) do before[c] = true end
					local rets = table.pack(fn(selfArg, ...))
					local mine = {}
					for _, c in ipairs(page:GetChildren()) do
						if not before[c] and c:IsA("GuiObject") then table.insert(mine, c) end
					end
					local handle = rets[1]
					if type(handle) == "table" and handle.SetVisible == nil and #mine > 0 then
						handle._visibleState = true
						function handle:SetVisible(state)
							state = state and true or false
							handle._visibleState = state
							for _, inst in ipairs(mine) do
								if inst.Parent then
									inst.Visible = state
									inst:SetAttribute("DemandHidden", (not state) or nil)
								end
							end
						end
					end
					return table.unpack(rets, 1, rets.n)
				end
			end
		end

		return Tab
	end

	function Window:CreateTab(tabName, tabImage, _ext)
		local page, pageWrapper = buildPage()
		local Tab = buildTabAPI(page)

		local pill = create("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 36),
			Text = "",
			BackgroundTransparency = 1,
			LayoutOrder = #tabs + 1,
			ZIndex = 4,
			Parent = dockButtons,
		})
		roundFull(pill)
		padAll(pill, 0, 18, 0, 18)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = pill,
		})
		local pillIcon = nil
		if tabImage and tabImage ~= 0 and tabImage ~= "" then
			pillIcon = makeIcon(pill, tabImage, 16, Theme.TextSub)
			if pillIcon then
				pillIcon.LayoutOrder = 1
				pillIcon.ZIndex = 5
			end
		end
		local pillLabel = create("TextLabel",{
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_MEDIUM,
			TextSize = 15,
			Text = tabName or "Tab",
			TextColor3 = Theme.TextSub,
			LayoutOrder=2,
			ZIndex = 5,
			Parent = pill,
		})

		local tabEntry = {
			Name = tabName,
			Page = page,
			Wrapper = pageWrapper,
			Pill = pill,
			PillLabel = pillLabel,
			PillIcon = pillIcon,
			API = Tab,
		}
		table.insert(tabs, tabEntry)

		pill.MouseButton1Click:Connect(function()
			if tabEntry.Locked then return end
			selectTab(tabEntry)
		end)
		function Tab:SetLocked(state)
			tabEntry.Locked = state and true or false
			local t = tabEntry.Locked and 0.6 or 0
			if pillLabel then pillLabel.TextTransparency = t end
			if pillIcon then pillIcon.ImageTransparency = t end
		end
		pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if currentTab == tabEntry and not settingsOpen then
				moveIndicator(false)
			end
		end)

		if #tabs == 1 then
			currentTab = tabEntry
			settingsOpen=false
			styleTabPills()
			pageWrapper.Visible = true
			task.delay(0.1, function()
				moveIndicator(false)
			end)
			task.delay(0.8, function()
				moveIndicator(false)
			end)
		end

		return Tab
	end

	local toggleKeyName = "K"
	if Settings.ToggleUIKeybind then
		if typeof(Settings.ToggleUIKeybind) == "EnumItem" then
			toggleKeyName = Settings.ToggleUIKeybind.Name
		else
			toggleKeyName = tostring(Settings.ToggleUIKeybind)
		end
	end

	local function buildSettingsPage()
		local page, pageWrapper = buildPage()
		settingsEntry = {Page = page, Wrapper = pageWrapper}
		local SettingsTab = buildTabAPI(page)

		SettingsTab:CreateSection("Generation")
		local genLabels, labelToGen = {}, {}
		for _, id in ipairs(GEN_ORDER) do
			table.insert(genLabels, GENERATIONS[id].label)
			labelToGen[GENERATIONS[id].label] = id
		end
		local pendingGen = GEN.generation
		SettingsTab:CreateSegmentedPicker({
			Name = "Generation",
			Options = genLabels,
			CurrentOption = GENERATIONS[GEN.generation].label,
			Callback = function(opt)
				pendingGen = labelToGen[opt] or GEN.generation
			end,
		})
		SettingsTab:CreateParagraph({
			Title = "Switch generation",
			Content = "Pick a generation and press Apply. The menu unloads and reloads in that look, keeping every setting you changed. Your choice is remembered next time you run the script.",
		})
		SettingsTab:CreateButton({
			Name = "Apply generation",
			Icon = "refresh-cw",
			Callback = function()
				if pendingGen ~= GEN.generation then
					task.spawn(function() RayfieldLibrary:SetGeneration(pendingGen) end)
				end
			end,
		})

		SettingsTab:CreateSection("Appearance")
		SettingsTab:CreateDropdown({
			Name = "Color theme",
			Icon = "palette",
			Options = THEME_ORDER,
			CurrentOption = GEN.theme,
			Callback = function(opt)
				local name = type(opt) == "table" and opt[1] or opt
				if name and name ~= GEN.theme then
					task.spawn(function() RayfieldLibrary:SetTheme(name) end)
				end
			end,
		})
		-- every Roblox font, plus Auto (follows the generation default). Type to search.
		local fontOptions = { "Auto" }
		for _, name in ipairs(ALL_FONTS) do table.insert(fontOptions, name) end
		local curFont = "Auto"
		if type(GEN.fontOverride) == "string" then
			for _, name in ipairs(ALL_FONTS) do
				if name == GEN.fontOverride or string.lower(name) == GEN.fontOverride then curFont = name break end
			end
		end
		SettingsTab:CreateDropdown({
			Name = "Font",
			Icon = "type",
			Placeholder = "Auto",
			Options = fontOptions,
			CurrentOption = curFont,
			Callback = function(opt)
				local name = type(opt) == "table" and opt[1] or opt
				local key = (name == "Auto" or not name) and nil or name
				task.spawn(function() RayfieldLibrary:SetFont(key) end)
			end,
		})
		SettingsTab:CreateSlider({
			Name = "Window transparency",
			Icon = "square",
			Range = { 0, 90 },
			Increment = 1,
			Suffix = "%",
			CurrentValue = math.floor(GEN.transparency * 100 + 0.5),
			Callback = function(v)
				Window:SetTransparency(v / 100)
			end,
		})
		SettingsTab:CreateToggle({
			Name = "Acrylic blur",
			Icon = "sparkles",
			Description = "Frost the game behind a see-through window.",
			CurrentValue = GEN.acrylic,
			Callback = function(state)
				Window:SetAcrylic(state)
			end,
		})

		-- Bring-your-own AI keys, shared by every AI chat. They stack; the chat
		-- asks before switching when one runs out. Empty = free built-in AI.
		SettingsTab:CreateSection("AI keys")
		local keysLabel
		local function refreshKeysLabel()
			local n = #aiKeys
			local suffix = ""
			if n > 0 then suffix = "  (" .. maskKey(aiKeys[n]) .. (n > 1 and (" +" .. (n - 1) .. " more") or "") .. ")" end
			keysLabel:Set((n == 0 and "No keys  \u{00B7}  using free built-in AI" or (n .. (n == 1 and " key saved" or " keys saved") .. suffix)), "key-round")
		end
		keysLabel = SettingsTab:CreateLabel("...", "key-round")
		local keyInput = SettingsTab:CreateInput({
			Name = "Add API key",
			Icon = "plus",
			PlaceholderText = "sk-... then press Add",
			CurrentValue = "",
		})
		SettingsTab:CreateButton({
			Name = "Add key",
			Icon = "key-round",
			Callback = function()
				local k = tostring(keyInput.CurrentValue or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if #k < 8 then
					RayfieldLibrary:Notify({ Title = "AI keys", Content = "That does not look like a valid key.", Duration = 3, Image = "triangle-alert" })
					return
				end
				table.insert(aiKeys, k)
				persistChoice()
				keyInput:Set("")
				refreshKeysLabel()
				RayfieldLibrary:Notify({ Title = "AI keys", Content = "Key added. The AI chat will use it.", Duration = 3, Image = "check" })
			end,
		})
		SettingsTab:CreateButton({
			Name = "Remove last key",
			Icon = "minus",
			Callback = function()
				if #aiKeys > 0 then
					table.remove(aiKeys)
					persistChoice()
					refreshKeysLabel()
				end
			end,
		})
		SettingsTab:CreateButton({
			Name = "Clear all keys",
			Icon = "trash-2",
			Callback = function()
				if #aiKeys == 0 then return end
				RayfieldLibrary:Dialog({
					Title = "Clear all AI keys?",
					Content = "This removes the " .. #aiKeys .. " saved key(s). The AI chat falls back to the free built-in provider.",
					Options = {
						{ Text = "Cancel" },
						{ Text = "Clear", Color = Color3.fromRGB(200, 70, 70), Callback = function()
							for i = #aiKeys, 1, -1 do aiKeys[i] = nil end
							persistChoice()
							refreshKeysLabel()
						end },
					},
				})
			end,
		})
		refreshKeysLabel()

		SettingsTab:CreateSection("Interface")
		SettingsTab:CreateKeybind({
			Name = "Toggle UI",
			Icon = "eye",
			CurrentKeybind = toggleKeyName,
			CallOnChange = true,
			Callback = function(newKey)
				toggleKeyName = newKey
			end,
		})
		SettingsTab:CreateToggle({
			Name = "Unlock cursor while open",
			Icon = "mouse-pointer-2",
			CurrentValue=false,
			Description = "Unlocks the cursor while the menu is open so you can configure in FPS games that lock it.",
			Callback = function(value)
				unlockCursor=value
			end,
		})
		-- Live session dashboard: who is running, how busy the server is, and how
		-- the client is doing, refreshed every second while the menu exists.
		SettingsTab:CreateSection("Session")
		local playerRow = SettingsTab:CreateLabel("Player  " .. (LocalPlayer and LocalPlayer.Name or "Unknown"), "user")
		local clientsRow = SettingsTab:CreateLabel("Active clients  ...", "users")
		local uptimeRow = SettingsTab:CreateLabel("Uptime  0s", "timer")
		local fpsRow = SettingsTab:CreateLabel("FPS  ...", "activity")
		do
			local sessionStart = os.clock()
			local frames = 0
			connect(RunService.RenderStepped, function() frames += 1 end)
			task.spawn(function()
				while not destroyed and page.Parent do
					task.wait(1)
					if destroyed or not page.Parent then break end
					pcall(function()
						local secs = math.floor(os.clock() - sessionStart)
						local up
						if secs >= 3600 then
							up = string.format("%dh %dm", math.floor(secs / 3600), math.floor(secs % 3600 / 60))
						elseif secs >= 60 then
							up = string.format("%dm %ds", math.floor(secs / 60), secs % 60)
						else
							up = secs .. "s"
						end
						clientsRow:Set("Active clients  " .. #Players:GetPlayers() .. " in server")
						uptimeRow:Set("Uptime  " .. up)
						fpsRow:Set("FPS  " .. frames)
						frames = 0
					end)
				end
			end)
		end

		SettingsTab:CreateSection("Configuration")
		SettingsTab:CreateLabel(configEnabled and ("Saving to " .. configFolder .. "/" .. configFile .. ".json") or "Configuration saving is off", "folder")
		SettingsTab:CreateSection("About")
		SettingsTab:CreateParagraph({
			Title = "Rayfield Gen 3 [Concept]",
			Content = "Unofficial rebuild of the Rayfield Interface Suite. Original Rayfield by Sirius.",
		})
		SettingsTab:CreateButton({
			Name = "Unload interface",
			Icon = "trash-2",
			Callback = function()
				RayfieldLibrary:Destroy()
			end,
		})
	end

	settingsButton.MouseButton1Click:Connect(function()
		if not settingsEntry then buildSettingsPage() end
		settingsOpen = not settingsOpen
		styleTabPills()
		if settingsOpen then
			showPage(settingsEntry)
		elseif currentTab then
			showPage(currentTab)
		end
	end)

	local function makeDraggable(zone)
		local dragging = false
		local dragStart = nil
		local startPos=nil
		zone.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if morphing or hidden then return end
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end)
		zone.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				tween(root, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
					Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					),
				})
			end
		end)
	end
	makeDraggable(header)
	makeDraggable(handle)

	local function setMinimizeIcon(restore)
		applyLucide(minimizeIcon, restore and {"maximize-2", "expand"} or {"minus"})
	end

	local function setMinimized(value)
		if morphing or hidden then return end
		minimized = value
		setMinimizeIcon(minimized)
		tween(window, TI_MORPH, {Size=UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
	end

	minimizeButton.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)

	local function hideWindow()
		if morphing or hidden then return end
		morphing = true
		hidden = true
		storedPosition = root.Position
		tween(handle, TI_FAST,{BackgroundTransparency = 1})
		tween(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{GroupTransparency = 1})
		task.wait(0.17)
		main.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, math.floor(PILL_H / 2))})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(PILL_W, PILL_H)})

		tween(window, TI_MORPH, {BackgroundColor3 = Color3.fromRGB(46,46, 46)})
		tween(windowStroke, TI_MORPH, {Transparency = 0.45});
		tween(shadow, TI_MORPH, {ImageTransparency = 0.55})
		tween(root, TI_MORPH, {Position = UDim2.new(0.5, 0, 0, 16)})
		task.wait(0.34)
		pillContent.Visible = true
		pillButton.Visible = true
		tween(pillContent, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		morphing = false
	end

	local function showWindow()
		if morphing or not hidden then return end
		morphing = true
		hidden = false
		tween(pillContent, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		task.wait(0.14)
		pillContent.Visible = false
		pillButton.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, GenStyle.windowCorner)})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
		tween(window, TI_MORPH,{BackgroundColor3 = Theme.Background})
		tween(windowStroke, TI_MORPH, {Transparency = 0.93})
		tween(shadow,TI_MORPH, {ImageTransparency = 0.42})
		tween(root, TI_MORPH, {Position = storedPosition or shownPosition})
		task.wait(0.36)
		main.Visible = true
		tween(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		tween(handle, TI_MED, {BackgroundTransparency = 0.35})
		morphing = false
	end

	closeButton.MouseButton1Click:Connect(function()
		task.spawn(hideWindow)
	end)
	pillButton.MouseButton1Click:Connect(function()
		task.spawn(showWindow)
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == toggleKeyName then
			if hidden then
				task.spawn(showWindow)
			else
				task.spawn(hideWindow)
			end
		end
	end)

	RayfieldLibrary._hideWindow = hideWindow
	RayfieldLibrary._showWindow = showWindow
	RayfieldLibrary._isHidden = function() return hidden end

	function Window.ModifyTheme(newTheme)
		if type(newTheme) == "table" then
			for k, v in pairs(newTheme) do
				if Theme[k] ~= nil and typeof(v) == "Color3" then
					Theme[k] = v
				end
			end
			repaint()
		end
	end

	function Window:SetTitle(newTitle)
		titleLabel.Text = newTitle or titleLabel.Text
	end

	function Window:SetSubtitle(newSubtitle)
		subtitleLabel.Text = newSubtitle or subtitleLabel.Text
	end

	function Window:SetTabStyle(style)
		tabStyle = (tostring(style) == "Accent") and "Accent" or "White"
		applyTabStyle()
		styleTabPills()
	end

	function Window:SetTabAccent(color)
		if typeof(color) == "Color3" then
			tabAccent = color
			applyTabStyle()
			styleTabPills()
		end
	end

	-- 0 = solid, up to ~0.9 = see-through. The element cards frost with it so a
	-- transparent menu stays a cohesive glass surface, not solid cards floating.
	function Window:SetTransparency(value)
		local t = math.clamp(tonumber(value) or 0, 0, 0.92)
		GEN.transparency = t
		window.BackgroundTransparency = t
		for _, g in ipairs(glassSurfaces) do
			if g.inst and g.inst.Parent then
				g.inst.BackgroundTransparency = glassValue(g.base, g.factor, t)
			end
		end
		persistChoice()
	end

	-- Frosted-glass blur of the game behind the (see-through) window. Turning it
	-- on makes the window see-through so the frost shows; turning it off restores
	-- the transparency the window had before, so it goes solid again.
	function Window:SetAcrylic(state)
		state = state and true or false
		local was = GEN.acrylic
		GEN.acrylic = state
		if state then
			enableAcrylic(window)
			if not was then GEN.acrylicPrevT = GEN.transparency end
			if GEN.transparency < 0.2 then Window:SetTransparency(0.4) end
		else
			clearAcrylic()
			if was then Window:SetTransparency(GEN.acrylicPrevT or 0) end
		end
		persistChoice()
	end

	function Window:Greet(GreetSettings)
		GreetSettings = GreetSettings or {}
		local texts = GreetSettings.Texts or {
			"Hello",
			"\228\189\160\229\165\189",
			"\224\164\168\224\164\174\224\164\184\224\165\141\224\164\164\224\165\135",
			"hola",
			"bonjour",
			"\217\133\216\177\216\173\216\168\216\167",
			"ol\195\161",
		}
		local hold = GreetSettings.Hold or 0.5

		local clipper = create("CanvasGroup", {
			Name = "Greeting",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 900,
			Parent = window,
		})
		round(clipper, 24)
		local overlay = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -40),
			Size = UDim2.new(1.6, 0, 1, 140),
			BackgroundColor3 = Color3.fromRGB(250, 250, 250),
			ZIndex = 900,
			Parent = clipper,
		})
		round(overlay, 90)
		local word = create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -30),
			Size = UDim2.new(0.8, 0, 0, 44),
			Font = FONT_BOLD,
			TextSize = 28,
			TextColor3 = Color3.fromRGB(35, 35, 35),
			TextTransparency = 1,
			Text = "",
			ZIndex = 901,
			Parent = overlay,
		})

		task.spawn(function()
			local baseY = -30
			for _, t in ipairs(texts) do
				word.Text = t
				word.Position = UDim2.new(0.5, 0, 0.5, baseY + 12)
				tween(word, TI_SMOOTH, {TextTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, baseY)})
				task.wait(hold)
				tween(word, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					TextTransparency = 1,
					Position = UDim2.new(0.5, 0, 0.5, baseY - 12),
				})
				task.wait(0.24)
			end
			tween(overlay, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, -1, -220),
			})
			task.delay(0.75, function()
				clipper:Destroy()
			end)
		end)
	end

	-- A "Get Started" tutorial. Script authors pass a list of steps; the user
	-- gets a stepped overlay they can Skip, walk with Back/Next, and Finish.
	-- A step may point at an element (Target) to highlight it.
	function Window:CreateTutorial(TutorialSettings)
		TutorialSettings = TutorialSettings or {}
		local rawSteps = TutorialSettings.Steps or TutorialSettings.steps or {}
		local steps = {}
		for _, s in ipairs(rawSteps) do
			if type(s) == "string" then
				steps[#steps + 1] = { Content = s }
			elseif type(s) == "table" then
				steps[#steps + 1] = {
					Title = s.Title or s.Name or s.Header,
					Content = s.Content or s.Text or s.Body or s.Description or "",
					Icon = s.Icon,
					Target = s.Target,
				}
			end
		end

		local handle = {}
		local active = false
		local index = 0
		local epoch = 0
		local overlay, scrim, spot, cardHolder, cardScale, body, iconImg, titleLbl, contentLbl, dotsRow, backBtn, nextBtn, nextLbl, nextIcon, skipBtn
		local dots = {}

		local function finish(skipped)
			if not active then return end
			active = false
			epoch = epoch + 1
			local o = overlay
			overlay = nil
			if o then
				tween(scrim, TI_MED, { BackgroundTransparency = 1 })
				tween(o, TI_MED, { GroupTransparency = 1 })
				if cardScale then tween(cardScale, TI_MED, { Scale = 0.94 }) end
				task.delay(0.28, function() if o then o:Destroy() end end)
			end
			runCallback(skipped and TutorialSettings.OnSkip or TutorialSettings.OnFinish, index + 1)
		end

		local function positionSpot(target)
			if not spot then return end
			local ok = false
			if typeof(target) == "Instance" and target:IsA("GuiObject") and target.Visible then
				local wp, ws = window.AbsolutePosition, window.AbsoluteSize
				local tp, ts = target.AbsolutePosition, target.AbsoluteSize
				-- only if the target actually sits inside the window
				if ts.X > 0 and ts.Y > 0 and tp.X + ts.X > wp.X and tp.X < wp.X + ws.X then
					spot.Position = UDim2.fromOffset(tp.X - wp.X - 5, tp.Y - wp.Y - 5)
					spot.Size = UDim2.fromOffset(ts.X + 10, ts.Y + 10)
					ok = true
				end
			end
			spot.Visible = ok
			return ok
		end

		local function renderDots()
			for i, dot in ipairs(dots) do
				local on = (i == index + 1)
				tween(dot, TI_FAST, {
					BackgroundColor3 = on and Theme.Accent or Theme.TextMuted,
					Size = on and UDim2.fromOffset(18, 6) or UDim2.fromOffset(6, 6),
				})
			end
		end

		local function show(i, dir)
			index = math.clamp(i, 0, #steps - 1)
			local step = steps[index + 1]
			if not step then finish(false) return end
			epoch = epoch + 1
			local myEpoch = epoch

			-- crossfade the body out, swap text, fade back in with a small slide
			tween(body, TI_FAST, { GroupTransparency = 1 })
			local slide = (dir == -1) and 14 or -14
			tween(body, TI_FAST, { Position = UDim2.new(0, slide, 0, 0) })
			task.delay(0.15, function()
				if myEpoch ~= epoch or not active then return end
				-- icon
				if iconImg then
					if step.Icon then
						iconImg.Visible = true
						applyLucide(iconImg, step.Icon)
					else
						iconImg.Visible = false
					end
				end
				titleLbl.Visible = step.Title ~= nil and step.Title ~= ""
				titleLbl.Text = step.Title or ""
				contentLbl.Text = step.Content or ""
				-- highlight the target (if any) and keep the card clear of it
				local hasSpot = positionSpot(step.Target)
				if hasSpot then
					local tp = step.Target.AbsolutePosition.Y - window.AbsolutePosition.Y
					local topHalf = tp < (window.AbsoluteSize.Y * 0.5)
					cardHolder.AnchorPoint = Vector2.new(0.5, topHalf and 1 or 0)
					cardHolder.Position = topHalf and UDim2.new(0.5, 0, 1, -22) or UDim2.new(0.5, 0, 0, 22)
				else
					cardHolder.AnchorPoint = Vector2.new(0.5, 0.5)
					cardHolder.Position = UDim2.fromScale(0.5, 0.5)
				end
				-- buttons + dots
				backBtn.Visible = index > 0
				local last = index == #steps - 1
				nextLbl.Text = last and "Finish" or "Next"
				if nextIcon then applyLucide(nextIcon, last and "check" or "arrow-right") end
				renderDots()
				-- fade back in
				body.Position = UDim2.new(0, -slide, 0, 0)
				tween(body, TI_MED, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			end)
		end

		local function build()
			overlay = create("CanvasGroup", {
				Name = "Tutorial",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				GroupTransparency = 1,
				ZIndex = 940,
				Parent = window,
			})
			round(overlay, GenStyle.windowCorner)
			overlay.ClipsDescendants = true

			scrim = create("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(6, 6, 8),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 1,
				Parent = overlay,
			})

			-- the highlight ring around a targeted element
			spot = create("Frame", {
				BackgroundTransparency = 1,
				Visible = false,
				ZIndex = 2,
				Parent = overlay,
			})
			round(spot, 8)
			local spotStroke = create("UIStroke", { Thickness = 2, Transparency = 0.1, Parent = spot })
			paint(spotStroke, "Color", "Accent")

			cardHolder = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -60, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Card,
				ZIndex = 3,
				Parent = overlay,
			})
			paint(cardHolder, "BackgroundColor3", "Card")
			create("UISizeConstraint", { MaxSize = Vector2.new(360, math.huge), Parent = cardHolder })
			cardScale = create("UIScale", { Scale = 0.94, Parent = cardHolder })
			round(cardHolder, math.max(10, GenStyle.cardRadius + 4))
			local chStroke = create("UIStroke", { Transparency = 0.85, Thickness = 1, Parent = cardHolder })
			paint(chStroke, "Color", "Stroke")
			padAll(cardHolder, 20, 20, 18, 20)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 14),
				Parent = cardHolder,
			})

			-- body (icon + title + content), crossfaded on step change
			body = create("CanvasGroup", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				GroupTransparency = 0,
				LayoutOrder = 1,
				ZIndex = 3,
				Parent = cardHolder,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = body,
			})
			iconImg = create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(26, 26),
				ImageColor3 = Theme.Accent,
				LayoutOrder = 1,
				ZIndex = 3,
				Parent = body,
			})
			paint(iconImg, "ImageColor3", "Accent")
			titleLbl = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = FONT_BOLD,
				TextSize = 19,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Text = "",
				LayoutOrder = 2,
				ZIndex = 3,
				Parent = body,
			})
			paint(titleLbl, "TextColor3", "TextTitle")
			contentLbl = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = FONT_REGULAR,
				TextSize = 14,
				LineHeight = 1.12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				Text = "",
				LayoutOrder = 3,
				ZIndex = 3,
				Parent = body,
			})
			paint(contentLbl, "TextColor3", "TextSub")

			-- progress dots
			dotsRow = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 8),
				LayoutOrder = 2,
				ZIndex = 3,
				Parent = cardHolder,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = dotsRow,
			})
			dots = {}
			for i = 1, #steps do
				local dot = create("Frame", {
					BackgroundColor3 = Theme.TextMuted,
					Size = UDim2.fromOffset(6, 6),
					LayoutOrder = i,
					ZIndex = 3,
					Parent = dotsRow,
				})
				roundFull(dot)
				dots[i] = dot
			end

			-- footer: Skip on the left, Back + Next on the right
			local footer = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36),
				LayoutOrder = 3,
				ZIndex = 3,
				Parent = cardHolder,
			})
			skipBtn = create("TextButton", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(80, 32),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = TutorialSettings.SkipText or "Skip",
				ZIndex = 3,
				Parent = footer,
			})
			paint(skipBtn, "TextColor3", "TextMuted")
			skipBtn.MouseEnter:Connect(function() tween(skipBtn, TI_FAST, { TextColor3 = Theme.TextBody }) end)
			skipBtn.MouseLeave:Connect(function() tween(skipBtn, TI_FAST, { TextColor3 = Theme.TextMuted }) end)

			backBtn = create("TextButton", {
				BackgroundColor3 = Theme.CardInset,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -108, 0.5, 0),
				Size = UDim2.fromOffset(76, 34),
				Font = FONT_MEDIUM,
				TextSize = 14,
				Text = "Back",
				Visible = false,
				ZIndex = 3,
				Parent = footer,
			})
			paint(backBtn, "BackgroundColor3", "CardInset")
			paint(backBtn, "TextColor3", "TextBody")
			round(backBtn, 8)
			backBtn.MouseEnter:Connect(function() tween(backBtn, TI_FAST, { BackgroundColor3 = Theme.CardHover }) end)
			backBtn.MouseLeave:Connect(function() tween(backBtn, TI_FAST, { BackgroundColor3 = Theme.CardInset }) end)

			nextBtn = create("TextButton", {
				BackgroundColor3 = Theme.Accent,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(100, 34),
				Text = "",
				ZIndex = 3,
				Parent = footer,
			})
			paint(nextBtn, "BackgroundColor3", "Accent")
			round(nextBtn, 8)
			local nextRow = create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(88, 20),
				ZIndex = 4,
				Parent = nextBtn,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = nextRow,
			})
			nextLbl = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 20),
				Font = FONT_BOLD,
				TextSize = 14,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = "Next",
				LayoutOrder = 1,
				ZIndex = 4,
				Parent = nextRow,
			})
			nextIcon = create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(15, 15),
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				LayoutOrder = 2,
				ZIndex = 4,
				Parent = nextRow,
			})
			applyLucide(nextIcon, "arrow-right")
			nextBtn.MouseEnter:Connect(function() tween(nextBtn, TI_FAST, { BackgroundColor3 = Theme.AccentSoft or Theme.Accent }) end)
			nextBtn.MouseLeave:Connect(function() tween(nextBtn, TI_FAST, { BackgroundColor3 = Theme.Accent }) end)

			scrim.MouseButton1Click:Connect(function() end) -- eat clicks to the menu behind
			skipBtn.MouseButton1Click:Connect(function() finish(true) end)
			backBtn.MouseButton1Click:Connect(function() if index > 0 then show(index - 1, -1) end end)
			nextBtn.MouseButton1Click:Connect(function()
				if index >= #steps - 1 then finish(false) else show(index + 1, 1) end
			end)
		end

		function handle:Start(startIndex)
			if active then return end
			if #steps == 0 then return end
			active = true
			build()
			tween(scrim, TI_MED, { BackgroundTransparency = 0.45 })
			tween(overlay, TI_MED, { GroupTransparency = 0 })
			tween(cardScale, TI_SMOOTH, { Scale = 1 })
			show((tonumber(startIndex) or 1) - 1, 1)
		end
		function handle:Stop() finish(true) end
		function handle:IsActive() return active end
		function handle:Step() return index + 1 end

		if TutorialSettings.AutoStart then
			task.delay(TutorialSettings.Delay or 0.6, function() handle:Start() end)
		end
		return handle
	end

	local hasLoading = (Settings.LoadingTitle and Settings.LoadingTitle ~= "") or (Settings.LoadingSubtitle and Settings.LoadingSubtitle ~= "")

	if hasLoading then

		morphing = true
		local LOAD_W, LOAD_H = 320, 140
		window.Size = UDim2.fromOffset(LOAD_W, LOAD_H)
		root.Position = UDim2.new(0.5, 0, 0.5, -math.floor(LOAD_H / 2) - 9)

		local loading = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(LOAD_W, LOAD_H),
			ZIndex=5,
			Parent = window,
		})
		local spinner = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5,0),
			Position = UDim2.new(0.5, 0, 0, 26),
			Size = UDim2.fromOffset(24, 24),
			ImageColor3 = Theme.TextTitle,
			ImageTransparency = 0,
			Parent = loading,
		})
		applyLucide(spinner,{"loader"})
		tween(spinner, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360})
		create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 62),
			Size = UDim2.new(1, -40, 0, 22),
			Font = FONT_BOLD,
			TextSize = 18,
			Text = Settings.LoadingTitle or Settings.Name or "Rayfield",
			TextColor3 = Theme.TextTitle,
			Parent = loading,
		})
		create("TextLabel", {
			BackgroundTransparency=1,
			AnchorPoint = Vector2.new(0.5,0),
			Position = UDim2.new(0.5,0, 0, 88),
			Size = UDim2.new(1, -40, 0, 18),
			Font = FONT_MEDIUM,
			TextSize = 14,
			Text = Settings.LoadingSubtitle or "Rayfield Gen3",
			TextColor3 = Theme.TextSub,
			Parent = loading,
		})

		task.spawn(function()
			task.wait(1.15)
			if destroyed or not window.Parent then
				morphing = false
				return
			end
			tween(loading, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{BackgroundTransparency = 1});
			for _, child in ipairs(loading:GetChildren()) do
				if child:IsA("TextLabel") then
					tween(child, TweenInfo.new(0.16), {TextTransparency = 1})
				elseif child:IsA("ImageLabel") then
					tween(child, TweenInfo.new(0.16), {ImageTransparency = 1})
				end
			end
			task.wait(0.16)
			loading:Destroy()
			tween(window, TI_SLOW, {Size = UDim2.fromOffset(WINDOW_W, WINDOW_H)})
			tween(root, TI_SLOW, {Position = shownPosition})
			task.wait(0.18)
			tween(main, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
			tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})
			task.wait(0.34)
			morphing = false
		end)
	else
		window.Size = UDim2.fromOffset(WINDOW_W - 48, WINDOW_H - 56)
		shadow.ImageTransparency = 1
		tween(window, TI_SLOW, {Size = UDim2.fromOffset(WINDOW_W, WINDOW_H)});
		tween(shadow, TI_SLOW,{ImageTransparency = 0.42})
		tween(main,TweenInfo.new(0.45,Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})
	end

	function RayfieldLibrary:LoadConfiguration()
		if not configEnabled then return end
		local raw = readf(configFolder .. "/" .. configFile .. ".json")
		if not raw then return end
		local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or type(data) ~= "table" then return end
		for flag, value in pairs(data) do
			local element = RayfieldLibrary.Flags[flag]
			if element then
				pcall(function()
					if element.Type == "ColorPicker" and type(value) == "table" then
						element:Set(Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255))
					else
						element:Set(value)
					end
				end)
			end
		end
		RayfieldLibrary:Notify({Title = "Configuration loaded",Content = "Your saved settings were applied.",Duration = 3, Image = "file-check"})
	end

	return Window
end

-- ===========================================================================
-- Generation / theme engine
-- The author builds the UI once; we record it as a blueprint of proxy handles.
-- To switch generation (or theme or font) we snapshot every value, tear the
-- window down, re-skin, rebuild the exact same blueprint, and restore values.
-- The author's handles stay valid because each proxy forwards to whatever real
-- object currently backs it.
-- ===========================================================================

local GEN_FILE = BASE_FOLDER .. "/generation.json"

-- Compose the active look: reset to base, layer the generation tint, then the
-- chosen color theme; swap geometry + font. Read at the next construction.
function applyStyle()
	local gen = GENERATIONS[GEN.generation] or GENERATIONS.Gen3
	for k, v in pairs(GEN3_STYLE) do GenStyle[k] = v end
	if gen.style then for k, v in pairs(gen.style) do GenStyle[k] = v end end
	for k, v in pairs(BASE_THEME) do Theme[k] = v end
	if gen.theme then for k, v in pairs(gen.theme) do Theme[k] = v end end
	local th = THEMES[GEN.theme]
	if th then for k, v in pairs(th) do Theme[k] = v end end
	applyFont(GEN.fontOverride or GenStyle.fontKey)
end

function persistChoice()
	if not fsAvailable then return end
	pcall(function()
		mkfolder(BASE_FOLDER)
		writef(GEN_FILE, HttpService:JSONEncode({
			generation = GEN.generation, theme = GEN.theme, font = GEN.fontOverride,
			transparency = GEN.transparency, acrylic = GEN.acrylic, aiKeys = aiKeys,
		}))
	end)
end

local function loadPersistedChoice()
	if not fsAvailable then return end
	local raw = readf(GEN_FILE)
	if not raw then return end
	local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(data) == "table" then
		if GENERATIONS[data.generation] then GEN.generation = data.generation end
		if data.theme and THEMES[data.theme] then GEN.theme = data.theme end
		if data.font ~= nil then GEN.fontOverride = data.font end
		if type(data.transparency) == "number" then GEN.transparency = math.clamp(data.transparency, 0, 0.92) end
		if type(data.acrylic) == "boolean" then GEN.acrylic = data.acrylic end
		if type(data.aiKeys) == "table" then
			for i = #aiKeys, 1, -1 do aiKeys[i] = nil end
			for _, k in ipairs(data.aiKeys) do
				if type(k) == "string" and #k > 0 then table.insert(aiKeys, k) end
			end
		end
	end
end

-- A stable handle the author keeps. Its metatable forwards field reads/writes
-- and method calls to whichever real object currently backs it (node.cell.real).
-- Create* calls are recorded (with every returned value, so multi-return
-- factories like CreateColumns work) so children can be rebuilt and re-pointed.
local function makeNode(real, node)
	node.cell = { real = real }
	node.children = node.children or {}
	local proxy = {}
	setmetatable(proxy, {
		__index = function(_, key)
			local r = node.cell.real
			local v = r and r[key]
			if type(v) ~= "function" then return v end
			if type(key) == "string" and key:sub(1, 6) == "Create" then
				return function(_, ...)
					local rr = node.cell.real
					local args = table.pack(...)
					local rets = table.pack(rr[key](rr, table.unpack(args, 1, args.n)))
					local crec = { method = key, args = args, nodes = {} }
					table.insert(node.children, crec)
					local out = {}
					for i = 1, rets.n do
						local rv = rets[i]
						if type(rv) == "table" then
							local child = { children = {} }
							crec.nodes[i] = child
							out[i] = makeNode(rv, child)
						else
							out[i] = rv
						end
					end
					return table.unpack(out, 1, rets.n)
				end
			end
			return function(a, ...)
				local rr = node.cell.real
				local f = rr[key]
				if a == proxy then return f(rr, ...) end
				return f(a, ...)
			end
		end,
		__newindex = function(_, key, val)
			local r = node.cell.real
			if r then r[key] = val end
		end,
	})
	return proxy
end

local function replayNode(realParent, node)
	for _, crec in ipairs(node.children) do
		local ok, rets = pcall(function()
			return table.pack(realParent[crec.method](realParent, table.unpack(crec.args, 1, crec.args.n)))
		end)
		if ok and rets then
			for i, child in pairs(crec.nodes) do
				local rv = rets[i]
				if type(rv) == "table" then
					child.cell.real = rv
					replayNode(rv, child)
				end
			end
		end
	end
end

local VALUE_FIELD = {
	Toggle = "CurrentValue", Checkbox = "CurrentValue", Slider = "CurrentValue",
	Input = "CurrentValue", Dropdown = "CurrentOption", Keybind = "CurrentKeybind",
	ColorPicker = "Color", GradientPicker = "Value",
}

local function walkNodes(node, fn)
	for _, crec in ipairs(node.children) do
		for _, child in pairs(crec.nodes) do
			fn(child)
			walkNodes(child, fn)
		end
	end
end

local function snapshotValues(node)
	walkNodes(node, function(child)
		local real = child.cell and child.cell.real
		if type(real) == "table" then
			if real.Type and VALUE_FIELD[real.Type] then
				local val = real[VALUE_FIELD[real.Type]]
				if type(val) == "table" then
					local copy = {}
					for i, x in ipairs(val) do copy[i] = x end
					val = copy
				end
				child.savedValue = val
			end
			if real._visibleState ~= nil then
				child.savedVisible = real._visibleState
			end
		end
	end)
end

local function restoreValues(node)
	walkNodes(node, function(child)
		local real = child.cell and child.cell.real
		if child.savedValue ~= nil then
			if type(real) == "table" and type(real.Set) == "function" then
				pcall(function() real:Set(child.savedValue) end)
			end
		end
		if child.savedVisible == false then
			if type(real) == "table" and type(real.SetVisible) == "function" then
				pcall(function() real:SetVisible(false) end)
			end
		end
	end)
end

local function teardownForRebuild()
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	Connections = {}
	if rootGui then pcall(function() rootGui:Destroy() end) end
	rootGui = nil
	notifyStack = nil
	clearAcrylic()
	painted = {}
	glassSurfaces = {}
	pendingIcons = {}
	notifyOrder = 0
	RayfieldLibrary.Flags = {}
	RayfieldLibrary._hideWindow = nil
	RayfieldLibrary._showWindow = nil
	RayfieldLibrary._isHidden = nil
	destroyed = false
end

function performRebuild()
	local bp = GEN.blueprint
	if not bp then applyStyle(); return end
	suppressCallbacks = true
	snapshotValues(bp)
	teardownForRebuild()
	applyStyle()
	-- rebuild without re-running one-time entry gates or intro animations
	local rebuildSettings = {}
	for k, v in pairs(bp.settings) do rebuildSettings[k] = v end
	rebuildSettings.KeySystem = nil
	rebuildSettings.LoadingTitle = nil
	rebuildSettings.LoadingSubtitle = nil
	local realWindow = _constructWindow(rebuildSettings)
	GEN.windowCell.real = realWindow
	replayNode(realWindow, bp)
	restoreValues(bp)
	suppressCallbacks = false
	persistChoice()
end

function RayfieldLibrary:CreateWindow(Settings)
	Settings = Settings or {}
	if Settings.Generation and GENERATIONS[Settings.Generation] then GEN.generation = Settings.Generation end
	if Settings.Theme and THEMES[Settings.Theme] then GEN.theme = Settings.Theme end
	if Settings.Font ~= nil then GEN.fontOverride = Settings.Font end
	if type(Settings.Transparency) == "number" then GEN.transparency = math.clamp(Settings.Transparency, 0, 0.92) end
	if Settings.Acrylic ~= nil then
		GEN.acrylic = Settings.Acrylic and true or false
		if GEN.acrylic then
			GEN.acrylicPrevT = GEN.transparency
			if GEN.transparency < 0.2 then GEN.transparency = 0.4 end
		end
	end
	loadPersistedChoice()
	applyStyle()
	local record = { settings = Settings, children = {} }
	GEN.blueprint = record
	local realWindow = _constructWindow(Settings)
	local proxy = makeNode(realWindow, record)
	GEN.windowCell = record.cell
	GEN.windowProxy = proxy
	return proxy
end

function RayfieldLibrary:SetGeneration(gen)
	if not GENERATIONS[gen] or gen == GEN.generation then return end
	GEN.generation = gen
	performRebuild()
	local g = GENERATIONS[gen]
	RayfieldLibrary:Notify({Title = "Switched to " .. (g.label or gen), Content = g.blurb or "", Duration = 4, Image = "layers"})
end

function RayfieldLibrary:SetTheme(name)
	if not THEMES[name] or name == GEN.theme then return end
	GEN.theme = name
	performRebuild()
	RayfieldLibrary:Notify({Title = "Theme: " .. name, Content = "Applied the " .. name .. " palette.", Duration = 3, Image = "palette"})
end

function RayfieldLibrary:SetFont(key)
	GEN.fontOverride = key
	performRebuild()
end

function RayfieldLibrary:GetGeneration() return GEN.generation end
function RayfieldLibrary:GetTheme() return GEN.theme end
function RayfieldLibrary:GetGenerationList() return GEN_ORDER end
function RayfieldLibrary:GetThemeList() return THEME_ORDER end

function RayfieldLibrary:IsVisible()
	if RayfieldLibrary._isHidden then
		return not RayfieldLibrary._isHidden()
	end
	return rootGui ~= nil
end


function RayfieldLibrary:SetVisibility(visible)
	if visible and RayfieldLibrary._showWindow then
		task.spawn(RayfieldLibrary._showWindow);
	elseif not visible and RayfieldLibrary._hideWindow then
		task.spawn(RayfieldLibrary._hideWindow)
	end
end

function RayfieldLibrary:Destroy()
	destroyed = true
	clearAcrylic()
	for _, c in ipairs(Connections) do
		pcall(function() c:Disconnect() end)
	end
	Connections = {}
	if rootGui then
		rootGui:Destroy()
		rootGui = nil
	end
end

return RayfieldLibrary
