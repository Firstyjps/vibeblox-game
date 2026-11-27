--!strict
-- สี/ข้อความที่ใช้ร่วมกันทั้งโมเดลฝั่ง server และ UI ฝั่ง client (ไม่ใช่ค่าสมดุลเกม)

local Theme = {}

Theme.RARITY_COLORS = {
	Common = Color3.fromRGB(200, 210, 220),
	Rare = Color3.fromRGB(70, 160, 255),
	Epic = Color3.fromRGB(185, 95, 255),
	Legendary = Color3.fromRGB(255, 195, 45),
	Mythic = Color3.fromRGB(255, 70, 125),
} :: { [string]: Color3 }

Theme.RACE_COLORS = {
	Elf = Color3.fromRGB(110, 230, 120),
	Dragon = Color3.fromRGB(255, 125, 50),
	Vampire = Color3.fromRGB(215, 40, 70),
	Lich = Color3.fromRGB(150, 115, 255),
	Fairy = Color3.fromRGB(255, 150, 230),
} :: { [string]: Color3 }

Theme.ROLE_LABELS = {
	Tank = "🛡 แทงก์",
	Assassin = "🗡 แอสซาซิน",
	Mage = "✨ เวทย์",
} :: { [string]: string }

Theme.COIN = Color3.fromRGB(255, 205, 60)
Theme.GEM = Color3.fromRGB(80, 225, 255)
Theme.XP = Color3.fromRGB(140, 255, 120)
Theme.PANEL = Color3.fromRGB(30, 27, 52)
Theme.PANEL_LIGHT = Color3.fromRGB(50, 45, 85)
Theme.ACCENT = Color3.fromRGB(125, 95, 255)
Theme.GOOD = Color3.fromRGB(70, 200, 110)
Theme.DANGER = Color3.fromRGB(255, 80, 95)
Theme.TEXT = Color3.fromRGB(255, 255, 255)
Theme.TEXT_DIM = Color3.fromRGB(185, 180, 215)

-- สีตัวเลขดาเมจ
Theme.POP_COLORS = {
	Player = Color3.fromRGB(255, 240, 120),
	Summon = Color3.fromRGB(130, 220, 255),
	Hurt = Color3.fromRGB(255, 80, 80),
	Heal = Color3.fromRGB(120, 255, 140),
} :: { [string]: Color3 }

return Theme
