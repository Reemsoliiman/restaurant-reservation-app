import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../Models/restaurant.dart';
import '../../services/firestore_service.dart';
import 'restaurants_state.dart';

class RestaurantsCubit extends Cubit<RestaurantsState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _restaurantsSubscription;

  RestaurantsCubit({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        super(const RestaurantsInitial());

  void loadRestaurants() {
    emit(const RestaurantsLoading());

    _restaurantsSubscription?.cancel();
    _restaurantsSubscription = _firestoreService.streamRestaurants().listen(
      (snapshot) {
        try {
          final restaurants = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Restaurant.fromMap(doc.id, data);
          }).toList();

          emit(RestaurantsLoaded(restaurants: restaurants));
        } catch (e) {
          emit(RestaurantsError('Failed to load restaurants: $e'));
        }
      },
      onError: (error) {
        emit(RestaurantsError('Failed to load restaurants: $error'));
      },
    );
  }

  void updateSearchQuery(String query) {
    final currentState = state;
    if (currentState is RestaurantsLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void updateCategoryFilter(String? category) {
    final currentState = state;
    if (currentState is RestaurantsLoaded) {
      emit(currentState.copyWith(selectedCategory: category));
    }
  }

  void refresh() {
    loadRestaurants();
  }

  @override
  Future<void> close() {
    _restaurantsSubscription?.cancel();
    return super.close();
  }
}
