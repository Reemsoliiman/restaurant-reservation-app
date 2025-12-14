import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './Screens/add_restaurant_screen.dart';
import './Screens/vendor_home_screen.dart';
import './Screens/categories_screen.dart';
import './Screens/bookings_screen.dart';
import './Screens/notifications_screen.dart';
import './Screens/restaurant_detail_screen.dart';
import './Screens/edit_restaurant_screen.dart';
import './firebase_options.dart';
import 'services/fcm_service.dart';
import './cubits/vendor_restaurants/vendor_restaurants_cubit.dart';
import './services/firestore_service.dart';
import './services/local_user_service.dart';
import './models/restaurant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // initialize FCM and register token
  final fcm = FCMService();
  await fcm.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VendorRestaurantsCubit>(
          create: (context) => VendorRestaurantsCubit(
            firestoreService: FirestoreService(),
            localUserService: LocalUserService(),
          )..loadRestaurants(),
        ),
      ],
      child: MaterialApp(
        title: 'Vendor App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: const Color(0xFFFFA55C),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFA55C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA55C),
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFFFA55C),
            foregroundColor: Colors.white,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFFFA55C).withOpacity(0.1),
            selectedColor: const Color(0xFFFFA55C),
            labelStyle: const TextStyle(color: Colors.black87),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFFFFA55C),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFA55C),
            primary: const Color(0xFFFFA55C),
          ),
        ),
        home: const VendorHomeScreen(),
        routes: {
          '/add-restaurant': (context) => const AddRestaurantScreen(),
          '/categories': (context) => const CategoriesScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/bookings': (context) => const BookingsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/restaurant-details') {
            final restaurant = settings.arguments as Restaurant;
            return MaterialPageRoute(
              builder: (context) =>
                  RestaurantDetailScreen(restaurant: restaurant),
            );
          }
          if (settings.name == '/edit-restaurant') {
            final restaurant = settings.arguments as Restaurant;
            return MaterialPageRoute(
              builder: (context) =>
                  EditRestaurantScreen(restaurant: restaurant),
            );
          }
          return null;
        },
      ),
    );
  }
}