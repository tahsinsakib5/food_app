import 'package:flutter/material.dart';
import 'package:food_app/screan/resturent_details_page.dart';
import 'package:food_app/screan/riderTraker_map.dart';
import 'package:lottie/lottie.dart';

class OrderConfirmPage extends StatelessWidget {
  final CartProvider cart;
  final String orderNumber;

  const OrderConfirmPage({
    Key? key,
  
    this.orderNumber = '', required this.cart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                repeat: false,
                'assets/SuccessCheck .json', // Add your Lottie file here
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              
              const SizedBox(height: 32),
              
              // Success Title
              Text(
                'Order Confirmed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Success Message
              Text(
                'Your order has been placed successfully',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Order Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Restaurant Name
                    _buildDetailRow(
                      icon: Icons.restaurant,
                      title: 'Restaurant',
                      value:"" ,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Total Amount
                    _buildDetailRow(
                      icon: Icons.payments,
                      title: 'Total Amount',
                      value: '\$${cart.totalPrice.toStringAsFixed(2)}',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Order Number
                    _buildDetailRow(
                      icon: Icons.confirmation_number,
                      title: 'Order Number',
                      value: orderNumber.isNotEmpty ? orderNumber : _generateOrderNumber(),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Estimated Time
                    _buildDetailRow(
                      icon: Icons.access_time,
                      title: 'Estimated Delivery',
                      value: '25-35 mins',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              Column(
                children: [
                  // Track Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                       Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RiderTrackingPage(
      riderLat: 24.141970995333942,
      riderLng: 90.6950284241064,
      orderNumber: "ff",
      restaurantName: "ff",
    ),
  ),
);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Track Your Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.orange),
                      ),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Thank You Message
              Text(
                'Thank you for your order!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    return 'ORD${now.millisecondsSinceEpoch}'.substring(0, 10);
  }
}