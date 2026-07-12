local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test5",
	Subtitle = "Tabs, color and gradient pickers",
	Icon = "flask-conical",
	Badge = {Text = "test", Icon = "bug"},
	TabStyle = "Accent",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Gen3Test5",
		FileName = "Test5",
	},
})

local Home = Window:CreateTab("Home", "house")
local Player = Window:CreateTab("Player", "user")
local Visuals = Window:CreateTab("Visuals", "eye")

-- which picker currently drives the tab accent ("solid", "gradient", or nil)
local connected = nil
local SolidConnect, GradientConnect

local function evalSeq(seq, t)
	local kps = seq.Keypoints
	for i = 1, #kps - 1 do
		if t >= kps[i].Time and t <= kps[i + 1].Time then
			local a, b = kps[i], kps[i + 1]
			local f = (b.Time == a.Time) and 0 or (t - a.Time) / (b.Time - a.Time)
			return a.Value:Lerp(b.Value, f)
		end
	end
	return kps[#kps].Value
end

Home:CreateSection("Tab dock")

Home:CreateSegmentedPicker({
	Name = "Tab style",
	Options = {"White", "Accent"},
	CurrentOption = "Accent",
	Callback = function(style)
		Window:SetTabStyle(style)
	end,
})

local AccentPicker = Home:CreateColorPicker({
	Name = "Tab accent color",
	Icon = "palette",
	Color = Color3.fromRGB(74, 178, 124),
	Callback = function(color)
		if not connected then
			Window:SetTabAccent(color)
		end
	end,
})

Home:CreateToggle({
	Name = "Tab accent glow",
	CurrentValue = true,
	Callback = function(value)
		AccentPicker:SetGlow(value)
	end,
})

Home:CreateSection("Single color picker")

local Solid = Home:CreateColorPicker({
	Name = "Solid color",
	Icon = "paintbrush",
	Color = Color3.fromRGB(255, 120, 60),
	Callback = function(color)
		if connected == "solid" then
			Window:SetTabAccent(color)
		end
	end,
})

Home:CreateToggle({
	Name = "Solid glow",
	CurrentValue = true,
	Callback = function(value)
		Solid:SetGlow(value)
	end,
})

SolidConnect = Home:CreateToggle({
	Name = "Connect solid to tab accent",
	Description = "Drives the tab accent from this color. Turns off the gradient connection.",
	CurrentValue = false,
	Callback = function(value)
		if value then
			connected = "solid"
			if GradientConnect then GradientConnect:Set(false) end
			Window:SetTabAccent(Solid.Color)
		elseif connected == "solid" then
			connected = nil
		end
	end,
})

Home:CreateSection("Gradient color picker")

local Gradient = Home:CreateGradientPicker({
	Name = "Theme gradient",
	Icon = "blend",
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 178, 124)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 168, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 90, 240)),
	}),
	Flag = "ThemeGradient",
	Callback = function(seq)
		if connected == "gradient" then
			Window:SetTabAccent(evalSeq(seq, 0.5))
		end
	end,
})

Home:CreateToggle({
	Name = "Gradient glow",
	CurrentValue = true,
	Callback = function(value)
		Gradient:SetGlow(value)
	end,
})

GradientConnect = Home:CreateToggle({
	Name = "Connect gradient to tab accent",
	Description = "Drives the tab accent from the gradient midpoint. Turns off the solid connection.",
	CurrentValue = false,
	Callback = function(value)
		if value then
			connected = "gradient"
			if SolidConnect then SolidConnect:Set(false) end
			Window:SetTabAccent(evalSeq(Gradient.Value, 0.5))
		elseif connected == "gradient" then
			connected = nil
		end
	end,
})

Player:CreateSection("Filler")
Player:CreateToggle({Name = "Example toggle", CurrentValue = true, Callback = function() end})

Visuals:CreateSection("Filler")
Visuals:CreateButton({Name = "Example button", Callback = function() end})

Rayfield:Notify({
	Title = "Gen3 Test5 loaded",
	Content = "Toggle each picker's glow, and connect one picker to the tab accent.",
	Duration = 5,
	Icon = "check",
})
