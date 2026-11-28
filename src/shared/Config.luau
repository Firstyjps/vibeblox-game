--!strict
-- ค่าตั้งของเกม (สมดุล/ราคา/อัตรา) — ปรับเกมที่นี่ ไม่ต้องแก้โค้ดระบบ
-- แยกหมวดด้วย comment ตามระบบ เพื่อให้หลายคนแก้คนละส่วนได้
-- ภาพรวมเกมดู docs/GDD.md

local Config = {}

-- ---------- ข้อมูลผู้เล่น ----------
Config.DATASTORE_NAME = "PlayerData_v1" -- เปลี่ยนเวอร์ชันเมื่อโครงสร้างข้อมูลเปลี่ยนแบบเข้ากันไม่ได้
Config.AUTOSAVE_INTERVAL = 60
Config.STARTING_COINS = 0
Config.STARTING_GEMS = 0

-- ---------- Dev ----------
-- UserId ที่ใช้ปุ่ม dev ได้ในเกมจริง (ใน Studio ใช้ได้ทุกคนอยู่แล้ว)
Config.DEV_USER_IDS = {} :: { number }

-- ---------- เผ่า ----------
-- Damage/Health = ตัวคูณ · Range = ระยะตี (studs) · AttackCooldown = วินาทีต่อการตี 1 ครั้ง
-- Lifesteal = สัดส่วนดาเมจที่ดูดกลับเป็น HP
-- Skills = สกิลเผ่า (ปลดที่ RACE_SKILL_UNLOCK_LEVEL) · Effect ดูรายการใน Formulas.playerStats
--   Damage/AttackSpeed/DamageReduction/CritChance/CoinBonus/Lifesteal = สัดส่วน (0.1 = 10%)
--   Range/WalkSpeed = ค่าบวกตรงๆ
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
		Skills = {
			{
				Id = "EagleEye",
				Name = "Eagle Eye",
				Description = "ระยะตี +2",
				Effect = "Range",
				PerRank = 2,
			},
			{
				Id = "NaturesGrace",
				Name = "Nature's Grace",
				Description = "ตีเร็วขึ้น 8%",
				Effect = "AttackSpeed",
				PerRank = 0.08,
			},
		},
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
		Skills = {
			{
				Id = "DragonScales",
				Name = "Dragon Scales",
				Description = "โดนดาเมจน้อยลง 5%",
				Effect = "DamageReduction",
				PerRank = 0.05,
			},
			{
				Id = "DragonMight",
				Name = "Dragon Might",
				Description = "ดาเมจ +8%",
				Effect = "Damage",
				PerRank = 0.08,
			},
		},
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
		Skills = {
			{
				Id = "BloodThirst",
				Name = "Blood Thirst",
				Description = "ดูดเลือด +4%",
				Effect = "Lifesteal",
				PerRank = 0.04,
			},
			{
				Id = "CrimsonStrike",
				Name = "Crimson Strike",
				Description = "โอกาสคริติคอล +6%",
				Effect = "CritChance",
				PerRank = 0.06,
			},
		},
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
		Skills = {
			{
				Id = "ArcanePower",
				Name = "Arcane Power",
				Description = "ดาเมจ +10%",
				Effect = "Damage",
				PerRank = 0.1,
			},
			{
				Id = "BoneWard",
				Name = "Bone Ward",
				Description = "โดนดาเมจน้อยลง 5%",
				Effect = "DamageReduction",
				PerRank = 0.05,
			},
		},
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
		Skills = {
			{
				Id = "PixieDust",
				Name = "Pixie Dust",
				Description = "ได้ Coins +10%",
				Effect = "CoinBonus",
				PerRank = 0.1,
			},
			{
				Id = "Flutter",
				Name = "Flutter",
				Description = "เดินเร็ว +1.5",
				Effect = "WalkSpeed",
				PerRank = 1.5,
			},
		},
	},
}

-- ---------- ต่อสู้ (ผู้เล่น) ----------
Config.BASE_DAMAGE = 10
Config.BASE_HEALTH = 100
Config.DAMAGE_VARIANCE = 0.1 -- ดาเมจสุ่ม ±10%
Config.CRIT_MULTIPLIER = 2
Config.MAX_DAMAGE_REDUCTION = 0.6
Config.MAX_CRIT_CHANCE = 0.75
Config.ATTACK_REQUESTS_PER_SECOND = 12 -- กันสแปม remote (cooldown จริงดูที่เผ่า)

-- ---------- เลเวล ----------
Config.MAX_LEVEL = 200
Config.XP_BASE = 15 -- XP ที่ต้องใช้ = XP_BASE * level ^ XP_EXPONENT
Config.XP_EXPONENT = 1.4

-- ---------- Skill Tree ----------
Config.SKILL_POINTS_PER_LEVEL = 3
Config.STAT_ORDER = { "Health", "Attack", "Speed" }
-- PerPoint: Health/Attack = สัดส่วน (0.05 = +5%) · Speed = ความเร็วเพิ่มตรงๆ · Max = ใส่ได้สูงสุดกี่ point
Config.STATS = {
	Health = { Name = "HP", Description = "+5% HP", PerPoint = 0.05, Max = 300 },
	Attack = {
		Name = "พลังโจมตี",
		Description = "+5% ดาเมจ",
		PerPoint = 0.05,
		Max = 300,
	},
	Speed = {
		Name = "ความเร็ว",
		Description = "+0.4 ความเร็วเดิน",
		PerPoint = 0.4,
		Max = 25,
	},
}
Config.RACE_SKILL_UNLOCK_LEVEL = 10
Config.RACE_SKILL_COST = 3 -- points ต่อขั้น
Config.RACE_SKILL_MAX_RANK = 5

-- ---------- Rebirth ----------
-- ต้องล้มบอสโลก 1 + มี Coins ≥ ราคา (ราคา = BASE_COST * COST_GROWTH ^ จำนวนครั้งที่ rebirth แล้ว)
Config.REBIRTH_BASE_COST = 5000
Config.REBIRTH_COST_GROWTH = 2.5
Config.REBIRTH_BONUS = 0.5 -- +50% Coins/พลังถาวรต่อครั้ง
Config.REBIRTH_TOKENS = 1

-- ---------- มอน ----------
-- ค่าพื้นฐาน — แต่ละด่านคูณด้วย HealthMultiplier / DamageMultiplier / RewardMultiplier ของด่านนั้น
Config.ENEMIES = {
	Slime = { Name = "Slime", Health = 35, Damage = 4, AttackCooldown = 1.2, Speed = 8, Coins = 5, XP = 12 },
	Wolf = {
		Name = "Shadow Wolf",
		Health = 55,
		Damage = 6,
		AttackCooldown = 1,
		Speed = 14,
		Coins = 8,
		XP = 18,
	},
	Imp = {
		Name = "Fire Imp",
		Health = 60,
		Damage = 8,
		AttackCooldown = 1.1,
		Speed = 12,
		Coins = 10,
		XP = 24,
	},
	Golem = {
		Name = "Ancient Golem",
		Health = 900,
		Damage = 18,
		AttackCooldown = 1.8,
		Speed = 7,
		Coins = 400,
		XP = 600,
	},
}
Config.ENEMY_AGGRO_RANGE = 28
Config.BOSS_AGGRO_RANGE = 40
Config.ENEMY_LEASH_RANGE = 70 -- ไล่ไกลจากจุดเกิดเกินนี้ → กลับบ้าน + ฟื้น HP
Config.ENEMY_ATTACK_REACH = 4 -- ระยะตี (บวกขนาดตัวมอน)
Config.ENEMY_RESPAWN_TIME = 3
Config.BOSS_RESPAWN_TIME = 45
Config.BOSS_GEMS = 25
Config.MOB_GEM_CHANCE = 0.02 -- โอกาสดรอป 1 Gem (ให้คนที่ตีแรงสุด)
Config.KILL_CREDIT_MIN_SHARE = 0.1 -- ต้องทำดาเมจ ≥ 10% ถึงนับความคืบหน้าด่าน

-- ---------- Stage (โลก 1) ----------
-- ด่าน 1–4: ฆ่ามอนครบ KillsToClear → ปลดด่านถัดไป · ด่านที่มี Boss: ล้มบอส = เคลียร์โลก
Config.WORLD_NAME = "Enchanted Forest"
Config.STAGES = {
	{
		Name = "Meadow",
		Enemies = { "Slime" },
		HealthMultiplier = 1,
		DamageMultiplier = 1,
		RewardMultiplier = 1,
		MaxEnemies = 10,
		KillsToClear = 15,
	},
	{
		Name = "Deep Woods",
		Enemies = { "Slime", "Wolf" },
		HealthMultiplier = 2,
		DamageMultiplier = 1.5,
		RewardMultiplier = 2,
		MaxEnemies = 10,
		KillsToClear = 20,
	},
	{
		Name = "Wolf Den",
		Enemies = { "Wolf" },
		HealthMultiplier = 3.5,
		DamageMultiplier = 2,
		RewardMultiplier = 3.5,
		MaxEnemies = 10,
		KillsToClear = 25,
	},
	{
		Name = "Ember Grove",
		Enemies = { "Wolf", "Imp" },
		HealthMultiplier = 6,
		DamageMultiplier = 3,
		RewardMultiplier = 6,
		MaxEnemies = 10,
		KillsToClear = 30,
	},
	{
		Name = "Golem Throne",
		Enemies = { "Imp" },
		Boss = "Golem",
		HealthMultiplier = 10,
		DamageMultiplier = 4,
		RewardMultiplier = 10,
		MaxEnemies = 4,
	},
}

-- ---------- Summon (สัตว์เวท) ----------
Config.MAX_EQUIPPED = 3
Config.MAX_SUMMONS = 50 -- กระเป๋าเก็บได้สูงสุด
Config.SUMMON_RANGE = 26 -- รัศมีรอบตัวผู้เล่นที่สัตว์จะไปตีให้
Config.SUMMON_XP_SHARE = 0.5 -- สัตว์ในทีมได้ XP = XP มอน * ค่านี้
Config.SUMMON_XP_BASE = 15
Config.SUMMON_XP_EXPONENT = 1.4
Config.SUMMON_LEVEL_BONUS = 0.1 -- +10% พลังต่อเลเวล

Config.ELEMENT_ORDER = { "Fire", "Water", "Nature", "Light", "Shadow" }
Config.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
-- MaxLevel = เลเวลตันของสัตว์ระดับนั้น
Config.RARITIES = {
	Common = { Multiplier = 1, MaxLevel = 20 },
	Rare = { Multiplier = 1.6, MaxLevel = 30 },
	Epic = { Multiplier = 2.6, MaxLevel = 40 },
	Legendary = { Multiplier = 4.2, MaxLevel = 50 },
	Mythic = { Multiplier = 7, MaxLevel = 60 },
}

-- ระยะใกล้: วิ่งเข้าไปตี · ระยะไกล: ยืนห่างแล้วยิง (Reach = ระยะที่ตีถึง)
Config.ATTACK_TYPES = {
	Melee = { Name = "ระยะใกล้", Damage = 8, AttackCooldown = 1, Speed = 24, Reach = 3 },
	Ranged = { Name = "ระยะไกล", Damage = 6, AttackCooldown = 1.2, Speed = 20, Reach = 18 },
}

Config.SUMMONS = {
	LeafFox = { Name = "Leaf Fox", Element = "Nature", AttackType = "Melee", Rarity = "Common" },
	BubbleNewt = { Name = "Bubble Newt", Element = "Water", AttackType = "Ranged", Rarity = "Common" },
	EmberPup = { Name = "Ember Pup", Element = "Fire", AttackType = "Melee", Rarity = "Common" },
	TideSerpent = { Name = "Tide Serpent", Element = "Water", AttackType = "Melee", Rarity = "Rare" },
	ShadowBat = { Name = "Shadow Bat", Element = "Shadow", AttackType = "Ranged", Rarity = "Rare" },
	ThornBoar = { Name = "Thorn Boar", Element = "Nature", AttackType = "Melee", Rarity = "Rare" },
	FlameLynx = { Name = "Flame Lynx", Element = "Fire", AttackType = "Melee", Rarity = "Epic" },
	MoonOwl = { Name = "Moon Owl", Element = "Light", AttackType = "Ranged", Rarity = "Epic" },
	StormGriffin = { Name = "Storm Griffin", Element = "Light", AttackType = "Ranged", Rarity = "Legendary" },
	AbyssKirin = { Name = "Abyss Kirin", Element = "Shadow", AttackType = "Melee", Rarity = "Mythic" },
}

-- ไข่: 1 ใบต่อ 1 โลก · Rates = % ของแต่ละระดับ (รวมกันควรได้ 100) · Creatures = ตัวที่ออกได้
-- สุ่มระดับก่อน แล้วสุ่มตัวในระดับนั้น — ทุกระดับใน Rates ต้องมีตัวใน Creatures อย่างน้อย 1 ตัว
Config.EGG_ORDER = { "Forest" }
Config.EGGS = {
	Forest = {
		Name = "Forest Egg",
		Price = 100,
		Rates = { Common = 70, Rare = 22, Epic = 6.5, Legendary = 1.4, Mythic = 0.1 },
		Creatures = {
			"LeafFox",
			"BubbleNewt",
			"EmberPup",
			"TideSerpent",
			"ShadowBat",
			"ThornBoar",
			"FlameLynx",
			"MoonOwl",
			"StormGriffin",
			"AbyssKirin",
		},
	},
}
Config.ROLL_COUNTS = { 1, 3 } -- สุ่ม 1 / สุ่ม 3

return Config
