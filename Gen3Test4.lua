local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test4",
	Subtitle = "Picker, shimmer, greeting",
	Icon = "flask-conical",
	Badge = {Text = "test", Icon = "bug"},
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Gen3Test4",
		FileName = "Test4",
	},
})

local Test = Window:CreateTab("New Stuff", "sparkles")

Test:CreateSection("Segmented picker")

Test:CreateSegmentedPicker({
	Name = "Plan",
	Options = {
		"Free",
		{Name = "Premium", Options = {"Monthly", "Annual"}},
	},
	CurrentOption = "Free",
	Callback = function(main, sub)
		print("Plan:", main, sub or "")
	end,
})

Test:CreateSegmentedPicker({
	Name = "Quality",
	Description = "A plain three way split, no nested options.",
	Options = {"Low", "Medium", "High"},
	CurrentOption = "Medium",
	Callback = function(main)
		print("Quality:", main)
	end,
})

Test:CreateSection("Text shimmer")

local Shimmer = Test:CreateShimmerLabel({
	Text = "Text Shimmer",
	TextSize = 22,
})

Test:CreateButton({
	Name = "Rename shimmer",
	Callback = function()
		Shimmer:Set("Rayfield Gen 3")
		print("Shimmer renamed")
	end,
})

Test:CreateSection("Greeting intro")

Test:CreateButton({
	Name = "Play greeting",
	Icon = "hand",
	Tooltip = "Replays the hello intro over the window",
	Callback = function()
		Window:Greet({
			Texts = {"Hello", "bonjour", "hola", "Guten tag", "ciao"},
		})
		print("Greeting played")
	end,
})

-- play the greeting once on load
Window:Greet()

Rayfield:Notify({
	Title = "Gen3 Test4 loaded",
	Content = "Try the plan picker, watch the shimmer, replay the greeting.",
	Duration = 5,
	Icon = "check",
})
