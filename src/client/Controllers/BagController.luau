--!strict
-- กระเป๋าสัตว์: ดูสัตว์ทั้งหมด, ใส่/ถอดทีม (สูงสุด 3), ปล่อยสัตว์ (กดสองครั้งยืนยัน)
-- ข้อมูลอ่านจาก Attribute SummonsJson / EquippedJson

local HttpService = game:GetService("HttpService")
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

local ROW_HEIGHT = 58
local RELEASE_CONFIRM_TIME = 3

local BagController = {}
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

function BagController.Init(controllers)
	Notify = controllers.NotifyController
end

function BagController.Start()
	local equipRemote = Net.func("EquipSummon")
	local releaseRemote = Net.func("ReleaseSummon")
	local panel = Ui.panel("🎒 กระเป๋าสัตว์", Vector2.new(620, 460))
	local content = panel.content

	local header = Ui.label(content, "", UDim2.new(1, 0, 0, 28), {
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(0, 36)
	list.Size = UDim2.new(1, 0, 1, -36)
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

	local function call(remote: RemoteFunction, ...: any)
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

	local pendingRelease: string? = nil
	local pendingUntil = 0

	local function refresh()
		local summons = decode("SummonsJson")
		local equipped = decode("EquippedJson")
		local equippedSet = {}
		for _, id in equipped do
			equippedSet[id] = true
		end

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
		header.Text =
			`ทีม {#equipped}/{Config.MAX_EQUIPPED} · กระเป๋า {#entries}/{Config.MAX_SUMMONS}`

		for order, item in entries do
			local stats = item.stats
			local rarityColor = Theme.RARITY_COLORS[stats.Rarity] or Theme.TEXT
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -12, 0, ROW_HEIGHT)
			row.BackgroundColor3 = Theme.PANEL_LIGHT
			row.LayoutOrder = order
			Ui.corner(row, 10)
			if item.equipped then
				Ui.stroke(row, rarityColor, 2)
			end
			row.Parent = list
			local stripe = Instance.new("Frame")
			stripe.Size = UDim2.new(0, 8, 1, 0)
			stripe.BackgroundColor3 = Theme.ELEMENT_COLORS[stats.Element] or Theme.TEXT
			Ui.corner(stripe, 4)
			stripe.Parent = row

			local maxed = item.entry.Level >= stats.MaxLevel
			Ui.label(
				row,
				`{stats.Name}  Lv.{item.entry.Level}{if maxed then " (MAX)" else ""}`,
				UDim2.new(1, -250, 0, 26),
				{
					Position = UDim2.fromOffset(16, 4),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = rarityColor,
				}
			)
			local element = Theme.ELEMENT_LABELS[stats.Element] or stats.Element
			local attackType = Theme.ATTACK_TYPE_LABELS[stats.AttackType] or stats.AttackType
			Ui.label(
				row,
				`{stats.Rarity} · {element} · {attackType} · ดาเมจ {Formulas.format(stats.Damage)}`,
				UDim2.new(1, -250, 0, 20),
				{
					Position = UDim2.fromOffset(16, 32),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Theme.TEXT_DIM,
				}
			)

			local equipButton = Ui.button(
				row,
				if item.equipped then "ถอด" else "ใส่ทีม",
				if item.equipped then Theme.DANGER else Theme.GOOD,
				UDim2.fromOffset(100, 42),
				function()
					call(equipRemote, item.id, not item.equipped)
				end
			)
			equipButton.AnchorPoint = Vector2.new(1, 0.5)
			equipButton.Position = UDim2.new(1, -118, 0.5, 0)

			if not item.equipped then
				local releaseButton: TextButton
				releaseButton = Ui.button(
					row,
					"ปล่อย",
					Color3.fromRGB(90, 85, 110),
					UDim2.fromOffset(100, 42),
					function()
						-- กดสองครั้งเพื่อยืนยัน (ปล่อยแล้วหายถาวร)
						if pendingRelease == item.id and os.clock() < pendingUntil then
							pendingRelease = nil
							call(releaseRemote, item.id)
						else
							pendingRelease = item.id
							pendingUntil = os.clock() + RELEASE_CONFIRM_TIME
							releaseButton.Text = "ยืนยัน?"
							releaseButton.BackgroundColor3 = Theme.DANGER
						end
					end
				)
				releaseButton.AnchorPoint = Vector2.new(1, 0.5)
				releaseButton.Position = UDim2.new(1, -8, 0.5, 0)
			end
		end

		if #entries == 0 then
			local empty = Instance.new("Frame")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -12, 0, 60)
			empty.Parent = list
			Ui.label(
				empty,
				"ยังไม่มีสัตว์ — ไปสุ่มไข่ที่ 🥚 Summon",
				UDim2.fromScale(1, 0.5),
				{
					TextColor3 = Theme.TEXT_DIM,
				}
			)
		end
	end

	-- EXP สัตว์เปลี่ยนทุกครั้งที่ฆ่ามอน → สร้างรายการใหม่เฉพาะตอนเปิดหน้านี้อยู่
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

	Ui.sideButton("🎒 กระเป๋า", 2, Color3.fromRGB(70, 150, 230), panel.toggle)
end

return BagController
