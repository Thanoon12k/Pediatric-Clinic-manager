# حساب السكرتير وطابور طبيب واحد — عيادتي

## الوظيفة المقصودة
- السكرتير يسجّل الدخول بالبريد الإلكتروني وكلمة المرور (Supabase Auth).
- يعمل مع **طبيب واحد فقط**، محدد من مسؤول قاعدة البيانات في `secretary_assignments`. لا توجد قائمة أطباء يمكن تغييرها من التطبيق.
- يضيف اسم المريض **لطابور اليوم**، ويعدّل ترتيب المنتظرين، ويحوّل الحالة إلى: انتظار / داخل عند الطبيب / مكتمل / ملغي.
- الطبيب نفسه يفتح "طابور المرضى" من لوحة الطبيب، ويرى نفس الأسماء والحالات.
- إضافة اسم لا تنشئ سجل مريض طبي ولا موعداً محجوزاً، ولا تسمح للسكرتير بقراءة المرضى أو الفحوصات أو الوصفات أو الرسائل.
- تعتمد تواريخ الطابور على توقيت العراق `Asia/Baghdad`؛ تأكد من ضبط وقت أجهزة الاستقبال.
- أرقام الدور محفوظة لكل طبيب ولكل يوم. ترتيب الدور يتغير دون تغيير الرقم الأصلي، لذلك قد لا يطابق ترتيب المناداة التسلسل الرقمي بعد تقديم مريض.

## قبل أي تغييرات على Supabase
1. خذ نسخة احتياطية من قاعدة البيانات، واختبر الخطوات أولاً على مشروع Staging وبيانات وهمية.
2. تأكد من تطبيق `supabase/migrations/001_initial_schema.sql` (أو وجود الجداول المقابلة في مشروعك) ثم **002** وتحقق من نجاحه.
3. نفّذ `supabase/migrations/003_secretary_and_clinic_queue.sql` باستخدام Supabase Dashboard → SQL Editor؛ لا تنفّذ أي SQL من التطبيق أو تنشر `service_role` في Flutter.
4. يفعل 003 أيضاً RLS في جدول `failed_operations` الذي كان غير محمي في المخطط الأصلي. اختبر أي تكامل قد يستخدمه قبل الترحيل.
5. لا تنشر في الإنتاج قبل اختبار الأدوار والهجمات العابرة للعيادات عملياً.

## إنشاء حساب السكرتير
1. Supabase Dashboard → Authentication → Users → Add user → Create new user.
2. أنشئ بريداً جديداً وكلمة مرور قوية للسكرتير واحتفظ بهما بأمان. لا ترسل كلمة السر في محادثة.
3. انسخ User UID لهذا الحساب من Authentication → Users.
4. افتح SQL Editor وتحقق من الأطباء:

```sql
select id, full_name, user_id, is_active
from public.doctors
order by full_name;
```

5. حدّد **Doctor UUID** الصحيح الخاص بالطبيب المطلوب. انتبه: هذا هو `doctors.id` وليس `doctors.user_id`.
6. تحقق من ملف السكرتير (ينبغي أن يكون `role='patient'` أولاً):

```sql
select id, full_name, role
from public.profiles
where id = '<SECRETARY_AUTH_USER_UID>';
```

7. في SQL Editor وبصلاحية المسؤول، نفّذ (بعد استبدال المعرفين):

```sql
begin;

update public.profiles
set role = 'secretary'
where id = '<SECRETARY_AUTH_USER_UID>'
  and role = 'patient';

insert into public.secretary_assignments (user_id, doctor_id, is_active)
values ('<SECRETARY_AUTH_USER_UID>', '<DOCTORS_TABLE_ID>', true)
on conflict (user_id)
do update set doctor_id = excluded.doctor_id,
              is_active = true;

commit;
```

8. تحقّق من الربط:

```sql
select p.full_name as secretary_name, p.role,
       d.full_name as doctor_name, a.is_active
from public.secretary_assignments a
join public.profiles p on p.id = a.user_id
join public.doctors d on d.id = a.doctor_id
where a.user_id = '<SECRETARY_AUTH_USER_UID>';
```

9. ثبّت APK الجديد (v1.2.0 أو أحدث) بعد نجاح بناء GitHub Actions، وسجّل دخول السكرتير بالبريد وكلمة المرور الجديدة. سيفتح طابور الطبيب المعين فقط.
10. افتح التطبيق بحساب الطبيب للتأكد من ظهور نفس الطابور في اختصار "طابور المرضى".

**إذا احتجت نقل السكرتير إلى طبيب آخر:** غيّر `secretary_assignments.doctor_id` فقط من SQL Editor بعد موافقة الإدارة. لا يوجد وصول متزامن لطبيبين.

## اختبارات الصلاحيات الضرورية قبل الإنتاج
| الفحص | النتيجة المطلوبة |
|---|---|
| سكرتير A يفتح طابور الطبيب A | مسموح |
| سكرتير A يضيف اسماً للطبيب B بتغيير طلب API | مرفوض |
| سكرتير A يعيد ترتيب أو يعدّل حالة مريض بطابور B | مرفوض |
| سكرتير A يطلب بيانات `patients` أو `examinations` أو `prescriptions` | لا بيانات |
| سكرتير A يحاول تحديث `profiles.role` بنفسه | مرفوض |
| سكرتير A يحاول `INSERT/UPDATE/DELETE` مباشرة على `clinic_queue` | مرفوض |
| سكرتير غير معين أو ملغي `is_active=false` | مرفوض |
| طبيب A يحاول قراءة طابور B | مرفوض |
| طبيب A وسكرتيره يعدّلان الطابور سوية | تعديل ذري، لا تتكرر أرقام الدور |
| مستخدم مجهول يحاول استدعاء RPC | مرفوض |

### ملاحظات أمنية
- سياسات RLS في مشروعك الحي تحتاج اختباراً، خصوصاً إذا كان `002` لم يُطبّق سابقاً. لا تفترض أن ظهور قفل الواجهة يعني منع الوصول في API.
- الصلاحيات تتحدد بالتحقق من `auth.uid()` ودور `profiles` وربط السكرتير الفعّال. تغيير دور المستخدم مباشرة من بيانات signup غير مسموح.
- واجهة السكرتير تتعامل مع **أسماء المرضى فقط**، وهي بحد ذاتها بيانات شخصية؛ استخدم حسابات فردية ولا تشارك كلمات المرور.
