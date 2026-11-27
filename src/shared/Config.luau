--!strict
-- ค่าตั้งของเกม (สมดุล/ราคา/อัตรา) — ปรับเกมที่นี่ ไม่ต้องแก้โค้ดระบบ
-- แยกหมวดด้วย comment ตามระบบ เพื่อให้หลายคนแก้คนละส่วนได้
-- ภาพรวมเกมดู docs/GAME_DESIGN.md

local Config = {}

-- ---------- ข้อมูลผู้เล่น ----------
Config.DATASTORE_NAME = "PlayerData_v1" -- เปลี่ยนเวอร์ชันเมื่อโครงสร้างข้อมูลเปลี่ยนแบบเข้ากันไม่ได้
Config.AUTOSAVE_INTERVAL = 60
Config.STARTING_COINS = 0
Config.STARTING_GEMS = 100

-- ---------- Dev ----------
-- UserId ที่ใช้ปุ่ม dev ได้ในเกมจริง (ใน Studio ใช้ได้ทุกคนอยู่แล้ว)
Config.DEV_USER_IDS = {} :: { number }

-- ---------- เผ่า ----------
-- Damage/Health = ตัวคูณ · Range = ระยะตี (studs) · AttackCooldown = วินาทีต่อการตี 1 ครั้ง
-- Lifesteal = สัดส่วนดาเมจที่ดูดกลับเป็น HP
Config.RACE_ORDER = { "Elf", "Dragon", "Vampire", "Lich", "Fairy" }
Config.RACES = {
	Elf = {
		Name = "Elf",
		Description = "ตีได้ไกล",
		Damage = 1,
		Health = 1,
		Range = 18,
		AttackCooldown = 0.45,
		WalkSpeed = 18,
		Lifesteal = 0,
	},
	Dragon = {
		Name = "Dragon",
		Description = "HP สูง ถึกทน",
		Damage = 1,
		Health = 1.5,
		Range = 10,
		AttackCooldown = 0.5,
		WalkSpeed = 16,
		Lifesteal = 0,
	},
	Vampire = {
		Name = "Vampire",
		Description = "ดูดเลือดทุกครั้งที่ตี",
		Damage = 1,
		Health = 1,
		Range = 10,
		AttackCooldown = 0.45,
		WalkSpeed = 17,
		Lifesteal = 0.12,
	},
	Lich = {
		Name = "Lich",
		Description = "ดาเมจแรง แต่ HP ต่ำ",
		Damage = 1.35,
		Health = 0.85,
		Range = 12,
		AttackCooldown = 0.5,
		WalkSpeed = 16,
		Lifesteal = 0,
	},
	Fairy = {
		Name = "Fairy",
		Description = "ตีเร็ว เดินเร็ว",
		Damage = 0.9,
		Health = 0.95,
		Range = 10,
		AttackCooldown = 0.32,
		WalkSpeed = 24,
		Lifesteal = 0,
	},
}

-- ---------- ต่อสู้ (ผู้เล่น) ----------
Config.BASE_DAMAGE = 10
Config.BASE_HEALTH = 100
Config.DAMAGE_VARIANCE = 0.1 -- ดาเมจสุ่ม ±10%
Config.ATTACK_REQUESTS_PER_SECOND = 12 -- กันสแปม remote (cooldown จริงดูที่เผ่า)

-- ---------- เลเวล ----------
Config.MAX_LEVEL = 200
Config.XP_BASE = 20 -- XP ที่ต้องใช้ = XP_BASE * level ^ XP_EXPONENT
Config.XP_EXPONENT = 1.5
Config.LEVEL_DAMAGE_BONUS = 0.08 -- +8% ดาเมจต่อเลเวล
Config.LEVEL_HEALTH_BONUS = 0.06 -- +6% HP ต่อเลเวล

-- ---------- อัปเกรดด้วย Coins ----------
-- ราคา = BaseCost * CostGrowth ^ จำนวนที่ซื้อแล้ว · Step = โบนัสต่อขั้น (0.15 = +15%)
Config.UPGRADES = {
	Damage = { Name = "ดาเมจ", BaseCost = 40, CostGrowth = 1.35, Step = 0.15, Max = 100 },
	Health = { Name = "HP", BaseCost = 40, CostGrowth = 1.35, Step = 0.15, Max = 100 },
}

-- ---------- Rebirth ----------
Config.REBIRTH_MIN_LEVEL = 15
Config.REBIRTH_BONUS = 0.25 -- +25% Coins/XP ถาวรต่อครั้ง

-- ---------- มอน ----------
-- ค่าพื้นฐาน (โลกที่ 1) — โลกถัดไปคูณด้วย StatMultiplier / RewardMultiplier ของโลกนั้น
Config.ENEMIES = {
	Slime = {
		Name = "Slime",
		Health = 40,
		Damage = 4,
		AttackCooldown = 1.2,
		Speed = 8,
		Coins = 5,
		XP = 6,
		IsBoss = false,
	},
	Wolf = {
		Name = "Shadow Wolf",
		Health = 70,
		Damage = 7,
		AttackCooldown = 1,
		Speed = 14,
		Coins = 8,
		XP = 10,
		IsBoss = false,
	},
	Imp = {
		Name = "Fire Imp",
		Health = 60,
		Damage = 9,
		AttackCooldown = 1.1,
		Speed = 12,
		Coins = 9,
		XP = 12,
		IsBoss = false,
	},
	Golem = {
		Name = "Ancient Golem",
		Health = 1200,
		Damage = 22,
		AttackCooldown = 1.8,
		Speed = 7,
		Coins = 250,
		XP = 300,
		IsBoss = true,
	},
}
Config.ENEMY_AGGRO_RANGE = 28
Config.BOSS_AGGRO_RANGE = 40
Config.ENEMY_LEASH_RANGE = 70 -- ไล่ไกลจากจุดเกิดเกินนี้ → กลับบ้าน + ฟื้น HP
Config.ENEMY_ATTACK_REACH = 4 -- ระยะตี (บวกขนาดตัวมอน)
Config.ENEMY_RESPAWN_TIME = 4
Config.BOSS_RESPAWN_TIME = 60
Config.MOB_GEM_CHANCE = 0.05 -- โอกาสดรอป 1 Gem (ให้คนที่ตีแรงสุด)
Config.BOSS_GEMS = 15
Config.KILL_CREDIT_MIN_SHARE = 0.1 -- ต้องทำดาเมจ ≥ 10% ถึงนับภารกิจ

-- ---------- โลก ----------
-- ลำดับในตาราง = ลำดับโลก · UnlockCost = Coins ที่ต้องจ่ายตอนเปิด (ต้องทำภารกิจโลกก่อนหน้าก่อน)
Config.WORLDS = {
	{
		Name = "Enchanted Forest",
		Enemies = { "Slime", "Wolf" },
		Boss = "Golem",
		StatMultiplier = 1,
		RewardMultiplier = 1,
		MaxEnemies = 12,
		QuestKills = 25,
		QuestGems = 50,
		UnlockCost = 0,
	},
	{
		Name = "Inferno",
		Enemies = { "Imp", "Wolf" },
		Boss = "Golem",
		StatMultiplier = 6,
		RewardMultiplier = 4,
		MaxEnemies = 12,
		QuestKills = 40,
		QuestGems = 100,
		UnlockCost = 2500,
	},
}

-- ---------- Summon ----------
Config.SUMMON_COST_GEMS = 50
Config.MAX_EQUIPPED = 3
Config.MAX_SUMMONS = 60 -- เก็บได้สูงสุดกี่ตัว
Config.SUMMON_RANGE = 26 -- รัศมีรอบตัวผู้เล่นที่ summon จะไปตีให้
Config.SUMMON_XP_SHARE = 0.5 -- summon ในทีมได้ XP = XP มอน * ค่านี้
Config.SUMMON_XP_BASE = 15
Config.SUMMON_XP_EXPONENT = 1.4
Config.SUMMON_LEVEL_BONUS = 0.1 -- +10% ดาเมจต่อเลเวล
Config.SUMMON_MAX_LEVEL = 100
Config.TANK_REDUCTION_CAP = 0.5

Config.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
Config.RARITIES = {
	Common = { Weight = 60, Multiplier = 1, TankReduction = 0.05 },
	Rare = { Weight = 25, Multiplier = 1.6, TankReduction = 0.08 },
	Epic = { Weight = 10, Multiplier = 2.6, TankReduction = 0.12 },
	Legendary = { Weight = 4, Multiplier = 4.2, TankReduction = 0.16 },
	Mythic = { Weight = 1, Multiplier = 7, TankReduction = 0.22 },
}

-- SplashRadius > 0 = ตีเป็นวง
Config.ROLES = {
	Tank = { Damage = 4, AttackCooldown = 1.2, Speed = 18, SplashRadius = 0 },
	Assassin = { Damage = 9, AttackCooldown = 0.7, Speed = 26, SplashRadius = 0 },
	Mage = { Damage = 5, AttackCooldown = 1.5, Speed = 20, SplashRadius = 9 },
}

-- ตู้สุ่ม: สุ่มระดับก่อน (ตาม Weight) แล้วสุ่มตัวในระดับนั้น — ทุกระดับต้องมีอย่างน้อย 1 ตัว
Config.SUMMONS = {
	MossGolem = { Name = "Moss Golem", Role = "Tank", Rarity = "Common" },
	ShadowRat = { Name = "Shadow Rat", Role = "Assassin", Rarity = "Common" },
	Wisp = { Name = "Wisp", Role = "Mage", Rarity = "Common" },
	StoneGuardian = { Name = "Stone Guardian", Role = "Tank", Rarity = "Rare" },
	NightFox = { Name = "Night Fox", Role = "Assassin", Rarity = "Rare" },
	EmberSprite = { Name = "Ember Sprite", Role = "Mage", Rarity = "Rare" },
	CrystalTortoise = { Name = "Crystal Tortoise", Role = "Tank", Rarity = "Epic" },
	PhantomBlade = { Name = "Phantom Blade", Role = "Assassin", Rarity = "Epic" },
	StormPhoenix = { Name = "Storm Phoenix", Role = "Mage", Rarity = "Legendary" },
	CelestialKirin = { Name = "Celestial Kirin", Role = "Assassin", Rarity = "Mythic" },
}

return Config
