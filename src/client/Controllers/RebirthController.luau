--!strict
-- หน้า Rebirth: โชว์เงื่อนไข (ล้มบอส + Coins) และสิ่งที่ได้ · กดสองครั้งเพื่อยืนยัน

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

local WATCHED = { "Coins", "Rebirths", "RebirthTokens", "BossDefeated" }
local CONFIRM_TIME = 3
local REBIRTH_COLOR = Color3.fromRGB(230, 90, 180)

local RebirthController = {}
local Notify

local function num(name: string): number
	local value = player:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

function RebirthController.Init(controllers)
	Notify = controllers.NotifyController
end

function RebirthController.Start()
	local rebirthRemote = Net.func("Rebirth")
	local panel = Ui.panel("🔁 Rebirth", Vector2.new(500, 360))
	local content = panel.content

	local info = Ui.label(content, "", UDim2.new(1, 0, 1, -70), {
		TextScaled = false,
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local confirmUntil = 0
	local button: TextButton
	button = Ui.button(content, "Rebirth", REBIRTH_COLOR, UDim2.new(1, 0, 0, 56), function()
		if os.clock() > confirmUntil then
			confirmUntil = os.clock() + CONFIRM_TIME
			button.Text = "กดอีกครั้งเพื่อยืนยัน!"
			task.delay(CONFIRM_TIME, function()
				if os.clock() > confirmUntil then
					button.Text = "Rebirth"
				end
			end)
			return
		end
		confirmUntil = 0
		button.Text = "Rebirth"
		local ok, success, message = pcall(function()
			return rebirthRemote:InvokeServer()
		end)
		if ok and success then
			panel.close()
		elseif Notify then
			Notify.show(
				if ok and type(message) == "string" then message else "Rebirth ไม่สำเร็จ",
				"Bad"
			)
		end
	end)
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.fromScale(0, 1)

	local function refresh()
		local rebirths = num("Rebirths")
		local cost = Formulas.rebirthCost(rebirths)
		local coins = num("Coins")
		local bossDone = player:GetAttribute("BossDefeated") == true
		local ready = bossDone and coins >= cost
		info.Text = table.concat({
			`Rebirth แล้ว {rebirths} ครั้ง · ตัวคูณตอนนี้ x{Formulas.rebirthMultiplier(
				rebirths
			)}`,
			`Rebirth Tokens: {num("RebirthTokens")}`,
			"",
			"เงื่อนไข",
			`{if bossDone then "✅" else "❌"} ล้มบอส {Config.WORLD_NAME}`,
			`{if coins >= cost then "✅" else "❌"} Coins {Formulas.format(coins)}/{Formulas.format(cost)}`,
			"",
			`ได้: ตัวคูณ Coins/พลังเป็น x{Formulas.rebirthMultiplier(
				rebirths + 1
			)} ถาวร + {Config.REBIRTH_TOKENS} Token`,
			"รีเซ็ต: Coins และด่าน (เลเวล, skill, สัตว์ ยังอยู่)",
		}, "\n")
		button.BackgroundColor3 = if ready then REBIRTH_COLOR else Theme.PANEL
	end

	for _, name in WATCHED do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	Ui.sideButton("🔁 Rebirth", 4, REBIRTH_COLOR, panel.toggle)
end

return RebirthController
