/// Decides at runtime which backend the app talks to.
///
/// - [AppDataSource.local]: fully offline "demo" mode (worked out of the box,
///   used for the portfolio/demo without Firebase credentials).
/// - [AppDataSource.firebase]: real Firebase project. Selected automatically
///   when the app is started with `--dart-define=DATA_SOURCE=firebase` and the
///   Firebase SDK initializes successfully.
enum AppDataSource { local, firebase }

abstract final class AppConfig {
  static AppDataSource dataSource = AppDataSource.local;

  static bool get isFirebase => dataSource == AppDataSource.firebase;
}