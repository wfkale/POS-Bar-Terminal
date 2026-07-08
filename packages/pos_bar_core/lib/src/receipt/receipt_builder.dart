import '../models/order.dart';
import '../models/venue_config.dart';
import 'bar_receipt.dart';

class ReceiptBuilder {
  static BarReceipt proforma({
    required BarOrder order,
    required VenueConfig venue,
    required String billNumber,
    String? tableLabel,
  }) {
    return _fromOrder(
      kind: 'proforma',
      order: order,
      venue: venue,
      documentNumber: billNumber,
      paymentMethod: null,
      tillLabel: null,
      tableLabel: tableLabel,
    );
  }

  static BarReceipt finalReceipt({
    required BarOrder order,
    required VenueConfig venue,
    required String paymentMethod,
    String? billNumber,
    String? tillLabel,
  }) {
    return _fromOrder(
      kind: 'final',
      order: order,
      venue: venue,
      documentNumber: billNumber ?? order.orderNumber,
      paymentMethod: paymentMethod,
      tillLabel: tillLabel,
      tableLabel: null,
    );
  }

  static BarReceipt _fromOrder({
    required String kind,
    required BarOrder order,
    required VenueConfig venue,
    required String documentNumber,
    required String? paymentMethod,
    required String? tillLabel,
    required String? tableLabel,
  }) {
    final taxRate = venue.taxRate;
    final total = order.total;
    final taxAmount = order.taxAmount ?? _taxFromInclusive(total, taxRate);
    final subtotal = order.subtotal ?? (total - taxAmount);

    return BarReceipt(
      kind: kind,
      venueName: venue.name,
      location: venue.address,
      phone: venue.phone,
      tin: venue.tin,
      vrn: venue.vrn,
      documentNumber: documentNumber,
      orderNumber: order.orderNumber,
      currency: venue.currency,
      items: order.lines
          .map(
            (l) => BarReceiptItem(
              name: l.itemName,
              quantity: l.quantity.toDouble(),
              unitPrice: l.unitPrice ?? (l.quantity == 0 ? 0 : l.lineTotal / l.quantity),
              lineTotal: l.lineTotal,
            ),
          )
          .toList(),
      subtotal: subtotal,
      taxAmount: taxAmount,
      taxRate: taxRate,
      total: total,
      printedAt: DateTime.now(),
      staffName: order.staffName,
      customerName: order.tabCustomer,
      tableLabel: tableLabel,
      paymentMethod: paymentMethod,
      tillLabel: tillLabel,
    );
  }

  static double _taxFromInclusive(double gross, double rate) {
    if (gross <= 0 || rate <= 0) return 0;
    return double.parse((gross * (rate / (100 + rate))).toStringAsFixed(2));
  }
}
