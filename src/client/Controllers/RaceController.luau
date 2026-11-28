--!strict
-- หน้าเลือกเผ่า: ขึ้นเองตอนยังไม่มีเผ่า (เลือกได้ครั้งเดียว)
-- ปุ่ม "Dev: เผ่า" โผล่เฉพาะ dev (server ตั้ง Attribute IsDev และตรวจซ้ำทุกครั้ง)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Modules = Shared:WaitForChild("Modules")
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local player = Players.LocalPlayer

local CARD_SIZE = Vector2.new(176, 250)

local RaceController = {}
local Notify

local overlay: Frame
local title: TextLabel
local closeButton: TextButton
local devMode = false
local busy = false

local function statLines(def: any): string
	local lines = {
		`ดาเมจ x{def.Damage}`,
		`HP x{def.Health}`,
		`ระยะตี {def.Range}`,
		`ตีทุก {def.AttackCooldown} วิ`,
		`ความเร็ว {def.WalkSpeed}`,
	}
	if def.Lifesteal > 0 then
		table.insert(lines, `ดูดเลือด {math.floor(def.Lifesteal * 100)}%`)
	end
	return table.concat(lines, "\n")
end

local function show(isDev: boolean)
	devMode = isDev
	title.Text = if isDev
		then "Dev: เปลี่ยนเผ่า"
		else "เลือกเผ่า Mystic Creature ของคุณ"
	closeButton.Visible = isDev
	overlay.Visible = true
end

local function pick(race: string)
	if busy then
		return
	end
	busy = true
	local remote = Net.func(if devMode then "DevSetRace" else "ChooseRace")
	local ok, result = pcall(function()
		return remote:InvokeServer(race)
	end)
	busy = false
	if ok and result == true then
		overlay.Visible = false
	elseif Notify then
		Notify.show(
			"เลือกเผ่าไม่สำเร็จ ลองอีกครั้ง",
			"Bad"
		)
	end
end

local function buildCard(parent: Instance, raceId: string, order: number)
	local def = (Config.RACES :: any)[raceId]
	local color = Theme.RACE_COLORS[raceId] or Theme.ACCENT
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	card.BackgroundColor3 = Theme.PANEL_LIGHT
	card.LayoutOrder = order
	Ui.corner(card, 16)
	Ui.stroke(card, color, 3)
	card.Parent = parent

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = color
	Ui.corner(header, 16)
	header.Parent = card
	Ui.label(header, def.Name, UDim2.new(1, -16, 1, -10), {
		Position = UDim2.fromOffset(8, 5),
		TextStrokeTransparency = 0.4,
	})
	Ui.label(card, def.Description, UDim2.new(1, -16, 0, 24), {
		Position = UDim2.fromOffset(8, 50),
		TextColor3 = color,
	})
	Ui.label(card, statLines(def), UDim2.new(1, -16, 0, 110), {
		Position = UDim2.fromOffset(8, 78),
		TextScaled = false,
		TextSize = 15,
		TextColor3 = Theme.TEXT_DIM,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local button = Ui.button(card, "เลือก", color, UDim2.new(1, -24, 0, 44), function()
		pick(raceId)
	end)
	button.Position = UDim2.new(0, 12, 1, -54)
end

function RaceController.Init(controllers)
	Notify = controllers.NotifyController
end

function RaceController.Start()
	local gui = Ui.screen("RacePicker", 20)
	overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(10, 8, 25)
	overlay.BackgroundTransparency = 0.25
	overlay.Visible = false
	overlay.Parent = gui

	title = Ui.label(overlay, "", UDim2.fromOffset(700, 48), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -CARD_SIZE.Y / 2 - 50),
		TextStrokeTransparency = 0.3,
	})

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.5)
	row.Size = UDim2.fromOffset(CARD_SIZE.X * #Config.RACE_ORDER + 12 * (#Config.RACE_ORDER - 1), CARD_SIZE.Y)
	row.Parent = overlay
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	for index, raceId in Config.RACE_ORDER do
		buildCard(row, raceId, index)
	end

	closeButton = Ui.button(overlay, "ปิด", Theme.DANGER, UDim2.fromOffset(120, 44), function()
		overlay.Visible = false
	end)
	closeButton.AnchorPoint = Vector2.new(0.5, 0)
	closeButton.Position = UDim2.new(0.5, 0, 0.5, CARD_SIZE.Y / 2 + 16)

	-- ยังไม่มีเผ่า → บังคับเลือก
	local function checkRace()
		if player:GetAttribute("Race") == "" then
			show(false)
		end
	end
	player:GetAttributeChangedSignal("Race"):Connect(checkRace)
	checkRace()

	-- ปุ่ม dev
	local devButton: TextButton? = nil
	local function checkDev()
		if player:GetAttribute("IsDev") == true and not devButton then
			devButton = Ui.sideButton("🛠 Dev: เผ่า", 99, Color3.fromRGB(90, 90, 110), function()
				show(true)
			end)
		end
	end
	player:GetAttributeChangedSignal("IsDev"):Connect(checkDev)
	checkDev()
end

return RaceController
