local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test3",
	Subtitle = "Pins, tooltips, cursor tag",
	Icon = "flask-conical",
	Badge = {Text = "test", Icon = "bug"},
	LoadingTitle = "Gen3 Test3",
	LoadingSubtitle = "third batch",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "Gen3Test3",
		FileName = "Test3",
	},
})

local Test = Window:CreateTab("New Stuff", "sparkles")

Test:CreateSection("Pinned list")

local Rooms = Test:CreatePinnedList({
	Title = "All Items",
	Items = {
		{Name = "404 Room", Description = "Fixing errors · Open 24 hours", Icon = "triangle-alert"},
		{Name = "Commit Zone", Description = "Code updates · Closes 9:00 PM", Icon = "git-commit-horizontal"},
		{Name = "NPM Stop", Description = "Install stuff · Closes 8:00 PM", Icon = "package"},
		{Name = "Token Lock", Description = "Login stuff · Open 24 hours", Icon = "key-round"},
		{Name = "Regex Zone", Description = "Find words · Closes 9:00 PM", Icon = "regex"},
	},
	Callback = function(name, pinned)
		print("Pin changed:", name, pinned)
	end,
})

Test:CreateSection("Tooltips")

Test:CreateButton({
	Name = "Docs",
	Icon = "book-open",
	Tooltip = "Documentation",
	Callback = function()
		print("Docs clicked")
	end,
})

Test:CreateButton({
	Name = "Guide",
	Icon = "map",
	Tooltip = "User Guide",
	Callback = function()
		print("Guide clicked")
	end,
})

Test:CreateToggle({
	Name = "Lorem",
	CurrentValue = false,
	Tooltip = "Lorem ipsum dolor sit amet consectetur adipisicing elit",
	Callback = function(value)
		print("Lorem toggle:", value)
	end,
})

Test:CreateSection("Cursor tag")

local Tag = Test:CreateCursorTag({
	Text = "Designer",
	Hint = "Move your mouse over this area",
})

Test:CreateButton({
	Name = "Rename the tag",
	Tooltip = "Changes the cursor tag text through Set",
	Callback = function()
		Tag:Set("Developer")
		print("Tag renamed")
	end,
})

-- pin one item from code after 3 seconds to test the programmatic path
task.delay(3, function()
	Rooms:Pin("Token Lock", true)
	print("Pinned from code. Currently pinned:", table.concat(Rooms:GetPinned(), ", "))
end)

Rayfield:Notify({
	Title = "Gen3 Test3 loaded",
	Content = "Hover cards for tooltips, pin some items, wave over the cursor tag area.",
	Duration = 5,
	Icon = "check",
})
