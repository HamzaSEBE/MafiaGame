# تشغيل الجلسات V2 والتحقق قبل النشر

## المكونات الفعلية

- `packages/game_core`: مصدر Dart واحد لقواعد اللعبة، prompts، النتائج، وreducer الخادم. ملفات `lib/domain` تعيد تصديره للحفاظ على imports الحالية.
- `services/game_engine`: محرك HTTP عديم الحالة، لا يحتفظ بجلسات أو بيانات حسابات. مدخلاته تأتي من API الموثوق. يجب نشره كـCloud Run خاص مع IAM.
- `services/game_api`: Node 24 / TypeScript / Firebase Admin 14؛ يتحقق من Firebase ID token وApp Check، ثم ينفذ معاملات Firestore والتنسيق مع المحرك.
- `sessionsV2`: checkpoint خاص بالحكم، roster بلا linkedUid، secrets لكل مقعد، حركات ثابتة، receipts، انتقالات دائمة، وoutbox للنتائج.
- الجلسات القديمة تبقى ضمن `sessions`. لا تُحوّل الجلسة المفتوحة إلى البروتوكول الجديد أثناء اللعب.

## التحقق المحلي

```bash
.local_tools/flutter/bin/flutter pub get
.local_tools/flutter/bin/flutter analyze --no-pub
.local_tools/flutter/bin/flutter test --no-pub --concurrency=1
npm ci --prefix services/game_api --ignore-scripts
python3 tool/verify_backend.py --jar /home/hamza/.cache/firebase/emulators/cloud-firestore-emulator-v1.22.0.jar
.local_tools/flutter/bin/flutter build web --release --no-pub
```

السكربت يحجز 8085 و8087 على loopback، ويرفض استخدام منفذ مشغول. يبدأ المحاكي والمحرك الفعلي، يشغل اختبارات القواعد وخدمة API، ويوقف عملياته فقط. لا يستخدم credentials إنتاج.
محاكي Firestore 1.22 يحتاج Java 21 أو أحدث؛ JDK 17 المحلي مخصص لبناء Android.
لـCI يُحمّل المحاكي من Firebase مع تحقق SHA-256 كما في workflow.

لتجربة واجهة V2 محلياً، شغّل أيضاً Auth emulator على 9099 وStorage emulator على 9199 باستخدام Firebase Emulator Suite، ثم:

```bash
cd services/game_engine
../../.local_tools/flutter/bin/dart run bin/server.dart
# في terminal آخر من جذر المشروع، بعد تشغيل المحاكيات:
GCLOUD_PROJECT=demo-mafia-review FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 GAME_ENGINE_URL=http://127.0.0.1:8087 ALLOWED_ORIGINS=http://localhost:7357 PORT=8086 npm start --prefix services/game_api
```

المحرك الافتراضي يستخدم 8080؛ اضبط `PORT=8087` عند التشغيل المحلي.
لبناء عميل اختبار V2 استخدم `flutter build apk --release` أو `flutter build web --release` مع تعريفات `ENABLE_SERVER_GAMES=true` و`USE_FIREBASE_EMULATORS=true` و`GAME_API_URL` و`JOIN_BASE_URL` بعناوين الاختبار المناسبة. جرّب APK على هاتف فعلي، وتأكد أن الهاتف يستطيع الوصول للخدمات المحلية. لا توجّه هذه التعريفات إلى مشروع الإنتاج.

الويب مخصص للاعب المنضم عبر رابط جلسة، وتطبيق Android للحكم. لا تبدأ متصفحاً أو محاكي Android أو خادماً إضافياً لمجرد البناء. القيود المحلية: 8GB RAM، اختبارات متسلسلة وخدمات مؤقتة تُوقف عند الانتهاء.

## نشر staging

1. اختَر مشروعاً منفصلاً ومنطقة مناسبة لقاعدة Firestore، مع سقف تكلفة وحصص اتصالات/طلبات كافية. لا تُنشئ قاعدة ذات موقع عشوائي؛ الموقع قرار بنية دائم.
2. أنشئ Artifact Registry وحساب خدمة API بصلاحية Firestore المطلوبة فقط، وحساباً منفصلاً للمحرك دون صلاحية Firestore. ابنِ الصور بـ`infra/cloudbuild.yaml` مع `_REGION` و`_REPOSITORY` محددين.
3. انشر المحرك **دون public invocation**. امنح حساب API `roles/run.invoker` على خدمة المحرك فقط. المكتبة ترسل OIDC identity token إلى المحرك الخاص.
4. انشر API مع `GAME_ENGINE_URL` و`ALLOWED_ORIGINS` المحددين، ومع Application Default Credentials من حساب خدمة التشغيل. لا تضع مفاتيح service-account في تطبيق Flutter أو صور Docker.
5. API العام يتحقق داخل الطلب من Firebase Auth وApp Check. لا تضبط متغيرات emulator في staging/production؛ هي تعطل App Check وتغير التحقق من Auth.
6. فعّل Play Integrity للتطبيق وreCAPTCHA v3 للويب. ابنِ العميل مع `GAME_API_URL`, `JOIN_BASE_URL`, `APP_CHECK_WEB_SITE_KEY`, و`ENABLE_SERVER_GAMES=true`. إذا غاب site key، يعرض الويب خطأ إعداد واضحاً.
7. انشر `firestore.rules` و`firestore.indexes.json` و`storage.rules` قبل العميل الجديد. انتظار بناء indexes مطلوب قبل فتح V2. الحفظ الافتراضي للصور يستخدم photoBase64 بحد 256KB للعمل على Spark. تشغيل AVATAR_STORAGE_ENABLED=true ينقل الصور الجديدة إلى Storage ويحتاج bucket وقواعد Storage وخطة تدعمها.
8. كبداية pilot، ضع حدود instances وتزامن محدودة يتناسبان مع الميزانية. زِدها وفق القياسات من اختبارات الضغط؛ لا تعتمد رقماً نظرياً كإثبات 100 ألف.
9. أنشئ Cloud Scheduler يستدعي `POST /internal/maintenance` كل دقيقة باستخدام OIDC من حساب scheduler محدد. اضبط `MAINTENANCE_AUDIENCE` على أصل API و`SCHEDULER_SERVICE_ACCOUNT` على email الحساب. endpoint يتحقق من token وemail؛ Firebase user token لا يكفي.
10. maintenance يسلّم outbox بمعاملة وmarker خاص بالخادم، ثم يحذف الغرف المنتهية مع الأطفال recursively. الغرفة التي تنتظر حفظ النتائج لا تُحذف. الانتقالات pending تُستأنف عند إعادة المحاولة أو استرجاع الحكم؛ takeover يعدّل epoch للانتقال ويمنع العامل القديم من commit.
11. اختبر التسجيل والانضمام والموافقة وتغيير النافذة وإعادة التصويت/فشل المحرك/تغيير الحكم/حفظ النتيجة قبل رفع traffic. افتح V2 لمجموعة صغيرة أولاً؛ flag يؤثر على الجلسات الجديدة، وروابط QR تحمل protocol.

## العقود والحدود

- أقصى غرفة V2: **120 مقعداً**؛ 3 مستندات/مقعد أثناء الإنشاء تبقى ضمن حد المعاملة. الهدف الشائع للاختبار 20 لاعباً وحكم.
- checkpoint <=700KB وHTTP <=900KB. تتوقف العملية برسالة خطأ عند تجاوز الحد؛ التخزين الكامل للأحداث قابل لاحقاً للتقسيم حسب الجولة.
- كل فعل يتضمن expectedRevision وexpectedActionVersion وcommandId. تعديل التصويت من tab قديمة يعود BALLOT_CONFLICT. تكرار commandId بنفس المحتوى يعيد النتيجة، ومحتوى مختلف يُرفض.
- gate يغلق قبل قراءة الحركات. root لا يُكتب مع كل تصويت؛ يكتب اللاعب مستنده وreceipt وحدّ المعدل الخاص به. التحقيق يكتب نتيجته السرية فقط. الإفصاح يحدّث النسخة والحالة الخاصة ووزن التصويت.
- حكم واحد عبر hostInstanceId وhostEpoch وlease لمدة دقيقتين، تجدد كل 45 ثانية. الاسترجاع السلبي في Home لا يستولي على الحكم؛ الضغط على متابعة الجلسة يسترجعه لهذا الجهاز ويوقف كتابات الجهاز السابق.
- الحالة المنشورة تستخرج من reducer؛ API لا يقبل checkpoint أو winner من العميل بعد الإنشاء. إعداد الأدوار الأولي يخص الحكم، ويُتحقق من الأسماء والأنواع والعدد، ثم تُخزّن حالة البداية.
- clock المستخدم في الانتقال محفوظ بالintent؛ المحرك يستخدمه لإنتاج أحداث ثابتة في إعادة المحاولة. مؤقت النقاش محفوظ كـdeadline/paused/remaining في checkpoint، ويستعيد الحكم الوقت المتبقي بعد إعادة الفتح. تعديله أمر خادم محمي بالنسخة والlease، ولا يكتب مستنداً كل ثانية. انتهاء العداد لا يقصي لاعباً تلقائياً.
- الثيم المشترك: four fixed packs/version 1. API يتحقق من صلاحية المضيف عند الإنشاء، والضيف يراه داخل الجلسة النشطة فقط. لا يحفظه لحساب الضيف ولا يمنحه Premium.
- نتائج V2 تأتي من outbox. العميل ينتظر السجل المخزّن؛ لا ينفذ increments ثانية. يمكن للعميل تعديل سجل حسابه الشخصي الحالي وفق قواعد legacy؛ marker V2 نفسه محمي من الكتابة.

## Entitlements والفوترة

`entitlements` حقل server-managed داخل profile:

```json
{"schemaVersion":1,"status":"active","features":["themes"],"expiresAt":"2027-01-01T00:00:00Z","source":"manual","revision":1}
```

العميل لا يستطيع كتابته. grants malformed/expired/revoked تمنع الثيم الحصري حتى لو بقي isPremium القديم true. العضوية القديمة تمنح themes فقط. الدعم اليدوي الموثوق:

```bash
GCLOUD_PROJECT=STAGING_PROJECT ENTITLEMENT_PROJECT_ACK=STAGING_PROJECT \
  node services/game_api/tools/entitlement.mjs USER_UID 2027-01-01T00:00:00Z
# استخدم revoke بدلاً من تاريخ الانتهاء للإلغاء.
```

لا توجد منتجات أو أسعار شراء محددة من صاحب التطبيق؛ لذلك لا يوجد زر شراء وهمي. دمج Play Billing/StoreKit والتحقق من receipts والإشعارات والاعتراف بالشراء يحتاج إعداد المنتجات وأسرار المتاجر قبل فتح الفوترة.

## التشغيل والقياس

- سجلات API: route/status/code/duration، دون ID tokens أو أسرار الأدوار. راقب 5xx، زمن الطلب، contention وTRANSITION_PENDING، outbox المتأخر، CPU/memory وعدد instances، والحصص والتكلفة.
- أداة الضغط: `tool/load/README.md`. اختبر 21→210→2100→10k→100k، وتوزيع 100 shards عند الهدف، reconnects وsoak. التقرير المحلي لا يثبت سعة الإنتاج.
- فعّل إنذارات تكلفة، وفشل 5xx>0.1%، p95>500ms، propagation>1s، وoutbox يتجاوز دقيقتين خلال الاختبار؛ قيم التشغيل النهائية تُراجع حسب baseline الفعلي.
- احفظ snapshots/نسخ Firestore الاحتياطية حسب سياسة المنتج، واختبر الاستعادة. إبقاء rules V1 فقط لفترة انتقال؛ إلغاؤها يحتاج انتظار انتهاء الغرف والحد الأدنى لإصدار العميل.
- لا يمكن توليد APK release موقّع دون `android/key.properties` وupload keystore حقيقي. build release العادي يرفض fallback لمفتاح debug. للتجربة على الهاتف فقط، tool/build_android_release.sh --existing-test-signature يستخدم مفتاح الاختبار الموجود إذا طابق بصمة APK السابق؛ يرفض مفتاحاً مفقوداً أو مختلفاً. لا يعيد نشر APK قديم كتحديث جديد.


## التطوير على جهاز RAM 8GB

- لا browser أو Android emulator أو dev server لأجل البناء. الاختبار على هاتف Android فعلي.
- Gradle: heap 1280MB، metaspace 768MB، ومعالجان للـJVM، عامل واحد، parallel=false، daemon=false، وKotlin داخل نفس العملية.
- التحقق متسلسل: flutter analyze ثم flutter test --concurrency=1 ثم بناء APK. لا تبدأ بناء Android والويب والاختبارات معاً.
- بناء هاتف ARM64: `tool/build_android_release.sh` مع توقيع الإنتاج، أو `tool/build_android_release.sh --existing-test-signature` لنسخة الاختبار المتوافقة مع APK الحالي.
- API/rules integration تشغّل خدمات loopback مؤقتة عند الحاجة فقط؛ Firestore heap محدود 384MB ويوقفها verify_backend.py في finally. هذه ليست Android emulators.
- لا ترفع keystore أو key.properties إلى GitHub. فحص توقيع APK والإصدار بـapksigner/aapt عبر CLI فقط.
