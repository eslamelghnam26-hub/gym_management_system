import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/locale_provider.dart';

const List<Locale> appSupportedLocales = [Locale('ar'), Locale('en')];

/// Hand-rolled, typed localization. German simplicity over codegen:
/// every label is a getter so refactors keep compile-time safety, and each
/// string has a bilingual (ar/en) pair. Arabic is the default + RTL.
class AppStrings {
  AppStrings({required bool arabic}) : _ar = arabic;

  final bool _ar;

  String _t(String ar, String en) => _ar ? ar : en;

  // ---- Brand ----------------------------------------------------------
  String get appName => _t('جيم برو', 'Gym Pro');
  String get appSubtitle => _t('نظام إدارة الجيم', 'Gym Management System');
  String get demoMode => _t('وضع العرض التجريبي', 'Demo mode');
  String get localNote =>
      _t('التطبيق يعمل حالياً ببيانات محلية بدون Firebase. اربطه بمشروع Firebase من خلال `--dart-define=DATA_SOURCE=firebase`.',
          'Running on local data (no Firebase). To use a real project run with `--dart-define=DATA_SOURCE=firebase`.');

  // ---- Auth -----------------------------------------------------------
  String get login => _t('تسجيل الدخول', 'Sign in');
  String get loginSubtitle =>
      _t('ادخل بيانات حسابك للمتابعة', 'Enter your credentials to continue');
  String get email => _t('البريد الإلكتروني', 'Email');
  String get password => _t('كلمة المرور', 'Password');
  String get confirmPassword => _t('تأكيد كلمة المرور', 'Confirm password');
  String get fullName => _t('الاسم الكامل', 'Full name');
  String get phone => _t('رقم الهاتف', 'Phone');
  String get forgotPassword => _t('نسيت كلمة المرور؟', 'Forgot password?');
  String get createAccount => _t('إنشاء حساب جديد', 'Create account');
  String get doNotHaveAccount =>
      _t('ليس لديك حساب؟', "Don't have an account?");
  String get alreadyHaveAccount => _t('لديك حساب؟', 'Already have an account?');
  String get signUp => _t('إنشاء حساب', 'Sign up');
  String get resetPassword => _t('إعادة تعيين كلمة المرور', 'Reset password');
  String get resetHint => _t(
      'أدخل بريدك وسنرسل لك رابط إعادة التعيين',
      'Enter your email and we will send you a reset link');
  String get resetSent => _t(
      'تم إرسال خطوات إعادة التعيين إلى بريدك',
      'Password reset steps sent to your email');
  String get demoAccounts => _t('حسابات تجريبية (ديمو)', 'Demo accounts');
  String get demoHint => _t(
      'اضغط على أي حساب للتعبئة السريعة',
      'Tap an account to autofill');
  String get roleAdmin => _t('مدير', 'Admin');
  String get roleReceptionist => _t('استقبال', 'Receptionist');
  String get roleTrainer => _t('مدرب', 'Trainer');
  String get roleMember => _t('عضو', 'Member');

  // ---- Common ---------------------------------------------------------
  String get dashboard => _t('الرئيسية', 'Dashboard');
  String get profile => _t('حسابي', 'Profile');
  String get settings => _t('الإعدادات', 'Settings');
  String get language => _t('اللغة', 'Language');
  String get theme => _t('المظهر', 'Theme');
  String get light => _t('فاتح', 'Light');
  String get dark => _t('داكن', 'Dark');
  String get system => _t('حسب النظام', 'System');
  String get logout => _t('تسجيل الخروج', 'Log out');
  String get logoutConfirm =>
      _t('هل تريد تسجيل الخروج؟', 'Are you sure you want to log out?');
  String get cancel => _t('إلغاء', 'Cancel');
  String get confirm => _t('تأكيد', 'Confirm');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get save => _t('حفظ', 'Save');
  String get refresh => _t('تحديث', 'Refresh');
  String get welcome => _t('أهلاً بيك', 'Welcome');
  String get welcomeBack => _t('أهلاً بيك في', 'Welcome back to');
  String get loading => _t('جارٍ التحميل…', 'Loading…');
  String get overview => _t('نظرة عامة', 'Overview');
  String get nothingHere => _t('لا توجد بيانات بعد', 'Nothing here yet');
  String get featureComingSoon => _t(
      'هذه الميزة ستبقى متاحة في المراحل القادمة من التطوير',
      'This feature is coming in the next development phases');

  // ---- Admin dashboard ------------------------------------------------
  String get totalMembers => _t('إجمالي الأعضاء', 'Total members');
  String get activeMembers => _t('الأعضاء النشطون', 'Active members');
  String get expiredSubscriptions =>
      _t('الاشتراكات المنتهية', 'Expired subscriptions');
  String get expiringSoonSubscriptions =>
      _t('تنتهي قريباً', 'Expiring soon');
  String get todayAttendance => _t('حضور اليوم', "Today's attendance");
  String get totalRevenue => _t('إجمالي الإيرادات', 'Total revenue');
  String get totalExpenses => _t('إجمالي المصروفات', 'Total expenses');
  String get netProfit => _t('صافي الأرباح', 'Net profit');
  String get recentSection => _t('آخر التحديثات', 'Recent activity');

  // ---- Member dashboard -----------------------------------------------
  String get membershipStatus => _t('حالة الاشتراك', 'Membership status');
  String get currentPlan => _t('الباقة الحالية', 'Current plan');
  String get remainingDays => _t('الأيام المتبقية', 'Remaining days');
  String get paymentStatus => _t('حالة الدفع', 'Payment status');
  String get attendanceSummary => _t('ملخص الحضور', 'Attendance summary');
  String get myMembership => _t('اشتراكي', 'My membership');
  String get myPayments => _t('مدفوعاتي', 'My payments');
  String get myAttendance => _t('حضوري', 'My attendance');
  String get myTrainer => _t('المدرب الخاص بي', 'My trainer');
  String get gymInfo => _t('معلومات الجيم', 'Gym info');
  String get notifications => _t('الإشعارات', 'Notifications');
  String get aiAssistant => _t('مساعد الجيم الذكي', 'Gym AI assistant');
  String get quickAccess => _t('وصول سريع', 'Quick access');
  String get statusActive => _t('نشط', 'Active');
  String get statusExpired => _t('منتهي', 'Expired');
  String get statusPending => _t('معلق', 'Pending');
  String get statusCancelled => _t('ملغي', 'Cancelled');

  // ---- Management modules (Phase 2) -----------------------------------
  String get titleMembers => _t('الأعضاء', 'Members');
  String get titleTrainers => _t('المدربون', 'Trainers');
  String get titlePlans => _t('الباقات', 'Plans');
  String get add => _t('إضافة', 'Add');
  String get edit => _t('تعديل', 'Edit');
  String get delete => _t('حذف', 'Delete');
  String get search => _t('بحث', 'Search');
  String get searchHint =>
      _t('ابحث بالاسم أو الهاتف…', 'Search by name or phone…');
  String get filters => _t('تصفية', 'Filters');
  String get all => _t('الكل', 'All');
  String get status => _t('الحالة', 'Status');
  String get info => _t('المعلومات', 'Details');
  String get actions => _t('إجراءات', 'Actions');
  String get deleteConfirmTitle =>
      _t('حذف العنصر؟', 'Delete this item?');
  String get deleteConfirmBody =>
      _t('لا يمكن التراجع عن هذا الإجراء.', 'This action cannot be undone.');
  String get savedSuccess => _t('تم الحفظ بنجاح', 'Saved successfully');
  String get saveError => _t('تعذر حفظ البيانات', 'Failed to save data');
  String get fetchFailed => _t('تعذر تحميل البيانات', 'Failed to load data');

  String get dateOfBirth => _t('تاريخ الميلاد', 'Date of birth');
  String get gender => _t('الجنس', 'Gender');
  String get male => _t('ذكر', 'Male');
  String get female => _t('أنثى', 'Female');
  String get address => _t('العنوان', 'Address');
  String get emergencyContact =>
      _t('جهة الاتصال الطارئة', 'Emergency contact');
  String get notes => _t('ملاحظات', 'Notes');
  String get assignedTrainer => _t('المدرب', 'Trainer');
  String get plan => _t('الباقة', 'Plan');
  String get startDate => _t('تاريخ البدء', 'Start date');
  String get endDate => _t('تاريخ الانتهاء', 'End date');
  String get selectPlan => _t('اختر الباقة', 'Select a plan');
  String get selectTrainer => _t('اختر المدرب', 'Select a trainer');
  String get selectGender => _t('اختر الجنس', 'Select gender');
  String get days => _t('يوم', 'days');
  String get emptyMembers =>
      _t('لا يوجد أعضاء بعد', 'No members yet');
  String get emptyTrainers =>
      _t('لا يوجد مدربون بعد', 'No trainers yet');
  String get emptyPlans => _t('لا توجد باقات بعد', 'No plans yet');
  String get emptyFiltered =>
      _t('لا توجد نتائج مطابقة', 'No matching results');

  String get specialization => _t('التخصص', 'Specialization');
  String get salary => _t('الراتب', 'Salary');
  String get schedule => _t('الجدول', 'Schedule');
  String get assignedMembers =>
      _t('الأعضاء المشرف عليهم', 'Trained members');

  String get planName => _t('اسم الباقة', 'Plan name');
  String get duration => _t('المدة', 'Duration');
  String get price => _t('السعر', 'Price');
  String get sessions => _t('الجلسات', 'Sessions');
  String get sessionsUnlimited => _t('غير محدود', 'Unlimited');
  String get features => _t('المزايا', 'Features');
  String get addFeature => _t('إضافة ميزة…', 'Add a feature…');
  String get activeToggle => _t('الباقة مفعّلة', 'Plan is active');

  // ---- Subscriptions (Phase 3) ---------------------------------------
  String get titleSubscriptions => _t('الاشتراكات', 'Subscriptions');
  String get newSubscription => _t('اشتراك جديد', 'New subscription');
  String get renewal => _t('تجديد', 'Renew');
  String get subscribe => _t('اشترك الآن', 'Subscribe now');
  String get subActive => _t('نشط', 'Active');
  String get subExpired => _t('منتهي', 'Expired');
  String get subCancelled => _t('ملغي', 'Cancelled');
  String get noSubscriptions => _t('لا توجد اشتراكات بعد', 'No subscriptions yet');
  String get noSubscriptionsForYou => _t(
      'لا يوجد اشتراك لك بعد — تفضل بالاستقبال أو جدّد من هنا',
      'You have no active subscription — visit reception or renew here');
  String get chooseMember => _t('اختر العضو', 'Select a member');
  String get choosePlan => _t('اختر الباقة', 'Select a plan');
  String get amount => _t('المبلغ', 'Amount');
  String get expiresOn => _t('ينتهي في', 'Expires on');
  String get startsOn => _t('يبدأ في', 'Starts on');
  String get planDuration => _t('مدة الباقة', 'Plan duration');
  String get renewSubscription => _t('تجديد الاشتراك', 'Renew subscription');

  // ---- Payments (Phase 3) --------------------------------------------
  String get titlePayments => _t('المدفوعات', 'Payments');
  String get newPayment => _t('دفعة جديدة', 'New payment');
  String get methodCash => _t('كاش', 'Cash');
  String get methodCard => _t('بطاقة بنكية', 'Card');
  String get methodWallet => _t('محفظة إلكترونية', 'Mobile wallet');
  String get methodBankTransfer => _t('تحويل بنكي', 'Bank transfer');
  String get payNow => _t('ادفع الآن', 'Pay now');
  String get processing => _t('جارٍ معالجة الدفع…', 'Processing payment…');
  String get paymentSuccess => _t('تم الدفع بنجاح', 'Payment successful');
  String get paymentFailed => _t('فشل الدفع', 'Payment failed');
  String get receipt => _t('إيصال الدفع', 'Payment receipt');
  String get reference => _t('رقم المرجع', 'Reference');
  String get cardNumber => _t('رقم البطاقة', 'Card number');
  String get cardHolder => _t('اسم حامل البطاقة', 'Cardholder name');
  String get cardExpiry => _t('تاريخ الانتهاء (MM/YY)', 'Expiry (MM/YY)');
  String get cardCvv => _t('CVV', 'CVV');
  String get walletPhone => _t('رقم المحفظة', 'Wallet phone');
  String get bankReference => _t('رقم التحويل', 'Transfer reference');
  String get paymentMethod => _t('وسيلة الدفع', 'Payment method');
  String get noPayments => _t('لا توجد مدفوعات بعد', 'No payments yet');
  String get paid => _t('مدفوع', 'Paid');
  String get pendingPay => _t('معلق', 'Pending');
  String get refunded => _t('مرجع', 'Refunded');
  String get failedPay => _t('فاشل', 'Failed');
  String get todayRevenue => _t('مدفوعات اليوم', "Today's payments");
  String get thisMonth => _t('هذا الشهر', 'This month');
  String get paymentCount => _t('عدد المدفوعات', 'Payments count');
  String get markRefunded => _t('إرجاع المبلغ', 'Refund');
  String get includedInReceipt => _t('مرفق بالإيصال', 'Included in receipt');
  String get noLink => _t('بدون ربط باشتراك', 'No linked subscription');

  // ---- Attendance (Phase 3) ------------------------------------------
  String get titleAttendance => _t('الحضور', 'Attendance');
  String get present => _t('حاضر', 'Present');
  String get absent => _t('غائب', 'Absent');
  String get checkIn => _t('دخول', 'Check in');
  String get checkOut => _t('خروج', 'Check out');
  String get checkedIn => _t('دخل', 'Checked in');
  String get checkedOut => _t('خرج', 'Checked out');
  String get noAttendanceToday =>
      _t('لا يوجد حضور اليوم', 'No attendance today');
  String get attendanceHistory => _t('سجل الحضور', 'Attendance history');
  String get todayStatus => _t('حالة اليوم', "Today's status");
  String get arrivedAt => _t('دخول', 'In at');
  String get leftAt => _t('خروج', 'Out at');
  String get notCheckedInToday =>
      _t('لم تسجّل حضور اليوم', 'Not checked in today');
  String get notProvided => _t('غير متوفر', 'Not provided');

  // ---- Expenses (Phase 4) --------------------------------------------
  String get titleExpenses => _t('المصروفات', 'Expenses');
  String get newExpense => _t('مصروف جديد', 'New expense');
  String get expenseCategory => _t('التصنيف', 'Category');
  String get catSalary => _t('رواتب', 'Salaries');
  String get catRent => _t('إيجار', 'Rent');
  String get catEquipment => _t('أجهزة وصيانة', 'Equipment');
  String get catUtilities => _t('مرافق (كهرباء/ماء)', 'Utilities');
  String get catOther => _t('أخرى', 'Other');
  String get expenseDate => _t('التاريخ', 'Date');
  String get totalExpensesShort => _t('إجمالي المصروفات', 'Total expenses');
  String get noExpenses => _t('لا توجد مصروفات', 'No expenses yet');

  // ---- Announcements (Phase 4) ---------------------------------------
  String get titleAnnouncements => _t('الإعلانات', 'Announcements');
  String get newAnnouncement => _t('إعلان جديد', 'New announcement');
  String get announcementTitle => _t('العنوان', 'Title');
  String get announcementBody => _t('النص', 'Body');
  String get audience => _t('الفئة المستهدفة', 'Audience');
  String get audienceAll => _t('الكل', 'Everyone');
  String get audienceMembers => _t('الأعضاء', 'Members');
  String get audienceTrainers => _t('المدربون', 'Trainers');
  String get noAnnouncements => _t('لا توجد إعلانات', 'No announcements yet');
  String get gymNews => _t('أخبار الجيم', 'Gym news');

  // ---- Gym settings (Phase 4) ----------------------------------------
  String get gymName => _t('اسم الجيم', 'Gym name');
  String get gymAddress => _t('العنوان', 'Address');
  String get gymPhone => _t('الهاتف', 'Phone');
  String get gymEmail => _t('البريد الإلكتروني', 'Email');
  String get openingHours => _t('مواعيد العمل', 'Opening hours');
  String get autoRenewDays => _t('تذكير التجديد قبل (يوم)', 'Renew reminder (days)');
  String get saveSettings => _t('حفظ الإعدادات', 'Save settings');
  String get gymInformation => _t('معلومات الجيم', 'Gym information');
  String get contactUs => _t('تواصل معنا', 'Contact us');
  String get gymGalleryTitle => _t('جولة داخل الجيم', 'Inside the gym');
  String get gymGallerySubtitle =>
      _t('لقطات من داخل الصالة والتدريبات', 'A look inside our training halls');

  // ---- Module hub (admin) --------------------------------------------
  String get managementModules => _t('إدارة الجيم', 'Gym management');
  String get recentPayments => _t('أحدث المدفوعات', 'Recent payments');
  String get viewAll => _t('عرض الكل', 'View all');
  String get quickActions => _t('إجراءات سريعة', 'Quick actions');
  String get memberSince => _t('عضو منذ', 'Member since');
  String get activeNow => _t('نشط الآن', 'Active now');
  String get expiredNow => _t('منتهي', 'Expired');

  String subStatusLabel(SubscriptionStatus status) => switch (status) {
        SubscriptionStatus.active => subActive,
        SubscriptionStatus.expired => subExpired,
        SubscriptionStatus.cancelled => subCancelled,
      };

  String paymentMethodLabel(PaymentMethod method) => switch (method) {
        PaymentMethod.cash => methodCash,
        PaymentMethod.card => methodCard,
        PaymentMethod.wallet => methodWallet,
        PaymentMethod.bankTransfer => methodBankTransfer,
      };

  String paymentStatusLabel(PaymentStatus status) => switch (status) {
        PaymentStatus.paid => paid,
        PaymentStatus.pending => pendingPay,
        PaymentStatus.refunded => refunded,
        PaymentStatus.failed => failedPay,
      };

  String expenseCategoryLabel(ExpenseCategory category) => switch (category) {
        ExpenseCategory.salary => catSalary,
        ExpenseCategory.rent => catRent,
        ExpenseCategory.equipment => catEquipment,
        ExpenseCategory.utilities => catUtilities,
        ExpenseCategory.other => catOther,
      };

  String audienceLabel(AnnouncementAudience audience) => switch (audience) {
        AnnouncementAudience.all => audienceAll,
        AnnouncementAudience.members => audienceMembers,
        AnnouncementAudience.trainers => audienceTrainers,
      };

  // ---- Messages -------------------------------------------------------
  String errorMessage(String code) {
    return switch (code) {
      'invalid_credentials' => _t('بيانات الدخول غير صحيحة', 'Invalid email or password'),
      'email_in_use' => _t('هذا البريد مسجّل بالفعل', 'This email is already registered'),
      'weak_password' => _t('كلمة المرور ضعيفة (6 أحرف على الأقل)', 'Password is too weak (min 6 characters)'),
      'user_not_found' => _t('لا يوجد حساب بهذا البريد', 'No account with this email'),
      'network' => _t('تعذر الاتصال بالشبكة', 'Network error'),
      'auth' => _t('خطأ في المصادقة', 'Authentication failed'),
      'not_found' => _t('العنصر غير موجود', 'Item not found'),
      'gateway_not_configured' => _t(
          'بوابة الدفع غير مفعّلة — اختر وسيلة أخرى أو الربط لاحقاً',
          'Payment gateway not configured — pick another method'),
      'card_incomplete' => _t('أكمل بيانات البطاقة', 'Complete card details'),
      'card_invalid_number' => _t('رقم بطاقة غير صالح', 'Invalid card number'),
      'card_expired' => _t('البطاقة منتهية الصلاحية', 'Card is expired'),
      'card_invalid_cvv' => _t('رمز CVV غير صالح', 'Invalid CVV'),
      'card_declined' => _t('تم رفض البطاقة — جرّب رقماً آخر', 'Card declined — try another number'),
      _ => _t('حدث خطأ غير متوقع', 'Something went wrong'),
    };
  }

  String errorHint(String code) {
    return switch (code) {
      'required' => _t('هذا الحقل مطلوب', 'This field is required'),
      'invalid_email' => _t('بريد إلكتروني غير صالح', 'Invalid email address'),
      'short_password' => _t('6 أحرف على الأقل', 'At least 6 characters'),
      'invalid_phone' => _t('رقم هاتف غير صالح', 'Invalid phone number'),
      'mismatch' => _t('كلمتا المرور غير متطابقتين', 'Passwords do not match'),
      _ => '',
    };
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(arabic: locale.languageCode == 'ar');
});