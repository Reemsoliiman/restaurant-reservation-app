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
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (v) => context
                      .read<RestaurantsCubit>()
                      .updateSearchQuery(v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: state.selectedCategory == null,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      labelStyle: const TextStyle(color: Colors.black),
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
                          backgroundColor: Colors.white,
                          side: BorderSide(
                              color: state.selectedCategory == c
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300),
                          labelStyle: TextStyle(
                            color: state.selectedCategory == c
                                ? Colors.white
                                : Colors.black,
                          ),
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
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (ctx, i) {
                      final r = filteredRestaurants[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RestaurantDetailsScreen(
                              restaurantId: r.id,
                              restaurantName: r.name,
                              vendorId: r.vendorId,
                            ),
                          ));
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Restaurant Image
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: _buildRestaurantImage(r.imageUrl),
                                ),
                              ),
                              // Restaurant Name and Category
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      r.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
        color: Colors.grey[300],
        child: const Icon(Icons.restaurant, size: 48),
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
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 48),
        );
      }
    }

    return Image.network(
      imageUrl,
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
          child: const Icon(Icons.broken_image, size: 48),
        );
      },
    );
  }
}