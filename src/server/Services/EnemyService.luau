--!strict
-- มอน/บอส: เกิด, AI (เดินเล่น → ไล่ → ตี → กลับบ้าน), รับดาเมจ, ตายแล้วแจกรางวัลตามสัดส่วนดาเมจ
--   services.EnemyService.findNearest(position, radius) → Enemy?
--   services.EnemyService.damage(enemy, amount, player, "Player" | "Summon")
--   services.EnemyService.damageArea(center, radius, amount, player, kind)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local TICK = 0.1
local RETURN_TIMEOUT = 6

-- หน้าตาชั่วคราว (เปลี่ยนเป็นโมเดลจริงทีหลัง)
local VISUALS: { [string]: any } = {
	Slime = {
		Size = Vector3.new(3.6, 3.6, 3.6),
		Shape = Enum.PartType.Ball,
		Color = Color3.fromRGB(80, 220, 200),
		Material = Enum.Material.Glass,
		Eye = Color3.fromRGB(20, 20, 30),
	},
	Wolf = {
		Size = Vector3.new(2.6, 2.8, 5),
		Shape = Enum.PartType.Block,
		Color = Color3.fromRGB(75, 55, 110),
		Material = Enum.Material.SmoothPlastic,
		Eye = Color3.fromRGB(255, 60, 60),
	},
	Imp = {
		Size = Vector3.new(2.6, 4, 2.6),
		Shape = Enum.PartType.Block,
		Color = Color3.fromRGB(210, 50, 40),
		Material = Enum.Material.SmoothPlastic,
		Eye = Color3.fromRGB(255, 230, 60),
	},
	Golem = {
		Size = Vector3.new(9, 11, 7),
		Shape = Enum.PartType.Block,
		Color = Color3.fromRGB(120, 125, 135),
		Material = Enum.Material.Slate,
		Eye = Color3.fromRGB(90, 230, 255),
	},
}

export type Enemy = {
	kind: string,
	worldIndex: number,
	isBoss: boolean,
	model: Model,
	root: BasePart,
	align: AlignPosition,
	orient: AlignOrientation,
	healthFill: Frame,
	size: Vector3,
	radius: number,
	groundY: number,
	maxHealth: number,
	health: number,
	damage: number,
	attackCooldown: number,
	aggro: number,
	home: Vector3,
	lastAttack: number,
	wanderAt: number,
	returning: boolean,
	returnStarted: number,
	lastAttacker: Player?,
	lastAttackedAt: number,
	damageBy: { [Player]: number },
	dead: boolean,
}

local EnemyService = {}
local ProgressionService, WorldService, CombatService, SummonService

local enemies: { [Enemy]: true } = {}
local folder: Folder
local rng = Random.new()
local popEvent: UnreliableRemoteEvent
local notifyEvent: RemoteEvent

local function flat(v: Vector3, y: number): Vector3
	return Vector3.new(v.X, y, v.Z)
end

local function alivePosition(player: Player): Vector3?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root and humanoid.Health > 0 then
		return root.Position
	end
	return nil
end

local function updateBar(enemy: Enemy)
	enemy.healthFill.Size = UDim2.fromScale(math.clamp(enemy.health / enemy.maxHealth, 0, 1), 1)
end

local function buildModel(kind: string, position: Vector3, scale: number, isBoss: boolean)
	local visual = VISUALS[kind]
	local def = (Config.ENEMIES :: any)[kind]
	local size = visual.Size * scale
	local model = Instance.new("Model")
	model.Name = def.Name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Shape = visual.Shape
	root.Size = size
	root.Color = visual.Color
	root.Material = visual.Material
	root.CanCollide = false
	root.CanTouch = false
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(size.X * 0.16, size.Y * 0.14, 0.2)
		eye.Color = visual.Eye
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.CanTouch = false
		eye.CanQuery = false
		eye.Massless = true
		eye.CFrame = root.CFrame * CFrame.new(side * size.X * 0.22, size.Y * 0.15, -size.Z / 2 - 0.05)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = eye
		weld.Parent = eye
		eye.Parent = model
	end

	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxForce = math.huge
	align.MaxVelocity = def.Speed
	align.Responsiveness = 40
	align.Position = position
	align.Parent = root
	local orient = Instance.new("AlignOrientation")
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = attachment
	orient.MaxTorque = math.huge
	orient.Responsiveness = 25
	orient.CFrame = CFrame.new()
	orient.Parent = root

	local gui = Instance.new("BillboardGui")
	gui.Size = if isBoss then UDim2.fromOffset(240, 40) else UDim2.fromOffset(120, 28)
	gui.StudsOffset = Vector3.new(0, size.Y / 2 + 1.8, 0)
	gui.MaxDistance = if isBoss then 160 else 70
	gui.Parent = root
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.55)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = if isBoss then Color3.fromRGB(255, 200, 60) else Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = def.Name
	nameLabel.Parent = gui
	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromScale(0.05, 0.62)
	barBack.Size = UDim2.fromScale(0.9, 0.3)
	barBack.BackgroundColor3 = Color3.fromRGB(30, 20, 30)
	barBack.BorderSizePixel = 0
	barBack.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = if isBoss then Color3.fromRGB(255, 70, 90) else Color3.fromRGB(110, 230, 90)
	fill.BorderSizePixel = 0
	fill.Parent = barBack
	for _, frame in { barBack, fill } do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = frame
	end

	return model, root, align, orient, fill, size
end

local spawnMob, spawnBoss

local function spawnEnemy(worldIndex: number, kind: string, position: Vector3, isBoss: boolean)
	local world = Config.WORLDS[worldIndex]
	local def = (Config.ENEMIES :: any)[kind]
	local scale = if isBoss then 1 + (worldIndex - 1) * 0.2 else 1
	local size = VISUALS[kind].Size * scale
	local groundY = position.Y + size.Y / 2
	local home = flat(position, groundY)
	local model, root, align, orient, fill = buildModel(kind, home, scale, isBoss)
	local enemy: Enemy = {
		kind = kind,
		worldIndex = worldIndex,
		isBoss = isBoss,
		model = model,
		root = root,
		align = align,
		orient = orient,
		healthFill = fill,
		size = size,
		radius = math.max(size.X, size.Z) / 2,
		groundY = groundY,
		maxHealth = def.Health * world.StatMultiplier,
		health = def.Health * world.StatMultiplier,
		damage = def.Damage * world.StatMultiplier,
		attackCooldown = def.AttackCooldown,
		aggro = if isBoss then Config.BOSS_AGGRO_RANGE else Config.ENEMY_AGGRO_RANGE,
		home = home,
		lastAttack = 0,
		wanderAt = os.clock() + rng:NextNumber(1, 4),
		returning = false,
		returnStarted = 0,
		lastAttacker = nil,
		lastAttackedAt = 0,
		damageBy = {},
		dead = false,
	}
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil) -- server คุมการเคลื่อนที่ (กันโกง)
	end)
	enemies[enemy] = true

	if isBoss then
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("CurrentWorld") == worldIndex then
				notifyEvent:FireClient(player, `{def.Name} ปรากฏตัวแล้ว!`, "Boss")
			end
		end
	end
end

local function randomMobPosition(worldIndex: number): Vector3
	local area = WorldService.getArea(worldIndex)
	for _ = 1, 10 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(area.minRadius, area.maxRadius)
		local position = area.origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if (position - area.bossPosition).Magnitude > 30 then
			return position
		end
	end
	return area.origin + Vector3.new(area.minRadius, 0, 0)
end

function spawnMob(worldIndex: number)
	local kinds = Config.WORLDS[worldIndex].Enemies
	spawnEnemy(worldIndex, kinds[rng:NextInteger(1, #kinds)], randomMobPosition(worldIndex), false)
end

function spawnBoss(worldIndex: number)
	local area = WorldService.getArea(worldIndex)
	spawnEnemy(worldIndex, Config.WORLDS[worldIndex].Boss, area.bossPosition, true)
end

local function fadeAndDestroy(model: Model)
	local info = TweenInfo.new(0.35)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			TweenService:Create(descendant, info, { Transparency = 1 }):Play()
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end
	task.delay(0.4, function()
		model:Destroy()
	end)
end

local function kill(enemy: Enemy)
	enemy.dead = true
	enemies[enemy] = nil
	local world = Config.WORLDS[enemy.worldIndex]
	local def = (Config.ENEMIES :: any)[enemy.kind]

	local topPlayer: Player? = nil
	local topDamage = 0
	for player, dealt in enemy.damageBy do
		if player.Parent then
			local share = math.min(dealt / enemy.maxHealth, 1)
			local credited = share >= Config.KILL_CREDIT_MIN_SHARE
			local coins = math.max(1, math.floor(def.Coins * world.RewardMultiplier * share + 0.5))
			local xp = math.max(1, math.floor(def.XP * world.RewardMultiplier * share + 0.5))
			local gems = if enemy.isBoss and credited then Config.BOSS_GEMS else nil
			ProgressionService.grant(player, { Coins = coins, XP = xp, Gems = gems })
			SummonService.grantXP(player, xp * Config.SUMMON_XP_SHARE)
			if credited then
				WorldService.onEnemyKilled(player, enemy.worldIndex, enemy.isBoss)
			end
			if gems then
				notifyEvent:FireClient(player, `ชนะ {def.Name}! +{gems} Gems`, "Good")
			end
			if dealt > topDamage then
				topPlayer, topDamage = player, dealt
			end
		end
	end
	if not enemy.isBoss and topPlayer and rng:NextNumber() < Config.MOB_GEM_CHANCE then
		ProgressionService.grant(topPlayer, { Gems = 1 })
		notifyEvent:FireClient(topPlayer, "ได้ 1 Gem!", "Gem")
	end

	fadeAndDestroy(enemy.model)
	if enemy.isBoss then
		task.delay(Config.BOSS_RESPAWN_TIME, spawnBoss, enemy.worldIndex)
	else
		task.delay(Config.ENEMY_RESPAWN_TIME, spawnMob, enemy.worldIndex)
	end
end

function EnemyService.damage(enemy: Enemy, amount: number, player: Player?, kind: string)
	if enemy.dead then
		return
	end
	local final = math.max(1, math.floor(amount + 0.5))
	local dealt = math.min(final, enemy.health)
	enemy.health -= final
	if player then
		enemy.damageBy[player] = (enemy.damageBy[player] or 0) + dealt
		enemy.lastAttacker = player
		enemy.lastAttackedAt = os.clock()
	end
	popEvent:FireAllClients(enemy.root.Position + Vector3.new(0, enemy.size.Y / 2, 0), final, kind)
	if enemy.health <= 0 then
		kill(enemy)
	else
		updateBar(enemy)
	end
end

function EnemyService.findNearest(position: Vector3, radius: number): Enemy?
	local best: Enemy? = nil
	local bestDistance = radius
	for enemy in enemies do
		local distance = (flat(enemy.root.Position, 0) - flat(position, 0)).Magnitude - enemy.radius
		if distance <= bestDistance then
			best, bestDistance = enemy, distance
		end
	end
	return best
end

function EnemyService.damageArea(
	center: Vector3,
	radius: number,
	amount: number,
	player: Player?,
	kind: string
)
	local hits = {}
	for enemy in enemies do
		if (flat(enemy.root.Position, 0) - flat(center, 0)).Magnitude - enemy.radius <= radius then
			table.insert(hits, enemy)
		end
	end
	for _, enemy in hits do
		EnemyService.damage(enemy, amount, player, kind)
	end
end

local function findTarget(enemy: Enemy, now: number): (Player?, Vector3?)
	local leash = Config.ENEMY_LEASH_RANGE
	local attacker = enemy.lastAttacker
	if attacker and now - enemy.lastAttackedAt < 6 then
		local position = alivePosition(attacker)
		if position and (flat(position, enemy.groundY) - enemy.home).Magnitude < leash then
			return attacker, position
		end
	end
	local here = enemy.root.Position
	local best, bestPosition, bestDistance = nil, nil, enemy.aggro
	for _, player in Players:GetPlayers() do
		local position = alivePosition(player)
		if position then
			local distance = (flat(position, 0) - flat(here, 0)).Magnitude
			if distance < bestDistance and (flat(position, enemy.groundY) - enemy.home).Magnitude < leash then
				best, bestPosition, bestDistance = player, position, distance
			end
		end
	end
	return best, bestPosition
end

local function face(enemy: Enemy, from: Vector3, toward: Vector3)
	if (toward - from).Magnitude > 0.5 then
		enemy.orient.CFrame = CFrame.lookAt(from, toward).Rotation
	end
end

local function think(enemy: Enemy, now: number)
	local here = flat(enemy.root.Position, enemy.groundY)
	local target, targetPosition = nil, nil
	if not enemy.returning then
		target, targetPosition = findTarget(enemy, now)
	end

	if target and targetPosition then
		local goal = flat(targetPosition, enemy.groundY)
		local offset = goal - here
		local reach = Config.ENEMY_ATTACK_REACH + enemy.radius
		if offset.Magnitude > reach then
			enemy.align.Position = goal - offset.Unit * reach * 0.7
		else
			enemy.align.Position = here
			if now - enemy.lastAttack >= enemy.attackCooldown then
				enemy.lastAttack = now
				CombatService.damagePlayer(target, enemy.damage)
			end
		end
		face(enemy, here, goal)
		return
	end

	local fromHome = (here - enemy.home).Magnitude
	if fromHome > Config.ENEMY_LEASH_RANGE or (enemy.returning and fromHome > 3) then
		if not enemy.returning then
			enemy.returning = true
			enemy.returnStarted = now
		end
		enemy.align.Position = enemy.home
		face(enemy, here, enemy.home)
		if now - enemy.returnStarted > RETURN_TIMEOUT then
			enemy.root.CFrame = CFrame.new(enemy.home) -- ติดอะไรอยู่ → วาร์ปกลับ
		end
		return
	end
	if enemy.returning then
		-- ถึงบ้าน → ฟื้นเต็ม ล้างเครดิตดาเมจ
		enemy.returning = false
		enemy.health = enemy.maxHealth
		enemy.damageBy = {}
		enemy.lastAttacker = nil
		updateBar(enemy)
	end
	if now >= enemy.wanderAt then
		enemy.wanderAt = now + rng:NextNumber(3, 7)
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = if enemy.isBoss then 4 else rng:NextNumber(2, 10)
		local goal = enemy.home + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		enemy.align.Position = goal
		face(enemy, here, goal)
	end
end

function EnemyService.Init(services)
	ProgressionService = services.ProgressionService
	WorldService = services.WorldService
	CombatService = services.CombatService
	SummonService = services.SummonService
end

function EnemyService.Start()
	popEvent = Net.unreliable("DamagePop")
	notifyEvent = Net.event("Notify")
	folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = workspace

	WorldService.ensureBuilt()
	for worldIndex, world in Config.WORLDS do
		for _ = 1, world.MaxEnemies do
			spawnMob(worldIndex)
		end
		spawnBoss(worldIndex)
	end

	while true do
		task.wait(TICK)
		local now = os.clock()
		for enemy in enemies do
			local ok, err = pcall(think, enemy, now)
			if not ok then
				warn(`[EnemyService] AI พัง: {err}`)
			end
		end
	end
end

return EnemyService
