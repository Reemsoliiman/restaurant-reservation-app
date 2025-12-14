import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/local_user_service.dart';
import 'edit_restaurant_screen.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  Future<bool> _isOwner() async {
    final localUser = LocalUserService();
    final vendorId = await localUser.getUserId();
    return restaurant.vendorId == vendorId;
  }

  Widget _buildImage() {
    if (restaurant.imageUrl == null || restaurant.imageUrl!.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Icon(Icons.restaurant, size: 80),
      );
    }

    // Check if it's a base64 string or URL
    if (restaurant.imageUrl!.startsWith('http')) {
      // It's a URL (legacy format)
      return Image.network(
        restaurant.imageUrl!,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            color: Colors.grey[300],
            child: const Icon(Icons.restaurant, size: 80),
          );
        },
      );
    } else {
      // It's a base64 string
      try {
        return Image.memory(
          base64Decode(restaurant.imageUrl!),
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 250,
              color: Colors.grey[300],
              child: const Icon(Icons.restaurant, size: 80),
            );
          },
        );
      } catch (e) {
        return Container(
          height: 250,
          color: Colors.grey[300],
          child: const Icon(Icons.restaurant, size: 80),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          FutureBuilder<bool>(
            future: _isOwner(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Restaurant',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditRestaurantScreen(restaurant: restaurant),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    avatar: const Icon(Icons.category, size: 18),
                    label: Text(
                      restaurant.category,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    context,
                    icon: Icons.table_restaurant,
                    title: 'Tables',
                    value: '${restaurant.numberOfTables} tables',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.event_seat,
                    title: 'Seats Configuration',
                    value: restaurant.seatsPerTable.isNotEmpty
                        ? restaurant.seatsPerTable
                              .asMap()
                              .entries
                              .map(
                                (e) => 'Table ${e.key + 1}: ${e.value} seats',
                              )
                              .join('\n')
                        : 'No seats configured',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.access_time,
                    title: 'Available Time Slots',
                    value: restaurant.timeSlots.isNotEmpty
                        ? restaurant.timeSlots.join(', ')
                        : 'No time slots configured',
                  ),
                  if (restaurant.location != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on,
                      title: 'Location',
                      value:
                          'Lat: ${restaurant.location!.latitude.toStringAsFixed(4)}, Lng: ${restaurant.location!.longitude.toStringAsFixed(4)}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  FutureBuilder<bool>(
                    future: _isOwner(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditRestaurantScreen(
                                    restaurant: restaurant,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Restaurant'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
