--!strict
-- ตัวอย่าง Controller (ลบหรือแก้ได้): ปุ่มคลิก + แสดง Coins
-- แสดงรูปแบบที่ทีมใช้: client แค่ส่งคำขอ แล้วอ่านค่าจริงจาก Attribute ที่ server ตั้ง

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local player = Players.LocalPlayer

local ExampleClickController = {}

function ExampleClickController.Start()
	local clickRemote = Net.event("Click")

	local gui = Instance.new("ScreenGui")
	gui.Name = "ExampleClickUI"
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -24)
	button.Size = UDim2.fromOffset(220, 56)
	button.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 20
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	local function refresh()
		local coins = player:GetAttribute("Coins")
		button.Text = `Click!  (Coins: {if type(coins) == "number" then coins else 0})`
	end
	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	refresh()

	button.Activated:Connect(function()
		clickRemote:FireServer()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return ExampleClickController
