# vibeblox-game

เกม Roblox ของทีม **Vibeblox** — เขียนโค้ดเป็นไฟล์ (Luau + Rojo) ใช้ git ทำงานร่วมกัน และใช้ AI (Claude / Antigravity) ช่วยเขียน

> 🤖 **ใช้ AI ช่วย?** AI ทุกตัวจะอ่าน [`AGENTS.md`](AGENTS.md) อัตโนมัติ — ในนั้นมีกติกาโค้ดและโครงสร้างโปรเจกต์ทั้งหมด
>
> ⚡ **ทางลัด:** copy prompt ไปวางใน Claude / Antigravity ได้เลย
> - ติดตั้งครั้งแรก → [`docs/prompts/01-setup.md`](docs/prompts/01-setup.md)
> - ทำงานแต่ละครั้ง → [`docs/prompts/02-task.md`](docs/prompts/02-task.md)

---

## 1. ติดตั้งครั้งแรก (ทำครั้งเดียว)

### ทุกคน
1. **Roblox Studio** — โหลดจาก https://create.roblox.com แล้วล็อกอิน
2. **Git** — Mac: มีอยู่แล้ว (พิมพ์ `git --version` ถ้าไม่มีจะให้ติดตั้งเอง) · Windows: https://git-scm.com
3. **GitHub** — สมัครบัญชี แล้วส่งชื่อผู้ใช้ให้คนดูแลเพื่อเชิญเป็น collaborator
4. **VS Code** (หรือ Cursor / Antigravity) — เปิดโปรเจกต์แล้วกด *Install* ตามที่มันแนะนำ extension (Rojo, Luau LSP, StyLua, Selene)

### ติดตั้งเครื่องมือของทีมด้วย Rokit (ได้เวอร์ชันตรงกันทุกคน)
**Mac / Linux** — เปิด Terminal:
```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```
**Windows** — เปิด PowerShell:
```powershell
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```
ปิดแล้วเปิด Terminal ใหม่ จากนั้น:
```bash
git clone https://github.com/kron-studio/vibeblox-game.git
cd vibeblox-game
rokit install          # ลง rojo, selene, stylua ตามเวอร์ชันใน rokit.toml
rojo plugin install    # ลงปลั๊กอิน Rojo เข้า Roblox Studio
```

---

## 2. ทำงานทุกวัน

```bash
git checkout main && git pull          # เอาโค้ดล่าสุด
git checkout -b feat/<ชื่อคุณ>-<เรื่อง>   # แตก branch ของงานนี้ เช่น feat/first-sound
rojo serve                             # เปิดค้างไว้ระหว่างทำงาน
```
1. เปิด Roblox Studio → สร้าง **Baseplate** ใหม่ (place ส่วนตัวสำหรับทดสอบ)
2. แท็บ **Plugins → Rojo → Connect** → โค้ดใน `src/` จะเข้า Studio และอัปเดตทันทีที่เซฟไฟล์
3. แก้โค้ด (เองหรือให้ AI ช่วย) → กด **Play** ทดสอบ
4. เช็กก่อนส่งงาน:
   ```bash
   stylua src && selene src && rojo build -o build.rbxlx
   ```
5. ส่งงาน:
   ```bash
   git add -A && git commit -m "Add first sound effects"
   git push -u origin HEAD
   ```
   แล้วเปิด **Pull Request** บน GitHub → รอ CI เขียว ✅ → ให้เพื่อนดู → merge

---

## 3. วิธีเล่น / ทดสอบเกม

เกมคือ **Mystic Creature Simulator** — รายละเอียดทั้งหมดอยู่ใน [`docs/GDD.md`](docs/GDD.md) · ตัวเลขทั้งหมดปรับได้ใน `src/shared/Config.luau`

| ทำอะไร | ยังไง |
|---|---|
| เลือกเผ่า | ขึ้นเองตอนเข้าเกมครั้งแรก (เลือกได้ครั้งเดียว) |
| ตีมอน | ปุ่ม ⚔️ ล่างกลางจอ · PC คลิกซ้าย หรือกด **F** ค้างไว้ |
| ไปด่านถัดไป | ฆ่ามอนให้ครบ (ดูกล่องขวาบน) แล้วเดินไปประตูสีส้ม กด **E** |
| สุ่มสัตว์ | เมนูขวา 🥚 **Summon** หรือเดินไปที่ไข่ใกล้จุดเกิด (ใช้ Coins) |
| จัดทีม / ปล่อยสัตว์ | เมนูขวา 🎒 **กระเป๋า** (ใส่ทีมได้ 3 ตัว) |
| อัปค่าพลัง | เมนูขวา ⭐ **Skills** (เลเวลอัปได้ 3 points · สกิลเผ่าปลดที่ Lv.10) |
| Rebirth | เมนูขวา 🔁 **Rebirth** (ต้องล้มบอสด่าน 5 + มี Coins ถึงเกณฑ์) |

**ปุ่ม Dev** (🛠 Dev: เผ่า) — เปลี่ยนเผ่าได้อิสระไว้ทดสอบ · ใน Studio ทุกคนเห็นปุ่มนี้ · ในเกมจริงต้องใส่ UserId ใน `Config.DEV_USER_IDS`

**เช็กลิสต์ก่อนส่ง PR:** เลือกเผ่า → ตีมอน (Coins/XP ขึ้น) → สุ่มไข่ + ใส่ทีม (สัตว์เดินตาม/ช่วยตี) → อัป Skill → ลองเปลี่ยนเผ่าด้วยปุ่ม Dev → Output ไม่มี error แดง

> ใน place ที่ยังไม่ publish ข้อมูลจะไม่เซฟ (ปกติ) — ออกแล้วเข้าใหม่จะเริ่มจากศูนย์

---

## 4. เพิ่มระบบใหม่

| อยากทำ | สร้างไฟล์ที่ |
|---|---|
| ระบบฝั่ง server (เงิน, ไข่, ร้านค้า) | `src/server/Services/MyThing.luau` |
| UI / อินพุต / เอฟเฟกต์ | `src/client/Controllers/MyThingController.luau` |
| ค่าตัวเลข / ราคา | เพิ่มหมวดใน `src/shared/Config.luau` |
| โมเดล / ฉากที่สร้างใน Studio | คลิกขวาโมเดล → **Save to File** เป็น `.rbxmx` → วางใน `assets/models/` |

ดูตัวอย่างได้จากระบบที่มีอยู่ เช่น `SkillService.luau` + `SkillController.luau` (service ฝั่ง server + หน้า UI ฝั่ง client)

### บอก AI ยังไงให้ได้งานดี
> "เพิ่มระบบ Daily Reward ตามกติกาใน AGENTS.md — server เป็น Service ใหม่, UI เป็น Controller ใหม่, ตัวเลขอยู่ใน Config, รัน stylua/selene/rojo build ให้ผ่าน"

---

## 5. Publish ขึ้น Roblox (คนดูแลเท่านั้น)
1. `git checkout main && git pull` → `rojo build -o vibeblox-game.rbxlx`
2. เปิดไฟล์ใน Studio (หรือใช้ `rojo serve` + Connect เข้า place ของเกมจริง)
3. **File → Publish to Roblox**
4. บอกในห้อง Discord ว่า publish commit ไหน

---

## 6. ปัญหาที่เจอบ่อย
- **Rojo Connect ไม่ได้** → ลืมรัน `rojo serve` หรือรันผิดโฟลเดอร์
- **`[PlayerData] ใช้ DataStore ไม่ได้`** → ปกติใน place ที่ยังไม่ publish (เล่นได้แต่ไม่เซฟ) — ถ้าอยากเทสเซฟ ต้อง publish place + เปิด *Game Settings → Security → Enable Studio Access to API Services*
- **CI แดงเพราะ stylua** → รัน `stylua src` แล้ว commit ใหม่
- **ทะเลาะกันที่ไฟล์เดียวกัน (merge conflict)** → `git pull origin main` ใน branch ตัวเอง แก้จุดที่ชน แล้ว commit
