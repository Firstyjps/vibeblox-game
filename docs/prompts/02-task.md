# 🎮 ทำงาน / เพิ่มฟีเจอร์ (ใช้ทุกครั้งที่จะทำงาน)

## ก่อนเริ่ม
1. เลือกงานจากแท็บ **Issues** ใน https://github.com/kron-studio/vibeblox-game/issues แล้วกด assign ให้ตัวเอง (จะได้ไม่ทำซ้ำกับเพื่อน)
2. เปิด **Claude Code** (หรือ Antigravity) **ในโฟลเดอร์ `vibeblox-game`**
3. copy ข้อความในกรอบด้านล่าง → **แก้บรรทัดแรกเป็นงานที่จะทำ** → วางให้ AI

---

```text
งานที่จะทำ: <เขียนตรงนี้ เช่น "เพิ่มระบบ Daily Reward ได้เหรียญทุกวัน ยิ่งเข้าติดกันยิ่งได้เยอะ">

ทำตามกติกาใน AGENTS.md ทุกข้อ และทำตามลำดับนี้:
1. git checkout main && git pull แล้วแตก branch ใหม่ชื่อ feat/<ชื่อ GitHub ฉัน>-<เรื่องสั้นๆ>
2. อ่านโค้ดที่เกี่ยวข้องก่อน แล้วบอกแผนสั้นๆ ว่าจะสร้างหรือแก้ไฟล์ไหน ถ้าต้องแตะไฟล์ส่วนกลาง (Config, PlayerData, Net, default.project.json) ให้บอกฉันก่อนลงมือ
3. เขียนโค้ด: ระบบฝั่ง server เป็น Service ใหม่, UI เป็น Controller ใหม่, ตัวเลขทั้งหมดอยู่ใน Config, และ server ต้องตรวจทุกอย่าง
4. รัน stylua src && selene src && rojo build -o build.rbxlx ให้ผ่าน (0 errors, 0 warnings) แล้วลบ build.rbxlx
5. บอกวิธีทดสอบใน Studio ให้ฉัน: รัน rojo serve, ใน Studio กด Plugins → Rojo → Connect, กด Play แล้วลองอะไรบ้าง จากนั้นรอฉันยืนยันว่าเล่นได้จริง
6. เมื่อฉันบอกว่าโอเค: commit (ข้อความภาษาอังกฤษสั้นๆ), push branch แล้วเปิด Pull Request ด้วย gh pr create โดยกรอกตาม template
7. ส่งลิงก์ PR ให้ฉัน และดูว่า CI ผ่านไหม ถ้าไม่ผ่านให้แก้แล้ว push ใหม่

ห้าม push เข้า main, ห้าม merge PR เอง และห้าม publish เกม
```

---

## หลังเปิด PR
1. ส่งลิงก์ PR ในห้อง Discord ให้เพื่อนช่วยดู
2. รอ CI ขึ้น ✅ เขียว (ถ้าแดง ให้ AI แก้)
3. เพื่อนดูแล้วโอเค → กด **Merge pull request** บน GitHub
4. คนดูแลจะเป็นคน publish ขึ้น Roblox

## กฎสั้นๆ
- ❌ push เข้า `main` ตรงๆ ไม่ได้ (GitHub จะปฏิเสธ) — ต้องผ่าน PR เสมอ
- ❌ ห้าม publish เกมเอง
- ✅ 1 branch = 1 งาน · เริ่มงานใหม่ต้อง `git pull` จาก main ก่อนเสมอ
- ✅ จะแก้ไฟล์ส่วนกลาง บอกในห้องก่อน
