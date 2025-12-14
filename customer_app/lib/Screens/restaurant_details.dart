import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Models/table_model.dart';
import '../services/firestore_service.dart';
import '../cubits/restaurant_details/restaurant_details_cubit.dart';
import '../cubits/restaurant_details/restaurant_details_state.dart';
import '../cubits/booking/booking_cubit.dart';
import 'booking_screen.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  static const routeName = '/restaurant-details';
  final String? restaurantId;
  final String? restaurantName;
  final String? vendorId;

  const RestaurantDetailsScreen(
      {super.key, this.restaurantId, this.restaurantName, this.vendorId});

  @override
  Widget build(BuildContext context) {
    final rid = restaurantId;
    if (rid == null) {
      return const Scaffold(
          body: Center(child: Text('No restaurant selected')));
    }

    final firestoreService = FirestoreService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RestaurantDetailsCubit(
            firestoreService: firestoreService,
          )..loadRestaurantDetails(
              restaurantId: rid,
              restaurantName: restaurantName ?? '',
              vendorId: vendorId,
            ),
        ),
        BlocProvider(
          create: (context) => BookingCubit(
            firestoreService: firestoreService,
          ),
        ),
      ],
      child: _RestaurantDetailsView(
        restaurantId: rid,
        restaurantName: restaurantName,
        vendorId: vendorId,
      ),
    );
  }
}

class _RestaurantDetailsView extends StatelessWidget {
  final String restaurantId;
  final String? restaurantName;
  final String? vendorId;

  const _RestaurantDetailsView({
    required this.restaurantId,
    this.restaurantName,
    this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantDetailsCubit, RestaurantDetailsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(restaurantName ?? 'Restaurant'),
          ),
          body: Column(
            children: [
              // Restaurant info section
              if (state is RestaurantDetailsLoaded) _buildRestaurantInfo(state),
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, RestaurantDetailsState state) {
    if (state is RestaurantDetailsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RestaurantDetailsError) {
      return Center(child: Text('Error: ${state.message}'));
    }

    if (state is RestaurantDetailsLoaded) {
      final tables = state.tables;

      if (tables.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_bar, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No tables found',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                    'This restaurant does not have any tables configured yet. Contact the vendor or check Firestore data.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context
                      .read<RestaurantDetailsCubit>()
                      .loadRestaurantDetails(
                        restaurantId: restaurantId,
                        restaurantName: restaurantName ?? '',
                        vendorId: vendorId,
                      ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: tables.length,
          itemBuilder: (ctx, i) {
            final t = tables[i];
            return _buildTableCard(
              context: context,
              table: t,
              state: state,
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRestaurantInfo(RestaurantDetailsLoaded state) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.imageUrl != null && state.imageUrl!.isNotEmpty)
            _buildRestaurantImage(state.imageUrl!),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.category != null && state.category!.isNotEmpty)
                  Chip(
                    label: Text(state.category!),
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                if (state.category != null && state.category!.isNotEmpty)
                  const SizedBox(height: 8),
                if (state.description != null && state.description!.isNotEmpty)
                  Text(
                    state.description!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                if (state.description != null && state.description!.isNotEmpty)
                  const SizedBox(height: 12),
                // Display restaurant details
                if (state.numberOfTables != null)
                  _buildInfoRow(
                    Icons.table_restaurant,
                    'Tables',
                    '${state.numberOfTables} tables',
                  ),
                if (state.timeSlots.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    'Time Slots',
                    state.timeSlots.join(', '),
                  ),
                ],
                if (state.location != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    'Sales Point',
                    'Lat: ${state.location.latitude.toStringAsFixed(4)}, Lng: ${state.location.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantImage(String imageUrl) {
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
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: const Icon(Icons.broken_image, size: 64),
        );
      }
    }

    // It's a network URL
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 64),
          );
        },
      ),
    );
  }

  Widget _buildTableCard({
    required BuildContext context,
    required TableModel table,
    required RestaurantDetailsLoaded state,
  }) {
    // Get actual number of seats for this table
    final actualSeats = state.seatsPerTable.isNotEmpty &&
            table.tableIndex > 0 &&
            table.tableIndex <= state.seatsPerTable.length
        ? state.seatsPerTable[table.tableIndex - 1]
        : table.seats;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookingScreen(
            restaurantId: restaurantId,
            restaurantName: restaurantName ?? '',
            table: table,
            vendorId: vendorId,
            maxSeatsForTable: actualSeats,
            allTimeSlots: state.timeSlots.isNotEmpty
                ? state.timeSlots
                : ['10:00', '10:30', '11:00', '11:30', '12:00'],
          ),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Table with chairs based on actual seats
            Center(
              child: _buildTableWithChairs(actualSeats),
            ),
            // Table number overlay
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[400]!, width: 1),
                  ),
                  child: Text(
                    '${table.tableIndex}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableWithChairs(int seats) {
    if (seats == 2) {
      // 2 seats: left and right only
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left chair
          Container(
            width: 12,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          // Table center
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          // Right chair
          Container(
            width: 12,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    } else if (seats == 4) {
      // 4 seats: top, bottom, left, right
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top chair
          Container(
            width: 25,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 3),
          // Middle row with table
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left chair
              Container(
                width: 10,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 3),
              // Table center
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 3),
              // Right chair
              Container(
                width: 10,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Bottom chair
          Container(
            width: 25,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      );
    } else {
      // 6 seats: 2 on each side (top, bottom) and 1 on left and right
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top 2 chairs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Middle row with table
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left chair
              Container(
                width: 10,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 3),
              // Table center (larger for 6 seats)
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 3),
              // Right chair
              Container(
                width: 10,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Bottom 2 chairs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}
