import 'package:flutter/material.dart';
import 'package:food_app/firebase_options.dart';
import 'package:food_app/screan/first_page.dart';
import 'package:food_app/screan/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_app/screan/resturent_details_page.dart';

import 'package:provider/provider.dart';   
Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(  
    
    
       MultiProvider(
        providers: [
           ChangeNotifierProvider(create: (_) => CartProvider()),
        
          
        ],
        child: MyApp(),
      ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
       
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Firstpage(restaurantName: 'My Restaurant',)
      
    
    );
  }
}

