import 'package:flutter/material.dart';
import 'package:food_app/screan/resturent_details_page.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  void incrementQuantity(String itemId) {
    // Implementation 
    notifyListeners();
  }

  void decrementQuantity(String itemId) {
    // Implementation
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}