local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test2",
	Subtitle = "Progress, hint, ripple",
	Icon = "flask-conical",
	Badge = {Text = "test", Icon = "bug"},
	LoadingTitle = "Gen3 Test2",
	LoadingSubtitle = "second batch",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Gen3Test2",
		FileName = "Test2",
	},
})

local Test = Window:CreateTab("New Stuff", "sparkles")

Test:CreateSection("Ripple button")

Test:CreateRippleButton({
	Name = "Click me",
	Icon = "mouse-pointer-click",
	Description = "Ripple spreads from wherever you press.",
	Callback = function()
		print("Ripple button clicked")
	end,
})

Test:CreateButton({
	Name = "Normal button for comparison",
	Callback = function()
		print("Normal button clicked")
	end,
})

Test:CreateSection("Progress bar")

Test:CreateProgressBar({
	Name = "Static progress",
	Icon = "battery-medium",
	CurrentValue = 65,
})

local LoadBar = Test:CreateProgressBar({
	Name = "Fake download",
	Icon = "download",
	Description = "Animates from 0 to 100 on a loop through Set.",
	CurrentValue = 0,
})

Test:CreateProgressBar({
	Name = "XP this level",
	Icon = "star",
	MaxValue = 500,
	Suffix = " xp",
	CurrentValue = 340,
})

Test:CreateSection("Scroll hint")

local Hint = Test:CreateScrollHint({
	Text = "Scroll to see the progress bar",
})

-- filler so the page actually scrolls
for i = 1, 6 do
	Test:CreateLabel("Filler row " .. i)
end

Test:CreateButton({
	Name = "You reached the bottom",
	Icon = "flag",
	Callback = function()
		Hint:Set("You found it")
		print("Bottom button clicked")
	end,
})

-- drive the fake download
task.spawn(function()
	while true do
		for v = 0, 100, 10 do
			LoadBar:Set(v)
			task.wait(0.4)
		end
		task.wait(1.2)
	end
end)

Rayfield:Notify({
	Title = "Gen3 Test2 loaded",
	Content = "Click the buttons for the ripple, watch the download bar fill.",
	Duration = 5,
	Icon = "check",
})
