# 🚀 Muscia Backend Server (Render Deployment Guide)

سيرفر وسيط خفيف وعالي السرعة مبني بـ Node.js & Express لتوزيع وفك تشفير مسارات الصوت لجميع أغاني وفناني العالم، وتوفير كلمات الأغاني المتزامنة لتطبيق Muscia.

---

## 🌟 مميزات السيرفر:
1. **حل مسارات الصوت (Audio Stream Resolver)**:
   - `/api/stream?title=Wegz&artist=ElShaiYaBaba`
   - دمج مباشر مع شبكات Akamai CDN و Piped Streaming.
2. **الكلمات المتزامنة (Synced Lyrics)**:
   - `/api/lyrics?title=Song&artist=Artist`
   - متوافق مع نظام كاريوكي وعرض الكلمات في المشغل.
3. **تخزين مؤقت فائق السرعة (Memory Cache)**:
   - أي أغنية يتم البحث عنها لأول مرة يتم تخزين رابط الصوت لتقديم استجابة خلال 1ms لجميع المستخدمين.

---

## 🚀 خطوات الرفع على Render (مجاناً 100%):

1. **ارفع كود المشروع إلى GitHub**:
   ```bash
   git add .
   git commit -m "Add Muscia app and Render backend"
   git push origin main
   ```

2. **افتح موقع Render**:
   - اذهب إلى: [https://dashboard.render.com](https://dashboard.render.com)
   - اضغط على زر **New +** ثم اختر **Web Service**.
   - اختر مستودع **GitHub** الخاص بمشروعك (`muscia-app`).

3. **إعدادات الخدمة على Render**:
   - **Name**: `muscia-backend`
   - **Root Directory**: `server`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node index.js`
   - **Instance Type**: `Free`

4. **اضغط Create Web Service**:
   - خلال دقيقة واحدة سيعطيك Render رابطاً حياً مثل:
     `https://muscia-backend.onrender.com`
   - السيرفر سيعمل 24/7 ويخدم التطبيق مباشرة في أي مكان بالعالم!
