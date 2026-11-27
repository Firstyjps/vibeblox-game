--!strict
-- หน้า Summon: สุ่มด้วย Gems + จัดทีม (ใส่/ถอด) — ข้อมูลอ่านจาก Attribute SummonsJson / EquippedJson

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Modules = Shared:WaitForChild("Modules")
local Formulas = require(Modules:WaitForChild("Formulas"))
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local player = Players.LocalPlayer

local ROW_HEIGHT = 54

local SummonController = {}
local Notify

local function decode(name: string): any
	local raw = player:GetAttribute(name)
	if type(raw) ~= "string" then
		return {}
	end
	local ok, value = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(value) == "table" then value else {}
end

local function rarityRank(rarity: string): number
	return table.find(Config.RARITY_ORDER, rarity) or 0
end

function SummonController.Init(controllers)
	Notify = controllers.NotifyController
end

function SummonController.Start()
	local summonRemote = Net.func("Summon")
	local equipRemote = Net.func("EquipSummon")
	local panel = Ui.panel("🔮 Summon", Vector2.new(720, 460))
	local content = panel.content

	-- ---------- ซ้าย: ตู้สุ่ม ----------
	local left = Instance.new("Frame")
	left.Size = UDim2.new(0, 250, 1, 0)
	left.BackgroundColor3 = Theme.PANEL_LIGHT
	Ui.corner(left, 14)
	left.Parent = content

	local rates = {}
	local totalWeight = 0
	for _, rarity in Config.RARITY_ORDER do
		totalWeight += (Config.RARITIES :: any)[rarity].Weight
	end
	for _, rarity in Config.RARITY_ORDER do
		local weight = (Config.RARITIES :: any)[rarity].Weight
		table.insert(rates, `{rarity}  {math.floor(weight / totalWeight * 1000 + 0.5) / 10}%`)
	end
	Ui.label(left, "ตู้ Mystic", UDim2.new(1, -16, 0, 30), { Position = UDim2.fromOffset(8, 8) })
	Ui.label(left, table.concat(rates, "\n"), UDim2.new(1, -24, 0, 100), {
		Position = UDim2.fromOffset(12, 42),
		TextScaled = false,
		TextSize = 16,
		TextColor3 = Theme.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local result = Instance.new("Frame")
	result.Position = UDim2.fromOffset(12, 150)
	result.Size = UDim2.new(1, -24, 0, 110)
	result.BackgroundColor3 = Theme.PANEL
	Ui.corner(result, 12)
	local resultStroke = Instance.new("UIStroke")
	resultStroke.Thickness = 3
	resultStroke.Color = Theme.ACCENT
	resultStroke.Parent = result
	result.Parent = left
	local resultText = Ui.label(result, "กดสุ่มเลย!", UDim2.new(1, -16, 1, -16), {
		Position = UDim2.fromOffset(8, 8),
		TextColor3 = Theme.TEXT_DIM,
	})
	local resultScale = Instance.new("UIScale")
	resultScale.Parent = result

	local busy = false
	local rollButton = Ui.button(
		left,
		`สุ่ม ({Config.SUMMON_COST_GEMS} 💎)`,
		Theme.ACCENT,
		UDim2.new(1, -24, 0, 56),
		function()
			if busy then
				return
			end
			busy = true
			local ok, success, payload = pcall(function()
				return summonRemote:InvokeServer()
			end)
			busy = false
			if ok and success == true and type(payload) == "table" then
				local stats = Formulas.summonStats(payload.Kind, 1)
				if stats then
					local color = Theme.RARITY_COLORS[stats.Rarity] or Theme.TEXT
					resultText.Text =
						`{stats.Rarity}\n{stats.Name}\n{Theme.ROLE_LABELS[stats.Role] or stats.Role}`
					resultText.TextColor3 = color
					resultStroke.Color = color
					resultScale.Scale = 0.6
					TweenService
						:Create(resultScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 })
						:Play()
				end
			elseif Notify then
				Notify.show(
					if ok and type(payload) == "string"
						then payload
						else "สุ่มไม่สำเร็จ",
					"Bad"
				)
			end
		end
	)
	rollButton.AnchorPoint = Vector2.new(0, 1)
	rollButton.Position = UDim2.new(0, 12, 1, -12)

	-- ---------- ขวา: ทีม + คลัง ----------
	local teamLabel = Ui.label(content, "", UDim2.new(1, -266, 0, 30), {
		Position = UDim2.fromOffset(266, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(266, 36)
	list.Size = UDim2.new(1, -266, 1, -36)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local function setEquipped(id: string, equip: boolean)
		local ok, success, message = pcall(function()
			return equipRemote:InvokeServer(id, equip)
		end)
		if not (ok and success) and Notify then
			Notify.show(
				if ok and type(message) == "string" then message else "ทำไม่สำเร็จ",
				"Bad"
			)
		end
	end

	local function refresh()
		local summons = decode("SummonsJson")
		local equipped = decode("EquippedJson")
		local equippedSet = {}
		for _, id in equipped do
			equippedSet[id] = true
		end
		teamLabel.Text =
			`ทีม {#equipped}/{Config.MAX_EQUIPPED} · ตีมอนรอบตัวให้อัตโนมัติ`

		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local entries = {}
		for id, entry in summons do
			local stats = Formulas.summonStats(entry.Kind, entry.Level)
			if stats then
				table.insert(
					entries,
					{ id = id, entry = entry, stats = stats, equipped = equippedSet[id] == true }
				)
			end
		end
		table.sort(entries, function(a, b)
			if a.equipped ~= b.equipped then
				return a.equipped
			end
			local ra, rb = rarityRank(a.stats.Rarity), rarityRank(b.stats.Rarity)
			if ra ~= rb then
				return ra > rb
			end
			return a.entry.Level > b.entry.Level
		end)

		for order, item in entries do
			local color = Theme.RARITY_COLORS[item.stats.Rarity] or Theme.TEXT
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -12, 0, ROW_HEIGHT)
			row.BackgroundColor3 = Theme.PANEL_LIGHT
			row.LayoutOrder = order
			Ui.corner(row, 10)
			if item.equipped then
				Ui.stroke(row, color, 2)
			end
			row.Parent = list
			local stripe = Instance.new("Frame")
			stripe.Size = UDim2.new(0, 8, 1, 0)
			stripe.BackgroundColor3 = color
			Ui.corner(stripe, 4)
			stripe.Parent = row
			Ui.label(row, `{item.stats.Name}  Lv.{item.entry.Level}`, UDim2.new(1, -150, 0, 26), {
				Position = UDim2.fromOffset(16, 4),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = color,
			})
			local roleText = Theme.ROLE_LABELS[item.stats.Role] or item.stats.Role
			Ui.label(
				row,
				`{item.stats.Rarity} · {roleText} · ดาเมจ {Formulas.format(item.stats.Damage)}`,
				UDim2.new(1, -150, 0, 18),
				{
					Position = UDim2.fromOffset(16, 31),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.TEXT_DIM,
				}
			)
			local button = Ui.button(
				row,
				if item.equipped then "ถอด" else "ใส่ทีม",
				if item.equipped then Theme.DANGER else Theme.GOOD,
				UDim2.fromOffset(110, 40),
				function()
					setEquipped(item.id, not item.equipped)
				end
			)
			button.AnchorPoint = Vector2.new(1, 0.5)
			button.Position = UDim2.new(1, -8, 0.5, 0)
		end

		if #entries == 0 then
			local empty = Instance.new("Frame")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -12, 0, 60)
			empty.Parent = list
			Ui.label(
				empty,
				"ยังไม่มี summon — สุ่มทางซ้ายได้เลย",
				UDim2.fromScale(1, 0.5),
				{
					TextColor3 = Theme.TEXT_DIM,
				}
			)
		end
	end

	-- XP summon เปลี่ยนทุกครั้งที่ฆ่ามอน → สร้างรายการใหม่เฉพาะตอนเปิดหน้านี้อยู่
	local dirty = true
	local function onChanged()
		if panel.frame.Visible then
			refresh()
		else
			dirty = true
		end
	end
	panel.frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.frame.Visible and dirty then
			dirty = false
			refresh()
		end
	end)
	player:GetAttributeChangedSignal("SummonsJson"):Connect(onChanged)
	player:GetAttributeChangedSignal("EquippedJson"):Connect(onChanged)

	Ui.sideButton("🔮 Summon", 1, Theme.ACCENT, panel.toggle)
end

return SummonController
