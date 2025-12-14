import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category.dart';
import '../services/firestore_service.dart';
import '../services/local_user_service.dart';
import '../cubits/add_restaurant/add_restaurant_cubit.dart';
import '../cubits/add_restaurant/add_restaurant_state.dart';
import '../cubits/categories/categories_cubit.dart';
import '../cubits/categories/categories_state.dart';
import '../widgets/picker/user_image_picker.dart';

class AddRestaurantScreen extends StatelessWidget {
  const AddRestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AddRestaurantCubit(
            firestoreService: FirestoreService(),
            localUserService: LocalUserService(),
          ),
        ),
        BlocProvider(
          create: (context) => CategoriesCubit(
            firestoreService: FirestoreService(),
          )..loadCategories(),
        ),
      ],
      child: const _AddRestaurantView(),
    );
  }
}

class _AddRestaurantView extends StatefulWidget {
  const _AddRestaurantView();

  @override
  State<_AddRestaurantView> createState() => _AddRestaurantViewState();
}

class _AddRestaurantViewState extends State<_AddRestaurantView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tablesController = TextEditingController(text: '1');
  final List<TextEditingController> _seatsControllers = [
    TextEditingController(text: '4'),
  ];
  final _timeControllers = List.generate(5, (i) => TextEditingController());

  File? _pickedImage;
  Category? _selectedCategory;
  Position? _position;

  @override
  void initState() {
    super.initState();
    // Default time slots
    final defaults = ['10:00', '10:30', '11:00', '11:30', '12:00'];
    for (var i = 0; i < 5; i++) {
      _timeControllers[i].text = defaults[i];
    }
  }

  void _updateSeatControllers(int tables) {
    if (tables < 1) tables = 1;
    while (_seatsControllers.length < tables) {
      _seatsControllers.add(TextEditingController(text: '4'));
    }
    while (_seatsControllers.length > tables) {
      _seatsControllers.removeLast();
    }
    setState(() {});
  }

  void _pickImage(File picked) {
    setState(() {
      _pickedImage = picked;
    });
  }

  Future<void> _useCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled for sales point.'),
        ),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions for sales point are permanently denied.',
          ),
        ),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      _position = pos;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final desc = _descriptionController.text.trim();
    final tables = int.tryParse(_tablesController.text) ?? 1;
    final seatsList = _seatsControllers
        .map((c) => int.tryParse(c.text) ?? 1)
        .toList();

    if (seatsList.any((s) => s < 1 || s > 6)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seats per table must be between 1 and 6'),
        ),
      );
      return;
    }
    final timeSlots = _timeControllers.map((c) => c.text.trim()).toList();

    GeoPoint? gp;
    if (_position != null) {
      gp = GeoPoint(_position!.latitude, _position!.longitude);
    }

    context.read<AddRestaurantCubit>().addRestaurant(
      name: name,
      description: desc,
      imageFile: _pickedImage,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      numberOfTables: tables,
      seatsPerTable: seatsList,
      timeSlots: timeSlots,
      location: gp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddRestaurantCubit, AddRestaurantState>(
      listener: (context, state) {
        if (state is AddRestaurantSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant added successfully')),
          );
          Navigator.of(context).pop();
        } else if (state is AddRestaurantError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        }
      },
      builder: (context, state) {
        final isLoading = state is AddRestaurantLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Add Restaurant')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserImagePicker(_pickImage),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant name',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                      if (state is CategoriesLoading) {
                        return const CircularProgressIndicator();
                      }
                      if (state is CategoriesError) {
                        return Text('Error: ${state.message}');
                      }
                      if (state is CategoriesLoaded) {
                        final cats = state.categories;
                        // Ensure we match the selected category by id to avoid Dropdown equality issues
                        Category? selected;
                        if (_selectedCategory != null) {
                          try {
                            selected = cats.firstWhere(
                              (c) => c.id == _selectedCategory!.id,
                            );
                          } catch (e) {
                            // If the previously selected category is no longer present in the list
                            // just treat it as unselected and log for diagnostics.
                            selected = null;
                            debugPrint('Category match error: $e');
                          }
                        }
                        return DropdownButtonFormField<Category>(
                          initialValue: selected,
                          items: cats
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          validator: (v) => v == null ? 'Select category' : null,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tablesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of tables',
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 1;
                      _updateSeatControllers(n);
                    },
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'At least 1';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Seats per table (per table, max 6)'),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_seatsControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextFormField(
                          controller: _seatsControllers[i],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Table ${i + 1} seats',
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1 || n > 6) return '1-6 seats';
                            return null;
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Text('Time slots per day (5 slots)'),
                  const SizedBox(height: 6),
                  ..._timeControllers.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextFormField(
                        controller: c,
                        decoration: const InputDecoration(
                          labelText: 'Time slot',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use sales point location'),
                      ),
                      const SizedBox(width: 12),
                      if (_position != null)
                        Expanded(
                          child: Text(
                            'Lat: ${_position!.latitude.toStringAsFixed(4)}, Lng: ${_position!.longitude.toStringAsFixed(4)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Restaurant'),
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
