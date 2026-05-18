import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get total => _items.fold(0, (sum, i) => sum + i.lineTotal);

  void add(CartItem item) {
    final idx = _items.indexWhere(
      (i) => i.productId == item.productId && i.variantId == item.variantId,
    );
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(
        quantity: _items[idx].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

final cartState = CartState();
