--!strict
-- โลก: สร้างแมพชั่วคราวจาก Part, จุดเกิด, Portal เดินทาง/เปิดโลก, ภารกิจโลก
-- อยากเปลี่ยนเป็นโมเดลจริง: แก้ฟังก์ชัน decorate* หรือวางโมเดลใน assets/models ทับตำแหน่งเดียวกัน

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)

-- หน้าตา/ตำแหน่งของแต่ละโลก (ไม่ใช่ค่าสมดุล → อยู่ที่นี่)
local LAYOUT = {
	{
		Origin = Vector3.new(0, 0, 0),
		FloorColor = Color3.fromRGB(105, 200, 85),
		FloorMaterial = Enum.Material.Grass,
		WallColor = Color3.fromRGB(70, 140, 60),
		Decor = "Forest",
	},
	{
		Origin = Vector3.new(1500, 0, 0),
		FloorColor = Color3.fromRGB(70, 32, 32),
		FloorMaterial = Enum.Material.Basalt,
		WallColor = Color3.fromRGB(45, 20, 20),
		Decor = "Inferno",
	},
}

local FLOOR_SIZE = 300
local MOB_MIN_RADIUS = 35
local MOB_MAX_RADIUS = 115
local BOSS_OFFSET = Vector3.new(0, 0, -105)
local PORTAL_OFFSET = Vector3.new(45, 0, 10)
local ARENA_RADIUS = 22

local WorldService = {}
local PlayerData, ProgressionService

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
	gui.Size = UDim2.fromOffset(240, 60)
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

local function decorateForest(folder: Folder, origin: Vector3, rng: Random)
	for _ = 1, 45 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(30, FLOOR_SIZE / 2 - 10)
		local pos = origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if (pos - (origin + BOSS_OFFSET)).Magnitude > ARENA_RADIUS + 8 then
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
				Color = Color3.fromHSV(rng:NextNumber(0.25, 0.36), 0.7, 0.85),
				Parent = folder,
			})
		end
	end
	for _ = 1, 20 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(20, FLOOR_SIZE / 2 - 10)
		local size = rng:NextNumber(1.2, 2.2)
		part({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			Position = origin + Vector3.new(math.cos(angle) * radius, size / 2, math.sin(angle) * radius),
			Color = Color3.fromHSV(rng:NextNumber(0, 1), 0.55, 1),
			CanCollide = false,
			Parent = folder,
		})
	end
end

local function decorateInferno(folder: Folder, origin: Vector3, rng: Random)
	for _ = 1, 30 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(30, FLOOR_SIZE / 2 - 10)
		local pos = origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if (pos - (origin + BOSS_OFFSET)).Magnitude > ARENA_RADIUS + 8 then
			local height = rng:NextNumber(6, 18)
			part({
				Name = "Spike",
				Size = Vector3.new(rng:NextNumber(3, 6), height, rng:NextNumber(3, 6)),
				CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(
					rng:NextNumber(-0.2, 0.2),
					rng:NextNumber(0, 6),
					rng:NextNumber(-0.2, 0.2)
				),
				Color = Color3.fromRGB(40, 25, 25),
				Material = Enum.Material.Slate,
				Parent = folder,
			})
		end
	end
	for _ = 1, 14 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(30, FLOOR_SIZE / 2 - 15)
		local size = rng:NextNumber(8, 18)
		part({
			Name = "Lava",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, size, size),
			CFrame = CFrame.new(
				origin + Vector3.new(math.cos(angle) * radius, 0.1, math.sin(angle) * radius)
			) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 110, 30),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end
end

local function buildPortal(folder: Folder, origin: Vector3, fromWorld: number, toWorld: number)
	local base = origin + PORTAL_OFFSET
	local color = if toWorld > fromWorld then Color3.fromRGB(255, 120, 40) else Color3.fromRGB(80, 230, 120)
	for _, side in { -1, 1 } do
		part({
			Name = "PortalPillar",
			Size = Vector3.new(1.5, 12, 1.5),
			Position = base + Vector3.new(0, 6, side * 5),
			Color = Color3.fromRGB(90, 80, 120),
			Material = Enum.Material.Marble,
			Parent = folder,
		})
	end
	local gate = part({
		Name = `PortalTo{toWorld}`,
		Size = Vector3.new(0.6, 10, 8.5),
		Position = base + Vector3.new(0, 5, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = false,
		Parent = folder,
	})
	local target = Config.WORLDS[toWorld]
	local subtitle = if toWorld > fromWorld
		then `ต้องเคลียร์ภารกิจ + {Formulas.format(target.UnlockCost)} Coins`
		else "กลับโลกก่อนหน้า"
	label(gate, `→ {target.Name}\n{subtitle}`, color, 8)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = `ไป {target.Name}`
	prompt.ObjectText = "Portal"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = gate
	prompt.Triggered:Connect(function(player)
		WorldService.usePortal(player, toWorld)
	end)
end

local function buildWorld(index: number)
	local layout = LAYOUT[index]
	local world = Config.WORLDS[index]
	local origin = layout.Origin
	local folder = Instance.new("Folder")
	folder.Name = `World{index}_{world.Name}`
	folder.Parent = mapFolder

	part({
		Name = "Floor",
		Size = Vector3.new(FLOOR_SIZE, 4, FLOOR_SIZE),
		Position = origin - Vector3.new(0, 2, 0),
		Color = layout.FloorColor,
		Material = layout.FloorMaterial,
		Parent = folder,
	})
	-- กำแพงล่องหนกันตกขอบ + ขอบที่มองเห็น
	for _, dir in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
		local isX = dir.X ~= 0
		local size = if isX then Vector3.new(4, 60, FLOOR_SIZE) else Vector3.new(FLOOR_SIZE, 60, 4)
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
			Color = layout.WallColor,
			Material = Enum.Material.Rock,
			Parent = folder,
		})
	end

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

	local spawn: SpawnLocation
	local existing = workspace:FindFirstChild("SpawnLocation")
	if index == 1 and existing and existing:IsA("SpawnLocation") then
		spawn = existing
	else
		spawn = Instance.new("SpawnLocation")
		spawn.Name = `World{index}Spawn`
		spawn.Anchored = true
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.Position = origin + Vector3.new(0, 0.5, 0)
		spawn.Neutral = index == 1 -- คนเข้าเกมใหม่เกิดโลก 1 เสมอ
		spawn.Parent = folder
	end
	spawn.Duration = 3
	spawns[index] = spawn
	label(spawn, world.Name, Color3.fromRGB(255, 255, 255), 6)

	local rng = Random.new(index * 1000)
	if layout.Decor == "Forest" then
		decorateForest(folder, origin, rng)
	else
		decorateInferno(folder, origin, rng)
	end

	if index < #Config.WORLDS then
		buildPortal(folder, origin, index, index + 1)
	end
	if index > 1 then
		buildPortal(folder, origin + Vector3.new(0, 0, -25), index, index - 1)
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

-- สร้างแมพครั้งเดียว (service อื่นเรียกก่อนใช้ตำแหน่งในโลกได้)
function WorldService.ensureBuilt()
	if built then
		return
	end
	built = true
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		-- ใช้พื้นของแต่ละโลกแทน (กันพื้นซ้อนกระพริบ)
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
	end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Worlds"
	mapFolder.Parent = workspace
	for index in Config.WORLDS do
		buildWorld(index)
	end
	setupLighting()
end

export type Area = { origin: Vector3, minRadius: number, maxRadius: number, bossPosition: Vector3 }

function WorldService.getArea(worldIndex: number): Area
	WorldService.ensureBuilt()
	local origin = LAYOUT[worldIndex].Origin
	return {
		origin = origin,
		minRadius = MOB_MIN_RADIUS,
		maxRadius = MOB_MAX_RADIUS,
		bossPosition = origin + BOSS_OFFSET,
	}
end

function WorldService.travel(player: Player, worldIndex: number)
	local spawn = spawns[worldIndex]
	player:SetAttribute("CurrentWorld", worldIndex)
	player.RespawnLocation = spawn
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 4, 0)))
	end
end

local function questDone(data: any): boolean
	local world = Config.WORLDS[data.WorldUnlocked]
	return world ~= nil and data.QuestKills >= world.QuestKills and data.QuestBoss
end

function WorldService.usePortal(player: Player, toWorld: number)
	local data = PlayerData.get(player)
	if not data or not Config.WORLDS[toWorld] then
		return
	end
	if toWorld <= data.WorldUnlocked then
		WorldService.travel(player, toWorld)
		return
	end
	-- ยังไม่เปิด: ต้องเป็นโลกถัดไปของโลกไกลสุด + ทำภารกิจแล้ว + Coins พอ
	local cost = Config.WORLDS[toWorld].UnlockCost
	local notifyEvent = Net.event("Notify")
	if toWorld ~= data.WorldUnlocked + 1 then
		return
	end
	if not questDone(data) then
		notifyEvent:FireClient(
			player,
			"ต้องเคลียร์ภารกิจโลกนี้ก่อน",
			"Bad"
		)
		return
	end
	if data.Coins < cost then
		notifyEvent:FireClient(player, `ต้องใช้ {Formulas.format(cost)} Coins`, "Bad")
		return
	end
	PlayerData.update(player, function(d)
		d.Coins -= cost
		d.WorldUnlocked = toWorld
		d.QuestKills = 0
		d.QuestBoss = false
	end)
	notifyEvent:FireClient(
		player,
		`เปิดโลก {Config.WORLDS[toWorld].Name} แล้ว!`,
		"Good"
	)
	WorldService.travel(player, toWorld)
end

-- EnemyService เรียกเมื่อผู้เล่นได้เครดิตการฆ่า
function WorldService.onEnemyKilled(player: Player, worldIndex: number, isBoss: boolean)
	local data = PlayerData.get(player)
	if not data or data.WorldUnlocked ~= worldIndex then
		return
	end
	local world = Config.WORLDS[worldIndex]
	local wasDone = questDone(data)
	if wasDone then
		return
	end
	PlayerData.update(player, function(d)
		if isBoss then
			d.QuestBoss = true
		elseif d.QuestKills < world.QuestKills then
			d.QuestKills += 1
		end
	end)
	if questDone(data) then
		ProgressionService.grant(player, { Gems = world.QuestGems })
		Net.event("Notify"):FireClient(
			player,
			`ภารกิจ {world.Name} สำเร็จ! +{world.QuestGems} Gems`,
			"Good"
		)
	end
end

function WorldService.Init(services)
	PlayerData = services.PlayerData
	ProgressionService = services.ProgressionService
end

function WorldService.Start()
	WorldService.ensureBuilt()
	local function onPlayer(player: Player)
		player:SetAttribute("CurrentWorld", 1)
		player.RespawnLocation = spawns[1]
		-- กันพลาด: ตายในโลกอื่นแล้วต้องเกิดในโลกนั้น
		player.CharacterAdded:Connect(function(character)
			local world = player:GetAttribute("CurrentWorld")
			if type(world) == "number" and world ~= 1 and spawns[world] then
				character:WaitForChild("HumanoidRootPart")
				task.defer(function()
					character:PivotTo(CFrame.new(spawns[world].Position + Vector3.new(0, 4, 0)))
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return WorldService
