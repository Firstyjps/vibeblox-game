--!strict
-- หน้าอัปเกรด (Damage / HP ด้วย Coins) + Rebirth — ราคาแสดงจาก Formulas เดียวกับ server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Modules = Shared:WaitForChild("Modules")
local Formulas = require(Modules:WaitForChild("Formulas"))
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local player = Players.LocalPlayer

local UPGRADE_ORDER = { "Damage", "Health" }
local WATCHED = { "Coins", "Level", "Race", "Rebirths", "DamageUpgrades", "HealthUpgrades" }

local ShopController = {}
local Notify

local function snapshot(): any
	local function num(name: string, default: number): number
		local value = player:GetAttribute(name)
		return if type(value) == "number" then value else default
	end
	local race = player:GetAttribute("Race")
	return {
		Race = if type(race) == "string" then race else "",
		Coins = num("Coins", 0),
		Level = num("Level", 1),
		Rebirths = num("Rebirths", 0),
		DamageUpgrades = num("DamageUpgrades", 0),
		HealthUpgrades = num("HealthUpgrades", 0),
	}
end

local function invoke(remote: RemoteFunction, ...: any)
	local args = { ... }
	local ok, success, message = pcall(function()
		return remote:InvokeServer(table.unpack(args))
	end)
	if not (ok and success) and Notify then
		Notify.show(
			if ok and type(message) == "string" then message else "ทำไม่สำเร็จ",
			"Bad"
		)
	end
end

function ShopController.Init(controllers)
	Notify = controllers.NotifyController
end

function ShopController.Start()
	local upgradeRemote = Net.func("BuyUpgrade")
	local rebirthRemote = Net.func("Rebirth")
	local panel = Ui.panel("⬆️ อัปเกรด & Rebirth", Vector2.new(540, 420))
	local content = panel.content

	local statsLabel = Ui.label(content, "", UDim2.new(1, 0, 0, 26), {
		TextColor3 = Theme.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local rows: { [string]: { info: TextLabel, button: TextButton } } = {}
	for index, kind in UPGRADE_ORDER do
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(0, 34 + (index - 1) * 74)
		row.Size = UDim2.new(1, 0, 0, 66)
		row.BackgroundColor3 = Theme.PANEL_LIGHT
		Ui.corner(row, 12)
		row.Parent = content
		local info = Ui.label(row, "", UDim2.new(1, -190, 1, -16), {
			Position = UDim2.fromOffset(12, 8),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local button = Ui.button(row, "", Theme.GOOD, UDim2.fromOffset(160, 48), function()
			invoke(upgradeRemote, kind)
		end)
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -10, 0.5, 0)
		rows[kind] = { info = info, button = button }
	end

	local rebirthBox = Instance.new("Frame")
	rebirthBox.Position = UDim2.fromOffset(0, 190)
	rebirthBox.Size = UDim2.new(1, 0, 1, -190)
	rebirthBox.BackgroundColor3 = Theme.PANEL_LIGHT
	Ui.corner(rebirthBox, 12)
	Ui.stroke(rebirthBox, Color3.fromRGB(255, 120, 200), 2)
	rebirthBox.Parent = content
	local rebirthInfo = Ui.label(rebirthBox, "", UDim2.new(1, -24, 0, 80), {
		Position = UDim2.fromOffset(12, 8),
		TextScaled = false,
		TextSize = 17,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local confirmUntil = 0
	local rebirthButton: TextButton
	rebirthButton = Ui.button(
		rebirthBox,
		"Rebirth",
		Color3.fromRGB(230, 90, 180),
		UDim2.new(1, -24, 0, 50),
		function()
			local data = snapshot()
			if data.Level < Config.REBIRTH_MIN_LEVEL then
				if Notify then
					Notify.show(`ต้องถึง Lv.{Config.REBIRTH_MIN_LEVEL} ก่อน`, "Bad")
				end
				return
			end
			-- กดสองครั้งเพื่อยืนยัน (กันกดพลาดแล้วเงินหาย)
			if os.clock() > confirmUntil then
				confirmUntil = os.clock() + 3
				rebirthButton.Text = "กดอีกครั้งเพื่อยืนยัน!"
				task.delay(3, function()
					if os.clock() > confirmUntil then
						rebirthButton.Text = "Rebirth"
					end
				end)
				return
			end
			confirmUntil = 0
			rebirthButton.Text = "Rebirth"
			invoke(rebirthRemote)
		end
	)
	rebirthButton.AnchorPoint = Vector2.new(0, 1)
	rebirthButton.Position = UDim2.new(0, 12, 1, -12)

	local function refresh()
		local data = snapshot()
		statsLabel.Text =
			`ดาเมจ {Formulas.format(Formulas.playerDamage(data))} · HP {Formulas.format(
				Formulas.playerMaxHealth(data)
			)} · 🪙 {Formulas.format(data.Coins)}`

		for kind, row in rows do
			local def = (Config.UPGRADES :: any)[kind]
			local owned = data[kind .. "Upgrades"]
			row.info.Text =
				`{def.Name} ขั้น {owned}/{def.Max}  (+{math.floor(owned * def.Step * 100 + 0.5)}%)`
			if owned >= def.Max then
				row.button.Text = "เต็มแล้ว"
				row.button.BackgroundColor3 = Theme.PANEL
			else
				local cost = Formulas.upgradeCost(kind, owned)
				row.button.Text = `อัป {Formulas.format(cost)} 🪙`
				row.button.BackgroundColor3 = if data.Coins >= cost then Theme.GOOD else Theme.PANEL
			end
		end

		local nextMultiplier = Formulas.rebirthMultiplier(data.Rebirths + 1)
		rebirthInfo.Text =
			`Rebirth แล้ว {data.Rebirths} ครั้ง (โบนัส Coins/XP x{Formulas.rebirthMultiplier(
				data.Rebirths
			)})\nต้องถึง Lv.{Config.REBIRTH_MIN_LEVEL} · รีเซ็ต Coins + Level\nได้โบนัสเป็น x{nextMultiplier} ถาวร`
		rebirthButton.BackgroundColor3 = if data.Level >= Config.REBIRTH_MIN_LEVEL
			then Color3.fromRGB(230, 90, 180)
			else Theme.PANEL
	end

	for _, name in WATCHED do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	Ui.sideButton("⬆️ อัปเกรด", 2, Theme.GOOD, panel.toggle)
end

return ShopController
