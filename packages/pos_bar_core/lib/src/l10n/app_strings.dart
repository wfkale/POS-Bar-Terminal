class AppStrings {
  AppStrings(this._code);

  final String _code;

  bool get _sw => _code == 'sw';

  String get appTitleFloor => _sw ? 'POS Bar — Sakafu' : 'POS Bar — Floor';
  String get appTitleCashier => _sw ? 'POS Bar — Keshia' : 'POS Bar — Cashier';

  String get retry => _sw ? 'Jaribu tena' : 'Retry';
  String get cancel => _sw ? 'Ghairi' : 'Cancel';
  String get cart => _sw ? 'Kikapu' : 'Cart';
  String get total => _sw ? 'Jumla' : 'Total';
  String get available => _sw ? 'Inapatikana' : 'Available';
  String get signIn => _sw ? 'Ingia' : 'Sign in';
  String get resume => _sw ? 'Endelea' : 'Resume';
  String get cash => _sw ? 'Taslimu' : 'Cash';
  String get card => _sw ? 'Kadi' : 'Card';
  String get mpesa => _sw ? 'M-Pesa' : 'M-Pesa';
  String get open => _sw ? 'Wazi' : 'OPEN';

  // Bar terminal
  String get tapNameToSignIn => _sw ? 'Gusa jina lako kuingia' : 'Tap your name to sign in';
  String get barAttendant => _sw ? 'Mhudumu' : 'Bar Attendant';
  String get enterPin => _sw ? 'Weka PIN yako ya tarakimu 4' : 'Enter your 4-digit PIN';
  String hi(String name) => _sw ? 'Habari $name' : 'Hi $name';
  String welcome(String name) => _sw ? 'Karibu, $name' : 'Welcome, $name';
  String couldNotLoadStaff(String error) =>
      _sw ? 'Imeshindwa kupakia wafanyakazi\n$error' : 'Could not load staff\n$error';

  String get cashOrder => _sw ? 'Agizo la Taslimu' : 'Cash Order';
  String get tabOrder => _sw ? 'Agizo la Tab' : 'Tab Order';
  String get payAtCounter => _sw ? 'Lipa kwenye kaunta' : 'Pay at counter now';
  String get addToOpenTab => _sw ? 'Ongeza kwenye tab iliyo wazi' : 'Add to open tab';
  String get newTab => _sw ? 'Tab Mpya' : 'New Tab';
  String get openCustomerTab => _sw ? 'Fungua tab ya mteja' : 'Open customer tab';
  String get openTabs => _sw ? 'Tab Zilizo Wazi' : 'Open Tabs';
  String get viewRunningTabs => _sw ? 'Angalia tab zinazoendelea' : 'View running tabs';
  String get myPerformance => _sw ? 'Utendaji Wangu' : 'My Performance';
  String get todaysMetrics => _sw ? 'Takwimu za leo' : "Today's metrics";
  String get openNewTab => _sw ? 'Fungua Tab Mpya' : 'Open New Tab';
  String get customerName => _sw ? 'Jina la mteja' : 'Customer name';
  String get tableArea => _sw ? 'Meza / eneo' : 'Table / area';
  String get openTab => _sw ? 'Fungua Tab' : 'Open Tab';
  String get noOpenTabs => _sw ? 'Hakuna tab zilizo wazi' : 'No open tabs';
  String get noTableLabel => _sw ? 'Hakuna lebo ya meza' : 'No table label';
  String get selectTabFirst => _sw ? 'Chagua tab kwanza' : 'Select a tab first';
  String orderSentToCashier(String orderNo) =>
      _sw ? 'Agizo $orderNo limetumwa kwa keshia' : 'Order $orderNo sent to cashier';
  String get billPrinted => _sw ? 'Bili imechapishwa' : 'Bill printed';
  String get selectTab => _sw ? 'Chagua tab' : 'Select tab';
  String get sendAndPrintBill => _sw ? 'Tuma & Chapisha Bili' : 'Send & Print Bill';

  String get tabsOpened => _sw ? 'Tab Zilizofunguliwa' : 'Tabs Opened';
  String get ordersCreated => _sw ? 'Agizo Zilizoundwa' : 'Orders Created';
  String get ordersPaid => _sw ? 'Agizo Zilizolipwa' : 'Orders Paid';
  String get totalSales => _sw ? 'Mauzo Jumla' : 'Total Sales';
  String get avgOrder => _sw ? 'Wastani wa Agizo' : 'Avg Order';
  String get billsPrinted => _sw ? 'Bili Zilizochapishwa' : 'Bills Printed';
  String get voids => _sw ? 'Kughairi' : 'Voids';

  // Cashier
  String get tapTillToSignIn => _sw ? 'Chagua till yako kuingia' : 'Select your till to sign in';
  String get cashierTerminal => _sw ? 'Keshia Terminal' : 'Cashier Terminal';
  String get tillsRegisters => _sw ? 'Till / Kaunta' : 'Tills / Registers';
  String get cashiersOnDuty => _sw ? 'Wakeshia walio kazini' : 'Cashiers on duty';
  String shiftOpen(String name) => _sw ? 'Shift imefunguliwa · $name' : 'Shift open · $name';
  String sinceTime(String time) => _sw ? 'Tangu $time' : 'Since $time';
  String signInToTill(String till) => _sw ? 'Ingia kwenye $till' : 'Sign in to $till';
  String onAnotherTill(String till) => _sw ? 'Yu kwenye $till' : 'On $till';
  String get resumeShift => _sw ? 'Endelea na shift yako' : 'Resume your shift';
  String get enterPinOpenShift => _sw ? 'Weka PIN kufungua shift' : 'Enter PIN to open shift';
  String get notOnShift => _sw ? 'Hayuko kwenye shift' : 'Not on shift';
  String onTill(String till, String time) => _sw ? 'Yu $till · $time' : 'On $till · $time';
  String get cashierQueue => _sw ? 'Foleni ya Keshia' : 'Cashier Queue';
  String get closeShift => _sw ? 'Funga shift' : 'Close shift';
  String get queueClear => _sw ? 'Foleni ni tupu' : 'Queue is clear';
  String get waitingOrders => _sw ? 'Inasubiri maagizo kutoka baa…' : 'Waiting for bar orders…';
  String fromStaff(String name) => _sw ? 'Kutoka: $name' : 'From: $name';
  String tabCustomer(String name) => _sw ? 'Tab: $name' : 'Tab: $name';
  String orderPaid(String orderNo) => _sw ? '$orderNo imelipwa' : '$orderNo paid';
  String openShiftTitle(String till) => _sw ? 'Fungua shift · $till' : 'Open shift · $till';
  String get openingFloatIntro =>
      _sw ? 'Hesabu pesa kwenye droo na weka float ya kufungua.' : 'Count the cash in your drawer and enter the opening float.';
  String get openingFloat => _sw ? 'Float ya kufungua' : 'Opening float';
  String get skipNoFloat => _sw ? 'Ruka (bila float)' : 'Skip (no float)';
  String get openShiftBtn => _sw ? 'Fungua shift' : 'Open shift';
  String get countClosingCash => _sw ? 'Weka hesabu ya pesa mwisho wa shift' : 'Enter closing cash count in drawer';
  String get venueName => _sw ? 'The Copper Lounge' : 'The Copper Lounge';
  String get language => _sw ? 'Lugha' : 'Language';
  String get english => _sw ? 'English' : 'English';
  String get kiswahili => _sw ? 'Kiswahili' : 'Kiswahili';
  String get logout => _sw ? 'Toka' : 'Log out';
  String get clear => _sw ? 'Futa' : 'Clear';
  String couldNotLoadRoster(String error) =>
      _sw ? 'Imeshindwa kupakia orodha\n$error' : 'Could not load roster\n$error';
  String get cashierRole => _sw ? 'Keshia' : 'Cashier';
  String get floorStaff => _sw ? 'Wafanyakazi wa sakafu' : 'Floor staff';
  String get requestTabDeletion => _sw ? 'Omba kufuta tab' : 'Request tab deletion';
  String get deletionReason => _sw ? 'Sababu ya kufuta' : 'Reason for deletion';
  String get deletionPending => _sw ? 'Inasubiri idhini' : 'Pending approval';
  String get deletionRequested => _sw ? 'Ombi la kufuta limewasilishwa' : 'Deletion request submitted';
  String get payQueue => _sw ? 'Foleni ya malipo' : 'Pay queue';
  String get floorOps => _sw ? 'Shughuli za sakafu' : 'Floor';

  // Printing
  String get printerSettings => _sw ? 'Mipangilio ya printa' : 'Printer settings';
  String get printerSettingsIntro => _sw
      ? 'Unganisha printa ya joto 80mm (eneo la kuchapa ~72mm) kupitia Bluetooth au USB Serial. Chrome/Edge inahitajika.'
      : 'Pair an 80mm thermal printer (~72mm print width) over Bluetooth or USB Serial. Chrome/Edge required.';
  String get noPrinterPaired => _sw ? 'Hakuna printa' : 'No printer paired';
  String get pairPrinterHint => _sw ? 'Unganisha printa ili kuchapisha bili na risiti' : 'Connect a printer to print bills and receipts';
  String get forgetPrinter => _sw ? 'Ondoa printa' : 'Forget printer';
  String get printerForgotten => _sw ? 'Printa imeondolewa' : 'Printer forgotten';
  String get printerNotSupported => _sw
      ? 'Kifaa hiki hakitumii Web Bluetooth/Serial. Tumia Chrome kwenye Android au desktop.'
      : 'This browser does not support Web Bluetooth/Serial. Use Chrome on Android or desktop.';
  String get connectBluetooth => _sw ? 'Unganisha Bluetooth' : 'Connect Bluetooth';
  String get connectUsbSerial => _sw ? 'Unganisha USB / Serial' : 'Connect USB / Serial';
  String get testPrint => _sw ? 'Chapisha jaribio' : 'Test print';
  String get testPrintSent => _sw ? 'Jaribio limetumwa kwa printa' : 'Test print sent to printer';
  String printerPaired(String name) => _sw ? '$name imeunganishwa' : '$name paired';
  String get completeWithReceipt => _sw ? 'KAMILISHA NA RISITI' : 'COMPLETE WITH RECEIPT';
  String get completeNoReceipt => _sw ? 'KAMILISHA BILA RISITI' : 'COMPLETE NO RECEIPT';
  String get choosePayment => _sw ? 'Chagua njia ya malipo' : 'Choose payment method';
  String get receiptPrinted => _sw ? 'Risiti imechapishwa' : 'Receipt printed';
  String get billPrintFailed => _sw
      ? 'Malipo yamefanikiwa, lakini uchapishaji wa risiti umeshindikana'
      : 'Payment succeeded, but receipt printing failed';
  String get printerNeeded => _sw
      ? 'Unganisha printa kwenye Mipangilio ya printa kwanza'
      : 'Pair a printer in Printer settings first';
}
