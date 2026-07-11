local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test1",
	Subtitle = "New elements test",
	Icon = "flask-conical",
	Badge = {Text = "test", Icon = "bug"},
	LoadingTitle = "Gen3 Test1",
	LoadingSubtitle = "checkbox, copy, flip",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Gen3Test1",
		FileName = "Test1",
	},
})

local Test = Window:CreateTab("New Stuff", "sparkles")

Test:CreateSection("Checkbox")

local PlainCheckbox = Test:CreateCheckbox({
	Name = "Plain checkbox",
	CurrentValue = false,
	Callback = function(value)
		print("Plain checkbox:", value)
	end,
})

Test:CreateCheckbox({
	Name = "Checkbox with description",
	Description = "Starts checked, has a flag, saves to config.",
	CurrentValue = true,
	Flag = "TestCheckbox",
	Callback = function(value)
		print("Flagged checkbox:", value)
	end,
})

Test:CreateSection("Copy button")

Test:CreateCopyButton({
	Name = "Copy Discord Invite",
	Icon = "link",
	Text = "https://discord.gg/rayfield",
	Callback = function(value)
		print("Copied:", value)
	end,
})

local DynamicCopy = Test:CreateCopyButton({
	Name = "Copy player name",
	Icon = "user",
	Description = "Value set from code after creation.",
	Text = "placeholder",
})

Test:CreateSection("Flip button")

Test:CreateFlipButton({
	Front = "Hover me",
	Back = "Now click me",
	Callback = function()
		print("Flip button clicked")
	end,
})

local Counter = 0
local CountFlip = Test:CreateFlipButton({
	Front = "Clicks: 0",
	Back = "Click to count",
	Description = "Front text updates through Set on every click.",
	Callback = function()
		Counter += 1
	end,
})

-- exercise the Set methods after creation
task.spawn(function()
	task.wait(2)
	if DynamicCopy.Set then
		DynamicCopy:Set(game.Players.LocalPlayer.Name)
	end
	while task.wait(0.5) do
		CountFlip:Set({Front = "Clicks: " .. Counter})
	end
end)

-- flip the plain checkbox from code once, to test the programmatic path
task.delay(4, function()
	if PlainCheckbox.Set then
		PlainCheckbox:Set(true)
		print("Checkbox set from code")
	end
end)

Rayfield:Notify({
	Title = "Gen3 Test1 loaded",
	Content = "Try the checkbox, copy and flip cards. Watch the console for callbacks.",
	Duration = 5,
	Icon = "check",
})
