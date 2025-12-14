import 'package:bloc/bloc.dart';
import '../../models/restaurant.dart';
import '../../services/firestore_service.dart';
import 'edit_restaurant_state.dart';

class EditRestaurantCubit extends Cubit<EditRestaurantState> {
  final FirestoreService _firestoreService;

  EditRestaurantCubit({required FirestoreService firestoreService})
      : _firestoreService = firestoreService,
        super(const EditRestaurantInitial());

  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      emit(const EditRestaurantLoading());
      await _firestoreService.updateRestaurant(restaurant);
      emit(const EditRestaurantSuccess());
    } catch (e) {
      emit(EditRestaurantError('Failed to update restaurant: ${e.toString()}'));
    }
  }

  void reset() {
    emit(const EditRestaurantInitial());
  }
}
