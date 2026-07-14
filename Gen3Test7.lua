local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_3_Concept/main/source.lua"))()

-- To try the key system, uncomment KeySystem and KeySettings below.
local Window = Rayfield:CreateWindow({
	Name = "Gen3 Test7",
	Subtitle = "Phase 7",
	Icon = "sparkles",
	Badge = { Text = "phase 7", Icon = "flask-conical" },
	TabStyle = "Accent",
	Acrylic = true, -- frosted-glass blur; makes the window see-through so the frost shows
	-- KeySystem = true,
	-- KeySettings = { Title = "Key required", Key = { "letmein" } },
	ConfigurationSaving = { Enabled = true, FolderName = "Gen3Test7", FileName = "cfg" },
})

local Home = Window:CreateTab("Home", "house")

Home:CreateSection("Sliders")
Home:CreateSlider({ Name = "Field of View", Icon = "eye", Range = { 70, 120 }, Increment = 1,
	CurrentValue = 95, Suffix = "deg", Flag = "fov", Callback = function() end })
Home:CreateSlider({ Name = "Volume", Icon = "volume-2", Range = { 0, 100 }, Increment = 1,
	CurrentValue = 40, Suffix = "%", Flag = "vol", Callback = function() end })

-- Elements on demand: picking Advanced reveals two extra elements, Simple hides them
Home:CreateSection("Show elements on demand")
local AdvToggle, AdvSlider
Home:CreateDropdown({
	Name = "Mode",
	Icon = "sliders-horizontal",
	Options = { "Simple", "Advanced" },
	CurrentOption = "Simple",
	Flag = "mode",
	Callback = function(opt)
		local mode = type(opt) == "table" and opt[1] or opt
		local show = mode == "Advanced"
		if AdvToggle then AdvToggle:SetVisible(show) end
		if AdvSlider then AdvSlider:SetVisible(show) end
	end,
})
AdvToggle = Home:CreateToggle({ Name = "Advanced toggle", CurrentValue = false, Flag = "advtg", Callback = function() end })
AdvSlider = Home:CreateSlider({ Name = "Advanced slider", Range = { 0, 100 }, Increment = 1,
	CurrentValue = 30, Description = "Only visible in Advanced mode.", Flag = "advsl", Callback = function() end })
AdvToggle:SetVisible(false)
AdvSlider:SetVisible(false)

-- Divider and spacer
Home:CreateSpacer(18)
Home:CreateDivider()

Home:CreateSection("Dialog")
Home:CreateButton({
	Name = "Ask me (smooth dialog)",
	Icon = "message-square",
	Callback = function()
		Rayfield:Dialog({
			Title = "Reset everything?",
			Content = "This clears every saved value and puts the menu back to its defaults. You can't undo it.",
			Options = {
				{ Text = "Cancel" },
				{ Text = "Reset", Color = Color3.fromRGB(200, 70, 70), Callback = function() end },
			},
		})
	end,
})

Home:CreateSection("Transparency and blur")
Home:CreateToggle({ Name = "Acrylic blur", Icon = "sparkles", CurrentValue = true, Callback = function(s) Window:SetAcrylic(s) end })

-- Built-in AI: free and rate limited out of the box, no key needed.
-- Pass Keys = { "sk-...", "sk-..." } to use your own; they stack, and the chat
-- asks before switching keys when one fails.
local AITab = Window:CreateTab("AI", "bot")
AITab:CreateAIChat({
	Name = "Assistant",
	Height = 320,
	SystemPrompt = "You are a friendly, concise assistant inside a Roblox menu.",
	-- Keys = { "sk-your-key-1", "sk-your-key-2" },
})
AITab:CreateParagraph({
	Title = "Session dashboard",
	Content = "Open the gear (top right) and check the Session section: player, active clients in the server, uptime, and FPS, all live.",
})

Rayfield:LoadConfiguration()
Rayfield:Notify({
	Title = "Gen3 Test7 loaded",
	Content = "Try Mode > Advanced, the AI tab, and the gear's Session stats.",
	Duration = 6,
	Icon = "check",
})
