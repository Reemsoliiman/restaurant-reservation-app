import 'package:equatable/equatable.dart';

abstract class EditRestaurantState extends Equatable {
  const EditRestaurantState();

  @override
  List<Object?> get props => [];
}

class EditRestaurantInitial extends EditRestaurantState {
  const EditRestaurantInitial();
}

class EditRestaurantLoading extends EditRestaurantState {
  const EditRestaurantLoading();
}

class EditRestaurantSuccess extends EditRestaurantState {
  const EditRestaurantSuccess();

  @override
  List<Object?> get props => [];
}

class EditRestaurantError extends EditRestaurantState {
  final String message;

  const EditRestaurantError(this.message);

  @override
  List<Object?> get props => [message];
}
