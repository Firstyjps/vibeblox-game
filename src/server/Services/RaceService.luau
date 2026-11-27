--!strict
-- เผ่า: เลือกครั้งแรก (ครั้งเดียว), ปุ่ม dev เปลี่ยนเผ่าได้อิสระ, ใส่ค่าพลัง (HP/ความเร็ว) ให้ตัวละคร
-- ค่าพลังคำนวณใหม่เองทุกครั้งที่ Race/Level/HealthUpgrades เปลี่ยน

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Modules.Formulas)
local RateLimit = require(ReplicatedStorage.Shared.Modules.RateLimit)
local Theme = require(ReplicatedStorage.Shared.Modules.Theme)

local STAT_FIELDS = { "Race", "Level", "HealthUpgrades" }

local RaceService = {}
local PlayerData

local function isDev(player: Player): boolean
	return RunService:IsStudio() or table.find(Config.DEV_USER_IDS, player.UserId) ~= nil
end

local function isValidRace(race: unknown): boolean
	return type(race) == "string" and (Config.RACES :: any)[race] ~= nil
end

local function updateTag(character: Model, data: any)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local tag = head:FindFirstChild("RaceTag") :: BillboardGui?
	if not tag then
		local gui = Instance.new("BillboardGui")
		gui.Name = "RaceTag"
		gui.Size = UDim2.fromOffset(160, 26)
		gui.StudsOffset = Vector3.new(0, 2.4, 0)
		gui.MaxDistance = 90
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
		gui.Parent = head
		tag = gui
	end
	local label = (tag :: BillboardGui):FindFirstChild("Label") :: TextLabel
	local race = Formulas.race(data.Race)
	label.Text = `{race.Name} · Lv.{data.Level}`
	label.TextColor3 = Theme.RACE_COLORS[data.Race] or Theme.TEXT
end

function RaceService.applyStats(player: Player)
	local character = player.Character
	local data = PlayerData.get(player)
	if not character or not data then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local maxHealth = Formulas.playerMaxHealth(data)
	local ratio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
	humanoid.MaxHealth = maxHealth
	humanoid.Health = math.clamp(maxHealth * ratio, 1, maxHealth)
	humanoid.WalkSpeed = Formulas.race(data.Race).WalkSpeed
	updateTag(character, data)
end

local function setRace(player: Player, race: string)
	PlayerData.update(player, function(data)
		data.Race = race
	end)
	Net.event("Notify"):FireClient(player, `คุณคือเผ่า {race} แล้ว!`, "Good")
end

function RaceService.Init(services)
	PlayerData = services.PlayerData
end

function RaceService.Start()
	local allow = RateLimit.new(2)

	Net.func("ChooseRace").OnServerInvoke = function(player: Player, race: unknown)
		if not allow(player) or not isValidRace(race) then
			return false
		end
		local data = PlayerData.get(player)
		if not data or data.Race ~= "" then
			return false -- เลือกได้ครั้งเดียว
		end
		setRace(player, race :: string)
		return true
	end

	Net.func("DevSetRace").OnServerInvoke = function(player: Player, race: unknown)
		if not isDev(player) or not allow(player) or not isValidRace(race) then
			return false
		end
		if not PlayerData.get(player) then
			return false
		end
		setRace(player, race :: string)
		return true
	end

	local function onPlayer(player: Player)
		player:SetAttribute("IsDev", isDev(player))
		for _, field in STAT_FIELDS do
			player:GetAttributeChangedSignal(field):Connect(function()
				RaceService.applyStats(player)
			end)
		end
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			character:WaitForChild("Head")
			RaceService.applyStats(player)
		end)
		if player.Character then
			task.spawn(RaceService.applyStats, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	PlayerData.Loaded:Connect(function(player)
		RaceService.applyStats(player)
	end)
end

return RaceService
