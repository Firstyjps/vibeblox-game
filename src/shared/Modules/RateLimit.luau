--!strict
-- จำกัดความถี่ต่อผู้เล่น (ใช้ฝั่ง server ครอบ remote)
--   local allow = RateLimit.new(5)   -- ไม่เกิน 5 ครั้ง/วินาที
--   if not allow(player) then return end

local Players = game:GetService("Players")

local RateLimit = {}

function RateLimit.new(perSecond: number): (Player) -> boolean
	local interval = 1 / perSecond
	local last: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	return function(player: Player): boolean
		local now = os.clock()
		local previous = last[player]
		if previous and now - previous < interval then
			return false
		end
		last[player] = now
		return true
	end
end

return RateLimit
