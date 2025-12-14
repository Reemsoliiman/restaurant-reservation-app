import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/firestore_service.dart';
import '../cubits/categories/categories_cubit.dart';
import '../cubits/categories/categories_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoriesCubit(
        firestoreService: FirestoreService(),
      )..loadCategories(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _add() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await context.read<CategoriesCubit>().addCategory(name);
    _nameController.clear();
  }

  void _remove(String id) async {
    await context.read<CategoriesCubit>().removeCategory(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Category name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _add, child: const Text('Add'))
                  ],
                ),
                const SizedBox(height: 12),
                if (state is CategoriesError)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: _buildCategoriesList(state),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesList(CategoriesState state) {
    if (state is CategoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is CategoriesLoaded) {
      final categories = state.categories;
      if (categories.isEmpty) {
        return const Center(child: Text('No categories yet'));
      }
      
      return ListView.builder(
        itemCount: categories.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(categories[i].name),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _remove(categories[i].id),
          ),
        ),
      );
    }
    
    return const Center(child: Text('Failed to load categories'));
  }
}
