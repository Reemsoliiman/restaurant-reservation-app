import 'package:equatable/equatable.dart';
import '../../models/restaurant.dart';

abstract class VendorRestaurantsState extends Equatable {
  const VendorRestaurantsState();

  @override
  List<Object?> get props => [];
}

class VendorRestaurantsInitial extends VendorRestaurantsState {
  const VendorRestaurantsInitial();
}

class VendorRestaurantsLoading extends VendorRestaurantsState {
  const VendorRestaurantsLoading();
}

class VendorRestaurantsLoaded extends VendorRestaurantsState {
  final List<Restaurant> restaurants;
  final bool showOnlyMyRestaurants;
  final String vendorId;

  const VendorRestaurantsLoaded({
    required this.restaurants,
    this.showOnlyMyRestaurants = false,
    required this.vendorId,
  });

  @override
  List<Object?> get props => [restaurants, showOnlyMyRestaurants, vendorId];

  List<Restaurant> get filteredRestaurants {
    if (showOnlyMyRestaurants) {
      return restaurants.where((r) => r.vendorId == vendorId).toList();
    }
    return restaurants;
  }

  VendorRestaurantsLoaded copyWith({
    List<Restaurant>? restaurants,
    bool? showOnlyMyRestaurants,
    String? vendorId,
  }) {
    return VendorRestaurantsLoaded(
      restaurants: restaurants ?? this.restaurants,
      showOnlyMyRestaurants:
          showOnlyMyRestaurants ?? this.showOnlyMyRestaurants,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}

class VendorRestaurantsError extends VendorRestaurantsState {
  final String message;

  const VendorRestaurantsError(this.message);

  @override
  List<Object?> get props => [message];
}
