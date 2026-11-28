--!strict
-- Skill Tree: ใช้ Skill Points อัปค่าพื้นฐาน (HP / พลังโจมตี / ความเร็ว) และสกิลเฉพาะเผ่า (ปลดที่ Lv.10)
-- ค่าพลังจริงคำนวณใน Formulas.playerStats · ส่งขั้นสกิลเผ่าให้ UI ผ่าน Attribute "RaceSkillsJson"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)
local RateLimit = require(ReplicatedStorage.Shared.Modules.RateLimit)

local MAX_POINTS_PER_REQUEST = 100

local SkillService = {}
local PlayerData

local function sync(player: Player)
	local data = PlayerData.get(player)
	if data then
		player:SetAttribute("RaceSkillsJson", HttpService:JSONEncode(data.RaceSkills))
	end
end

local function findRaceSkill(race: string, skillId: string): any?
	for _, skill in Formulas.race(race).Skills do
		if skill.Id == skillId then
			return skill
		end
	end
	return nil
end

-- ใส่ point ลงค่าพื้นฐาน · count = จำนวน point (1–100)
local function spendStat(player: Player, stat: unknown, count: unknown): (boolean, string?)
	if type(stat) ~= "string" or type(count) ~= "number" or count ~= count then
		return false
	end
	local def = (Config.STATS :: any)[stat]
	local data: any = PlayerData.get(player)
	if not def or not data then
		return false
	end
	local field = "Stat" .. stat
	local amount = math.clamp(math.floor(count), 1, MAX_POINTS_PER_REQUEST)
	amount = math.min(amount, data.SkillPoints, def.Max - data[field])
	if amount <= 0 then
		return false,
			if data.SkillPoints <= 0
				then "Skill Points ไม่พอ"
				else "อัปเต็มแล้ว"
	end
	PlayerData.update(player, function(d: any)
		d.SkillPoints -= amount
		d[field] += amount
	end)
	return true
end

local function upgradeRaceSkill(player: Player, skillId: unknown): (boolean, string?)
	if type(skillId) ~= "string" then
		return false
	end
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local skill = findRaceSkill(data.Race, skillId)
	if not skill then
		return false
	end
	if data.Level < Config.RACE_SKILL_UNLOCK_LEVEL then
		return false, `ปลดสกิลเผ่าที่ Lv.{Config.RACE_SKILL_UNLOCK_LEVEL}`
	end
	local rank = data.RaceSkills[skillId] or 0
	if rank >= Config.RACE_SKILL_MAX_RANK then
		return false, "สกิลนี้เต็มแล้ว"
	end
	if data.SkillPoints < Config.RACE_SKILL_COST then
		return false, `ต้องใช้ {Config.RACE_SKILL_COST} Skill Points`
	end
	PlayerData.update(player, function(d)
		d.SkillPoints -= Config.RACE_SKILL_COST
		d.RaceSkills[skillId] = rank + 1
	end)
	sync(player)
	return true
end

-- RaceService เรียกตอน dev เปลี่ยนเผ่า: คืน point ของสกิลเผ่าเดิมทั้งหมด
function SkillService.refundRaceSkills(player: Player)
	PlayerData.update(player, function(d)
		local refund = 0
		for _, rank in d.RaceSkills do
			refund += rank * Config.RACE_SKILL_COST
		end
		d.SkillPoints += refund
		d.RaceSkills = {}
	end)
	sync(player)
end

function SkillService.Init(services)
	PlayerData = services.PlayerData
end

function SkillService.Start()
	local allow = RateLimit.new(10)

	Net.func("SpendStat").OnServerInvoke = function(player: Player, stat: unknown, count: unknown)
		if not allow(player) then
			return false
		end
		return spendStat(player, stat, count)
	end
	Net.func("UpgradeRaceSkill").OnServerInvoke = function(player: Player, skillId: unknown)
		if not allow(player) then
			return false
		end
		return upgradeRaceSkill(player, skillId)
	end

	PlayerData.Loaded:Connect(sync)
	for _, player in Players:GetPlayers() do
		if PlayerData.get(player) then
			sync(player)
		end
	end
end

return SkillService
