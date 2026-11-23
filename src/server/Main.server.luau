-- จุดเริ่มฝั่ง server: โหลดทุก ModuleScript ใน Services แล้วเรียก Init() ทุกตัวก่อน ค่อย Start()
-- เพิ่มระบบใหม่ = สร้างไฟล์ใหม่ใน src/server/Services/ ไม่ต้องแก้ไฟล์นี้
--
-- รูปแบบ Service:
--   local MyService = {}
--   function MyService.Init(services) end   -- (ไม่บังคับ) เตรียมของ ห้ามรอ/ห้าม yield
--   function MyService.Start() end          -- (ไม่บังคับ) เริ่มทำงาน ใช้ service อื่นได้แล้ว
--   return MyService

local servicesFolder = script.Parent:WaitForChild("Services")

local services: { [string]: any } = {}
for _, module in servicesFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok then
			services[module.Name] = result
		else
			warn(`[Server] โหลด {module.Name} ไม่สำเร็จ: {result}`)
		end
	end
end

for name, service in services do
	if type(service.Init) == "function" then
		local ok, err = pcall(service.Init, services)
		if not ok then
			warn(`[Server] {name}.Init พัง: {err}`)
		end
	end
end

for name, service in services do
	if type(service.Start) == "function" then
		task.spawn(function()
			local ok, err = pcall(service.Start)
			if not ok then
				warn(`[Server] {name}.Start พัง: {err}`)
			end
		end)
	end
end

print(`[Server] พร้อม: {#servicesFolder:GetChildren()} services`)
