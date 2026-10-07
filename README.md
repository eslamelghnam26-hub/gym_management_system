# Gym Management System

تطبيق Flutter كامل لنظام إدارة الجيم: تطبيق موبايل للأعضاء + لوحة تحكم ويب في نفس المشروع ومتصلان بنفس بيانات Firebase Firestore (نفس الـ collections، بدون Backend منفصل). أي تغيير من اللوحة ينعكس فورًا على التطبيق والعكس.

## البنية

```
lib/
├── main.dart                 # تطبيق الموبايل (entrypoint رئيسي)
├── web_admin/
│   └── main.dart             # لوحة التحكم (entrypoint ويب)
│   └── admin_shell.dart      # القوائم + حماية الأدوار
│   └── pages/                # dashboard, members, plans, subscriptions,
│   │                         # attendance, payments, trainers, expenses,
│   │                         # reports, announcements, ai_knowledge,
│   │                         # notifications, users, settings
│   └── widgets/              # web_page, web_stat_card, charts (CustomPainter),
│                             # web_dialogs (WebFormDialog/WebTableShell/...)
├── models/                   # member, membership_plan, subscription, payment,
│                             # attendance_record, expense, announcement,
│                             # gym_settings, trainer, app_user, gym_notification
├── repositories/             # abstract + demo + firebase تنفيذ لكل مصدر
├── providers/                # Riverpod AsyncNotifier controllers
├── services/                 # bootstrap، firebase
└── core/                     # الثوابت، الثيم، التنسيقات، المكونات المشتركة
```

## التشغيل

```bash
# تطبيق الموبايل
flutter run

# لوحة تحكم الويب (وضع تجريبي أولاً)
flutter run -d chrome -t lib/web_admin/main.dart

# عند تجهيز Firebase:
flutter run -d chrome -t lib/web_admin/main.dart --dart-define=DATA_SOURCE=firebase

# بناء الويب للنشر
flutter build web --release -t lib/web_admin/main.dart
```

الموقع التجريبي يعمل فورًا دون Firebase. يظهر شارة **Demo** في الأعلى حتى تُملأ الإعدادات أدناه — كل البيانات تُحفظ محليًا.

### حسابات تجريبية (كلمة المرور للجميع: `password123`)
| البريد | الدور |
|---|---|
| `admin@gym.com` | مدير — كل الأقسام |
| `reception@gym.com` | استقبال — دفعات/اشتراكات/تقارير |
| `trainer@gym.com` | مدرب — أعضاء/حضور |
| `member@gym.com` | عضو — ممنوع من اللوحة |

## الربط بـ Firebase (خطوات النشر)

1. أنشئ مشروعًا على https://console.firebase.google.com واضغط **Web app**.
2. الصق إعدادات `firebaseConfig` في `lib/firebase_options.dart` (القالب موجود بعناصر فارغة).
3. انشر القواعد: `firebase deploy --only firestore:rules` (ملف `firestore.rules` جاهز بحماية الأدوار).
4. اربط Hosting بالمجلد `build/web` من خلال `firebase.json` المرفق:
   ```bash
   firebase login
   firebase use <project-id>
   flutter build web --release -t lib/web_admin/main.dart
   firebase deploy --only hosting
   ```
5. أنشئ مستخدم مدير أول من Firebase Auth، ثم أضف وثيقته في مجموعة `users` بدور `admin` — عندها تدخل اللوحة وتدير باقي الكوادر من **المستخدمون والصلاحيات**.

## الأقسام والمزايا

- **لوحة التحكم**: مؤشرات حية (إيراد، أعضاء، اشتراكات، حضور) + رسوم بيانية بدون مكتبات خارجية (CustomPainter).
- **العمليات**: أعضاء، باقات، اشتراكات (تجديد/إلغاء)، حضور، مدفوعات (استرداد/تعديل)، مصروفات.
- **التقارير**: يومي/أسبوعي/شهري/سنوي — إيراد مقابل مصروف وصافي ربح.
- **التواصل**: إعلانات، إشعارات (الكل أو عضو محدد).
- **الإدارة**: مستخدمون وصلاحيات (مع حماية آخر مدير)، إعدادات الجيم، قاعدة معرفة لمساعد AI (خدمات/قواعد/فوائد).