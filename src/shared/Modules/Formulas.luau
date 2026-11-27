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
}

function Formulas.race(raceId: string?): typeof(NO_RACE)
	local def = if raceId then (Config.RACES :: any)[raceId] else nil
	return def or NO_RACE
end

function Formulas.xpToNext(level: number): number
	return math.floor(Config.XP_BASE * level ^ Config.XP_EXPONENT)
end

function Formulas.rebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Config.REBIRTH_BONUS
end

function Formulas.playerDamage(data: any): number
	local race = Formulas.race(data.Race)
	local levelBonus = 1 + (data.Level - 1) * Config.LEVEL_DAMAGE_BONUS
	local upgradeBonus = 1 + data.DamageUpgrades * Config.UPGRADES.Damage.Step
	return Config.BASE_DAMAGE * race.Damage * levelBonus * upgradeBonus
end

function Formulas.playerMaxHealth(data: any): number
	local race = Formulas.race(data.Race)
	local levelBonus = 1 + (data.Level - 1) * Config.LEVEL_HEALTH_BONUS
	local upgradeBonus = 1 + data.HealthUpgrades * Config.UPGRADES.Health.Step
	return math.floor(Config.BASE_HEALTH * race.Health * levelBonus * upgradeBonus)
end

function Formulas.upgradeCost(kind: string, owned: number): number
	local def = (Config.UPGRADES :: any)[kind]
	return math.floor(def.BaseCost * def.CostGrowth ^ owned)
end

function Formulas.summonXpToNext(level: number): number
	return math.floor(Config.SUMMON_XP_BASE * level ^ Config.SUMMON_XP_EXPONENT)
end

export type SummonStats = {
	Name: string,
	Role: string,
	Rarity: string,
	Damage: number,
	AttackCooldown: number,
	Speed: number,
	SplashRadius: number,
	TankReduction: number,
}

function Formulas.summonStats(kind: string, level: number): SummonStats?
	local def = (Config.SUMMONS :: any)[kind]
	if not def then
		return nil
	end
	local role = (Config.ROLES :: any)[def.Role]
	local rarity = (Config.RARITIES :: any)[def.Rarity]
	return {
		Name = def.Name,
		Role = def.Role,
		Rarity = def.Rarity,
		Damage = role.Damage * rarity.Multiplier * (1 + (level - 1) * Config.SUMMON_LEVEL_BONUS),
		AttackCooldown = role.AttackCooldown,
		Speed = role.Speed,
		SplashRadius = role.SplashRadius,
		TankReduction = if def.Role == "Tank" then rarity.TankReduction else 0,
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
