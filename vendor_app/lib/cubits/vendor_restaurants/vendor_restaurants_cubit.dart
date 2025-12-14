import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../services/firestore_service.dart';
import '../../services/local_user_service.dart';
import 'vendor_restaurants_state.dart';

class VendorRestaurantsCubit extends Cubit<VendorRestaurantsState> {
  final FirestoreService _firestoreService;
  final LocalUserService _localUserService;
  StreamSubscription? _restaurantsSubscription;

  VendorRestaurantsCubit({
    FirestoreService? firestoreService,
    LocalUserService? localUserService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _localUserService = localUserService ?? LocalUserService(),
       super(const VendorRestaurantsInitial());

  Future<void> loadRestaurants() async {
    try {
      emit(const VendorRestaurantsLoading());

      final vendorId = await _localUserService.getUserId();

      _restaurantsSubscription?.cancel();
      // Load ALL restaurants, not just vendor's own
      _restaurantsSubscription = _firestoreService.restaurantsStream().listen(
        (restaurants) {
          emit(
            VendorRestaurantsLoaded(
              restaurants: restaurants,
              vendorId: vendorId,
              showOnlyMyRestaurants: false,
            ),
          );
        },
        onError: (error) {
          emit(VendorRestaurantsError('Failed to load restaurants: $error'));
        },
      );
    } catch (e) {
      emit(VendorRestaurantsError('Failed to load restaurants: $e'));
    }
  }

  void toggleFilter() {
    final currentState = state;
    if (currentState is VendorRestaurantsLoaded) {
      emit(
        currentState.copyWith(
          showOnlyMyRestaurants: !currentState.showOnlyMyRestaurants,
        ),
      );
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
