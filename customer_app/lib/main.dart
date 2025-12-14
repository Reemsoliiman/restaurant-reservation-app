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

// Define your app colors here
class AppColors {
  static const Color primaryDark = Color.fromRGBO(54, 63, 99, 1);
  static const Color accentOrange = Color.fromARGB(255, 255, 115, 0);
  static const Color accentOrangeFaded = Color.fromARGB(200, 255, 115, 0);
  static const Color accentOrangeLight = Color.fromARGB(150, 255, 115, 0);
  static const Color white = Colors.white;
  static const Color textLight = Color.fromRGBO(249, 251, 253, 1);
  static const Color errorRed = Colors.red;
  static const Color greyBorder = Color.fromRGBO(54, 63, 99, 1);
}

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
          useMaterial3: true,
          primaryColor: AppColors.accentOrange,
          scaffoldBackgroundColor: AppColors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: AppColors.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentOrange,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppColors.greyBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppColors.accentOrangeFaded,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppColors.errorRed,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppColors.errorRed,
                width: 1,
              ),
            ),
          ),
          chipTheme: const ChipThemeData(
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.accentOrangeLight,
            labelStyle: TextStyle(color: Colors.white),
            secondaryLabelStyle: TextStyle(color: Colors.white),
          ),
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