// screens/shop/food_details_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodDetailsPage extends StatefulWidget {
  final String restaurantId;
  final String foodId;
  final Map<String, dynamic>? initialData;

  const FoodDetailsPage({
    Key? key,
    required this.restaurantId,
    required this.foodId,
    this.initialData, 
  }) : super(key: key);

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  Map<String, dynamic>? _foodData;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;

  // Temporary review input fields
  final TextEditingController _reviewCommentController = TextEditingController();
  double _reviewRating = 5.0;
  final TextEditingController _reviewUserNameController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.restaurantId.isEmpty || widget.foodId.isEmpty) {
      setState(() {
        _error = 'Invalid restaurant or food ID';
        _isLoading = false;
      });
      return;
    }
    
    _fetchFoodData();
    _fetchReviews();
  }

  @override
  void dispose() {
    _reviewCommentController.dispose();
    _reviewUserNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchFoodData() async {
    try {
      final DocumentSnapshot foodDoc = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('foodItems')
          .doc(widget.foodId)
          .get();

      if (foodDoc.exists) {
        setState(() {
          _foodData = {
            'id': foodDoc.id,
            ...foodDoc.data() as Map<String, dynamic>
          };
        });
      } else {
        setState(() {
          _error = 'Food item not found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load food data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final QuerySnapshot reviewsSnapshot = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('foodItems')
          .doc(widget.foodId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _reviews = reviewsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_reviewCommentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('foodItems')
          .doc(widget.foodId)
          .collection('reviews')
          .add({
            'userName': _reviewUserNameController.text.isNotEmpty 
                ? _reviewUserNameController.text 
                : 'Anonymous',
            'rating': _reviewRating,
            'comment': _reviewCommentController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _reviewCommentController.clear();
      _reviewUserNameController.clear();
      _reviewRating = 5.0;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold(0.0, (sum, review) => sum + (review['rating'] ?? 0));
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Food Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const _LoadingState()
          : _error != null
              ? _ErrorState(error: _error!)
              : _FoodDetailsContent(
                  foodData: _foodData!,
                  reviews: _reviews,
                  averageRating: _averageRating,
                  reviewCommentController: _reviewCommentController,
                  reviewUserNameController: _reviewUserNameController,
                  reviewRating: _reviewRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _reviewRating = rating;
                    });
                  },
                  onSubmitReview: _submitReview,
                  isSubmittingReview: _isSubmittingReview,
                ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading food details...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDetailsContent extends StatelessWidget {
  final Map<String, dynamic> foodData;
  final List<Map<String, dynamic>> reviews;
  final double averageRating;
  final TextEditingController reviewCommentController;
  final TextEditingController reviewUserNameController;
  final double reviewRating;
  final Function(double) onRatingChanged;
  final VoidCallback onSubmitReview;
  final bool isSubmittingReview;

  const _FoodDetailsContent({
    required this.foodData,
    required this.reviews,
    required this.averageRating,
    required this.reviewCommentController,
    required this.reviewUserNameController,
    required this.reviewRating,
    required this.onRatingChanged,
    required this.onSubmitReview,
    required this.isSubmittingReview,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Food header image - full width
          _FoodImageHeader(foodData: foodData),
          
          // Food basic info - full width with slight padding
          _FoodBasicInfo(
            foodData: foodData,
            averageRating: averageRating,
            reviewCount: reviews.length,
          ),
          
          // Food details section - full width
          _FoodDetailsSection(foodData: foodData),
          
          // Reviews section - full width
          _ReviewsSection(
            reviews: reviews,
            reviewCommentController: reviewCommentController,
            reviewUserNameController: reviewUserNameController,
            reviewRating: reviewRating,
            onRatingChanged: onRatingChanged,
            onSubmitReview: onSubmitReview,
            isSubmittingReview: isSubmittingReview,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FoodImageHeader extends StatelessWidget {
  final Map<String, dynamic> foodData;

  const _FoodImageHeader({required this.foodData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        image: foodData['imageUrl'] != null
            ? DecorationImage(
                image: NetworkImage(foodData['imageUrl']!),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey[100],
      ),
      child: foodData['imageUrl'] == null
          ? Center(
              child: Icon(
                Icons.fastfood,
                size: 80,
                color: Colors.grey[400],
              ),
            )
          : null,
    );
  }
}

class _FoodBasicInfo extends StatelessWidget {
  final Map<String, dynamic> foodData;
  final double averageRating;
  final int reviewCount;

  const _FoodBasicInfo({
    required this.foodData,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            foodData['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber[700],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($reviewCount)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '\$${(foodData['price'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (foodData['description'] != null)
            Text(
              foodData['description']!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodDetailsSection extends StatelessWidget {
  final Map<String, dynamic> foodData;

  const _FoodDetailsSection({required this.foodData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Color(0xFFF0F0F0),
            width: 12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Food Information',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          _DetailItem(
            icon: Icons.category_rounded,
            title: 'Category',
            value: foodData['category'] ?? 'Not specified',
          ),
          const SizedBox(height: 20),
          _DetailItem(
            icon: Icons.restaurant_rounded,
            title: 'Food Type',
            value: foodData['isVeg'] == true ? 'Vegetarian' : 'Non-Vegetarian',
            valueColor: foodData['isVeg'] == true ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 20),
          _DetailItem(
            icon: Icons.attach_money_rounded,
            title: 'Price',
            value: '\$${(foodData['price'] ?? 0.0).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 20),
          _DetailItem(
            icon: Icons.inventory_2_rounded,
            title: 'Availability',
            value: foodData['isEnabled'] == true ? 'Available' : 'Not Available',
            valueColor: foodData['isEnabled'] == true ? Colors.green : Colors.red,
          ),
          if (foodData['createdAt'] != null) ...[
            const SizedBox(height: 20),
            _DetailItem(
              icon: Icons.calendar_today_rounded,
              title: 'Added Date',
              value: foodData['createdAt'] is Timestamp
                  ? DateFormat('MMMM dd, yyyy').format(
                      (foodData['createdAt'] as Timestamp).toDate())
                  : 'Date not available',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final TextEditingController reviewCommentController;
  final TextEditingController reviewUserNameController;
  final double reviewRating;
  final Function(double) onRatingChanged;
  final VoidCallback onSubmitReview;
  final bool isSubmittingReview;

  const _ReviewsSection({
    required this.reviews,
    required this.reviewCommentController,
    required this.reviewUserNameController,
    required this.reviewRating,
    required this.onRatingChanged,
    required this.onSubmitReview,
    required this.isSubmittingReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Reviews',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Review input section
          _ReviewInputSection(
            commentController: reviewCommentController,
            userNameController: reviewUserNameController,
            rating: reviewRating,
            onRatingChanged: onRatingChanged,
            onSubmitReview: onSubmitReview,
            isSubmitting: isSubmittingReview,
          ),
          
          const SizedBox(height: 32),
          
          // Reviews list
          if (reviews.isNotEmpty) ...[
            Text(
              'All Reviews (${reviews.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: reviews.map((review) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ReviewCard(review: review),
                )
              ).toList(),
            ),
          ] else
            const _EmptyReviewsState(),
        ],
      ),
    );
  }
}

class _ReviewInputSection extends StatelessWidget {
  final TextEditingController commentController;
  final TextEditingController userNameController;
  final double rating;
  final Function(double) onRatingChanged;
  final VoidCallback onSubmitReview;
  final bool isSubmitting;

  const _ReviewInputSection({
    required this.commentController,
    required this.userNameController,
    required this.rating,
    required this.onRatingChanged,
    required this.onSubmitReview,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Your Experience',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: userNameController,
            decoration: InputDecoration(
              labelText: 'Your Name (optional)',
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Rating',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => onRatingChanged((index + 1).toDouble()),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.star_rounded,
                          size: 36,
                          color: index < rating 
                              ? Colors.amber
                              : Colors.grey[300],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: commentController,
            decoration: InputDecoration(
              labelText: 'Your Review',
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.orange.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rating stars
              ...List.generate(5, (starIndex) {
                return Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: starIndex < (review['rating'] ?? 0)
                      ? Colors.amber
                      : Colors.grey[300],
                );
              }),
              const Spacer(),
              Text(
                review['createdAt'] is Timestamp
                  ? DateFormat('MMM dd, yyyy').format(
                      (review['createdAt'] as Timestamp).toDate())
                  : 'Date not available',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (review['comment'] != null && (review['comment'] as String).isNotEmpty)
            Text(
              review['comment'].toString(),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),
          if (review['userName'] != null)
            Text(
              '- ${review['userName']}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyReviewsState extends StatelessWidget {
  const _EmptyReviewsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.reviews_outlined,
            size: 70,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your experience!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}