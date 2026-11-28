--!strict
-- HUD: Coins / Gems / Tokens / Level + XP bar (กลางบน), ด่านปัจจุบัน และกล่องความคืบหน้าด่าน (ขวาบน)
-- อ่านค่าจาก player Attribute ที่ server ตั้งเท่านั้น

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modules = Shared:WaitForChild("Modules")
local Formulas = require(Modules:WaitForChild("Formulas"))
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local player = Players.LocalPlayer

local WATCHED = {
	"Coins",
	"Gems",
	"RebirthTokens",
	"Level",
	"XP",
	"SkillPoints",
	"StageUnlocked",
	"StageKills",
	"BossDefeated",
	"CurrentStage",
}

local HudController = {}

local function num(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if type(value) == "number" then value else default
end

local function chip(parent: Instance, width: number, color: Color3, order: number): TextLabel
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(width, 40)
	frame.BackgroundColor3 = Theme.PANEL
	frame.BackgroundTransparency = 0.15
	frame.LayoutOrder = order
	Ui.corner(frame, 12)
	Ui.stroke(frame, color, 2)
	frame.Parent = parent
	return Ui.label(frame, "", UDim2.new(1, -12, 1, -10), {
		Position = UDim2.fromOffset(6, 5),
		TextColor3 = color,
	})
end

function HudController.Start()
	local gui = Ui.screen("Hud", 1)

	local bar = Instance.new("Frame")
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 8)
	bar.Size = UDim2.fromOffset(600, 40)
	bar.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local coins = chip(bar, 130, Theme.COIN, 1)
	local gems = chip(bar, 100, Theme.GEM, 2)
	local tokens = chip(bar, 90, Theme.TOKEN, 3)

	local levelFrame = Instance.new("Frame")
	levelFrame.Size = UDim2.fromOffset(220, 40)
	levelFrame.BackgroundColor3 = Theme.PANEL
	levelFrame.BackgroundTransparency = 0.15
	levelFrame.LayoutOrder = 4
	Ui.corner(levelFrame, 12)
	Ui.stroke(levelFrame, Theme.XP, 2)
	levelFrame.Parent = bar
	local xpFill = Instance.new("Frame")
	xpFill.BackgroundColor3 = Theme.XP
	xpFill.BackgroundTransparency = 0.55
	xpFill.Size = UDim2.fromScale(0, 1)
	Ui.corner(xpFill, 12)
	xpFill.Parent = levelFrame
	local level = Ui.label(levelFrame, "", UDim2.new(1, -12, 1, -10), { Position = UDim2.fromOffset(6, 5) })

	local stageName = Ui.label(gui, "", UDim2.fromOffset(360, 22), {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 54),
		TextStrokeTransparency = 0.4,
	})

	-- กล่องความคืบหน้าด่าน (ขวาบน)
	local progress = Instance.new("Frame")
	progress.AnchorPoint = Vector2.new(1, 0)
	progress.Position = UDim2.new(1, -12, 0, 8)
	progress.Size = UDim2.fromOffset(240, 92)
	progress.BackgroundColor3 = Theme.PANEL
	progress.BackgroundTransparency = 0.15
	Ui.corner(progress, 12)
	Ui.stroke(progress, Theme.ACCENT, 2)
	progress.Parent = gui
	local progressTitle = Ui.label(progress, "", UDim2.new(1, -16, 0, 24), {
		Position = UDim2.fromOffset(8, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.COIN,
	})
	local progressBody = Ui.label(progress, "", UDim2.new(1, -16, 0, 54), {
		Position = UDim2.fromOffset(8, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextScaled = false,
		TextSize = 16,
		TextWrapped = true,
	})

	local function refresh()
		coins.Text = `🪙 {Formulas.format(num("Coins", 0))}`
		gems.Text = `💎 {Formulas.format(num("Gems", 0))}`
		tokens.Text = `🔁 {Formulas.format(num("RebirthTokens", 0))}`
		local lv = num("Level", 1)
		local need = Formulas.xpToNext(lv)
		local points = num("SkillPoints", 0)
		level.Text = `Lv.{lv}  {Formulas.format(num("XP", 0))}/{Formulas.format(need)}`
			.. (if points > 0 then `  ⭐{points}` else "")
		xpFill.Size = UDim2.fromScale(math.clamp(num("XP", 0) / need, 0, 1), 1)

		local currentIndex = num("CurrentStage", 1)
		local current = Config.STAGES[currentIndex]
		stageName.Text = if current
			then `🌍 {Config.WORLD_NAME} · ด่าน {currentIndex}: {current.Name}`
			else ""

		local unlocked = num("StageUnlocked", 1)
		local stage = Config.STAGES[unlocked]
		if not stage then
			return
		end
		progressTitle.Text = `ด่าน {unlocked}/{#Config.STAGES}: {stage.Name}`
		if stage.Boss then
			if player:GetAttribute("BossDefeated") == true then
				progressBody.Text =
					"✅ ล้มบอสแล้ว! Rebirth ได้ (เมนูขวา)"
			else
				local bossName = (Config.ENEMIES :: any)[stage.Boss].Name
				progressBody.Text =
					`ล้มบอส {bossName}\nเพื่อเคลียร์ {Config.WORLD_NAME}`
			end
		elseif stage.KillsToClear then
			local kills = math.min(num("StageKills", 0), stage.KillsToClear)
			progressBody.Text =
				`กำจัดมอน {kills}/{stage.KillsToClear}\nเพื่อปลดด่าน {unlocked + 1}`
		end
	end

	for _, name in WATCHED do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

return HudController
