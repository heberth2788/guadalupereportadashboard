import 'dart:collection'; // To use UnmodifiableListView class
import 'package:flutter/foundation.dart'; // To use ChangeNotifier class
import 'package:guadalupereportadashboard/learnandtest/provider/Item.dart';

const cartItemCost = 50;

/// ChangeNotifier is a simple class included in the Flutter SDK which provides change notification to its listeners. 
/// In other words, if something is a ChangeNotifier, you can subscribe to its changes. 
/// (It is a form of Observable, for those familiar with the term.)
/// IMPORTANT: The only code that is specific to ChangeNotifier is the call to notifyListeners()
class CartModel extends ChangeNotifier {

  /// Internal private state of the cart
  final List<Item> _items = [];

  /// Unmodifiable list view of the items
  UnmodifiableListView<Item> get items => UnmodifiableListView(_items);
  
  /// Total price
  int get totalPrice => _items.length * cartItemCost;

  /// Add an item to the cart
  void add(Item item) {
    _items.add(item);
    notifyListeners(); // This tells to the widgets that are listening to this model to rebuild.
  }

  /// Remove all items from the cart
  void removeAll() {
    _items.clear();
    notifyListeners(); // This tells to the widgets that are listening to this model to rebuild.
  }
}