import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../Models/table_model.dart';
import '../services/firestore_service.dart';
import '../cubits/booking/booking_cubit.dart';
import '../cubits/booking/booking_state.dart';

class BookingScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final TableModel table;
  final List<String> allTimeSlots;
  final String? vendorId;
  final int maxSeatsForTable;

  const BookingScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.table,
    required this.allTimeSlots,
    this.vendorId,
    required this.maxSeatsForTable,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingCubit(
        firestoreService: FirestoreService(),
      ),
      child: _BookingView(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        table: table,
        allTimeSlots: allTimeSlots,
        vendorId: vendorId,
        maxSeatsForTable: maxSeatsForTable,
      ),
    );
  }
}

class _BookingView extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final TableModel table;
  final List<String> allTimeSlots;
  final String? vendorId;
  final int maxSeatsForTable;

  const _BookingView({
    required this.restaurantId,
    required this.restaurantName,
    required this.table,
    required this.allTimeSlots,
    this.vendorId,
    required this.maxSeatsForTable,
  });

  @override
  State<_BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<_BookingView> {
  int _seats = 1;
  String? _slot;
  DateTime? _selectedDate;
  Set<String> _lastKnownBookedSlots = {};

  @override
  void initState() {
    super.initState();
    _seats = 1;
  }

  void _loadAvailableSlots() {
    if (_selectedDate == null) return;

    context.read<BookingCubit>().loadAvailableSlots(
          restaurantId: widget.restaurantId,
          tableId: widget.table.id,
          date: _selectedDate!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation successful')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
          // Don't reset - let the real-time stream update the slots automatically
        } else if (state is BookingError) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Booking failed'),
              content: Text(
                  '${state.message}\n\nTry selecting a different slot or refreshing the page.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK')),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is BookingLoading;
        
        // Cache the booked slots when available, use cached value otherwise
        if (state is BookingSlotsLoaded) {
          _lastKnownBookedSlots = state.bookedSlots;
        }
        final bookedSlots = _lastKnownBookedSlots;
        
        final maxSeats =
            widget.maxSeatsForTable > 6 ? 6 : widget.maxSeatsForTable;

        return Scaffold(
          appBar: AppBar(title: Text('Book ${widget.table.label}')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount of guests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount of guests',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Table capacity: $maxSeats guests',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: isLoading || _seats <= 1
                              ? null
                              : () => setState(() => _seats--),
                          icon: const Icon(Icons.remove),
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Number display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$_seats',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.add,
                                color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Plus button (visual only, functionality in the blue container)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: isLoading || _seats >= maxSeats
                              ? null
                              : () => setState(() => _seats++),
                          icon: const Icon(Icons.add),
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Reservation date
                  Text(
                    'Reservation date',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _loadAvailableSlots();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('MMMM, d\'th\'').format(_selectedDate!)
                            : 'Select date',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Time slots
                  Row(
                    children: [
                      Text(
                        'Time slots',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state is BookingSlotsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_selectedDate == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Please select a date first',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.allTimeSlots.map((slot) {
                        final isBooked = bookedSlots.contains(slot);
                        final isSelected = _slot == slot;
                        return GestureDetector(
                          onTap: isLoading || isBooked
                              ? null
                              : () => setState(() => _slot = slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? Colors.red[100]
                                  : isSelected
                                      ? Colors.blue[400]
                                      : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.blue[700]!, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isBooked
                                        ? Colors.red[900]
                                        : isSelected
                                            ? Colors.white
                                            : Colors.green[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isBooked ? 'Booked' : 'Available',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isBooked
                                        ? Colors.red[700]
                                        : isSelected
                                            ? Colors.white70
                                            : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 40),

                  // Confirm button
                  ElevatedButton(
                    onPressed:
                        isLoading || _slot == null || _selectedDate == null
                            ? null
                            : () {
                                // Validate guest count
                                if (_seats > maxSeats) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'This table can only accommodate $maxSeats guests'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                context.read<BookingCubit>().createBooking(
                                      restaurantId: widget.restaurantId,
                                      restaurantName: widget.restaurantName,
                                      tableId: widget.table.id,
                                      tableLabel: widget.table.label,
                                      tableIndex: widget.table.tableIndex,
                                      seats: _seats,
                                      date: _selectedDate!,
                                      timeSlot: _slot!,
                                      vendorId: widget.vendorId ?? '',
                                    );
                              },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Confirm Booking',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
