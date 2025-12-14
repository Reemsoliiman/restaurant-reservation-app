import 'package:equatable/equatable.dart';

abstract class AddRestaurantState extends Equatable {
  const AddRestaurantState();

  @override
  List<Object?> get props => [];
}

class AddRestaurantInitial extends AddRestaurantState {
  const AddRestaurantInitial();
}

class AddRestaurantLoading extends AddRestaurantState {
  const AddRestaurantLoading();
}

class AddRestaurantSuccess extends AddRestaurantState {
  final String message;

  const AddRestaurantSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AddRestaurantError extends AddRestaurantState {
  final String message;

  const AddRestaurantError(this.message);

  @override
  List<Object?> get props => [message];
}
