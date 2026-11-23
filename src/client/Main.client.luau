-- จุดเริ่มฝั่ง client: โหลดทุก ModuleScript ใน Controllers แล้วเรียก Init() ก่อน Start()
-- เพิ่ม UI/ระบบฝั่งผู้เล่นใหม่ = สร้างไฟล์ใหม่ใน src/client/Controllers/ ไม่ต้องแก้ไฟล์นี้

local controllersFolder = script.Parent:WaitForChild("Controllers")

local controllers: { [string]: any } = {}
for _, module in controllersFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok then
			controllers[module.Name] = result
		else
			warn(`[Client] โหลด {module.Name} ไม่สำเร็จ: {result}`)
		end
	end
end

for name, controller in controllers do
	if type(controller.Init) == "function" then
		local ok, err = pcall(controller.Init, controllers)
		if not ok then
			warn(`[Client] {name}.Init พัง: {err}`)
		end
	end
end

for name, controller in controllers do
	if type(controller.Start) == "function" then
		task.spawn(function()
			local ok, err = pcall(controller.Start)
			if not ok then
				warn(`[Client] {name}.Start พัง: {err}`)
			end
		end)
	end
end
