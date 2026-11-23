# AGENTS.md — กติกาสำหรับ AI (Claude / Antigravity / Gemini / Codex) และคนในทีม

> ไฟล์นี้คือ "สัญญา" ของโปรเจกต์ ทุก AI ต้องอ่านและทำตามก่อนแก้โค้ด
> `CLAUDE.md` และ `GEMINI.md` แค่ชี้มาที่ไฟล์นี้ — แก้กติกาที่นี่ที่เดียว

## โปรเจกต์
- เกม Roblox ของทีม Vibeblox · เขียนด้วย **Luau** · sync เข้า Studio ด้วย **Rojo 7**
- โค้ดอยู่ใน `src/` เท่านั้น — **ห้ามแก้ script ใน Studio ตรงๆ** (Rojo จะเขียนทับ)
- ตอบ/คอมเมนต์เป็นภาษาไทยได้ · ชื่อตัวแปร/ไฟล์เป็นอังกฤษ

## โครงสร้าง (Rojo map ไปที่ไหน)
| โฟลเดอร์ | ใน Roblox | ใช้ทำ |
|---|---|---|
| `src/server/Services/*.luau` | ServerScriptService.Server.Services | ระบบฝั่ง server — 1 ระบบ = 1 ไฟล์ |
| `src/client/Controllers/*.luau` | StarterPlayerScripts.Client.Controllers | UI/อินพุต/เอฟเฟกต์ฝั่งผู้เล่น — 1 ระบบ = 1 ไฟล์ |
| `src/shared/*.luau` | ReplicatedStorage.Shared | โค้ด/ค่าที่ใช้ทั้งสองฝั่ง (`Config`, `Net`) |
| `src/shared/Modules/` | ReplicatedStorage.Shared.Modules | helper ที่ใช้ร่วมกัน |
| `assets/models/*.rbxmx` | Workspace.Map | โมเดล/ฉากที่สร้างใน Studio แล้ว export มา |

`Main.server.luau` / `Main.client.luau` โหลดทุกไฟล์ใน Services / Controllers อัตโนมัติ — **ไม่ต้องแก้สองไฟล์นี้** เวลาเพิ่มระบบ

### รูปแบบ Service / Controller
```lua
local MyService = {}
local PlayerData

function MyService.Init(services)   -- ไม่บังคับ: เก็บ reference service อื่น ห้าม yield
	PlayerData = services.PlayerData
end

function MyService.Start()          -- ไม่บังคับ: เริ่มทำงาน
end

return MyService
```

## กติกาโค้ด (ต้องทำ)
1. **Server เป็นคนตัดสินทุกอย่าง** — client แค่ "ขอ" ผ่าน remote; server ต้องตรวจชนิดข้อมูล, ระยะ, เงินพอไหม, ความถี่ (rate limit) ทุกครั้ง อย่าเชื่อค่าจาก client
2. **Remote สร้างผ่าน `Net` เท่านั้น** — `Net.event("Name")`, `Net.func("Name")` ไม่ต้องแก้ `default.project.json`
3. **ข้อมูลผู้เล่นแก้ผ่าน `PlayerData.update(player, fn)` เท่านั้น** — เพิ่ม field ใหม่ที่ `DEFAULT` ใน `PlayerData.luau` (ข้อมูลเก่าจะได้ค่าเริ่มต้นเอง) ห้ามเปลี่ยนชนิดของ field เดิม
4. **ค่าสมดุลเกม (ราคา, อัตรา, cooldown) อยู่ใน `src/shared/Config.luau`** ไม่ hardcode ในระบบ
5. ส่งค่าให้ UI ผ่าน player Attribute (เพิ่มชื่อใน `REPLICATED_FIELDS`) แทนการยิง remote บ่อยๆ
6. ทุกอย่างที่เรียก Roblox web API (DataStore, MarketplaceService, HttpService) ต้องครอบ `pcall`
7. ใช้ `task.wait/spawn/delay` ไม่ใช้ `wait/spawn/delay` แบบเก่า · ขึ้นต้นไฟล์ใหม่ด้วย `--!strict` เมื่อทำได้
8. ของที่สร้างบ่อย (popup, effect) ให้ reuse หรือ `Destroy()` เสมอ — ห้ามรั่ว
9. UI ต้องใช้ได้บนมือถือ: ไม่วางปุ่มมุมซ้ายล่าง (จอยสติ๊ก) / ขวาล่าง (ปุ่มกระโดด), ใช้ `UIScale` ย่อตามจอ
10. ห้ามใส่ความลับ (API key, cookie) ในโค้ดหรือ commit

## ก่อนบอกว่า "เสร็จ" ต้องผ่าน
```bash
stylua src            # จัดรูปแบบ
selene src            # ต้อง 0 errors, 0 warnings
rojo build -o build.rbxlx   # ต้อง build ผ่าน (ไฟล์นี้ไม่ต้อง commit)
```
แล้วทดสอบจริงใน Studio (Play) อย่างน้อย 1 รอบ · ดู Output ต้องไม่มี error สีแดงจากโค้ดเรา

## Git / การทำงานเป็นทีม
- **ห้าม commit ตรงเข้า `main`** — แตก branch: `feat/<ชื่อ>-<เรื่อง>`, `fix/<ชื่อ>-<เรื่อง>` (เช่น `feat/first-sound`)
- 1 branch = 1 เรื่อง · commit message ภาษาอังกฤษสั้นๆ บอกว่าทำอะไร
- เปิด Pull Request → CI (lint + build) ต้องเขียว → ให้เพื่อนอย่างน้อย 1 คนดู → merge
- ก่อนเริ่มงาน `git pull` จาก main เสมอ · ถ้าจะแก้ไฟล์ส่วนกลาง (`Config`, `PlayerData`, `Net`, project.json) บอกในห้อง Discord ก่อน
- **Publish ขึ้น Roblox ทำโดยคนดูแลเท่านั้น** (ดู README) — AI ห้าม publish เอง

## สิ่งที่ AI ห้ามทำ
- ห้าม publish เกม, เปลี่ยนการตั้งค่าเกมใน Creator Hub, หรือซื้อ/ขายอะไรด้วย Robux
- ห้าม force push, ห้ามลบ branch ของคนอื่น, ห้าม rewrite history ของ main
- ห้ามลบ/ปิด rate limit หรือการตรวจฝั่ง server เพื่อ "ให้เทสผ่าน"
- ห้ามเปลี่ยน `Config.DATASTORE_NAME` ถ้าไม่ได้ตั้งใจล้างข้อมูลผู้เล่นทุกคน
