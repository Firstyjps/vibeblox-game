--!strict
-- หน้า Skill Tree: ใช้ Skill Points อัป HP / พลังโจมตี / ความเร็ว + สกิลเผ่า (ปลดที่ Lv.10)
-- ค่าที่โชว์คำนวณด้วย Formulas เดียวกับ server · server ตรวจซ้ำทุกครั้ง

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Modules = Shared:WaitForChild("Modules")
local Formulas = require(Modules:WaitForChild("Formulas"))
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local player = Players.LocalPlayer

local WATCHED =
	{ "Race", "Level", "SkillPoints", "StatHealth", "StatAttack", "StatSpeed", "Rebirths", "RaceSkillsJson" }
local STAT_ICONS = { Health = "❤️", Attack = "⚔️", Speed = "👟" }

local SkillController = {}
local Notify

local function snapshot(): any
	local function num(name: string, default: number): number
		local value = player:GetAttribute(name)
		return if type(value) == "number" then value else default
	end
	local race = player:GetAttribute("Race")
	local ranks = {}
	local raw = player:GetAttribute("RaceSkillsJson")
	if type(raw) == "string" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if ok and type(decoded) == "table" then
			ranks = decoded
		end
	end
	return {
		Race = if type(race) == "string" then race else "",
		Level = num("Level", 1),
		SkillPoints = num("SkillPoints", 0),
		StatHealth = num("StatHealth", 0),
		StatAttack = num("StatAttack", 0),
		StatSpeed = num("StatSpeed", 0),
		Rebirths = num("Rebirths", 0),
		RaceSkills = ranks,
	}
end

local function row(parent: Instance, y: number): (Frame, TextLabel, TextLabel)
	local frame = Instance.new("Frame")
	frame.Position = UDim2.fromOffset(0, y)
	frame.Size = UDim2.new(1, 0, 0, 52)
	frame.BackgroundColor3 = Theme.PANEL_LIGHT
	Ui.corner(frame, 10)
	frame.Parent = parent
	local title = Ui.label(frame, "", UDim2.new(1, -200, 0, 24), {
		Position = UDim2.fromOffset(12, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local detail = Ui.label(frame, "", UDim2.new(1, -200, 0, 18), {
		Position = UDim2.fromOffset(12, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.TEXT_DIM,
	})
	return frame, title, detail
end

function SkillController.Init(controllers)
	Notify = controllers.NotifyController
end

function SkillController.Start()
	local spendRemote = Net.func("SpendStat")
	local raceSkillRemote = Net.func("UpgradeRaceSkill")
	local panel = Ui.panel("⭐ Skill Tree", Vector2.new(600, 470))
	local content = panel.content

	local function call(remote: RemoteFunction, ...: any)
		local args = { ... }
		local ok, success, message = pcall(function()
			return remote:InvokeServer(table.unpack(args))
		end)
		if not (ok and success) and Notify then
			Notify.show(
				if ok and type(message) == "string" then message else "ทำไม่สำเร็จ",
				"Bad"
			)
		end
	end

	local pointsLabel = Ui.label(content, "", UDim2.new(1, 0, 0, 28), {
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.COIN,
	})
	local statsLabel = Ui.label(content, "", UDim2.new(1, 0, 0, 20), {
		Position = UDim2.fromOffset(0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.TEXT_DIM,
	})

	-- ---------- ค่าพื้นฐาน ----------
	local statRows = {}
	for index, stat in Config.STAT_ORDER do
		local frame, title, detail = row(content, 58 + (index - 1) * 58)
		for buttonIndex, amount in { 1, 5 } do
			local button = Ui.button(frame, `+{amount}`, Theme.GOOD, UDim2.fromOffset(80, 40), function()
				call(spendRemote, stat, amount)
			end)
			button.AnchorPoint = Vector2.new(1, 0.5)
			button.Position = UDim2.new(1, -8 - (2 - buttonIndex) * 88, 0.5, 0)
		end
		statRows[stat] = { title = title, detail = detail }
	end

	-- ---------- สกิลเผ่า ----------
	local raceTitle = Ui.label(content, "", UDim2.new(1, 0, 0, 26), {
		Position = UDim2.fromOffset(0, 236),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local raceRows = {}
	for index = 1, 2 do
		local frame, title, detail = row(content, 266 + (index - 1) * 58)
		local button = Ui.button(frame, "", Theme.ACCENT, UDim2.fromOffset(168, 40), function()
			local skill = Formulas.race(snapshot().Race).Skills[index]
			if skill then
				call(raceSkillRemote, skill.Id)
			end
		end)
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -8, 0.5, 0)
		raceRows[index] = { frame = frame, title = title, detail = detail, button = button }
	end

	local function refresh()
		local data = snapshot()
		local stats = Formulas.playerStats(data)
		pointsLabel.Text =
			`⭐ Skill Points: {data.SkillPoints}   (เลเวลอัปได้ {Config.SKILL_POINTS_PER_LEVEL} points)`
		statsLabel.Text = `ดาเมจ {Formulas.format(stats.Damage)} · HP {Formulas.format(
			stats.MaxHealth
		)} · ความเร็ว {math.floor(stats.WalkSpeed * 10) / 10} · ระยะตี {stats.Range}`

		for stat, ui in statRows do
			local def = (Config.STATS :: any)[stat]
			local value = data["Stat" .. stat]
			ui.title.Text = `{STAT_ICONS[stat] or ""} {def.Name}  ขั้น {value}/{def.Max}`
			ui.detail.Text = `{def.Description} ต่อ point`
		end

		local race = Formulas.race(data.Race)
		local unlocked = data.Level >= Config.RACE_SKILL_UNLOCK_LEVEL
		raceTitle.Text = if unlocked
			then `สกิลเผ่า {race.Name} (ขั้นละ {Config.RACE_SKILL_COST} points)`
			else `🔒 สกิลเผ่า {race.Name} — ปลดที่ Lv.{Config.RACE_SKILL_UNLOCK_LEVEL}`
		raceTitle.TextColor3 = Theme.RACE_COLORS[data.Race] or Theme.TEXT
		for index, ui in raceRows do
			local skill = race.Skills[index]
			ui.frame.Visible = skill ~= nil
			if skill then
				local rank = data.RaceSkills[skill.Id] or 0
				ui.title.Text = `{skill.Name}  ขั้น {rank}/{Config.RACE_SKILL_MAX_RANK}`
				ui.detail.Text = `{skill.Description} ต่อขั้น`
				if rank >= Config.RACE_SKILL_MAX_RANK then
					ui.button.Text = "เต็มแล้ว"
					ui.button.BackgroundColor3 = Theme.PANEL
				elseif not unlocked then
					ui.button.Text = `🔒 Lv.{Config.RACE_SKILL_UNLOCK_LEVEL}`
					ui.button.BackgroundColor3 = Theme.PANEL
				else
					ui.button.Text = `อัป ({Config.RACE_SKILL_COST} ⭐)`
					ui.button.BackgroundColor3 = if data.SkillPoints >= Config.RACE_SKILL_COST
						then Theme.ACCENT
						else Theme.PANEL
				end
			end
		end
	end

	for _, name in WATCHED do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	Ui.sideButton("⭐ Skills", 3, Color3.fromRGB(230, 170, 40), panel.toggle)
end

return SkillController
