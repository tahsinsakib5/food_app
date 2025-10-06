
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_app/Authication/aaaaaauthcheck_page.dart';
import 'package:food_app/screan/resturent_details_page.dart';
import 'package:food_app/widget/cart.dart';


class HomePage extends StatelessWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,

        leading: IconButton(onPressed: () {
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthCheckPage()));
        }, icon:Icon(Icons.arrow_back_ios)),
      ),
  
      body: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ALL RESTURENTS",
              style: Theme.of(context).textTheme.titleMedium,
            ),
      
       
          
            SizedBox(
              height: 10,
            ),
            // Firebase data stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('restaurants')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
      
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
      
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No restaurants found'));
                  }
      
                  final restaurants = snapshot.data!.docs;
      
                  return ListView.builder(
                    itemCount: restaurants.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index].data() as Map<String, dynamic>? ?? {};
                      final restaurantId = restaurants[index].id;
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => RestaurantDetailsPage(
                              restaurant: restaurant,
                             restaurantId: "$restaurantId",
      
                             
                            ),
                          ));
      
                          print("Restaurant ID: $restaurantId");
                        },
                        child: RestaurantCard(shop:restaurant)
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}