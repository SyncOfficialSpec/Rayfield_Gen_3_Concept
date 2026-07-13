local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test7",
	Subtitle = "Transparency, fonts, sliders",
	Icon = "sparkles",
	Badge = { Text = "phase 7", Icon = "flask-conical" },
	TabStyle = "Accent",
	Transparency = 0.25, -- glassy window; adjust live in the gear settings
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

Home:CreateSection("Window transparency")
Home:CreateParagraph({
	Title = "Try it",
	Content = "Open the gear (top right). Drag Window transparency to see the panel go glassy, and open the Font picker to search every Roblox font. Or use the buttons below.",
})
Home:CreateButton({ Name = "More transparent", Icon = "eye", Callback = function() Window:SetTransparency(0.5) end })
Home:CreateButton({ Name = "Solid window", Icon = "eye-off", Callback = function() Window:SetTransparency(0) end })

Rayfield:LoadConfiguration()
Rayfield:Notify({
	Title = "Gen3 Test7 loaded",
	Content = "Drag the sliders. Open the gear for fonts and transparency.",
	Duration = 6,
	Icon = "check",
})
