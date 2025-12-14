import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'restaurant_details.dart';
import 'login_screen.dart';
import 'my_bookings.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/restaurants/restaurants_cubit.dart';
import '../cubits/restaurants/restaurants_state.dart';

class RestaurantsListScreen extends StatelessWidget {
  static const routeName = '/restaurants';
  const RestaurantsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RestaurantsCubit>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.of(context).pushNamed(MyBookingsScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthCubit>().signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RestaurantsCubit, RestaurantsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration:
                      const InputDecoration(labelText: 'Search by name'),
                  onChanged: (v) => context
                      .read<RestaurantsCubit>()
                      .updateSearchQuery(v.trim()),
                ),
              ),
              if (state is RestaurantsLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (state is RestaurantsError)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<RestaurantsCubit>().refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is RestaurantsLoaded)
                _buildRestaurantsList(context, state)
              else
                const Expanded(child: Center(child: Text('Loading...'))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRestaurantsList(BuildContext context, RestaurantsLoaded state) {
    final filteredRestaurants = state.filteredRestaurants;

    if (state.restaurants.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_menu, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No restaurants available',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                    'There are currently no restaurants in the database.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<RestaurantsCubit>().refresh(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Get unique categories from restaurants
    final categories = state.restaurants
        .map((r) => r.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return Expanded(
      child: Column(
        children: [
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: state.selectedCategory == null,
                      onSelected: (_) => context
                          .read<RestaurantsCubit>()
                          .updateCategoryFilter(null),
                    ),
                  ),
                  ...categories.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: state.selectedCategory == c,
                          onSelected: (_) => context
                              .read<RestaurantsCubit>()
                              .updateCategoryFilter(c),
                        ),
                      ))
                ],
              ),
            ),
          Expanded(
            child: filteredRestaurants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No restaurants match your search'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context
                                .read<RestaurantsCubit>()
                                .updateSearchQuery('');
                            context
                                .read<RestaurantsCubit>()
                                .updateCategoryFilter(null);
                          },
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (ctx, i) {
                      final r = filteredRestaurants[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: _buildRestaurantImage(r.imageUrl),
                          title: Text(
                            r.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(r.category),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => RestaurantDetailsScreen(
                                restaurantId: r.id,
                                restaurantName: r.name,
                                vendorId: r.vendorId,
                              ),
                            ));
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildRestaurantImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.restaurant, size: 32),
      );
    }

    // Check if it's a base64 string
    if (imageUrl.startsWith('data:image') ||
        imageUrl.startsWith('/9j/') ||
        imageUrl.startsWith('iVBOR')) {
      try {
        // Remove data URI prefix if present
        String base64String = imageUrl;
        if (imageUrl.contains('base64,')) {
          base64String = imageUrl.split('base64,')[1];
        }

        final bytes = base64Decode(base64String);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.broken_image, size: 32),
        );
      }
    }

    // It's a network URL
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 32),
            );
          },
        ),
      ),
    );
  }
}
