local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test5",
	Subtitle = "Tab dock and color picker",
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
	CurrentOption = "White",
	Callback = function(style)
		Window:SetTabStyle(style)
		print("Tab style:", style)
	end,
})

Home:CreateLabel("Switch between the tabs up top and feel the slide.", "mouse-pointer-click")

Home:CreateSection("New color picker")

Home:CreateColorPicker({
	Name = "Tab accent color",
	Icon = "palette",
	Color = Color3.fromRGB(74, 178, 124),
	Flag = "AccentColor",
	Callback = function(color)
		Window:SetTabAccent(color)
		print(("Tab accent: %d, %d, %d"):format(color.R * 255, color.G * 255, color.B * 255))
	end,
})

Player:CreateSection("Filler")
Player:CreateToggle({
	Name = "Example toggle",
	CurrentValue = true,
	Callback = function(v) print("Toggle:", v) end,
})
Player:CreateSlider({
	Name = "Example slider",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) end,
})

Visuals:CreateSection("Filler")
Visuals:CreateButton({
	Name = "Example button",
	Callback = function() print("Button") end,
})

Rayfield:Notify({
	Title = "Gen3 Test5 loaded",
	Content = "Click through the tabs, flip the style, open the color picker.",
	Duration = 5,
	Icon = "check",
})
