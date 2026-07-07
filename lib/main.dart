import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/staff_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(BarTerminalApp(config: config));
}

class BarTerminalApp extends StatefulWidget {
  const BarTerminalApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<BarTerminalApp> createState() => _BarTerminalAppState();
}

class _BarTerminalAppState extends State<BarTerminalApp> {
  late final AppConfig _config = widget.config;
  final _locale = AppLocaleController();
  late final VenueConfigController _venue = VenueConfigController(config: _config);
  late ApiClient _api = ApiClient(config: _config);
  StaffSession? _session;
  StaffCard? _pendingStaff;

  @override
  void initState() {
    super.initState();
    _locale.load();
    _venue.load();
  }

  void _onLoggedIn(StaffSession session) {
    _api = ApiClient(config: _config, token: session.token);
    setState(() {
      _session = session;
      _pendingStaff = null;
    });
  }

  void _logout() => setState(() {
        _session = null;
        _pendingStaff = null;
        _api = ApiClient(config: _config);
      });

  Widget _buildHome() {
    if (_session != null) {
      return HomeScreen(api: _api, session: _session!, onLogout: _logout);
    }
    if (_pendingStaff != null) {
      return PinScreen(
        staff: _pendingStaff!,
        api: _api,
        onBack: () => setState(() => _pendingStaff = null),
        onSuccess: _onLoggedIn,
      );
    }
    return StaffSplashScreen(
      api: _api,
      onStaffSelected: (staff) => setState(() => _pendingStaff = staff),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_locale, _venue]),
      builder: (context, _) {
        return VenueScope(
          controller: _venue,
          child: LocaleScope(
            controller: _locale,
            child: MaterialApp(
              key: ValueKey('${_locale.locale.languageCode}_${_venue.venue.name}'),
              title: _venue.venue.name,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark(),
              locale: _locale.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('sw'),
              ],
              home: _buildHome(),
            ),
          ),
        );
      },
    );
  }
}
