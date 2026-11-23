--!strict
-- ค่าตั้งของเกม (สมดุล/ราคา/อัตรา) — ปรับเกมที่นี่ ไม่ต้องแก้โค้ดระบบ
-- แยกหมวดด้วย comment ตามระบบ เพื่อให้หลายคนแก้คนละส่วนได้

local Config = {}

-- ---------- ข้อมูลผู้เล่น ----------
Config.DATASTORE_NAME = "PlayerData_v1" -- เปลี่ยนเวอร์ชันเมื่อโครงสร้างข้อมูลเปลี่ยนแบบเข้ากันไม่ได้
Config.AUTOSAVE_INTERVAL = 60
Config.STARTING_COINS = 0

return Config
