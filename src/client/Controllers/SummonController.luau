--!strict
-- หน้าสุ่มไข่: โชว์อัตราดรอป, สุ่ม 1 / สุ่ม 3 ด้วย Coins, แอนิเมชันเปิดไข่
-- สุ่มจริงที่ server (SummonService) — client แค่ขอและโชว์ผล

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Modules = Shared:WaitForChild("Modules")
local Formulas = require(Modules:WaitForChild("Formulas"))
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local CARD_SIZE = Vector2.new(104, 150)
local MAX_CARDS = 3

local SummonController = {}
local Notify

function SummonController.Init(controllers)
	Notify = controllers.NotifyController
end

function SummonController.Start()
	local summonRemote = Net.func("Summon")
	local eggId = Config.EGG_ORDER[1]
	local egg = (Config.EGGS :: any)[eggId]
	local panel = Ui.panel(`🥚 {egg.Name}`, Vector2.new(580, 440))
	local content = panel.content

	-- ---------- ซ้าย: อัตราดรอป ----------
	local left = Instance.new("Frame")
	left.Size = UDim2.new(0, 190, 1, 0)
	left.BackgroundColor3 = Theme.PANEL_LIGHT
	Ui.corner(left, 14)
	left.Parent = content
	Ui.label(
		left,
		"อัตราดรอป",
		UDim2.new(1, -16, 0, 28),
		{ Position = UDim2.fromOffset(8, 8) }
	)
	local y = 44
	for _, rarity in Config.RARITY_ORDER do
		local rate = egg.Rates[rarity]
		if rate and rate > 0 then
			Ui.label(left, `{rarity}  {rate}%`, UDim2.new(1, -24, 0, 24), {
				Position = UDim2.fromOffset(12, y),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.RARITY_COLORS[rarity] or Theme.TEXT,
			})
			y += 30
		end
	end
	Ui.label(
		left,
		"สุ่มที่ server · ผลเข้ากระเป๋าทันที",
		UDim2.new(1, -16, 0, 40),
		{
			Position = UDim2.new(0, 8, 1, -48),
			TextScaled = false,
			TextSize = 13,
			TextWrapped = true,
			TextColor3 = Theme.TEXT_DIM,
		}
	)

	-- ---------- ขวา: ผลสุ่ม + ปุ่ม ----------
	local right = Instance.new("Frame")
	right.BackgroundTransparency = 1
	right.Position = UDim2.fromOffset(202, 0)
	right.Size = UDim2.new(1, -202, 1, 0)
	right.Parent = content

	local cardsRow = Instance.new("Frame")
	cardsRow.BackgroundTransparency = 1
	cardsRow.Size = UDim2.new(1, 0, 0, CARD_SIZE.Y)
	cardsRow.Position = UDim2.fromOffset(0, 10)
	cardsRow.Parent = right
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = cardsRow

	local hint = Ui.label(right, "กดสุ่มเลย!", UDim2.new(1, 0, 0, 30), {
		Position = UDim2.fromOffset(0, CARD_SIZE.Y + 24),
		TextColor3 = Theme.TEXT_DIM,
	})

	local function clearCards()
		for _, child in cardsRow:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	-- การ์ด 1 ใบ: ไข่สั่น → แตก → โชว์สัตว์
	local function revealCard(order: number, kind: string)
		local stats = Formulas.summonStats(kind, 1)
		if not stats then
			return
		end
		local rarityColor = Theme.RARITY_COLORS[stats.Rarity] or Theme.TEXT
		local card = Instance.new("Frame")
		card.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
		card.BackgroundColor3 = Theme.PANEL_LIGHT
		card.LayoutOrder = order
		Ui.corner(card, 12)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Theme.TEXT_DIM
		stroke.Parent = card
		card.Parent = cardsRow

		local eggIcon = Ui.label(card, "🥚", UDim2.fromScale(0.8, 0.6), {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
		})
		local shake = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true)
		TweenService:Create(eggIcon, shake, { Rotation = 15 }):Play()

		task.delay(0.55 + order * 0.25, function()
			if not card.Parent then
				return
			end
			eggIcon:Destroy()
			stroke.Color = rarityColor
			Ui.label(card, stats.Rarity, UDim2.new(1, -10, 0, 22), {
				Position = UDim2.fromOffset(5, 8),
				TextColor3 = rarityColor,
			})
			Ui.label(card, stats.Name, UDim2.new(1, -10, 0, 44), {
				Position = UDim2.fromOffset(5, 34),
				TextWrapped = true,
			})
			Ui.label(card, Theme.ELEMENT_LABELS[stats.Element] or stats.Element, UDim2.new(1, -10, 0, 22), {
				Position = UDim2.fromOffset(5, 84),
				TextColor3 = Theme.ELEMENT_COLORS[stats.Element] or Theme.TEXT,
			})
			Ui.label(
				card,
				Theme.ATTACK_TYPE_LABELS[stats.AttackType] or stats.AttackType,
				UDim2.new(1, -10, 0, 20),
				{
					Position = UDim2.fromOffset(5, 112),
					TextColor3 = Theme.TEXT_DIM,
				}
			)
			local scale = Instance.new("UIScale")
			scale.Scale = 0.6
			scale.Parent = card
			TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end)
	end

	local busy = false
	local function roll(count: number)
		if busy then
			return
		end
		busy = true
		local ok, success, payload = pcall(function()
			return summonRemote:InvokeServer(eggId, count)
		end)
		if ok and success == true and type(payload) == "table" then
			clearCards()
			hint.Text =
				"ได้สัตว์ใหม่! ดู/จัดทีมที่ 🎒 กระเป๋า"
			for order, result in payload do
				if order <= MAX_CARDS and type(result) == "table" and type(result.Kind) == "string" then
					revealCard(order, result.Kind)
				end
			end
			task.wait(0.6)
		elseif Notify then
			Notify.show(
				if ok and type(payload) == "string"
					then payload
					else "สุ่มไม่สำเร็จ",
				"Bad"
			)
		end
		busy = false
	end

	local buttons = Instance.new("Frame")
	buttons.BackgroundTransparency = 1
	buttons.AnchorPoint = Vector2.new(0, 1)
	buttons.Position = UDim2.fromScale(0, 1)
	buttons.Size = UDim2.new(1, 0, 0, 60)
	buttons.Parent = right
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.Padding = UDim.new(0, 12)
	buttonLayout.Parent = buttons
	for _, count in Config.ROLL_COUNTS do
		Ui.button(
			buttons,
			`สุ่ม {count} ({Formulas.format(egg.Price * count)} 🪙)`,
			if count == 1 then Theme.ACCENT else Color3.fromRGB(230, 140, 40),
			UDim2.fromOffset(170, 56),
			function()
				roll(count)
			end
		)
	end

	Ui.sideButton("🥚 Summon", 1, Theme.ACCENT, panel.toggle)
	Net.event("OpenPanel").OnClientEvent:Connect(function(name: unknown)
		if name == "Summon" then
			panel.open()
		end
	end)
end

return SummonController
