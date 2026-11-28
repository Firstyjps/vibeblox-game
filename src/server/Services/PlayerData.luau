--!strict
-- ข้อมูลผู้เล่น + เซฟ DataStore (ระบบอื่นอ่าน/แก้ผ่าน service นี้เท่านั้น)
--
--   local data = services.PlayerData.get(player)            -- อ่าน (อาจเป็น nil ระหว่างโหลด)
--   services.PlayerData.update(player, function(d) d.Coins += 5 end)  -- แก้ + ส่งค่าให้ client + ติดธงเซฟ
--
-- กติกา: เพิ่ม field ใหม่ที่ DEFAULT เท่านั้น (ข้อมูลเก่าจะได้ค่าเริ่มต้นอัตโนมัติ)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type SummonEntry = { Kind: string, Level: number, XP: number }

export type Data = {
	Coins: number,
	Gems: number,
	RebirthTokens: number,
	Race: string, -- "" = ยังไม่เลือก
	Level: number,
	XP: number,
	SkillPoints: number, -- point ที่ยังไม่ได้ใช้
	StatHealth: number,
	StatAttack: number,
	StatSpeed: number,
	RaceSkills: { [string]: number }, -- id สกิลเผ่า → ขั้น
	Rebirths: number,
	StageUnlocked: number, -- ด่านไกลสุดที่เปิดแล้ว (นับความคืบหน้าเฉพาะด่านนี้)
	StageKills: number,
	BossDefeated: boolean, -- ล้มบอสโลก 1 แล้ว (เงื่อนไข Rebirth)
	Summons: { [string]: SummonEntry }, -- id → สัตว์
	Equipped: { string }, -- id ของสัตว์ที่ใส่ทีม
	NextSummonId: number,
}

local DEFAULT: Data = {
	Coins = Config.STARTING_COINS,
	Gems = Config.STARTING_GEMS,
	RebirthTokens = 0,
	Race = "",
	Level = 1,
	XP = 0,
	SkillPoints = 0,
	StatHealth = 0,
	StatAttack = 0,
	StatSpeed = 0,
	RaceSkills = {},
	Rebirths = 0,
	StageUnlocked = 1,
	StageKills = 0,
	BossDefeated = false,
	Summons = {},
	Equipped = {},
	NextSummonId = 1,
}

-- ค่าที่ส่งให้ client ผ่าน player Attribute (อ่านใน client ด้วย player:GetAttribute("Coins"))
-- (ตาราง Summons/Equipped/RaceSkills → SummonService/SkillService ส่งเองเป็น JSON)
local REPLICATED_FIELDS = {
	"Coins",
	"Gems",
	"RebirthTokens",
	"Race",
	"Level",
	"XP",
	"SkillPoints",
	"StatHealth",
	"StatAttack",
	"StatSpeed",
	"Rebirths",
	"StageUnlocked",
	"StageKills",
	"BossDefeated",
}
local LEADERSTATS = { "Level", "Rebirths", "Coins" }

local MAX_RETRIES = 3

type Session = { data: Data, canSave: boolean, dirty: boolean }

local PlayerData = {}
local sessions: { [Player]: Session } = {}
local loadedEvent = Instance.new("BindableEvent")
PlayerData.Loaded = loadedEvent.Event -- (player, data) ยิงเมื่อโหลดเสร็จ

-- เกมที่ยังไม่ publish / ปิด API Services → ใช้ DataStore ไม่ได้ เล่นได้แต่ไม่เซฟ
local storeOk, store = pcall(function()
	return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
end)
if not storeOk then
	warn(
		`[PlayerData] ใช้ DataStore ไม่ได้ เล่นได้แต่ไม่เซฟ: {store}`
	)
	store = nil
end

local function withRetry<T>(label: string, fn: () -> T): (boolean, any)
	local lastErr
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if attempt < MAX_RETRIES then
			task.wait(attempt)
		end
	end
	warn(`[PlayerData] {label} ไม่สำเร็จ: {lastErr}`)
	return false, lastErr
end

-- copy ลึก (ตารางซ้อนต้องไม่แชร์กันระหว่างผู้เล่น)
local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in value :: any do
		copy[key] = deepCopy(item)
	end
	return copy :: any
end

local function sanitize(saved: unknown): Data
	local data = deepCopy(DEFAULT)
	if type(saved) == "table" then
		local raw: any = data
		for key, default in DEFAULT :: any do
			local value = (saved :: any)[key]
			if type(value) == type(default) then
				raw[key] = value
			end
		end
	end
	return data
end

local function replicate(player: Player, data: Data)
	local raw: any = data
	for _, field in REPLICATED_FIELDS do
		if player:GetAttribute(field) ~= raw[field] then
			player:SetAttribute(field, raw[field])
		end
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		for _, field in LEADERSTATS do
			local value = leaderstats:FindFirstChild(field)
			if value and value:IsA("IntValue") then
				value.Value = raw[field]
			end
		end
	end
end

local function save(player: Player)
	local session = sessions[player]
	if not session or not session.canSave or not session.dirty or not store then
		return
	end
	local snapshot = deepCopy(session.data)
	session.dirty = false
	local ok = withRetry(`เซฟ {player.Name}`, function()
		return store:UpdateAsync(tostring(player.UserId), function()
			return snapshot
		end)
	end)
	if not ok then
		session.dirty = true
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, field in LEADERSTATS do
		local value = Instance.new("IntValue")
		value.Name = field
		value.Parent = leaderstats
	end
	leaderstats.Parent = player

	local data, canSave = deepCopy(DEFAULT), false
	if store then
		local ok, saved = withRetry(`โหลด {player.Name}`, function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok then
			data, canSave = sanitize(saved), true
		end
	end
	if player.Parent == nil then
		return
	end
	sessions[player] = { data = data, canSave = canSave, dirty = false }
	replicate(player, data)
	loadedEvent:Fire(player, data)
end

function PlayerData.get(player: Player): Data?
	local session = sessions[player]
	return session and session.data
end

function PlayerData.update(player: Player, mutate: (Data) -> ()): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	mutate(session.data)
	session.dirty = true
	replicate(player, session.data)
	return true
end

function PlayerData.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		sessions[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_INTERVAL)
			for player in sessions do
				task.spawn(save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in sessions do
			pending += 1
			task.spawn(function()
				save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait()
		end
	end)
end

return PlayerData
