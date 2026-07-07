import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

export 'app_strings.dart';
export 'language_toggle.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController();

  static const _prefKey = 'pos_bar_locale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  AppStrings get strings => AppStrings(_locale.languageCode);

  bool get isSwahili => _locale.languageCode == 'sw';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == 'en' || code == 'sw') {
      _locale = Locale(code!);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  Future<void> toggle() {
    return setLocale(isSwahili ? const Locale('en') : const Locale('sw'));
  }
}

class LocaleScope extends InheritedNotifier<AppLocaleController> {
  const LocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.notifier!;
  }

  static AppStrings stringsOf(BuildContext context) => of(context).strings;
}

extension L10nContext on BuildContext {
  AppStrings get l10n => LocaleScope.stringsOf(this);
}
