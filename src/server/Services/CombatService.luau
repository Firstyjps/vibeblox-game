--!strict
-- การต่อสู้ของผู้เล่น: client แค่ "ขอตี" → server เลือกเป้า/เช็ก cooldown/คำนวณดาเมจเอง
-- และรับดาเมจจากมอน (ลดด้วยแทงก์ในทีม)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)
local RateLimit = require(ReplicatedStorage.Shared.Modules.RateLimit)
local Theme = require(ReplicatedStorage.Shared.Modules.Theme)

local COOLDOWN_TOLERANCE = 0.9 -- เผื่อ ping นิดหน่อย

local CombatService = {}
local PlayerData, EnemyService, SummonService

local lastAttack: { [Player]: number } = {}
local rng = Random.new()
local popEvent: UnreliableRemoteEvent
local attackFx: UnreliableRemoteEvent

local function aliveParts(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root and humanoid.Health > 0 then
		return humanoid, root
	end
	return nil, nil
end

local function onAttack(player: Player)
	local data = PlayerData.get(player)
	if not data or data.Race == "" then
		return
	end
	local race = Formulas.race(data.Race)
	local now = os.clock()
	local previous = lastAttack[player]
	if previous and now - previous < race.AttackCooldown * COOLDOWN_TOLERANCE then
		return
	end
	local humanoid, root = aliveParts(player)
	if not humanoid or not root then
		return
	end
	local target = EnemyService.findNearest(root.Position, race.Range)
	if not target then
		return
	end
	lastAttack[player] = now

	local variance = 1 + rng:NextNumber(-Config.DAMAGE_VARIANCE, Config.DAMAGE_VARIANCE)
	local damage = Formulas.playerDamage(data) * variance
	attackFx:FireAllClients(root.Position, target.root.Position, Theme.RACE_COLORS[data.Race] or Theme.TEXT)
	EnemyService.damage(target, damage, player, "Player")

	if race.Lifesteal > 0 then
		local heal = damage * race.Lifesteal
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + heal)
	end
end

function CombatService.damagePlayer(player: Player, amount: number)
	local humanoid, root = aliveParts(player)
	if not humanoid or not root then
		return
	end
	if (player.Character :: Model):FindFirstChildOfClass("ForceField") then
		return -- เพิ่งเกิด
	end
	local reduction = SummonService.getTankReduction(player)
	local final = math.max(1, math.floor(amount * (1 - reduction) + 0.5))
	humanoid:TakeDamage(final)
	popEvent:FireClient(player, root.Position + Vector3.new(0, 3, 0), final, "Hurt")
end

function CombatService.Init(services)
	PlayerData = services.PlayerData
	EnemyService = services.EnemyService
	SummonService = services.SummonService
end

function CombatService.Start()
	popEvent = Net.unreliable("DamagePop")
	attackFx = Net.unreliable("AttackFx")
	local allow = RateLimit.new(Config.ATTACK_REQUESTS_PER_SECOND)

	Net.event("Attack").OnServerEvent:Connect(function(player: Player)
		if allow(player) then
			onAttack(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
	end)
end

return CombatService
