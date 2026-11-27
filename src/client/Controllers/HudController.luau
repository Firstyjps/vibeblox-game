--!strict
-- HUD: Coins / Gems / Level + XP bar / Rebirth (กลางบน) และกล่องภารกิจโลก (ขวาบน)
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
	"Level",
	"XP",
	"Rebirths",
	"WorldUnlocked",
	"QuestKills",
	"QuestBoss",
	"CurrentWorld",
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
	bar.Size = UDim2.fromOffset(620, 40)
	bar.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local coins = chip(bar, 140, Theme.COIN, 1)
	local gems = chip(bar, 120, Theme.GEM, 2)

	local levelFrame = Instance.new("Frame")
	levelFrame.Size = UDim2.fromOffset(200, 40)
	levelFrame.BackgroundColor3 = Theme.PANEL
	levelFrame.BackgroundTransparency = 0.15
	levelFrame.LayoutOrder = 3
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

	local rebirths = chip(bar, 110, Color3.fromRGB(255, 120, 200), 4)

	local worldName = Ui.label(gui, "", UDim2.fromOffset(300, 22), {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 54),
		TextStrokeTransparency = 0.4,
	})

	-- กล่องภารกิจ (ขวาบน)
	local quest = Instance.new("Frame")
	quest.AnchorPoint = Vector2.new(1, 0)
	quest.Position = UDim2.new(1, -12, 0, 8)
	quest.Size = UDim2.fromOffset(240, 96)
	quest.BackgroundColor3 = Theme.PANEL
	quest.BackgroundTransparency = 0.15
	Ui.corner(quest, 12)
	Ui.stroke(quest, Theme.ACCENT, 2)
	quest.Parent = gui
	local questTitle = Ui.label(quest, "", UDim2.new(1, -16, 0, 24), {
		Position = UDim2.fromOffset(8, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.COIN,
	})
	local questBody = Ui.label(quest, "", UDim2.new(1, -16, 0, 56), {
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
		local lv = num("Level", 1)
		local need = Formulas.xpToNext(lv)
		level.Text = `Lv.{lv}  ({Formulas.format(num("XP", 0))}/{Formulas.format(need)})`
		xpFill.Size = UDim2.fromScale(math.clamp(num("XP", 0) / need, 0, 1), 1)
		rebirths.Text = `🔁 {num("Rebirths", 0)}`

		local current = Config.WORLDS[num("CurrentWorld", 1)]
		worldName.Text = if current then `🌍 {current.Name}` else ""

		local unlocked = num("WorldUnlocked", 1)
		local world = Config.WORLDS[unlocked]
		if world then
			local kills = math.min(num("QuestKills", 0), world.QuestKills)
			local bossDone = player:GetAttribute("QuestBoss") == true
			questTitle.Text = `ภารกิจ: {world.Name}`
			if kills >= world.QuestKills and bossDone then
				local nextWorld = Config.WORLDS[unlocked + 1]
				questBody.Text = if nextWorld
					then `✅ เสร็จแล้ว! ไป Portal เปิด {nextWorld.Name} ({Formulas.format(
						nextWorld.UnlockCost
					)} 🪙)`
					else "✅ เคลียร์ทุกโลกแล้ว! รอโลกใหม่เร็วๆ นี้"
			else
				questBody.Text =
					`กำจัดมอน {kills}/{world.QuestKills}\nชนะบอส {if bossDone
						then "✅"
						else "❌"}`
			end
		end
	end

	for _, name in WATCHED do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

return HudController
