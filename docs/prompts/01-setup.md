# 🛠️ ติดตั้งโปรเจกต์ vibeblox-game (ทำครั้งเดียว)

## ก่อนเริ่ม
1. **กดรับคำเชิญ GitHub** ในอีเมล หรือเข้า https://github.com/Firstyjps/vibeblox-game/invitations
2. เปิด **Claude Code** (หรือ Antigravity) ในโฟลเดอร์ที่อยากเก็บงาน เช่น Desktop
3. copy ข้อความในกรอบด้านล่างทั้งหมดไปวางให้ AI แล้วทำตามที่มันบอก

---

```text
ช่วยติดตั้งโปรเจกต์เกม Roblox ของทีมให้ฉันครบทุกขั้น ทำทีละขั้นและรายงานผลสั้นๆ ภาษาไทย

1. ดูว่าเครื่องเป็น Mac หรือ Windows แล้วเช็กว่ามี git, gh (GitHub CLI) และ Roblox Studio หรือยัง
   - ถ้าไม่มี git หรือ gh ให้ติดตั้ง (Mac ใช้ brew ส่วน Windows ใช้ winget)
   - ถ้าไม่มี Roblox Studio ให้บอกฉันไปโหลดเองที่ https://create.roblox.com แล้วรอฉัน
2. เช็กว่าล็อกอิน GitHub แล้วหรือยัง (gh auth status) ถ้ายัง ให้รัน gh auth login แล้วบอกฉันว่าต้องกดอะไร
3. clone repo https://github.com/Firstyjps/vibeblox-game.git แล้ว cd เข้าไป
4. ติดตั้ง Rokit
   - Mac: curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
   - Windows (PowerShell): irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
   ถ้าติดตั้งแล้วยังหาคำสั่ง rokit ไม่เจอ ให้บอกฉันปิดแล้วเปิด terminal ใหม่
5. ในโฟลเดอร์ repo รัน: rokit install แล้ว rojo plugin install
6. ถ้ามี VS Code ให้ลง extension: evaera.vscode-rojo, JohnnyMorganz.luau-lsp, JohnnyMorganz.stylua, Kampfkarren.selene-vscode
7. ทดสอบว่าพร้อม: stylua --check src && selene src && rojo build -o build.rbxlx ต้องผ่านทั้งหมด แล้วลบ build.rbxlx ทิ้ง
8. อ่าน AGENTS.md กับ README.md แล้วสรุปให้ฉันฟังสั้นๆ ว่าโปรเจกต์นี้ทำงานยังไง และฉันต้องทำอะไรต่อ

ห้าม push อะไรขึ้น GitHub ในขั้นนี้
```

---

## เสร็จแล้วทำอะไรต่อ
- เปิด Roblox Studio → สร้าง **Baseplate** ใหม่ → ในโฟลเดอร์ repo รัน `rojo serve` → ใน Studio กด **Plugins → Rojo → Connect** → กด **Play**
- ถ้าเห็นปุ่ม **"Click! (Coins: 0)"** ที่ด้านล่างจอ แปลว่าทุกอย่างพร้อม ✅
- จะเริ่มทำงาน → ใช้ไฟล์ `02-task.md`
