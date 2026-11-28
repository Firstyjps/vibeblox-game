--!strict
-- แจ้งเตือนสั้นๆ กลางจอด้านบน (server ยิง Net "Notify" หรือ controller อื่นเรียก NotifyController.show)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Theme = require(Shared:WaitForChild("Modules"):WaitForChild("Theme"))
local Ui = require(Shared.Modules:WaitForChild("Ui"))

local MAX_VISIBLE = 4
local LIFETIME = 2.6

local COLORS: { [string]: Color3 } = {
	Good = Theme.GOOD,
	Bad = Theme.DANGER,
	Boss = Color3.fromRGB(255, 150, 40),
	Gem = Color3.fromRGB(40, 170, 210),
}

local NotifyController = {}
local container: Frame? = nil

local function getContainer(): Frame
	if container then
		return container
	end
	local gui = Ui.screen("Notify", 10)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 120)
	frame.Size = UDim2.fromOffset(440, 200)
	frame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	container = frame
	return frame
end

local order = 0

function NotifyController.show(text: string, kind: string?)
	local parent = getContainer()
	order += 1
	local label = Ui.label(parent, text, UDim2.fromOffset(420, 36), {
		BackgroundTransparency = 0.1,
		BackgroundColor3 = COLORS[kind or ""] or Theme.ACCENT,
		LayoutOrder = order,
	})
	Ui.corner(label, 10)
	Ui.stroke(label, Color3.new(0, 0, 0), 2)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.Parent = label

	local labels = {}
	for _, child in parent:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	table.sort(labels, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #labels - MAX_VISIBLE do
		labels[i]:Destroy()
	end

	task.delay(LIFETIME, function()
		if label.Parent then
			local info = TweenInfo.new(0.3)
			TweenService:Create(label, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			task.wait(0.3)
			label:Destroy()
		end
	end)
end

function NotifyController.Start()
	Net.event("Notify").OnClientEvent:Connect(function(text: unknown, kind: unknown)
		if type(text) == "string" then
			NotifyController.show(text, if type(kind) == "string" then kind else nil)
		end
	end)
end

return NotifyController
