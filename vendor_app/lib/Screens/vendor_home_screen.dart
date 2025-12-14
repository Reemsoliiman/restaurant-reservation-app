import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/vendor_restaurants/vendor_restaurants_cubit.dart';
import '../cubits/vendor_restaurants/vendor_restaurants_state.dart';
import '../cubits/vendor_notifications/vendor_notifications_cubit.dart';
import '../cubits/vendor_notifications/vendor_notifications_state.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  late VendorNotificationsCubit _notificationsCubit;

  @override
  void initState() {
    super.initState();
    _notificationsCubit = VendorNotificationsCubit();
    _notificationsCubit.startListening();
  }

  @override
  void dispose() {
    _notificationsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VendorNotificationsCubit, VendorNotificationsState>(
      bloc: _notificationsCubit,
      listener: (context, state) {
        if (state is VendorNotificationReceived) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          BlocBuilder<VendorRestaurantsCubit, VendorRestaurantsState>(
            builder: (context, state) {
              if (state is VendorRestaurantsLoaded) {
                return IconButton(
                  icon: Icon(
                    state.showOnlyMyRestaurants
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                  ),
                  tooltip: state.showOnlyMyRestaurants
                      ? 'Show all restaurants'
                      : 'Show only my restaurants',
                  onPressed: () {
                    context.read<VendorRestaurantsCubit>().toggleFilter();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.of(context).pushNamed('/categories'),
          ),
        ],
      ),
      body: BlocBuilder<VendorRestaurantsCubit, VendorRestaurantsState>(
        builder: (context, state) {
          if (state is VendorRestaurantsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VendorRestaurantsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is VendorRestaurantsLoaded) {
            final restaurants = state.filteredRestaurants;

            if (restaurants.isEmpty) {
              return Center(
                child: Text(
                  state.showOnlyMyRestaurants
                      ? 'You have no restaurants yet'
                      : 'No restaurants available',
                ),
              );
            }

            // Ensure we have active reservation listeners for these restaurants
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _notificationsCubit.updateRestaurantSubscriptions(restaurants),
            );

            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (ctx, i) {
                final r = restaurants[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: r.imageUrl != null && r.imageUrl!.isNotEmpty
                        ? (r.imageUrl!.startsWith('http')
                              ? Image.network(
                                  r.imageUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.restaurant),
                                )
                              : Image.memory(
                                  base64Decode(r.imageUrl!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.restaurant),
                                ))
                        : const Icon(Icons.restaurant),
                    title: Text(r.name),
                    subtitle: Text(r.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.event_note),
                      tooltip: 'View bookings',
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed('/bookings', arguments: r.id),
                    ),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed('/restaurant-details', arguments: r),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/add-restaurant'),
        child: const Icon(Icons.add),
      ),
    ),
    );
  }
}
