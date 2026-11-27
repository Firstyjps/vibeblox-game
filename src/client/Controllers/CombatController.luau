--!strict
-- ปุ่มตี (มือถือ: ปุ่มกลางขวา · PC: คลิกซ้าย / ปุ่ม F ค้างได้), ตัวเลขดาเมจ, เส้นเอฟเฟกต์ตอนตี
-- client แค่ "ขอตี" — server เป็นคนเลือกเป้าและเช็ก cooldown

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Modules = Shared:WaitForChild("Modules")
local Formulas = require(Modules:WaitForChild("Formulas"))
local Theme = require(Modules:WaitForChild("Theme"))
local Ui = require(Modules:WaitForChild("Ui"))

local REQUEST_INTERVAL = 0.12
local MAX_POPS = 40
local FX_MAX_DISTANCE = 160

local CombatController = {}

local activePops = 0
local fxFolder: Folder

local function showPop(position: Vector3, amount: number, kind: string)
	if activePops >= MAX_POPS then
		return
	end
	activePops += 1
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position + Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1)
	attachment.Parent = workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 34)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Adornee = attachment
	gui.Parent = attachment
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Theme.POP_COLORS[kind] or Theme.TEXT
	label.TextStrokeTransparency = 0.2
	label.Text = (if kind == "Hurt" then "-" else "") .. Formulas.format(amount)
	label.Parent = gui

	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffset = Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.75, function()
		attachment:Destroy()
		activePops -= 1
	end)
end

local function showSlash(from: Vector3, to: Vector3, color: Color3)
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - from).Magnitude > FX_MAX_DISTANCE then
		return
	end
	local distance = (to - from).Magnitude
	if distance < 0.1 then
		return
	end
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Size = Vector3.new(0.35, 0.35, distance)
	beam.CFrame = CFrame.lookAt((from + to) / 2, to)
	beam.Parent = fxFolder
	TweenService
		:Create(beam, TweenInfo.new(0.2), { Transparency = 1, Size = Vector3.new(0.05, 0.05, distance) })
		:Play()
	task.delay(0.22, function()
		beam:Destroy()
	end)
end

function CombatController.Start()
	local attackRemote = Net.event("Attack")
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "ClientFx"
	fxFolder.Parent = workspace

	local holdingButton = false
	local holdingInput = false
	local lastRequest = 0

	local function request()
		local now = os.clock()
		if now - lastRequest >= REQUEST_INTERVAL then
			lastRequest = now
			attackRemote:FireServer()
		end
	end

	-- ปุ่มตีกลางขวา (เหนือปุ่มกระโดดบนมือถือ)
	local gui = Ui.screen("Combat", 1)
	local button = Ui.button(gui, "⚔️ ตี", Theme.DANGER, UDim2.fromOffset(110, 110), request)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -24, 0.55, 0)
	local corner = button:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(0.5, 0)
	end
	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			holdingButton = true
		end
	end)
	button.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			holdingButton = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingInput = true
			request()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingInput = false
		end
	end)
	RunService.Heartbeat:Connect(function()
		if holdingButton or holdingInput then
			request()
		end
	end)

	Net.unreliable("DamagePop").OnClientEvent
		:Connect(function(position: unknown, amount: unknown, kind: unknown)
			if typeof(position) == "Vector3" and type(amount) == "number" and type(kind) == "string" then
				showPop(position, amount, kind)
			end
		end)
	Net.unreliable("AttackFx").OnClientEvent:Connect(function(from: unknown, to: unknown, color: unknown)
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" and typeof(color) == "Color3" then
			showSlash(from, to, color)
		end
	end)
end

return CombatController
