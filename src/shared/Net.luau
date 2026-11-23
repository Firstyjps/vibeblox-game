--!strict
-- จุดเดียวสำหรับสร้าง/หา Remote ทั้งหมด
-- server เรียก → สร้างให้ถ้ายังไม่มี · client เรียก → รอจนกว่า server สร้าง
-- ไม่ต้องไปแก้ default.project.json ทุกครั้งที่เพิ่ม remote (ลด merge conflict)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local FOLDER_NAME = "Remotes"
local IS_SERVER = RunService:IsServer()

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	if IS_SERVER then
		local created = Instance.new("Folder")
		created.Name = FOLDER_NAME
		created.Parent = ReplicatedStorage
		return created
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function get(name: string, className: string): Instance
	local parent = folder()
	local existing = parent:FindFirstChild(name)
	if existing then
		assert(
			existing.ClassName == className,
			`Remote "{name}" เป็น {existing.ClassName} ไม่ใช่ {className}`
		)
		return existing
	end
	if IS_SERVER then
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = parent
		return remote
	end
	return parent:WaitForChild(name)
end

function Net.event(name: string): RemoteEvent
	return get(name, "RemoteEvent") :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return get(name, "RemoteFunction") :: RemoteFunction
end

-- ใช้กับเหตุการณ์ถี่ๆ ที่หายได้ (เช่น ตำแหน่ง/เอฟเฟกต์)
function Net.unreliable(name: string): UnreliableRemoteEvent
	return get(name, "UnreliableRemoteEvent") :: UnreliableRemoteEvent
end

return Net
