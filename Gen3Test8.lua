local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test8",
	Subtitle = "Phase 8",
	Icon = "sparkles",
	Badge = { Text = "phase 8", Icon = "flask-conical" },
	TabStyle = "Accent",
	ConfigurationSaving = { Enabled = true, FolderName = "Gen3Test8", FileName = "cfg" },
	-- The assistant lives in the top bar (the sparkles icon) and opens a floating
	-- popup. It permanently knows Diablo made it and that this is Gen3, no matter
	-- what prompt or API keys are set. Pass AI = false to remove it.
	AI = {
		SystemPrompt = "You are the friendly Gen3 assistant. Keep answers short.",
		Actions = {
			{ Name = "jump", Description = "make the player's character jump once", Callback = function()
				local ch = game.Players.LocalPlayer.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if hum then hum.Jump = true end
			end },
		},
	},
})

local Home = Window:CreateTab("Home", "house")

Home:CreateSection("Slider (Gen2 look)")
local FovSlider = Home:CreateSlider({ Name = "Field of View", Icon = "eye", Range = { 70, 120 }, Increment = 1,
	CurrentValue = 95, Suffix = "deg", Flag = "fov", Callback = function() end })
Home:CreateSlider({ Name = "Volume", Icon = "volume-2", Range = { 0, 100 }, Increment = 1,
	CurrentValue = 40, Suffix = "%", Flag = "vol", Callback = function() end })

Home:CreateSection("Spoilers")
Home:CreateSpoiler({
	Name = "Boss location",
	Text = "The boss spawns behind the waterfall on the north cliff after 12 minutes.",
})
local ElemSpoiler = Home:CreateSpoiler({ Name = "Hidden controls" })
ElemSpoiler:CreateToggle({ Name = "God mode", CurrentValue = false, Flag = "god", Callback = function() end })
ElemSpoiler:CreateSlider({ Name = "Fly speed", Range = { 0, 200 }, Increment = 1, CurrentValue = 50, Flag = "fly", Callback = function() end })

Home:CreateSection("Dropdown")
local Weapon = Home:CreateDropdown({
	Name = "Weapon",
	Icon = "sword",
	Placeholder = "Pick one",
	Options = {
		{ Section = "Melee" }, "Sword", "Axe", "Dagger", "Mace",
		{ Section = "Ranged" }, "Bow", "Rifle", "Pistol", "Crossbow", "Sling",
	},
	CurrentOption = "Bow",
	Flag = "weapon",
	Callback = function() end,
})

local More = Window:CreateTab("More", "sliders-horizontal")

More:CreateSection("Hold to confirm")
More:CreateHoldButton({
	Name = "Hold to wipe save",
	Icon = "trash-2",
	Duration = 1,
	CompletionText = "Save wiped.",
	Callback = function() end,
})

-- A second dropdown, on a different tab, that the tutorial will jump to and open
More:CreateSection("Aiming")
local AimPart = More:CreateDropdown({
	Name = "Aim part",
	Icon = "crosshair",
	Options = { "Head", "Torso", "Arms", "Legs", "Root" },
	CurrentOption = "Head",
	Flag = "aimpart",
	Callback = function() end,
})

More:CreateSection("Assistant")
More:CreateParagraph({
	Title = "Ask the assistant",
	Content = "Tap the sparkles icon in the top bar to open the assistant popup. Ask: who made you? what is this? Then say: make me jump.",
})

local Tour
More:CreateButton({
	Name = "Replay Get Started",
	Icon = "graduation-cap",
	Callback = function() if Tour then Tour:Start() end end,
})

-- Built last so every element it points at already exists. The tutorial drives
-- the menu itself: it switches tabs, scrolls, and opens dropdowns for you.
Tour = Window:CreateTutorial({
	AutoStart = true,
	Delay = 0.9,
	OnFinish = function() Rayfield:Notify({ Title = "All set", Content = "You finished the tour.", Duration = 4, Icon = "check" }) end,
	Steps = {
		{ Title = "Welcome to Gen3 Test8", Icon = "sparkles",
			Content = "A quick tour of the phase 8 bits. Sit back, the tour drives the menu itself. Tap Next, or Skip anytime." },
		{ Title = "The Gen2 slider", Icon = "eye", Target = FovSlider,
			Content = "Sliders use the chunky Fanmade Gen2 track and white pill you liked." },
		{ Title = "Spoilers", Icon = "eye-off", Target = ElemSpoiler,
			Content = "Hide text or whole elements behind a cover. Tap the cover to reveal, the eye to hide." },
		{ Title = "The dropdown opens for you", Icon = "list", Target = Weapon, Open = true,
			Content = "Watch: the tour opens the Weapon dropdown so you can see exactly where the options live." },
		{ Title = "Even across tabs", Icon = "crosshair", Target = AimPart, Open = true,
			Content = "This one lives on the More tab. The tour switches tabs, scrolls to it, and opens it. That's the whole point." },
		{ Title = "Meet the assistant", Icon = "sparkles",
			Content = "The sparkles icon in the top bar opens the assistant popup. It knows it was made by Diablo and can run actions." },
		{ Title = "You're ready", Icon = "check",
			Content = "That's everything new. Press Finish and start building." },
	},
})

Rayfield:LoadConfiguration()
Rayfield:Notify({
	Title = "Gen3 Test8 loaded",
	Content = "The Get Started tour opens in a moment and drives the menu itself.",
	Duration = 6,
	Icon = "check",
})
