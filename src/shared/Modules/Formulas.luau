--!strict
-- สูตรคำนวณที่ใช้ทั้ง server (ตัดสินจริง) และ client (แสดงผลใน UI) — ตัวเลขดิบอยู่ใน Config

local Config = require(script.Parent.Parent:WaitForChild("Config"))

local Formulas = {}

-- ค่าพลังตอนยังไม่เลือกเผ่า
local NO_RACE = {
	Name = "-",
	Description = "",
	Damage = 1,
	Health = 1,
	Range = 10,
	AttackCooldown = 0.45,
	WalkSpeed = 16,
	Lifesteal = 0,
	Skills = {} :: { any },
}

function Formulas.race(raceId: string?): typeof(NO_RACE)
	local def = if raceId then (Config.RACES :: any)[raceId] else nil
	return def or NO_RACE
end

function Formulas.xpToNext(level: number): number
	return math.floor(Config.XP_BASE * level ^ Config.XP_EXPONENT)
end

-- ตัวคูณ Coins/พลังจาก Rebirth
function Formulas.rebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Config.REBIRTH_BONUS
end

function Formulas.rebirthCost(rebirths: number): number
	return math.floor(Config.REBIRTH_BASE_COST * Config.REBIRTH_COST_GROWTH ^ rebirths)
end

export type PlayerStats = {
	Damage: number,
	MaxHealth: number,
	WalkSpeed: number,
	Range: number,
	AttackCooldown: number,
	Lifesteal: number,
	DamageReduction: number,
	CritChance: number,
	CoinBonus: number,
}

-- รวมค่าพลังผู้เล่นทั้งหมด: เผ่า + Skill Points + สกิลเผ่า + Rebirth
-- data ต้องมี Race, Rebirths, StatHealth, StatAttack, StatSpeed, RaceSkills
function Formulas.playerStats(data: any): PlayerStats
	local race = Formulas.race(data.Race)
	local bonus = {
		Damage = 0,
		AttackSpeed = 0,
		DamageReduction = 0,
		CritChance = 0,
		CoinBonus = 0,
		Lifesteal = 0,
		Range = 0,
		WalkSpeed = 0,
	}
	local ranks = data.RaceSkills or {}
	for _, skill in race.Skills do
		local rank = ranks[skill.Id]
		if type(rank) == "number" and (bonus :: any)[skill.Effect] ~= nil then
			(bonus :: any)[skill.Effect] += rank * skill.PerRank
		end
	end
	local stats = Config.STATS
	local speedPoints = math.min(data.StatSpeed, stats.Speed.Max)
	return {
		Damage = Config.BASE_DAMAGE
			* race.Damage
			* (1 + data.StatAttack * stats.Attack.PerPoint)
			* (1 + bonus.Damage)
			* Formulas.rebirthMultiplier(data.Rebirths),
		MaxHealth = math.floor(
			Config.BASE_HEALTH * race.Health * (1 + data.StatHealth * stats.Health.PerPoint)
		),
		WalkSpeed = race.WalkSpeed + speedPoints * stats.Speed.PerPoint + bonus.WalkSpeed,
		Range = race.Range + bonus.Range,
		AttackCooldown = race.AttackCooldown / (1 + bonus.AttackSpeed),
		Lifesteal = race.Lifesteal + bonus.Lifesteal,
		DamageReduction = math.min(bonus.DamageReduction, Config.MAX_DAMAGE_REDUCTION),
		CritChance = math.min(bonus.CritChance, Config.MAX_CRIT_CHANCE),
		CoinBonus = bonus.CoinBonus,
	}
end

function Formulas.summonXpToNext(level: number): number
	return math.floor(Config.SUMMON_XP_BASE * level ^ Config.SUMMON_XP_EXPONENT)
end

export type SummonStats = {
	Name: string,
	Element: string,
	AttackType: string,
	Rarity: string,
	MaxLevel: number,
	Damage: number,
	AttackCooldown: number,
	Speed: number,
	Reach: number,
}

-- พลังสัตว์ 1 ตัว (ยังไม่คูณ Rebirth ของเจ้าของ)
function Formulas.summonStats(kind: string, level: number): SummonStats?
	local def = (Config.SUMMONS :: any)[kind]
	if not def then
		return nil
	end
	local attack = (Config.ATTACK_TYPES :: any)[def.AttackType]
	local rarity = (Config.RARITIES :: any)[def.Rarity]
	return {
		Name = def.Name,
		Element = def.Element,
		AttackType = def.AttackType,
		Rarity = def.Rarity,
		MaxLevel = rarity.MaxLevel,
		Damage = attack.Damage * rarity.Multiplier * (1 + (level - 1) * Config.SUMMON_LEVEL_BONUS),
		AttackCooldown = attack.AttackCooldown,
		Speed = attack.Speed,
		Reach = attack.Reach,
	}
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- 1234 → "1.2K"
function Formulas.format(n: number): string
	local index = 1
	local value = math.abs(n)
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local sign = if n < 0 then "-" else ""
	if index == 1 then
		return sign .. tostring(math.floor(value))
	end
	return sign .. string.format("%.1f", value):gsub("%.0$", "") .. SUFFIXES[index]
end

return Formulas
