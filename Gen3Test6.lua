local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test6",
	Subtitle = "New elements and options",
	Icon = "sparkles",
	Badge = { Text = "test", Icon = "bug" },
	TabStyle = "Accent",
	ConfigurationSaving = { Enabled = true, FolderName = "Gen3Test6", FileName = "cfg" },
})

local Home = Window:CreateTab("Home", "house")
local More = Window:CreateTab("More", "sliders-horizontal")

-- New buttons
Home:CreateSection("New buttons")

Home:CreateHoldButton({
	Name = "Hold to wipe save",
	Icon = "trash-2",
	Duration = 1.5,
	Callback = function()
		Rayfield:Notify({ Title = "Wiped", Content = "Held long enough.", Duration = 3, Icon = "check" })
	end,
})

Home:CreateButton({
	Name = "Ask me (dialog)",
	Icon = "message-square",
	Callback = function()
		Rayfield:Dialog({
			Title = "Reset everything?",
			Content = "This clears every saved value and puts the menu back to its defaults. You can't undo it.",
			Options = {
				{ Text = "Cancel" },
				{ Text = "Reset", Color = Color3.fromRGB(200, 70, 70), Callback = function()
					Rayfield:Notify({ Title = "Reset", Content = "Everything was reset.", Duration = 3 })
				end },
			},
		})
	end,
})

Home:CreateButton({ Name = "Locked button", Icon = "ban", Locked = true, Callback = function() end })

-- Collapsible section with nested elements
local Adv = Home:CreateCollapsibleSection({ Name = "Advanced", Icon = "settings-2", Open = false })
Adv:CreateToggle({ Name = "Nested toggle", CurrentValue = true, Flag = "nt", Callback = function() end })
Adv:CreateSlider({ Name = "Nested slider", Range = { 0, 100 }, Increment = 1, CurrentValue = 60, Flag = "ns", Callback = function() end })

-- Changelog
Home:CreateChangelog({
	Title = "Update Log",
	Version = "v6",
	Entries = {
		{ Type = "+", Text = "Hold button, dialogs, and collapsible sections" },
		{ Type = "+", Text = "Preset color themes and custom fonts" },
		{ Type = "!", Text = "Hold button fill now follows the rounded corners" },
		{ Type = "~", Text = "Locked elements and dropdown upgrades" },
		{ Type = "-", Text = "Removed the old shadow hack" },
	},
})

-- Dropdown with sections, placeholder, reset
More:CreateSection("Dropdown")
local D = More:CreateDropdown({
	Name = "Weapon",
	Icon = "sword",
	Placeholder = "Pick one",
	Options = {
		{ Section = "Melee" }, "Sword", "Axe",
		{ Section = "Ranged" }, "Bow", "Rifle",
	},
	CurrentOption = "Bow",
	Flag = "weapon",
	Callback = function() end,
})
More:CreateButton({ Name = "Reset dropdown", Icon = "rotate-ccw", Callback = function() D:Reset() end })

-- Locked toggle plus a runtime lock/unlock demo
More:CreateSection("Locking")
local Lockable = More:CreateToggle({ Name = "Lockable toggle", CurrentValue = false, Flag = "lk", Callback = function() end })
More:CreateToggle({
	Name = "Lock the toggle above",
	CurrentValue = false,
	Callback = function(state) Lockable:SetLocked(state) end,
})

Rayfield:LoadConfiguration()
Rayfield:Notify({
	Title = "Gen3 Test6 loaded",
	Content = "Themes and fonts live in the gear. Try the hold button and dialog.",
	Duration = 6,
	Icon = "check",
})
