import 'package:flutter/material.dart';
import 'package:food_app/screan/resturent_details_page.dart';
import 'package:food_app/widget/location_container.dart';
import 'package:food_app/widget/map_selector.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final String restaurantName;

  const CheckoutPage({super.key, required this.restaurantName});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  
  var _selectedLocation;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = ['Cash on Delivery', 'Credit Card', 'Digital Wallet'];
  
  Map<String, String> _specialInstructions = {};
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _address = '';
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    // Load saved address if available
    _addressController.text = '123 Main Street, City, State';
    _phoneController.text = '+1 234 567 8900';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _showSpecialInstructionsDialog(String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Special Instructions for $itemName'),
        content: TextField(
          controller: _instructionsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'E.g., No onions, Extra spicy, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_instructionsController.text.isNotEmpty) {
                setState(() {
                  _specialInstructions[itemId] = _instructionsController.text;
                });
                _instructionsController.clear();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Instructions added for $itemName'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate() && !_isPlacingOrder) {
      setState(() {
        _isPlacingOrder = true;
      });

      final cart = Provider.of<CartProvider>(context, listen: false);
      final user = _auth.currentUser;

      try {
        // Prepare order data
        Map<String, dynamic> orderData = {
          'userId': user?.uid ?? 'guest',
          'userEmail': user?.email ?? 'guest',
          'restaurantName': widget.restaurantName,
          'totalPrice': cart.totalPrice,
          'deliveryStatus': 'pending', // Initial status
          'orderDate': FieldValue.serverTimestamp(),
          'deliveryAddress': _addressController.text,
          'phoneNumber': _phoneController.text,
          'paymentMethod': _selectedPaymentMethod,
          'specialInstructions': _specialInstructions,
          'items': cart.items.map((item) => {
            'id': item.id,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'specialInstructions': _specialInstructions[item.id] ?? '',
          }).toList(),
        };

        // Add location data if available
        if (_selectedLocation != null) {
          orderData['location'] = {
            'latitude': _selectedLocation.latitude,
            'longitude': _selectedLocation.longitude,
          };
        }

        // Save to Firebase
        DocumentReference orderRef = await _firestore.collection('orders').add(orderData);

        // Show order confirmation
        _showOrderConfirmation(cart, orderRef.id);
        
      } catch (error) {
        print('Error placing order: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  void _showOrderConfirmation(CartProvider cart, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: $orderId'),
            Text('Restaurant: ${widget.restaurantName}'),
            Text('Total: \$${cart.totalPrice.toStringAsFixed(2)}'),
            Text('Items: ${cart.totalItems}'),
            Text('Delivery to: ${_addressController.text}'),
            Text('Payment: $_selectedPaymentMethod'),
            const SizedBox(height: 16),
            const Text('Your food will be delivered in 30-45 minutes.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Order Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          
                          ...cart.items.map((item) => Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Quantity: ${item.quantity}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        if (_specialInstructions.containsKey(item.id))
                                          Text(
                                            'Instructions: ${_specialInstructions[item.id]}',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _showSpecialInstructionsDialog(item.id, item.name),
                                    child: Text(
                                      _specialInstructions.containsKey(item.id) 
                                          ? 'Edit Instructions' 
                                          : 'Add Instructions',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                            ],
                          )).toList(),
                          
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                '\$${cart.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delivery Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Address',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter delivery address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Method
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ..._paymentMethods.map((method) => RadioListTile<String>(
                            title: Text(method),
                            value: method,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          )).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => MapSelector())
                      );
                      
                      if (result != null && result is Map) {
                        setState(() {
                          _selectedLocation = result['location'];
                          _address = result['address'];
                        });
                        
                        print('Selected Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
                        print('Address: $_address');
                      }
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 8),
                        Text('Select Location'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  if (_selectedLocation != null)
                  LocationDisplayContainer(
                    latitude: _selectedLocation!.latitude,
                    longitude: _selectedLocation!.longitude,
                    apiKey: "AIzaSyCG2YHIuPJYMOJzS6wSw5eZ0dTYXnhZFLs",
                  ),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Notes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Any special delivery instructions?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}