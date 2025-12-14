import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/firestore_service.dart';
import '../models/booking.dart';
import '../cubits/bookings_management/bookings_management_cubit.dart';
import '../cubits/bookings_management/bookings_management_state.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurantId = ModalRoute.of(context)?.settings.arguments as String?;

    if (restaurantId == null) {
      return const Scaffold(
        body: Center(child: Text('No restaurant selected')),
      );
    }

    return BlocProvider(
      create: (context) =>
          BookingsManagementCubit(firestoreService: FirestoreService())
            ..loadBookings(restaurantId),
      child: _BookingsView(restaurantId: restaurantId),
    );
  }
}

class _BookingsView extends StatefulWidget {
  final String restaurantId;

  const _BookingsView({required this.restaurantId});

  @override
  State<_BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<_BookingsView> {
  final List<String> _seenReservationIds = [];

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              booking.status == 'confirmed'
                  ? Icons.check_circle
                  : booking.status == 'pending'
                  ? Icons.pending
                  : Icons.info,
              color: booking.status == 'confirmed'
                  ? Colors.green
                  : booking.status == 'pending'
                  ? Colors.orange
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text('Booking Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                Icons.table_restaurant,
                'Table',
                'Table ${booking.tableIndex}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.event_seat,
                'Seats',
                '${booking.seats} seats',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_today, 'Date', booking.date),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Time Slot', booking.timeSlot),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.info_outline,
                'Status',
                booking.status.toUpperCase(),
                valueColor: booking.status == 'confirmed'
                    ? Colors.green
                    : booking.status == 'pending'
                    ? Colors.orange
                    : Colors.grey,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.schedule,
                'Booked At',
                _formatTimestamp(booking.createdAt),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.restaurant,
                'Restaurant ID',
                booking.restaurantId,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsManagementCubit, BookingsManagementState>(
      builder: (context, state) {
        if (state is BookingsManagementLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bookings')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is BookingsManagementError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bookings')),
            body: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is BookingsManagementLoaded) {
          final restaurant = state.restaurant;
          final reservations = state.bookings;
          final cubit = context.read<BookingsManagementCubit>();

          // detect new reservations and show a snackbar
          if (reservations.isNotEmpty) {
            final newIds = reservations
                .map((r) => r.id)
                .where((id) => !_seenReservationIds.contains(id))
                .toList();
            if (newIds.isNotEmpty) {
              _seenReservationIds.insertAll(0, newIds);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final nid = newIds.first;
                final r = reservations.firstWhere(
                  (r) => r.id == nid,
                  orElse: () => reservations.first,
                );
                final msg =
                    'New reservation: Table ${r.tableIndex} - ${r.timeSlot} on ${r.date}';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              });
            }
          }

          final filteredReservations = state.filteredBookings;

          if (filteredReservations.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Bookings')),
              body: const Center(child: Text('No bookings')),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Bookings')),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Pick date',
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: state.selectedDate ?? now,
                            firstDate: DateTime(now.year - 2),
                            lastDate: DateTime(now.year + 2),
                          );
                          if (picked != null) cubit.updateDateFilter(picked);
                        },
                      ),
                      const SizedBox(width: 8),
                      if (restaurant.timeSlots.isNotEmpty)
                        DropdownButton<String?>(
                          hint: const Text('Time slot'),
                          value: state.selectedTimeSlot,
                          items: [null, ...restaurant.timeSlots].map((e) {
                            if (e == null) {
                              return DropdownMenuItem<String?>(
                                value: null,
                                child: const Text('All'),
                              );
                            }
                            return DropdownMenuItem<String?>(
                              value: e,
                              child: Text(e),
                            );
                          }).toList(),
                          onChanged: (v) => cubit.updateTimeSlotFilter(v),
                        ),
                      if (state.selectedDate != null)
                        TextButton(
                          onPressed: () => cubit.updateDateFilter(null),
                          child: const Text('Clear date'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredReservations.length,
                    itemBuilder: (ctx, i) {
                      final r = filteredReservations[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: r.status == 'confirmed'
                                ? Colors.green
                                : r.status == 'pending'
                                ? Colors.orange
                                : Colors.grey,
                            child: Text(
                              '${r.tableIndex}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Table ${r.tableIndex} - ${r.seats} seats',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(r.date),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(r.timeSlot),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Status: ${r.status}',
                                    style: TextStyle(
                                      color: r.status == 'confirmed'
                                          ? Colors.green
                                          : r.status == 'pending'
                                          ? Colors.orange
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () => _showBookingDetails(context, r),
                          ),
                          onTap: () => _showBookingDetails(context, r),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Bookings')),
          body: Center(child: Text('Loading...')),
        );
      },
    );
  }
}
