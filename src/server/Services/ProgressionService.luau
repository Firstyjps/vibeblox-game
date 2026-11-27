--!strict
-- รางวัล (Coins/XP/Gems), เลเวลอัป, อัปเกรดด้วย Coins, Rebirth
--   services.ProgressionService.grant(player, { Coins = 10, XP = 5, Gems = 1 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)
local RateLimit = require(ReplicatedStorage.Shared.Modules.RateLimit)

local ProgressionService = {}
local PlayerData

export type Rewards = { Coins: number?, XP: number?, Gems: number? }

local function notify(player: Player, text: string, kind: string?)
	Net.event("Notify"):FireClient(player, text, kind)
end

-- Coins/XP คูณโบนัส rebirth · Gems ไม่คูณ
function ProgressionService.grant(player: Player, rewards: Rewards)
	local newLevel: number? = nil
	PlayerData.update(player, function(data)
		local multiplier = Formulas.rebirthMultiplier(data.Rebirths)
		if rewards.Coins then
			data.Coins += math.floor(rewards.Coins * multiplier + 0.5)
		end
		if rewards.Gems then
			data.Gems += rewards.Gems
		end
		if rewards.XP and data.Level < Config.MAX_LEVEL then
			data.XP += math.floor(rewards.XP * multiplier + 0.5)
			while data.Level < Config.MAX_LEVEL and data.XP >= Formulas.xpToNext(data.Level) do
				data.XP -= Formulas.xpToNext(data.Level)
				data.Level += 1
				newLevel = data.Level
			end
			if data.Level >= Config.MAX_LEVEL then
				data.XP = 0
			end
		end
	end)
	if newLevel then
		notify(player, `เลเวลอัป! Lv.{newLevel}`, "Good")
	end
end

local function buyUpgrade(player: Player, kind: unknown): (boolean, string?)
	if type(kind) ~= "string" then
		return false
	end
	local def = (Config.UPGRADES :: any)[kind]
	local data: any = PlayerData.get(player)
	if not def or not data then
		return false
	end
	local field = kind .. "Upgrades"
	local owned = data[field]
	if owned >= def.Max then
		return false, "อัปเต็มแล้ว"
	end
	local cost = Formulas.upgradeCost(kind, owned)
	if data.Coins < cost then
		return false, "Coins ไม่พอ"
	end
	PlayerData.update(player, function(d: any)
		d.Coins -= cost
		d[field] += 1
	end)
	return true
end

local function rebirth(player: Player): (boolean, string?)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	if data.Level < Config.REBIRTH_MIN_LEVEL then
		return false, `ต้องถึง Lv.{Config.REBIRTH_MIN_LEVEL} ก่อน`
	end
	local count = 0
	PlayerData.update(player, function(d)
		d.Coins = Config.STARTING_COINS
		d.Level = 1
		d.XP = 0
		d.Rebirths += 1
		count = d.Rebirths
	end)
	notify(
		player,
		`Rebirth ครั้งที่ {count}! โบนัส x{Formulas.rebirthMultiplier(count)}`,
		"Good"
	)
	return true
end

function ProgressionService.Init(services)
	PlayerData = services.PlayerData
end

function ProgressionService.Start()
	local allowUpgrade = RateLimit.new(8)
	local allowRebirth = RateLimit.new(1)

	Net.func("BuyUpgrade").OnServerInvoke = function(player: Player, kind: unknown)
		if not allowUpgrade(player) then
			return false
		end
		return buyUpgrade(player, kind)
	end

	Net.func("Rebirth").OnServerInvoke = function(player: Player)
		if not allowRebirth(player) then
			return false
		end
		return rebirth(player)
	end
end

return ProgressionService
