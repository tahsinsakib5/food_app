import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_app/screan/food_details_page.dart';
import 'package:food_app/screan/order_confirm_page.dart';
import 'package:food_app/widget/check_out_bottom_sheet.dart';
import 'package:provider/provider.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  final String? restaurantId;
  final String? restaurantName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.restaurantId,
    this.restaurantName,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      restaurantId: map['restaurantId'],
      restaurantName: map['restaurantName'],
    );
  }

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  StreamSubscription? _cartSubscription;

  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void initializeCart() {
    if (_user == null) return;

    _cartSubscription = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      _items.clear();
      for (var doc in snapshot.docs) {
        final cartItem = CartItem.fromMap(doc.data());
        _items.add(cartItem);
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error loading cart: $error');
    });
  }

  void disposeCart() {
    _cartSubscription?.cancel();
  }

  Future<void> addItem(CartItem newItem) async {
    if (_user == null) return;

    try {
      final cartDoc = _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cart')
          .doc(newItem.id);

      final existingDoc = await cartDoc.get();
      
      if (existingDoc.exists) {
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final newQuantity = (existingData['quantity'] ?? 1) + 1;
        await cartDoc.update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartDoc.set(newItem.toMap());
      }
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      throw e;
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      throw e;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_user == null) return;

    try {
      if (quantity <= 0) {
        await removeItem(itemId);
      } else {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('cart')
            .doc(itemId)
            .update({
          'quantity': quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      throw e;
    }
  }

  Future<void> incrementQuantity(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final newQuantity = _items[index].quantity + 1;
      await updateQuantity(itemId, newQuantity);
    }
  }

  Future<void> decrementQuantity(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        final newQuantity = _items[index].quantity - 1;
        await updateQuantity(itemId, newQuantity);
      } else {
        await removeItem(itemId);
      }
    }
  }

  Future<void> clearCart() async {
    if (_user == null) return;

    try {
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      throw e;
    }
  }

  static Future<int> getCartItemsCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
      
      int totalCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalCount += (data['quantity'] ?? 1) as int;
      }
      return totalCount;
    } catch (e) {
      debugPrint('Error getting cart count: $e');
      return 0;
    }
  }
}

class RestaurantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;                          
  final String? restaurantId;

  const RestaurantDetailsPage({Key? key, required this.restaurant, this.restaurantId}) : super(key: key);

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Main Course', 'Appetizers', 'Desserts', 'Drinks'];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> _allFoodItems = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _foodSubscription;

  @override
  void initState() {
    super.initState();
    _setupFoodStream();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.initializeCart();
    });
  }

  @override
  void dispose() {
    _foodSubscription?.cancel();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.disposeCart();
    super.dispose();
  }

  void _setupFoodStream() {
    _foodSubscription = _firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('foodItems')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _allFoodItems = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? 'No Name',
            'price': (data['price'] ?? 0.0).toDouble(),
            'description': data['description'] ?? 'No Description',
            'category': data['category'] ?? 'Main Course',
            'imageUrl': data['imageUrl'] ?? '',
            'isEnabled': data['isEnabled'] ?? true,
          };
        }).toList();
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _error = 'Failed to load food items: $error';
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> get _filteredFoodItems {
    if (_selectedCategoryIndex == 0) return _allFoodItems;
    final selectedCategory = _categories[_selectedCategoryIndex];
    return _allFoodItems.where((food) => food['category'] == selectedCategory).toList();
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CartBottomSheet(restaurantName: widget.restaurant['name'] ?? 'Restaurant'),
    );
  }

  void _addToCart(BuildContext context, Map<String, dynamic> food) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    final cartItem = CartItem(
      id: food['id'],
      name: food['name'] ?? 'Unknown Food',
      price: food['price']?.toDouble() ?? 0.0,
      imageUrl: food['imageUrl'] ?? '',
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurant['name'],
    );
    
    cartProvider.addItem(cartItem).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${food['name']} added to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : CustomScrollView(
                  slivers: [
                    // Restaurant header with image
                    SliverAppBar(
                      expandedHeight: 200,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Image.network(
                          widget.restaurant['imageUrl'] ?? 'https://via.placeholder.com/400',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, size: 60, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      pinned: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    
                    // Restaurant details
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.restaurant['name'] ?? 'Restaurant',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  (widget.restaurant['rating'] ?? 4.0).toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${widget.restaurant['reviews'] ?? 0} reviews)',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.restaurant['address'] ?? 'No address provided',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Open ${widget.restaurant['openingTime'] ?? '09:00'} - ${widget.restaurant['closingTime'] ?? '22:00'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Categories filter
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: FilterChip(
                                label: Text(_categories[index]),
                                selected: _selectedCategoryIndex == index,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Food items list
                    _filteredFoodItems.isEmpty
                        ? SliverToBoxAdapter(
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'No food items found\nTap + to add new items',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final food = _filteredFoodItems[index];
                                return _buildFoodItem(food);
                              },
                              childCount: _filteredFoodItems.length,
                            ),
                          ),
                  ],
                ),
      
      // Floating action button for cart
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.totalItems == 0) return const SizedBox();
          
          return FloatingActionButton.extended(
            onPressed: _showCartBottomSheet,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Badge(
              label: Text(cart.totalItems.toString()),
              child: const Icon(Icons.shopping_cart),
            ),
            label: Text('\$${cart.totalPrice.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartItem = cart.items.firstWhere(
          (item) => item.id == food['id'],
          orElse: () => CartItem(id: '', name: '', price: 0, imageUrl: ''),
        );
        
        return InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>FoodDetailsPage(restaurantId: widget.restaurantId!, foodId: food['id'],initialData:food,) ,));
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: food['imageUrl'] != null && food['imageUrl'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              food['imageUrl'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.fastfood, color: Colors.grey),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Food details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food['name']?.toString() ?? "Unknown Food",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          food['description']?.toString() ?? "No description available",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              (food['rating']?.toStringAsFixed(1) ?? "0.0"),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Price and Add to Cart button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(food['price']?.toStringAsFixed(2) ?? "0.00")}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCartControls(food, cart, cartItem),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartControls(Map<String, dynamic> food, CartProvider cart, CartItem cartItem) {
    if (cartItem.id.isNotEmpty) {
      // Item in cart - show quantity controls
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
              onPressed: () => cart.decrementQuantity(food['id']),
            ),
            Text(
              cartItem.quantity.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              onPressed: () => cart.incrementQuantity(food['id']),
            ),
          ],
        ),
      );
    } else {
      // Item not in cart - show Add button
      return ElevatedButton(
        onPressed: () => _addToCart(context, food),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text('Add to Cart'),
      );
    }
  }
}

class CartBottomSheet extends StatelessWidget {
  final String restaurantName;

  const CartBottomSheet({super.key, required this.restaurantName});

  void _showCheckoutPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPages(restaurantId: 
        "restaurantName"),
      ),
    );    
  }

  @override                       
  Widget build(BuildContext context) {        
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Cart',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (cart.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Browse Menu'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      // Cart items list
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[300],
                                  ),
                                  child: item.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            item.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.fastfood, color: Colors.grey);
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.fastfood, color: Colors.grey),
                                ),
                                title: Text(item.name),
                                subtitle: Text('\$${item.price.toStringAsFixed(2)} each'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () => cart.decrementQuantity(item.id),
                                    ),
                                    Text(
                                      item.quantity.toString(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () => cart.incrementQuantity(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Total and checkout button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total:', style: TextStyle(fontSize: 18)),
                                Text(
                                  '\$${cart.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showCheckoutPage(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Checkout',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

