local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test8",
	Subtitle = "Phase 8",
	Icon = "sparkles",
	Badge = { Text = "phase 8", Icon = "flask-conical" },
	TabStyle = "Accent",
	ConfigurationSaving = { Enabled = true, FolderName = "Gen3Test8", FileName = "cfg" },
})

local Home = Window:CreateTab("Home", "house")

-- Slider: exactly the Fanmade Gen2 look (chunky track, accent-gradient fill, white pill)
Home:CreateSection("Slider (Gen2 look)")
local FovSlider = Home:CreateSlider({ Name = "Field of View", Icon = "eye", Range = { 70, 120 }, Increment = 1,
	CurrentValue = 95, Suffix = "deg", Flag = "fov", Callback = function() end })
Home:CreateSlider({ Name = "Volume", Icon = "volume-2", Range = { 0, 100 }, Increment = 1,
	CurrentValue = 40, Suffix = "%", Flag = "vol", Callback = function() end })

-- Spoilers: click the cover to reveal, click the eye to hide again
Home:CreateSection("Spoilers")
Home:CreateSpoiler({
	Name = "Boss location",
	Text = "The boss spawns behind the waterfall on the north cliff after 12 minutes.",
})
local ElemSpoiler = Home:CreateSpoiler({ Name = "Hidden controls" })
ElemSpoiler:CreateToggle({ Name = "God mode", CurrentValue = false, Flag = "god", Callback = function() end })
ElemSpoiler:CreateSlider({ Name = "Fly speed", Range = { 0, 200 }, Increment = 1, CurrentValue = 50, Flag = "fly", Callback = function() end })

-- Dropdown: no scrollbar, and the search sits behind an icon you click to open
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
More:CreateSection("Tutorial")
More:CreateParagraph({
	Title = "Get Started tour",
	Content = "Press the button below to replay the walkthrough. Menu creators add it with Window:CreateTutorial and a list of steps.",
})

-- Build the tutorial first so the buttons/elements it points at already exist
local Tour
More:CreateButton({
	Name = "Replay Get Started",
	Icon = "graduation-cap",
	Callback = function() if Tour then Tour:Start() end end,
})

Tour = Window:CreateTutorial({
	AutoStart = true,
	Delay = 0.8,
	OnFinish = function() Rayfield:Notify({ Title = "All set", Content = "You finished the tour.", Duration = 4, Icon = "check" }) end,
	Steps = {
		{ Title = "Welcome to Gen3 Test8", Icon = "sparkles",
			Content = "This quick tour shows the new phase 8 bits. Tap Next to walk through them, or Skip anytime." },
		{ Title = "The Gen2 slider is back", Icon = "eye", Target = FovSlider and FovSlider.Card,
			Content = "Sliders now use the chunky Fanmade Gen2 track and white pill you liked." },
		{ Title = "Spoilers", Icon = "eye-off", Target = ElemSpoiler and ElemSpoiler.Card,
			Content = "Hide text or whole elements behind a cover. Tap the cover to reveal, tap the eye to hide." },
		{ Title = "Cleaner dropdowns", Icon = "search", Target = Weapon and Weapon.Card,
			Content = "No more scrollbar, and the search hides behind the little icon until you want it." },
		{ Title = "You're ready", Icon = "check",
			Content = "That's everything new. Press Finish and start building." },
	},
})

Rayfield:LoadConfiguration()
Rayfield:Notify({
	Title = "Gen3 Test8 loaded",
	Content = "The Get Started tour opens in a moment. Try the spoilers and the dropdown search icon.",
	Duration = 6,
	Icon = "check",
})
