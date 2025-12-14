import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import '../widgets/picker/user_image_picker.dart';
import '../cubits/edit_restaurant/edit_restaurant_cubit.dart';
import '../cubits/edit_restaurant/edit_restaurant_state.dart';
import '../cubits/categories/categories_cubit.dart';
import '../cubits/categories/categories_state.dart';

class EditRestaurantScreen extends StatelessWidget {
  final Restaurant restaurant;

  const EditRestaurantScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => EditRestaurantCubit(
            firestoreService: FirestoreService(),
          ),
        ),
        BlocProvider(
          create: (context) => CategoriesCubit(
            firestoreService: FirestoreService(),
          )..loadCategories(),
        ),
      ],
      child: _EditRestaurantView(restaurant: restaurant),
    );
  }
}

class _EditRestaurantView extends StatefulWidget {
  final Restaurant restaurant;

  const _EditRestaurantView({required this.restaurant});

  @override
  State<_EditRestaurantView> createState() => _EditRestaurantViewState();
}

class _EditRestaurantViewState extends State<_EditRestaurantView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _tablesController;
  late List<TextEditingController> _seatsControllers;
  late List<TextEditingController> _timeControllers;

  File? _pickedImage;
  Category? _selectedCategory;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant.name);
    _descriptionController = TextEditingController(
      text: widget.restaurant.description,
    );
    _tablesController = TextEditingController(
      text: widget.restaurant.numberOfTables.toString(),
    );

    // Initialize seats controllers
    _seatsControllers = widget.restaurant.seatsPerTable.isEmpty
        ? [TextEditingController(text: '4')]
        : widget.restaurant.seatsPerTable
              .map((s) => TextEditingController(text: s.toString()))
              .toList();

    // Initialize time slots controllers
    _timeControllers = List.generate(5, (i) {
      if (i < widget.restaurant.timeSlots.length) {
        return TextEditingController(text: widget.restaurant.timeSlots[i]);
      }
      return TextEditingController(text: '${10 + i}:00');
    });

    if (widget.restaurant.location != null) {
      _position = Position(
        latitude: widget.restaurant.location!.latitude,
        longitude: widget.restaurant.location!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tablesController.dispose();
    for (var controller in _seatsControllers) {
      controller.dispose();
    }
    for (var controller in _timeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateSeatControllers(int tables) {
    if (tables < 1) tables = 1;
    setState(() {
      while (_seatsControllers.length < tables) {
        _seatsControllers.add(TextEditingController(text: '4'));
      }
      while (_seatsControllers.length > tables) {
        _seatsControllers.removeLast().dispose();
      }
    });
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
        const SnackBar(content: Text('Location services are disabled.')),
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
          content: Text('Location permissions are permanently denied.'),
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

    String? imageUrl = widget.restaurant.imageUrl;
    if (_pickedImage != null) {
      try {
        // Convert image to base64 string (same as customer app)
        final bytes = await _pickedImage!.readAsBytes();
        final base64String = base64Encode(bytes);

        // Check if base64 string is too large (Firestore has 1MB limit per document)
        // Base64 increases size by ~33%, so we need to be careful
        final sizeInKB = (base64String.length / 1024).round();

        if (sizeInKB > 800) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image is too large ($sizeInKB KB). Please choose a smaller image or reduce quality.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        imageUrl = base64String;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    GeoPoint? gp;
    if (_position != null) {
      gp = GeoPoint(_position!.latitude, _position!.longitude);
    }

    final updatedRestaurant = Restaurant(
      id: widget.restaurant.id,
      name: name,
      description: desc,
      imageUrl: imageUrl,
      categoryId: _selectedCategory!.id,
      category: _selectedCategory!.name,
      numberOfTables: tables,
      seatsPerTable: seatsList,
      timeSlots: timeSlots,
      location: gp,
      vendorId: widget.restaurant.vendorId,
    );

    // Use cubit to update restaurant
    if (!mounted) return;
    await context.read<EditRestaurantCubit>().updateRestaurant(updatedRestaurant);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditRestaurantCubit, EditRestaurantState>(
      listener: (context, state) {
        if (state is EditRestaurantSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant updated successfully')),
          );
          Navigator.of(context).pop();
        } else if (state is EditRestaurantError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is EditRestaurantLoading;
        
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Restaurant')),
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.restaurant.imageUrl != null &&
                  widget.restaurant.imageUrl!.isNotEmpty &&
                  _pickedImage == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Image:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: widget.restaurant.imageUrl!.startsWith('http')
                            ? Image.network(
                                widget.restaurant.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            : Image.memory(
                                base64Decode(widget.restaurant.imageUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              UserImagePicker(_pickImage),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Restaurant name'),
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

                    // Find the matching category by ID from the current state data
                    Category? selected;
                    if (_selectedCategory != null) {
                      try {
                        selected = cats.firstWhere(
                          (c) => c.id == _selectedCategory!.id,
                        );
                      } catch (e) {
                        selected = null;
                      }
                    }

                    // If no selected category yet, find by restaurant's categoryId
                    if (selected == null) {
                      try {
                        selected = cats.firstWhere(
                          (c) => c.id == widget.restaurant.categoryId,
                        );
                        // Auto-set the _selectedCategory on first load
                        if (_selectedCategory == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() => _selectedCategory = selected);
                          });
                        }
                      } catch (e) {
                        selected = null;
                      }
                    }

                    return DropdownButtonFormField<Category>(
                      initialValue: selected,
                      items: cats
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      decoration: const InputDecoration(labelText: 'Category'),
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
              const Text('Seats per table (max 6)'),
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
              const Text('Time slots (5 slots)'),
              const SizedBox(height: 6),
              ..._timeControllers.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    controller: c,
                    decoration: const InputDecoration(labelText: 'Time slot'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use current location'),
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
                      : const Text('Update Restaurant'),
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
