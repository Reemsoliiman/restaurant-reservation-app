import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../services/firestore_service.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _categoriesSubscription;

  CategoriesCubit({required FirestoreService firestoreService})
      : _firestoreService = firestoreService,
        super(const CategoriesInitial());

  void loadCategories() {
    emit(const CategoriesLoading());
    
    _categoriesSubscription?.cancel();
    _categoriesSubscription = _firestoreService.categoriesStream().listen(
      (categories) {
        emit(CategoriesLoaded(categories));
      },
      onError: (error) {
        emit(CategoriesError('Failed to load categories: ${error.toString()}'));
      },
    );
  }

  Future<void> addCategory(String name) async {
    try {
      await _firestoreService.addCategory(name);
      // Categories will be updated via stream
    } catch (e) {
      emit(CategoriesError('Failed to add category: ${e.toString()}'));
    }
  }

  Future<void> removeCategory(String id) async {
    try {
      await _firestoreService.removeCategory(id);
      // Categories will be updated via stream
    } catch (e) {
      emit(CategoriesError('Failed to remove category: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
