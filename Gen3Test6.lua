local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test6",
	Subtitle = "Color and gradient pickers",
	Icon = "flask-conical",
	Badge = {Text = "test", Icon = "bug"},
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Gen3Test6",
		FileName = "Test6",
	},
})

local Tab = Window:CreateTab("Pickers", "palette")

Tab:CreateSection("Single color picker")

Tab:CreateColorPicker({
	Name = "Solid color",
	Icon = "paintbrush",
	Color = Color3.fromRGB(74, 178, 124),
	Callback = function(color)
		print(("Solid: %d,%d,%d"):format(color.R * 255, color.G * 255, color.B * 255))
	end,
})

Tab:CreateSection("Gradient color picker")

Tab:CreateGradientPicker({
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

Tab:CreateGradientPicker({
	Name = "Two color gradient",
	Icon = "blend",
	Colors = {Color3.fromRGB(255, 120, 60), Color3.fromRGB(255, 210, 90)},
	Callback = function(seq)
		print("Two-color gradient updated")
	end,
})

Rayfield:Notify({
	Title = "Gen3 Test6 loaded",
	Content = "Open the gradient picker, drag the stops, tap the rail to add colors.",
	Duration = 5,
	Icon = "check",
})
