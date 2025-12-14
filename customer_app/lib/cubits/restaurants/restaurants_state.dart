import 'package:equatable/equatable.dart';
import '../../Models/restaurant.dart';

abstract class RestaurantsState extends Equatable {
  const RestaurantsState();

  @override
  List<Object?> get props => [];
}

class RestaurantsInitial extends RestaurantsState {
  const RestaurantsInitial();
}

class RestaurantsLoading extends RestaurantsState {
  const RestaurantsLoading();
}

class RestaurantsLoaded extends RestaurantsState {
  final List<Restaurant> restaurants;
  final String searchQuery;
  final String? selectedCategory;

  const RestaurantsLoaded({
    required this.restaurants,
    this.searchQuery = '',
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [restaurants, searchQuery, selectedCategory];

  List<Restaurant> get filteredRestaurants {
    var filtered = restaurants;

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (r) => r.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      filtered = filtered.where((r) => r.category == selectedCategory).toList();
    }

    return filtered;
  }

  RestaurantsLoaded copyWith({
    List<Restaurant>? restaurants,
    String? searchQuery,
    Object? selectedCategory = _undefined,
  }) {
    return RestaurantsLoaded(
      restaurants: restaurants ?? this.restaurants,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory == _undefined 
          ? this.selectedCategory 
          : selectedCategory as String?,
    );
  }
}

// Sentinel value for distinguishing between null being passed vs not passed
const _undefined = Object();

class RestaurantsError extends RestaurantsState {
  final String message;

  const RestaurantsError(this.message);

  @override
  List<Object?> get props => [message];
}
