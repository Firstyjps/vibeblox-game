--!strict
-- รางวัล (Coins/XP/Gems), เลเวลอัป (+Skill Points), Rebirth
--   services.ProgressionService.grant(player, { Coins = 10, XP = 5, Gems = 1 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)
local RateLimit = require(ReplicatedStorage.Shared.Modules.RateLimit)

local ProgressionService = {}
local PlayerData, StageService

export type Rewards = { Coins: number?, XP: number?, Gems: number? }

local function notify(player: Player, text: string, kind: string?)
	Net.event("Notify"):FireClient(player, text, kind)
end

-- Coins คูณ Rebirth + โบนัสสกิล · XP/Gems ไม่คูณ
function ProgressionService.grant(player: Player, rewards: Rewards)
	local newLevel: number? = nil
	PlayerData.update(player, function(data)
		if rewards.Coins then
			local multiplier = Formulas.rebirthMultiplier(data.Rebirths)
				* (1 + Formulas.playerStats(data).CoinBonus)
			data.Coins += math.floor(rewards.Coins * multiplier + 0.5)
		end
		if rewards.Gems then
			data.Gems += rewards.Gems
		end
		if rewards.XP and data.Level < Config.MAX_LEVEL then
			data.XP += math.floor(rewards.XP + 0.5)
			while data.Level < Config.MAX_LEVEL and data.XP >= Formulas.xpToNext(data.Level) do
				data.XP -= Formulas.xpToNext(data.Level)
				data.Level += 1
				data.SkillPoints += Config.SKILL_POINTS_PER_LEVEL
				newLevel = data.Level
			end
			if data.Level >= Config.MAX_LEVEL then
				data.XP = 0
			end
		end
	end)
	if newLevel then
		notify(
			player,
			`เลเวลอัป! Lv.{newLevel} (+{Config.SKILL_POINTS_PER_LEVEL} Skill Points)`,
			"Good"
		)
	end
end

local function rebirth(player: Player): (boolean, string?)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	if not data.BossDefeated then
		return false, `ต้องล้มบอส {Config.WORLD_NAME} ก่อน`
	end
	local cost = Formulas.rebirthCost(data.Rebirths)
	if data.Coins < cost then
		return false, `ต้องมี {Formulas.format(cost)} Coins`
	end
	local count = 0
	PlayerData.update(player, function(d)
		d.Coins = Config.STARTING_COINS
		d.StageUnlocked = 1
		d.StageKills = 0
		d.BossDefeated = false
		d.Rebirths += 1
		d.RebirthTokens += Config.REBIRTH_TOKENS
		count = d.Rebirths
	end)
	StageService.travel(player, 1)
	notify(
		player,
		`Rebirth ครั้งที่ {count}! โบนัส x{Formulas.rebirthMultiplier(count)}`,
		"Good"
	)
	return true
end

function ProgressionService.Init(services)
	PlayerData = services.PlayerData
	StageService = services.StageService
end

function ProgressionService.Start()
	local allowRebirth = RateLimit.new(1)
	Net.func("Rebirth").OnServerInvoke = function(player: Player)
		if not allowRebirth(player) then
			return false
		end
		return rebirth(player)
	end
end

return ProgressionService
