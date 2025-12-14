import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './Screens/login_screen.dart';
import './Screens/register_screen.dart';
import './Screens/restaurants_list.dart';
import './Screens/restaurant_details.dart';
import './firebase_options.dart';
import './Screens/my_bookings.dart';
import './Screens/password_reset_screen.dart';
import './cubits/auth/auth_cubit.dart';
import './cubits/restaurants/restaurants_cubit.dart';
import './services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
        BlocProvider<RestaurantsCubit>(
          create: (context) => RestaurantsCubit(
            firestoreService: FirestoreService(),
          )..loadRestaurants(),
        ),
      ],
      child: MaterialApp(
        title: 'Restaurant Reservations',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasData) {
              return const RestaurantsListScreen();
            }
            return const LoginScreen();
          },
        ),
        routes: {
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          '/password-reset': (context) => const PasswordResetScreen(),
          MyBookingsScreen.routeName: (context) => const MyBookingsScreen(),
          RestaurantsListScreen.routeName: (context) =>
              const RestaurantsListScreen(),
          RestaurantDetailsScreen.routeName: (context) =>
              const RestaurantDetailsScreen(),
        },
      ),
    );
  }
}
