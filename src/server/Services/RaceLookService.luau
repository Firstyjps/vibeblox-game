--!strict
-- ร่างกายเพิ่มตามเผ่า (โมเดลชั่วคราวจาก Part เชื่อมกับตัวละคร — ทุกคนเห็น)
--   Elf หูแหลม · Dragon ปีก+เขา+หาง · Vampire ผ้าคลุม+ปกคอ · Lich มงกุฎเรืองแสง · Fairy ปีกโปร่งใส+ประกาย
-- เปลี่ยนเป็นโมเดลจริง: แก้ฟังก์ชันในตาราง BUILDERS ของเผ่านั้น

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Modules.Theme)

local LOOK_NAME = "RaceLook"
local APPEARANCE_TIMEOUT = 3

local RaceLookService = {}

type Builder = (character: Model, look: Model, color: Color3) -> ()

local function bodyPart(character: Model, name: string): BasePart?
	local found = character:FindFirstChild(name)
	if not found and (name == "UpperTorso" or name == "LowerTorso") then
		found = character:FindFirstChild("Torso") -- R6
	end
	return if found and found:IsA("BasePart") then found else nil
end

-- สร้าง Part ติดกับส่วนของร่างกาย · offset = ตำแหน่งเทียบกับส่วนนั้น (หลังตัว = +Z)
local function attach(look: Model, base: BasePart, offset: CFrame, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.CFrame = base.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = p
	weld.Parent = p
	p.Parent = look
	return p
end

local BUILDERS: { [string]: Builder } = {
	Elf = function(character, look)
		local head = bodyPart(character, "Head")
		if not head then
			return
		end
		for _, side in { -1, 1 } do
			attach(
				look,
				head,
				CFrame.new(side * (head.Size.X / 2 + 0.1), head.Size.Y * 0.1, 0.15)
					* CFrame.Angles(math.rad(25), 0, side * math.rad(-35)),
				{ Name = "Ear", Size = Vector3.new(0.12, 0.35, 1), Color = head.Color }
			)
		end
	end,

	Dragon = function(character, look, color)
		local torso = bodyPart(character, "UpperTorso")
		local head = bodyPart(character, "Head")
		local lower = bodyPart(character, "LowerTorso")
		if torso then
			for _, side in { -1, 1 } do
				attach(
					look,
					torso,
					CFrame.new(side * 2.1, 0.5, torso.Size.Z / 2 + 0.35)
						* CFrame.Angles(0, side * math.rad(-25), side * math.rad(20)),
					{ Name = "Wing", Size = Vector3.new(3.6, 2.4, 0.15), Color = color }
				)
				attach(
					look,
					torso,
					CFrame.new(side * 0.5, 0.4, torso.Size.Z / 2 + 0.15)
						* CFrame.Angles(0, 0, side * math.rad(20)),
					{
						Name = "WingArm",
						Size = Vector3.new(1.2, 0.3, 0.3),
						Color = color:Lerp(Color3.new(0, 0, 0), 0.3),
					}
				)
			end
		end
		if head then
			for _, side in { -1, 1 } do
				attach(
					look,
					head,
					CFrame.new(side * head.Size.X * 0.3, head.Size.Y / 2 + 0.2, 0.1)
						* CFrame.Angles(math.rad(-20), 0, side * math.rad(-15)),
					{
						Name = "Horn",
						Size = Vector3.new(0.22, 0.7, 0.22),
						Color = Color3.fromRGB(240, 225, 190),
					}
				)
			end
		end
		if lower then
			attach(
				look,
				lower,
				CFrame.new(0, -0.2, lower.Size.Z / 2 + 1.4)
					* CFrame.Angles(math.rad(-25), 0, 0)
					* CFrame.Angles(0, math.rad(90), 0),
				{
					Name = "Tail",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(2.8, 0.5, 0.5),
					Color = color,
				}
			)
		end
	end,

	Vampire = function(character, look, color)
		local torso = bodyPart(character, "UpperTorso")
		if not torso then
			return
		end
		attach(
			look,
			torso,
			CFrame.new(0, -1, torso.Size.Z / 2 + 0.2) * CFrame.Angles(math.rad(-8), 0, 0),
			{ Name = "Cape", Size = Vector3.new(2.3, 3.6, 0.1), Color = Color3.fromRGB(25, 15, 25) }
		)
		attach(
			look,
			torso,
			CFrame.new(0, torso.Size.Y / 2 + 0.25, torso.Size.Z / 2 + 0.1)
				* CFrame.Angles(math.rad(-20), 0, 0),
			{ Name = "Collar", Size = Vector3.new(2.4, 0.7, 0.12), Color = color }
		)
	end,

	Lich = function(character, look, color)
		local head = bodyPart(character, "Head")
		if not head then
			return
		end
		local spikes = 6
		for i = 1, spikes do
			local angle = (i / spikes) * math.pi * 2
			local radius = head.Size.X * 0.42
			attach(
				look,
				head,
				CFrame.new(math.cos(angle) * radius, head.Size.Y / 2 + 0.25, math.sin(angle) * radius),
				{
					Name = "Crown",
					Size = Vector3.new(0.18, if i % 2 == 0 then 0.7 else 0.45, 0.18),
					Color = color,
					Material = Enum.Material.Neon,
				}
			)
		end
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10
		light.Brightness = 2
		light.Parent = look:FindFirstChild("Crown")
	end,

	Fairy = function(character, look, color)
		local torso = bodyPart(character, "UpperTorso")
		if not torso then
			return
		end
		for _, side in { -1, 1 } do
			for _, row in
				{
					{ y = 0.6, size = Vector3.new(2, 1.6, 0.06), tilt = 25 },
					{ y = -0.4, size = Vector3.new(1.4, 1.1, 0.06), tilt = -20 },
				}
			do
				attach(
					look,
					torso,
					CFrame.new(side * 1.2, row.y, torso.Size.Z / 2 + 0.25)
						* CFrame.Angles(0, side * math.rad(-20), side * math.rad(row.tilt)),
					{
						Name = "Wing",
						Size = row.size,
						Color = color,
						Material = Enum.Material.Neon,
						Transparency = 0.45,
					}
				)
			end
		end
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		sparkles.LightEmission = 1
		sparkles.Rate = 6
		sparkles.Lifetime = NumberRange.new(0.8, 1.2)
		sparkles.Speed = NumberRange.new(0.5, 1.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.2, 0)
		sparkles.Parent = torso
		sparkles:SetAttribute("RaceLook", true)
	end,
}

local function clear(character: Model)
	local old = character:FindFirstChild(LOOK_NAME)
	if old then
		old:Destroy()
	end
	for _, descendant in character:GetDescendants() do
		if descendant:GetAttribute("RaceLook") then
			descendant:Destroy()
		end
	end
end

function RaceLookService.apply(player: Player)
	local character = player.Character
	if not character then
		return
	end
	clear(character)
	local race = player:GetAttribute("Race")
	local builder = if type(race) == "string" then BUILDERS[race] else nil
	if not builder then
		return
	end
	local look = Instance.new("Model")
	look.Name = LOOK_NAME
	look.Parent = character
	builder(character, look, Theme.RACE_COLORS[race :: string] or Color3.new(1, 1, 1))
end

local function onCharacter(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart")
	-- รอชุด/หัวของผู้เล่นโหลดก่อน ไม่งั้นส่วนที่ติดไว้อาจหลุด
	if not player:HasAppearanceLoaded() then
		local loaded = false
		local connection = player.CharacterAppearanceLoaded:Connect(function()
			loaded = true
		end)
		local deadline = os.clock() + APPEARANCE_TIMEOUT
		while not loaded and os.clock() < deadline do
			task.wait(0.1)
		end
		connection:Disconnect()
	end
	if player.Character == character then
		RaceLookService.apply(player)
	end
end

function RaceLookService.Start()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		player:GetAttributeChangedSignal("Race"):Connect(function()
			RaceLookService.apply(player)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return RaceLookService
