import 'package:flutter/foundation.dart';
import '../models/order.dart';

/// Cross-screen navigation hints for the operator app.
class OperatorNavState extends ChangeNotifier {
  int _tab = 0;
  OrderStatus? _ordersFilter;
  bool _ordersTodayOnly = false;

  int get tab => _tab;
  OrderStatus? get ordersFilter => _ordersFilter;
  bool get ordersTodayOnly => _ordersTodayOnly;

  void goToOrders({OrderStatus? filter, bool todayOnly = false}) {
    _tab = 1;
    _ordersFilter = filter;
    _ordersTodayOnly = todayOnly;
    notifyListeners();
  }

  void goToTab(int tab) {
    _tab = tab;
    notifyListeners();
  }

  void clearFilter() {
    _ordersFilter = null;
    _ordersTodayOnly = false;
    notifyListeners();
  }
}

final operatorNavState = OperatorNavState();
