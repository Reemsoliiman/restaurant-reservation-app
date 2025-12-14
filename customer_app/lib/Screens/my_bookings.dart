import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/firestore_service.dart';
import '../cubits/my_bookings/my_bookings_cubit.dart';
import '../cubits/my_bookings/my_bookings_state.dart';

class MyBookingsScreen extends StatelessWidget {
  static const routeName = '/my-bookings';

  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyBookingsCubit(
        firestoreService: FirestoreService(),
      )..loadMyBookings(),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            if (state is MyBookingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MyBookingsError) {
              final err = state.message;
              // Provide a helpful message when Firestore requires a composite index
              const indexLink =
                  'https://console.firebase.google.com/project/restaurant-system-1-a11a7/firestore/indexes';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      const Text('Failed to load bookings',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(err, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      const Text(
                          'If the error mentions an index is required, create the composite index in your Firebase Console:'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                              const ClipboardData(text: indexLink));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Firebase Console link copied to clipboard')));
                        },
                        child: const Text('Copy Firebase Console Index Link'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is MyBookingsLoaded) {
              final bookings = state.bookings;

              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings found'));
              }

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (ctx, i) {
                  final b = bookings[i];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ListTile(
                      title: Text(b.restaurantName),
                      subtitle: Text(
                          '${b.date} • ${b.timeSlot} • Table: ${b.tableNumber}\nSeats: ${b.seats} • Status: ${b.status}'),
                      isThreeLine: true,
                      trailing: b.status == 'cancelled'
                          ? null
                          : TextButton(
                              child: const Text('Cancel'),
                              onPressed: () async {
                                try {
                                  await context
                                      .read<MyBookingsCubit>()
                                      .cancelBooking(b.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Booking cancelled')));
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Cancel failed: ${e.toString()}')));
                                }
                              },
                            ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
