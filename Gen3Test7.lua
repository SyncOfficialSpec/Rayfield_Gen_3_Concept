local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test7",
	Subtitle = "Transparency, fonts, sliders",
	Icon = "sparkles",
	Badge = { Text = "phase 7", Icon = "flask-conical" },
	TabStyle = "Accent",
	Acrylic = true, -- frosted-glass blur; makes the window see-through so the frost shows
	ConfigurationSaving = { Enabled = true, FolderName = "Gen3Test7", FileName = "cfg" },
})

local Home = Window:CreateTab("Home", "house")

Home:CreateSection("Sliders")
Home:CreateSlider({ Name = "Field of View", Icon = "eye", Range = { 70, 120 }, Increment = 1,
	CurrentValue = 95, Suffix = "deg", Flag = "fov", Callback = function() end })
Home:CreateSlider({ Name = "Volume", Icon = "volume-2", Range = { 0, 100 }, Increment = 1,
	CurrentValue = 40, Suffix = "%", Flag = "vol", Callback = function() end })
Home:CreateSlider({ Name = "Sensitivity", Range = { 0, 10 }, Increment = 0.1,
	CurrentValue = 3.5, Flag = "sens", Callback = function() end })

Home:CreateSection("Text input")
Home:CreateInput({ Name = "Nickname", PlaceholderText = "type here", CurrentValue = "",
	Flag = "nick", Callback = function() end })

Home:CreateSection("Transparency and blur")
Home:CreateParagraph({
	Title = "Try it",
	Content = "The window loads glassy with acrylic blur on, so the game behind it is frosted. Open the gear to drag the transparency, toggle Acrylic blur, and search every Roblox font.",
})
Home:CreateToggle({ Name = "Acrylic blur", Icon = "sparkles", CurrentValue = true, Callback = function(s) Window:SetAcrylic(s) end })
Home:CreateButton({ Name = "More transparent", Icon = "eye", Callback = function() Window:SetTransparency(0.6) end })
Home:CreateButton({ Name = "Less transparent", Icon = "eye-off", Callback = function() Window:SetTransparency(0.25) end })

Rayfield:LoadConfiguration()
Rayfield:Notify({
	Title = "Gen3 Test7 loaded",
	Content = "Drag the sliders. Open the gear for fonts and transparency.",
	Duration = 6,
	Icon = "check",
})
