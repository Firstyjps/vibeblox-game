--!strict
-- ตัวช่วยสร้าง UI ฝั่ง client: ScreenGui พร้อม UIScale (ย่อตามจอ), ปุ่ม, panel, เมนูข้าง
-- เมนูข้างอยู่กลางซ้าย และ panel อยู่กลางจอ → ไม่ทับจอยสติ๊ก (ซ้ายล่าง) / ปุ่มกระโดด (ขวาล่าง)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("Theme"))

local Ui = {}

local DESIGN_SIZE = Vector2.new(1100, 650) -- ขนาดจอที่ออกแบบไว้ (scale = 1)

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function attachScale(gui: ScreenGui)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local function update()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		scale.Scale = math.clamp(math.min(viewport.X / DESIGN_SIZE.X, viewport.Y / DESIGN_SIZE.Y), 0.55, 1.25)
	end
	update()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
end

function Ui.screen(name: string, displayOrder: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = displayOrder or 0
	attachScale(gui)
	gui.Parent = playerGui()
	return gui
end

function Ui.corner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
end

function Ui.stroke(parent: GuiObject, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0, 0, 0)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
end

function Ui.label(parent: Instance, text: string, size: UDim2, props: { [string]: any }?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Theme.TEXT
	label.TextScaled = true
	label.Text = text
	if props then
		for key, value in props do
			(label :: any)[key] = value
		end
	end
	label.Parent = parent
	return label
end

function Ui.button(parent: Instance, text: string, color: Color3, size: UDim2, onClick: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Theme.TEXT
	button.TextScaled = true
	button.Text = text
	Ui.corner(button, 10)
	Ui.stroke(button, Color3.new(0, 0, 0), 2)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.Activated:Connect(function()
		scale.Scale = 0.92
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		onClick()
	end)
	button.Parent = parent
	return button
end

-- ---------- Panel (เปิดได้ทีละอัน) ----------
local panelGui: ScreenGui? = nil
local openPanel: Frame? = nil

export type Panel = { frame: Frame, content: Frame, open: () -> (), close: () -> (), toggle: () -> () }

function Ui.panel(title: string, size: Vector2): Panel
	if not panelGui then
		panelGui = Ui.screen("Panels", 5)
	end
	local frame = Instance.new("Frame")
	frame.Name = title
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.BackgroundColor3 = Theme.PANEL
	frame.Visible = false
	Ui.corner(frame, 18)
	Ui.stroke(frame, Theme.ACCENT, 3)
	frame.Parent = panelGui

	Ui.label(frame, title, UDim2.new(1, -120, 0, 40), {
		Position = UDim2.fromOffset(20, 10),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(16, 60)
	content.Size = UDim2.new(1, -32, 1, -76)
	content.Parent = frame

	local panel: Panel
	local function close()
		frame.Visible = false
		if openPanel == frame then
			openPanel = nil
		end
	end
	local function open()
		if openPanel and openPanel ~= frame then
			openPanel.Visible = false
		end
		openPanel = frame
		frame.Visible = true
	end
	panel = {
		frame = frame,
		content = content,
		open = open,
		close = close,
		toggle = function()
			if frame.Visible then
				close()
			else
				open()
			end
		end,
	}

	local closeButton = Ui.button(frame, "X", Theme.DANGER, UDim2.fromOffset(44, 44), close)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -10, 0, 10)
	return panel
end

-- ---------- เมนูข้าง (กลางซ้าย) ----------
local sideList: Frame? = nil

function Ui.sideButton(text: string, order: number, color: Color3, onClick: () -> ()): TextButton
	if not sideList then
		local gui = Ui.screen("SideMenu", 2)
		local list = Instance.new("Frame")
		list.Name = "List"
		list.BackgroundTransparency = 1
		list.AnchorPoint = Vector2.new(0, 0.5)
		list.Position = UDim2.new(0, 12, 0.48, 0)
		list.Size = UDim2.fromOffset(120, 300)
		list.Parent = gui
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = list
		sideList = list
	end
	local button = Ui.button(sideList :: Frame, text, color, UDim2.fromOffset(120, 52), onClick)
	button.LayoutOrder = order
	return button
end

return Ui
