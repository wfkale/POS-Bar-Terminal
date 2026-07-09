import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/app_strings.dart';
import '../config/app_config.dart';
import '../models/cashier_roster.dart';
import '../models/menu.dart';
import '../models/order.dart';
import '../models/staff.dart';
import '../models/tab.dart';
import '../models/venue_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  /// User-facing copy for PIN entry screens (localized).
  String pinLoginMessage(AppStrings l10n) {
    if (statusCode == 423) return l10n.accountLocked;
    if (statusCode == 401) return l10n.invalidPin;
    return message;
  }
}

class ApiClient {
  ApiClient({required this.config, String? token}) : _token = token;

  final AppConfig config;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<VenueConfig> fetchVenueConfig({int venueId = 1}) async {
    final res = await http.get(
      Uri.parse('${config.apiBaseUrl}/venue?venue_id=$venueId'),
      headers: _headers,
    );
    _ensureSuccess(res);
    return VenueConfig.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<List<StaffCard>> fetchOnDutyStaff({int venueId = 1}) async {
    final res = await http.get(
      Uri.parse('${config.apiBaseUrl}/staff/on-duty?venue_id=$venueId'),
      headers: _headers,
    );
    _ensureSuccess(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => StaffCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StaffSession> pinLogin({required int staffId, required String pin}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/staff/pin-login'),
      headers: _headers,
      body: jsonEncode({'staff_id': staffId, 'pin': pin}),
    );
    _ensureSuccess(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return StaffSession(
      token: body['token'] as String,
      staff: StaffProfile.fromJson(body['staff'] as Map<String, dynamic>),
    );
  }

  Future<List<MenuCategory>> fetchMenu() async {
    final res = await http.get(Uri.parse('${config.apiBaseUrl}/menu'), headers: _headers);
    _ensureSuccess(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => MenuCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BarTab>> fetchOpenTabs() async {
    final res = await http.get(Uri.parse('${config.apiBaseUrl}/tabs/open'), headers: _headers);
    _ensureSuccess(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => BarTab.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BarTab> createTab({required String customerName, String? tableLabel}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/tabs'),
      headers: _headers,
      body: jsonEncode({'customer_name': customerName, 'table_label': tableLabel}),
    );
    _ensureSuccess(res);
    return BarTab.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<void> requestTabDeletion(int tabId, {required String reason}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/tabs/$tabId/deletion-requests'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    _ensureSuccess(res);
  }

  Future<BarOrder> createOrder({
    required String type,
    int? tabId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/orders'),
      headers: _headers,
      body: jsonEncode({'type': type, 'tab_id': tabId, 'lines': lines}),
    );
    _ensureSuccess(res);
    return BarOrder.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<BarOrder> sendOrder(int orderId) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/orders/$orderId/send'),
      headers: _headers,
    );
    _ensureSuccess(res);
    return BarOrder.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> printBill(int orderId, {String type = 'proforma'}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/orders/$orderId/bills'),
      headers: _headers,
      body: jsonEncode({'type': type}),
    );
    _ensureSuccess(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<List<BarOrder>> fetchCashierQueue() async {
    final res = await http.get(Uri.parse('${config.apiBaseUrl}/cashier/queue'), headers: _headers);
    _ensureSuccess(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => BarOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BarOrder> payOrder(int orderId, {required String method, String? reference}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/orders/$orderId/pay'),
      headers: _headers,
      body: jsonEncode({'method': method, 'reference': reference}),
    );
    _ensureSuccess(res);
    return BarOrder.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> fetchMyMetrics() async {
    final res = await http.get(
      Uri.parse('${config.apiBaseUrl}/staff/me/metrics'),
      headers: _headers,
    );
    _ensureSuccess(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<TillRoster> fetchCashierRoster({int venueId = 1}) async {
    final res = await http.get(
      Uri.parse('${config.apiBaseUrl}/cashier/roster?venue_id=$venueId'),
      headers: _headers,
    );
    _ensureSuccess(res);
    return TillRoster.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<StaffShiftInfo?> fetchCurrentShift() async {
    final res = await http.get(
      Uri.parse('${config.apiBaseUrl}/shifts/current'),
      headers: _headers,
    );
    _ensureSuccess(res);
    final data = jsonDecode(res.body)['data'];
    if (data == null) return null;
    return StaffShiftInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<StaffShiftInfo> startShift({required int tillId, double? openingFloat}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/shifts/start'),
      headers: _headers,
      body: jsonEncode({
        'till_id': tillId,
        if (openingFloat != null) 'opening_float': openingFloat,
      }),
    );
    _ensureSuccess(res);
    return StaffShiftInfo.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<void> endShift({double? closingFloat, String? notes}) async {
    final res = await http.post(
      Uri.parse('${config.apiBaseUrl}/shifts/end'),
      headers: _headers,
      body: jsonEncode({
        if (closingFloat != null) 'closing_float': closingFloat,
        if (notes != null) 'notes': notes,
      }),
    );
    _ensureSuccess(res);
  }

  Future<BarTabDetail> fetchTabDetail(int tabId) async {
    final res = await http.get(
      Uri.parse('${config.apiBaseUrl}/tabs/$tabId'),
      headers: _headers,
    );
    _ensureSuccess(res);
    return BarTabDetail.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(_messageFromResponse(res), statusCode: res.statusCode);
  }

  String _messageFromResponse(http.Response res) {
    final fallback = 'Request failed (${res.statusCode})';
    if (res.body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return fallback;

      final errors = decoded['errors'];
      if (errors is Map<String, dynamic>) {
        for (final entry in errors.values) {
          if (entry is List && entry.isNotEmpty) {
            final first = entry.first?.toString();
            if (first != null && first.isNotEmpty) return first;
          }
          if (entry is String && entry.isNotEmpty) return entry;
        }
      }

      final message = decoded['message']?.toString();
      if (message != null && message.isNotEmpty && message != 'The given data was invalid.') {
        return message;
      }
    } catch (_) {
      // keep fallback
    }
    return fallback;
  }
}
