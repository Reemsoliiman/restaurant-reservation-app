import 'dart:io';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant.dart';
import '../../services/firestore_service.dart';
import '../../services/local_user_service.dart';
import 'add_restaurant_state.dart';

class AddRestaurantCubit extends Cubit<AddRestaurantState> {
  final FirestoreService _firestoreService;
  final LocalUserService _localUserService;

  AddRestaurantCubit({
    FirestoreService? firestoreService,
    LocalUserService? localUserService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _localUserService = localUserService ?? LocalUserService(),
       super(const AddRestaurantInitial());

  Future<void> addRestaurant({
    required String name,
    required String description,
    required String categoryId,
    required String categoryName,
    required int numberOfTables,
    required List<int> seatsPerTable,
    required List<String> timeSlots,
    File? imageFile,
    GeoPoint? location,
  }) async {
    try {
      emit(const AddRestaurantLoading());

      String? imageUrl;
      if (imageFile != null) {
        try {
          // Convert image to base64 string (same as customer app)
          final bytes = await imageFile.readAsBytes();
          final base64String = base64Encode(bytes);

          // Check if base64 string is too large (Firestore has 1MB limit per document)
          final sizeInKB = (base64String.length / 1024).round();

          if (sizeInKB > 800) {
            emit(
              AddRestaurantError(
                'Image is too large ($sizeInKB KB). Please choose a smaller image.',
              ),
            );
            return;
          }

          imageUrl = base64String;
        } catch (e) {
          emit(AddRestaurantError('Failed to process image: $e'));
          return;
        }
      }

      final vendorId = await _localUserService.getUserId();

      final restaurant = Restaurant(
        name: name,
        description: description,
        imageUrl: imageUrl,
        categoryId: categoryId,
        category: categoryName,
        numberOfTables: numberOfTables,
        seatsPerTable: seatsPerTable,
        timeSlots: timeSlots,
        location: location,
        vendorId: vendorId,
      );

      await _firestoreService.addRestaurant(restaurant);

      emit(const AddRestaurantSuccess('Restaurant added successfully!'));
    } catch (e) {
      emit(AddRestaurantError('Failed to add restaurant: $e'));
    }
  }

  void reset() {
    emit(const AddRestaurantInitial());
  }
}
