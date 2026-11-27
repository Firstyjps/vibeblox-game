--!strict
-- Summon: สุ่มด้วย Gems, ใส่/ถอดทีม, ได้ XP/เลเวล, ตัว summon เดินตามและตีมอนรอบตัวเจ้าของ
-- ส่งข้อมูลให้ UI ผ่าน Attribute "SummonsJson" / "EquippedJson"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)
local RateLimit = require(ReplicatedStorage.Shared.Modules.RateLimit)
local Theme = require(ReplicatedStorage.Shared.Modules.Theme)

local TICK = 0.1
local TELEPORT_DISTANCE = 80
local MELEE_REACH = 3
local MAGE_REACH = 12

-- หน้าตาชั่วคราวตามสาย
local VISUALS: { [string]: any } = {
	Tank = { Size = Vector3.new(3, 3, 3), Shape = Enum.PartType.Block, Hover = 0 },
	Assassin = { Size = Vector3.new(1.6, 2.6, 1.6), Shape = Enum.PartType.Block, Hover = 0.5 },
	Mage = { Size = Vector3.new(2.2, 2.2, 2.2), Shape = Enum.PartType.Ball, Hover = 2.5 },
}

type Follower = {
	id: string,
	model: Model,
	root: BasePart,
	align: AlignPosition,
	orient: AlignOrientation,
	label: TextLabel,
	halfHeight: number,
	hover: number,
	lastAttack: number,
}

local SummonService = {}
local PlayerData, EnemyService

local followers: { [Player]: { [string]: Follower } } = {}
local rng = Random.new()
local folder: Folder
local attackFx: UnreliableRemoteEvent

local function countSummons(data: any): number
	local count = 0
	for _ in data.Summons do
		count += 1
	end
	return count
end

local function rollKind(): string
	local total = 0
	for _, rarity in Config.RARITY_ORDER do
		total += (Config.RARITIES :: any)[rarity].Weight
	end
	local pick = rng:NextNumber(0, total)
	local chosen = Config.RARITY_ORDER[1]
	for _, rarity in Config.RARITY_ORDER do
		pick -= (Config.RARITIES :: any)[rarity].Weight
		if pick <= 0 then
			chosen = rarity
			break
		end
	end
	local pool = {}
	for kind, def in Config.SUMMONS :: any do
		if def.Rarity == chosen then
			table.insert(pool, kind)
		end
	end
	if #pool == 0 then
		for kind in Config.SUMMONS :: any do
			table.insert(pool, kind)
		end
	end
	table.sort(pool)
	return pool[rng:NextInteger(1, #pool)]
end

local function labelText(entry: any): string
	local def = (Config.SUMMONS :: any)[entry.Kind]
	return `{def.Name} Lv.{entry.Level}`
end

local function createFollower(id: string, entry: any, position: Vector3): Follower
	local def = (Config.SUMMONS :: any)[entry.Kind]
	local visual = VISUALS[def.Role]
	local color = Theme.RARITY_COLORS[def.Rarity] or Theme.TEXT
	local fancy = def.Rarity == "Legendary" or def.Rarity == "Mythic"

	local model = Instance.new("Model")
	model.Name = def.Name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Shape = visual.Shape
	root.Size = visual.Size
	root.Color = color
	root.Material = if fancy or def.Role == "Mage" then Enum.Material.Neon else Enum.Material.SmoothPlastic
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(0.35, 0.35, 0.1)
		eye.Color = Color3.new(1, 1, 1)
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.CanTouch = false
		eye.CanQuery = false
		eye.Massless = true
		eye.CFrame = root.CFrame
			* CFrame.new(side * visual.Size.X * 0.2, visual.Size.Y * 0.18, -visual.Size.Z / 2 - 0.03)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = eye
		weld.Parent = eye
		eye.Parent = model
	end
	if fancy or def.Role == "Mage" then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = root
	end

	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxForce = math.huge
	align.MaxVelocity = 20
	align.Responsiveness = 40
	align.Position = position
	align.Parent = root
	local orient = Instance.new("AlignOrientation")
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = attachment
	orient.MaxTorque = math.huge
	orient.Responsiveness = 30
	orient.Parent = root

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 22)
	gui.StudsOffset = Vector3.new(0, visual.Size.Y / 2 + 1, 0)
	gui.MaxDistance = 60
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = labelText(entry)
	label.Parent = gui

	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	return {
		id = id,
		model = model,
		root = root,
		align = align,
		orient = orient,
		label = label,
		halfHeight = visual.Size.Y / 2,
		hover = visual.Hover,
		lastAttack = 0,
	}
end

local function ownerRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root and humanoid.Health > 0 then
		return root
	end
	return nil
end

-- ให้ตัว summon ในโลกตรงกับทีมปัจจุบัน
local function refreshFollowers(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local list = followers[player] or {}
	followers[player] = list
	local wanted = {}
	for _, id in data.Equipped do
		wanted[id] = true
	end
	for id, follower in list do
		if not wanted[id] then
			follower.model:Destroy()
			list[id] = nil
		end
	end
	local root = ownerRoot(player)
	for _, id in data.Equipped do
		local entry = data.Summons[id]
		if entry then
			local follower = list[id]
			if follower then
				follower.label.Text = labelText(entry)
			elseif root then
				list[id] = createFollower(id, entry, root.Position + Vector3.new(rng:NextNumber(-3, 3), 0, 3))
			end
		end
	end
end

local function sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("SummonsJson", HttpService:JSONEncode(data.Summons))
	player:SetAttribute("EquippedJson", HttpService:JSONEncode(data.Equipped))
	refreshFollowers(player)
end

local function summon(player: Player): (boolean, any)
	local data = PlayerData.get(player)
	if not data then
		return false, nil
	end
	if data.Gems < Config.SUMMON_COST_GEMS then
		return false, "Gems ไม่พอ"
	end
	if countSummons(data) >= Config.MAX_SUMMONS then
		return false, "ที่เก็บ summon เต็ม"
	end
	local kind = rollKind()
	local newId = ""
	PlayerData.update(player, function(d)
		newId = tostring(d.NextSummonId)
		d.NextSummonId += 1
		d.Gems -= Config.SUMMON_COST_GEMS
		d.Summons[newId] = { Kind = kind, Level = 1, XP = 0 }
		if #d.Equipped < Config.MAX_EQUIPPED then
			table.insert(d.Equipped, newId)
		end
	end)
	sync(player)
	return true, { Id = newId, Kind = kind }
end

local function setEquipped(player: Player, id: unknown, equip: unknown): (boolean, string?)
	if type(id) ~= "string" or #id > 16 or type(equip) ~= "boolean" then
		return false
	end
	local data = PlayerData.get(player)
	if not data or not data.Summons[id] then
		return false
	end
	local index = table.find(data.Equipped, id)
	if equip then
		if index then
			return true
		end
		if #data.Equipped >= Config.MAX_EQUIPPED then
			return false, `ทีมเต็ม ({Config.MAX_EQUIPPED} ตัว)`
		end
	elseif not index then
		return true
	end
	PlayerData.update(player, function(d)
		if equip then
			table.insert(d.Equipped, id)
		else
			table.remove(d.Equipped, index :: number)
		end
	end)
	sync(player)
	return true
end

-- EnemyService เรียกตอนเจ้าของได้รางวัลจากมอน
function SummonService.grantXP(player: Player, amount: number)
	local data = PlayerData.get(player)
	local xp = math.floor(amount + 0.5)
	if not data or xp <= 0 or #data.Equipped == 0 then
		return
	end
	PlayerData.update(player, function(d)
		for _, id in d.Equipped do
			local entry = d.Summons[id]
			if entry and entry.Level < Config.SUMMON_MAX_LEVEL then
				entry.XP += xp
				while
					entry.Level < Config.SUMMON_MAX_LEVEL
					and entry.XP >= Formulas.summonXpToNext(entry.Level)
				do
					entry.XP -= Formulas.summonXpToNext(entry.Level)
					entry.Level += 1
				end
			end
		end
	end)
	sync(player)
end

-- แทงก์ในทีมลดดาเมจที่เจ้าของโดน
function SummonService.getTankReduction(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local total = 0
	for _, id in data.Equipped do
		local entry = data.Summons[id]
		local stats = entry and Formulas.summonStats(entry.Kind, entry.Level)
		if stats then
			total += stats.TankReduction
		end
	end
	return math.min(total, Config.TANK_REDUCTION_CAP)
end

local function slotOffset(index: number, count: number): Vector3
	return Vector3.new((index - (count + 1) / 2) * 4, 0, 5)
end

local function thinkFor(player: Player, list: { [string]: Follower }, now: number)
	local data = PlayerData.get(player)
	local owner = ownerRoot(player)
	if not data or not owner then
		return
	end
	local ownerPosition = owner.Position
	local groundY = ownerPosition.Y - 3
	local target = EnemyService.findNearest(ownerPosition, Config.SUMMON_RANGE)
	local count = #data.Equipped

	for index, id in data.Equipped do
		local follower = list[id]
		local entry = data.Summons[id]
		local stats = entry and Formulas.summonStats(entry.Kind, entry.Level)
		if follower and stats then
			local y = groundY + follower.halfHeight + follower.hover
			local here = follower.root.Position
			local slot = (owner.CFrame * CFrame.new(slotOffset(index, count))).Position
			slot = Vector3.new(slot.X, y, slot.Z)
			if (here - slot).Magnitude > TELEPORT_DISTANCE then
				follower.root.CFrame = CFrame.new(slot)
				here = slot
			end
			follower.align.MaxVelocity = stats.Speed

			if target and target.dead then
				target = EnemyService.findNearest(ownerPosition, Config.SUMMON_RANGE)
			end
			if target then
				local targetPosition = target.root.Position
				local goal = Vector3.new(targetPosition.X, y, targetPosition.Z)
				local offset = Vector3.new(goal.X - here.X, 0, goal.Z - here.Z)
				local reach = target.radius + (if stats.Role == "Mage" then MAGE_REACH else MELEE_REACH)
				if offset.Magnitude > reach then
					follower.align.Position = goal - offset.Unit * reach * 0.8
				else
					follower.align.Position = Vector3.new(here.X, y, here.Z)
					if now - follower.lastAttack >= stats.AttackCooldown then
						follower.lastAttack = now
						local color = Theme.RARITY_COLORS[stats.Rarity] or Theme.TEXT
						attackFx:FireAllClients(here, targetPosition, color)
						if stats.SplashRadius > 0 then
							EnemyService.damageArea(
								targetPosition,
								stats.SplashRadius,
								stats.Damage,
								player,
								"Summon"
							)
						else
							EnemyService.damage(target, stats.Damage, player, "Summon")
						end
					end
				end
				if offset.Magnitude > 0.5 then
					follower.orient.CFrame = CFrame.lookAt(here, goal).Rotation
				end
			else
				follower.align.Position = slot
				follower.orient.CFrame = owner.CFrame.Rotation
			end
		end
	end
end

function SummonService.Init(services)
	PlayerData = services.PlayerData
	EnemyService = services.EnemyService
end

function SummonService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Summons"
	folder.Parent = workspace
	attackFx = Net.unreliable("AttackFx")

	local allowSummon = RateLimit.new(3)
	local allowEquip = RateLimit.new(10)

	Net.func("Summon").OnServerInvoke = function(player: Player)
		if not allowSummon(player) then
			return false, nil
		end
		return summon(player)
	end
	Net.func("EquipSummon").OnServerInvoke = function(player: Player, id: unknown, equip: unknown)
		if not allowEquip(player) then
			return false
		end
		return setEquipped(player, id, equip)
	end

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart")
			refreshFollowers(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	PlayerData.Loaded:Connect(sync)
	for _, player in Players:GetPlayers() do
		if PlayerData.get(player) then
			sync(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		local list = followers[player]
		if list then
			for _, follower in list do
				follower.model:Destroy()
			end
		end
		followers[player] = nil
	end)

	while true do
		task.wait(TICK)
		local now = os.clock()
		for player, list in followers do
			local ok, err = pcall(thinkFor, player, list, now)
			if not ok then
				warn(`[SummonService] AI พัง: {err}`)
			end
		end
	end
end

return SummonService
