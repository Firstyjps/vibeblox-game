--!strict
-- ตัวอย่าง Service (ลบหรือแก้ได้): ผู้เล่นคลิก → ได้ Coins
-- แสดงรูปแบบที่ทีมใช้: server ตรวจทุกอย่าง (กันโกง), จำกัดความถี่, แก้ข้อมูลผ่าน PlayerData

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local CLICKS_PER_SECOND = 8

local ExampleClickService = {}
local PlayerData
local lastClick: { [Player]: number } = {}

function ExampleClickService.Init(services)
	PlayerData = services.PlayerData
end

function ExampleClickService.Start()
	Net.event("Click").OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastClick[player] or 0) < 1 / CLICKS_PER_SECOND then
			return -- คลิกเร็วเกิน (autoclicker) → ไม่นับ
		end
		lastClick[player] = now
		PlayerData.update(player, function(data)
			data.Coins += 1
		end)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastClick[player] = nil
	end)
end

return ExampleClickService
