/// Central schema for Cloud Firestore: collection names and (soon) field
/// keys. Single source of truth so paths are never duplicated as magic strings.
///
/// Relationships:
/// - `users`      → every app account (role drives RBAC)
/// - `members`    → gym member profile (1:1 with a `users` doc for member role)
/// - `trainers`   → trainer profiles (1:1 with a `users` doc for trainer role)
/// - `membership_plans` → available gym plans
/// - `subscriptions`    → member ↔ plan with start/end date (member id + plan id)
/// - `attendance`       → member check-ins (member id)
/// - `payments`         → payments linked to a subscription (member id + subscription id)
/// - `expenses`         → gym expenses
/// - `notifications`    → in-app notifications (target uid or "all")
/// - `gym_settings`     → single doc: gym info / opening hours / branding
/// - `announcements`    → public announcements shown to members
abstract final class FirestoreSchema {
  static const String users = 'users';
  static const String members = 'members';
  static const String trainers = 'trainers';
  static const String membershipPlans = 'membership_plans';
  static const String subscriptions = 'subscriptions';
  static const String attendance = 'attendance';
  static const String payments = 'payments';
  static const String expenses = 'expenses';
  static const String notifications = 'notifications';
  static const String gymSettings = 'gym_settings';
  static const String announcements = 'announcements';
}