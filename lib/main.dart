import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

import 'screens/cashier_shell_screen.dart';
import 'screens/home_screen.dart';
import 'screens/open_shift_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/staff_splash_screen.dart';
import 'screens/till_picker_screen.dart';

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
  TillStatus? _selectedTill;
  StaffShiftInfo? _activeShift;

  @override
  void initState() {
    super.initState();
    _locale.load();
    _venue.load();
  }

  bool get _isBartender => _session?.staff.role == 'cashier' || _pendingStaff?.role == 'cashier';

  void _resetToSplash() => setState(() {
        _session = null;
        _pendingStaff = null;
        _selectedTill = null;
        _activeShift = null;
        _api = ApiClient(config: _config);
      });

  void _onStaffSelected(StaffCard staff) => setState(() => _pendingStaff = staff);

  Future<void> _onPinSuccess(StaffSession session) async {
    _api = ApiClient(config: _config, token: session.token);

    if (session.staff.role == 'cashier') {
      final current = await _api.fetchCurrentShift();
      setState(() {
        _session = session;
        _pendingStaff = null;
        _activeShift = current;
        _selectedTill = null;
      });
      return;
    }

    setState(() {
      _session = session;
      _pendingStaff = null;
    });
  }

  void _onTillSelected(TillStatus till) {
    final shift = till.activeShift;
    if (shift != null && shift.staffId == _session!.staff.id) {
      setState(() {
        _activeShift = StaffShiftInfo(
          id: shift.id,
          tillId: till.id,
          tillName: till.name,
          tillCode: till.code,
          startedAt: shift.startedAt,
          openingFloat: shift.openingFloat,
        );
        _selectedTill = null;
      });
      return;
    }

    setState(() => _selectedTill = till);
  }

  void _onShiftOpened(StaffShiftInfo shift) {
    setState(() {
      _activeShift = shift;
      _selectedTill = null;
    });
  }

  Widget _buildHome() {
    if (_session != null && _isBartender && _activeShift != null) {
      return CashierShellScreen(
        api: _api,
        session: _session!,
        shift: _activeShift!,
        onEndShift: () async => _resetToSplash(),
      );
    }

    if (_session != null && _isBartender && _selectedTill != null) {
      return OpenShiftScreen(
        api: _api,
        till: _selectedTill!,
        cashierName: _session!.staff.name,
        onShiftOpened: _onShiftOpened,
        onBack: () => setState(() => _selectedTill = null),
      );
    }

    if (_session != null && _isBartender) {
      return TillPickerScreen(
        api: _api,
        session: _session!,
        onTillSelected: _onTillSelected,
        onBack: _resetToSplash,
      );
    }

    if (_session != null) {
      return HomeScreen(api: _api, session: _session!, onLogout: _resetToSplash);
    }

    if (_pendingStaff != null) {
      return PinScreen(
        staff: _pendingStaff!,
        api: _api,
        onBack: () => setState(() => _pendingStaff = null),
        onSuccess: _onPinSuccess,
      );
    }

    return StaffSplashScreen(
      api: _api,
      onStaffSelected: _onStaffSelected,
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
