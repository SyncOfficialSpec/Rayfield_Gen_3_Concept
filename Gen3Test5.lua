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

Home:CreateSection("Tab dock")

Home:CreateSegmentedPicker({
	Name = "Tab style",
	Options = {"White", "Accent"},
	CurrentOption = "Accent",
	Callback = function(style)
		Window:SetTabStyle(style)
		print("Tab style:", style)
	end,
})

Home:CreateColorPicker({
	Name = "Tab accent color",
	Icon = "palette",
	Color = Color3.fromRGB(74, 178, 124),
	Callback = function(color)
		Window:SetTabAccent(color)
	end,
})

Home:CreateSection("Single color picker")

local Solid = Home:CreateColorPicker({
	Name = "Solid color",
	Icon = "paintbrush",
	Color = Color3.fromRGB(74, 178, 124),
	Callback = function(color)
		print(("Solid: %d,%d,%d"):format(color.R * 255, color.G * 255, color.B * 255))
	end,
})

Home:CreateToggle({
	Name = "Color picker glow",
	Description = "Turns the glow behind the single color picker swatch on or off.",
	CurrentValue = true,
	Callback = function(value)
		Solid:SetGlow(value)
		print("Color picker glow:", value)
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
		print("Gradient stops:", #seq.Keypoints)
	end,
})

Home:CreateToggle({
	Name = "Gradient glow",
	Description = "Turns the glow behind the gradient swatch on or off.",
	CurrentValue = true,
	Callback = function(value)
		Gradient:SetGlow(value)
		print("Gradient glow:", value)
	end,
})

Player:CreateSection("Filler")
Player:CreateToggle({Name = "Example toggle", CurrentValue = true, Callback = function() end})

Visuals:CreateSection("Filler")
Visuals:CreateButton({Name = "Example button", Callback = function() end})

Rayfield:Notify({
	Title = "Gen3 Test5 loaded",
	Content = "Try the tabs, both pickers, and the glow toggles.",
	Duration = 5,
	Icon = "check",
})
