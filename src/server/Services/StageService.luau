--!strict
-- ด่าน (โลก 1 = 5 ด่าน): สร้างแมพชั่วคราวจาก Part, จุดเกิดแต่ละด่าน, ประตูไปด่านอื่น, ความคืบหน้าด่าน
-- อยากเปลี่ยนเป็นโมเดลจริง: แก้ฟังก์ชัน decorate หรือวางโมเดลใน assets/models ทับตำแหน่งเดียวกัน

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

-- หน้าตาแต่ละด่าน (ไม่ใช่ค่าสมดุล → อยู่ที่นี่) · ลำดับตรงกับ Config.STAGES
local THEMES: { any } = {
	{
		Floor = Color3.fromRGB(120, 210, 90),
		Material = Enum.Material.Grass,
		Edge = Color3.fromRGB(80, 150, 60),
		Trees = 12,
		Flowers = 40,
		Rocks = 4,
		Leaf = { 0.25, 0.33 },
	},
	{
		Floor = Color3.fromRGB(75, 160, 70),
		Material = Enum.Material.Grass,
		Edge = Color3.fromRGB(55, 110, 50),
		Trees = 40,
		Flowers = 12,
		Rocks = 6,
		Leaf = { 0.3, 0.38 },
	},
	{
		Floor = Color3.fromRGB(95, 120, 80),
		Material = Enum.Material.Ground,
		Edge = Color3.fromRGB(90, 85, 80),
		Trees = 14,
		Flowers = 0,
		Rocks = 30,
		Leaf = { 0.22, 0.3 },
	},
	{
		Floor = Color3.fromRGB(120, 70, 45),
		Material = Enum.Material.Ground,
		Edge = Color3.fromRGB(80, 40, 30),
		Trees = 14,
		Flowers = 0,
		Rocks = 10,
		Lava = 10,
		Leaf = { 0.04, 0.09 },
	},
	{
		Floor = Color3.fromRGB(150, 150, 165),
		Material = Enum.Material.Slate,
		Edge = Color3.fromRGB(100, 100, 115),
		Trees = 0,
		Flowers = 0,
		Rocks = 0,
		Pillars = 10,
		Leaf = { 0.3, 0.3 },
	},
}

local STAGE_SPACING = 300
local FLOOR_SIZE = 220
local MOB_MIN_RADIUS = 22
local MOB_MAX_RADIUS = 90
local BOSS_OFFSET = Vector3.new(0, 0, -45)
local GATE_OFFSET = 88
local ARENA_RADIUS = 24

local StageService = {}
local PlayerData

local built = false
local spawns: { SpawnLocation } = {}
local mapFolder: Folder

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function label(parent: BasePart, text: string, color: Color3, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 60)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 120
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0.2
	textLabel.Text = text
	textLabel.Parent = gui
	gui.Parent = parent
end

function StageService.center(stageIndex: number): Vector3
	return Vector3.new((stageIndex - 1) * STAGE_SPACING, 0, 0)
end

local function randomSpot(rng: Random, origin: Vector3, minRadius: number): Vector3
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(minRadius, FLOOR_SIZE / 2 - 8)
	return origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function decorate(folder: Folder, origin: Vector3, theme: any, rng: Random)
	local function clearOfPaths(pos: Vector3): boolean
		local offset = pos - origin
		-- เว้นทางเดินไปประตู (แกน X) และวงบอส
		return math.abs(offset.Z) > 10 and (pos - (origin + BOSS_OFFSET)).Magnitude > ARENA_RADIUS + 6
	end
	for _ = 1, theme.Trees do
		local pos = randomSpot(rng, origin, 20)
		if clearOfPaths(pos) then
			local height = rng:NextNumber(8, 16)
			part({
				Name = "Trunk",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(height, 2.4, 2.4),
				CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(125, 85, 55),
				Material = Enum.Material.Wood,
				Parent = folder,
			})
			local leaf = rng:NextNumber(8, 13)
			part({
				Name = "Leaves",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(leaf, leaf, leaf),
				Position = pos + Vector3.new(0, height + leaf * 0.3, 0),
				Color = Color3.fromHSV(rng:NextNumber(theme.Leaf[1], theme.Leaf[2]), 0.7, 0.85),
				Parent = folder,
			})
		end
	end
	for _ = 1, theme.Flowers do
		local size = rng:NextNumber(1.2, 2.2)
		part({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			Position = randomSpot(rng, origin, 10) + Vector3.new(0, size / 2, 0),
			Color = Color3.fromHSV(rng:NextNumber(0, 1), 0.55, 1),
			CanCollide = false,
			Parent = folder,
		})
	end
	for _ = 1, theme.Rocks do
		local pos = randomSpot(rng, origin, 20)
		if clearOfPaths(pos) then
			local size = rng:NextNumber(3, 8)
			part({
				Name = "Rock",
				Size = Vector3.new(size, size * 0.7, size),
				CFrame = CFrame.new(pos + Vector3.new(0, size * 0.3, 0)) * CFrame.Angles(
					rng:NextNumber(-0.3, 0.3),
					rng:NextNumber(0, 6),
					rng:NextNumber(-0.3, 0.3)
				),
				Color = Color3.fromRGB(110, 110, 120),
				Material = Enum.Material.Slate,
				Parent = folder,
			})
		end
	end
	for _ = 1, theme.Lava or 0 do
		local size = rng:NextNumber(8, 16)
		part({
			Name = "Lava",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, size, size),
			CFrame = CFrame.new(randomSpot(rng, origin, 25) + Vector3.new(0, 0.1, 0))
				* CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 120, 30),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end
	for i = 1, theme.Pillars or 0 do
		local angle = (i / theme.Pillars) * math.pi * 2
		local pos = origin
			+ BOSS_OFFSET
			+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * (ARENA_RADIUS + 6)
		part({
			Name = "Pillar",
			Size = Vector3.new(4, 22, 4),
			Position = pos + Vector3.new(0, 11, 0),
			Color = Color3.fromRGB(200, 195, 210),
			Material = Enum.Material.Marble,
			Parent = folder,
		})
	end
end

local function buildGate(folder: Folder, position: Vector3, fromStage: number, toStage: number)
	local forward = toStage > fromStage
	local color = if forward then Color3.fromRGB(255, 170, 40) else Color3.fromRGB(80, 230, 140)
	for _, side in { -1, 1 } do
		part({
			Name = "GatePillar",
			Size = Vector3.new(1.5, 12, 1.5),
			Position = position + Vector3.new(0, 6, side * 5),
			Color = Color3.fromRGB(90, 80, 120),
			Material = Enum.Material.Marble,
			Parent = folder,
		})
	end
	local gate = part({
		Name = `GateTo{toStage}`,
		Size = Vector3.new(0.6, 10, 8.5),
		Position = position + Vector3.new(0, 5, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = false,
		Parent = folder,
	})
	local stage = Config.STAGES[toStage]
	label(gate, `{if forward then "→" else "←"} ด่าน {toStage}: {stage.Name}`, color, 8)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = `ไปด่าน {toStage}`
	prompt.ObjectText = stage.Name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = gate
	prompt.Triggered:Connect(function(player)
		StageService.useGate(player, toStage)
	end)
end

-- ที่วางไข่ (เดินไปกด E เปิดหน้าสุ่ม — สุ่มจริงทำผ่าน SummonService)
local function buildEggStand(folder: Folder, position: Vector3, eggId: string)
	local egg = (Config.EGGS :: any)[eggId]
	part({
		Name = "EggPedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 8, 8),
		CFrame = CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(235, 225, 255),
		Material = Enum.Material.Marble,
		Parent = folder,
	})
	local shell = part({
		Name = "Egg",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5, 5, 5),
		Position = position + Vector3.new(0, 4.6, 0),
		Color = Color3.fromRGB(140, 230, 120),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	label(shell, `{egg.Name}\n{egg.Price} Coins`, Color3.fromRGB(255, 230, 120), 5)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "เปิดหน้าสุ่ม"
	prompt.ObjectText = egg.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = shell
	prompt.Triggered:Connect(function(player)
		Net.event("OpenPanel"):FireClient(player, "Summon")
	end)
end

local function buildStage(index: number)
	local theme = THEMES[index] or THEMES[1]
	local stage = Config.STAGES[index]
	local origin = StageService.center(index)
	local folder = Instance.new("Folder")
	folder.Name = `Stage{index}_{stage.Name}`
	folder.Parent = mapFolder

	part({
		Name = "Floor",
		Size = Vector3.new(FLOOR_SIZE, 4, FLOOR_SIZE),
		Position = origin - Vector3.new(0, 2, 0),
		Color = theme.Floor,
		Material = theme.Material,
		Parent = folder,
	})
	-- กำแพงล่องหนกันตกขอบ + ขอบที่มองเห็น
	for _, dir in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
		local size = if dir.X ~= 0 then Vector3.new(4, 60, FLOOR_SIZE) else Vector3.new(FLOOR_SIZE, 60, 4)
		part({
			Name = "Wall",
			Size = size,
			Position = origin + dir * (FLOOR_SIZE / 2) + Vector3.new(0, 30, 0),
			Transparency = 1,
			Parent = folder,
		})
		part({
			Name = "Edge",
			Size = Vector3.new(size.X, 5, size.Z),
			Position = origin + dir * (FLOOR_SIZE / 2) + Vector3.new(0, 2.5, 0),
			Color = theme.Edge,
			Material = Enum.Material.Rock,
			Parent = folder,
		})
	end

	if stage.Boss then
		part({
			Name = "BossArena",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, ARENA_RADIUS * 2, ARENA_RADIUS * 2),
			CFrame = CFrame.new(origin + BOSS_OFFSET + Vector3.new(0, 0.1, 0))
				* CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(150, 100, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.5,
			CanCollide = false,
			Parent = folder,
		})
	end

	local spawn: SpawnLocation
	local existing = workspace:FindFirstChild("SpawnLocation")
	if index == 1 and existing and existing:IsA("SpawnLocation") then
		spawn = existing
	else
		spawn = Instance.new("SpawnLocation")
		spawn.Name = `Stage{index}Spawn`
		spawn.Anchored = true
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.Position = origin + Vector3.new(0, 0.5, 0)
		spawn.Neutral = index == 1 -- คนเข้าเกมใหม่เกิดด่าน 1 เสมอ
		spawn.Parent = folder
	end
	spawn.Duration = 3
	spawns[index] = spawn
	label(spawn, `ด่าน {index}: {stage.Name}`, Color3.fromRGB(255, 255, 255), 6)

	decorate(folder, origin, theme, Random.new(index * 1000))
	local eggId = Config.EGG_ORDER[1]
	if index == 1 and eggId then
		buildEggStand(folder, origin + Vector3.new(0, 0, 24), eggId)
	end

	if index < #Config.STAGES then
		buildGate(folder, origin + Vector3.new(GATE_OFFSET, 0, 0), index, index + 1)
	end
	if index > 1 then
		buildGate(folder, origin - Vector3.new(GATE_OFFSET, 0, 0), index, index - 1)
	end
end

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.GlobalShadows = true
	if not Lighting:FindFirstChild("GameColor") then
		local color = Instance.new("ColorCorrectionEffect")
		color.Name = "GameColor"
		color.Saturation = 0.2
		color.Contrast = 0.08
		color.Parent = Lighting
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "GameBloom"
		bloom.Intensity = 0.6
		bloom.Size = 20
		bloom.Threshold = 1.6
		bloom.Parent = Lighting
	end
end

-- สร้างแมพครั้งเดียว (service อื่นเรียกก่อนใช้ตำแหน่งในด่านได้)
function StageService.ensureBuilt()
	if built then
		return
	end
	built = true
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		-- ใช้พื้นของแต่ละด่านแทน (กันพื้นซ้อนกระพริบ)
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
	end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = Config.WORLD_NAME
	mapFolder.Parent = workspace
	for index in Config.STAGES do
		buildStage(index)
	end
	setupLighting()
end

export type Area = { origin: Vector3, minRadius: number, maxRadius: number, bossPosition: Vector3 }

function StageService.getArea(stageIndex: number): Area
	StageService.ensureBuilt()
	local origin = StageService.center(stageIndex)
	return {
		origin = origin,
		minRadius = MOB_MIN_RADIUS,
		maxRadius = MOB_MAX_RADIUS,
		bossPosition = origin + BOSS_OFFSET,
	}
end

function StageService.travel(player: Player, stageIndex: number)
	local spawn = spawns[stageIndex]
	if not spawn then
		return
	end
	player:SetAttribute("CurrentStage", stageIndex)
	player.RespawnLocation = spawn
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 4, 0)))
	end
end

function StageService.useGate(player: Player, toStage: number)
	local data = PlayerData.get(player)
	if not data or not Config.STAGES[toStage] then
		return
	end
	if toStage > data.StageUnlocked then
		local need = Config.STAGES[toStage - 1]
		local text =
			`ต้องเคลียร์ด่าน {toStage - 1} ก่อน (ฆ่ามอน {data.StageKills}/{need.KillsToClear or 0})`
		Net.event("Notify"):FireClient(player, text, "Bad")
		return
	end
	StageService.travel(player, toStage)
end

-- EnemyService เรียกเมื่อผู้เล่นได้เครดิตการฆ่า
function StageService.onEnemyKilled(player: Player, stageIndex: number, isBoss: boolean)
	local data = PlayerData.get(player)
	if not data or data.StageUnlocked ~= stageIndex then
		return
	end
	local notify = Net.event("Notify")
	if isBoss then
		if not data.BossDefeated then
			PlayerData.update(player, function(d)
				d.BossDefeated = true
			end)
			notify:FireClient(
				player,
				`เคลียร์ {Config.WORLD_NAME} แล้ว! Rebirth ได้แล้ว`,
				"Good"
			)
		end
		return
	end
	local stage = Config.STAGES[stageIndex]
	local needed = stage.KillsToClear
	if not needed or data.StageKills >= needed then
		return
	end
	local unlocked: number? = nil
	PlayerData.update(player, function(d)
		d.StageKills += 1
		if d.StageKills >= needed and Config.STAGES[stageIndex + 1] then
			d.StageUnlocked = stageIndex + 1
			d.StageKills = 0
			unlocked = d.StageUnlocked
		end
	end)
	if unlocked then
		notify:FireClient(
			player,
			`ปลดด่าน {unlocked}: {Config.STAGES[unlocked].Name} แล้ว! ไปที่ประตูได้เลย`,
			"Good"
		)
	end
end

function StageService.Init(services)
	PlayerData = services.PlayerData
end

function StageService.Start()
	Net.event("OpenPanel") -- สร้างไว้ก่อน client รอ (ไข่ใช้เปิดหน้าสุ่ม)
	StageService.ensureBuilt()
	local function onPlayer(player: Player)
		player:SetAttribute("CurrentStage", 1)
		player.RespawnLocation = spawns[1]
		-- กันพลาด: ตายในด่านอื่นแล้วต้องเกิดในด่านนั้น
		player.CharacterAdded:Connect(function(character)
			local stage = player:GetAttribute("CurrentStage")
			if type(stage) == "number" and stage ~= 1 and spawns[stage] then
				character:WaitForChild("HumanoidRootPart")
				task.defer(function()
					character:PivotTo(CFrame.new(spawns[stage].Position + Vector3.new(0, 4, 0)))
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return StageService
