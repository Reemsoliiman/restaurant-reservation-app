import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/picker/user_image_picker.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import './restaurants_list.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool isVisible = false;
  
  File? _userImageFile;
  String? _base64Image;

  void _pickedImage(File image) async {
    _userImageFile = image;

    final bytes = await image.readAsBytes();
    _base64Image = base64Encode(bytes);
  }

  Future<void> onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid values to continue"), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_userImageFile == null || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick an image."), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    _formKey.currentState!.save();
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), behavior: SnackBarBehavior.floating));
      return;
    }

    // Use AuthCubit for registration
    await context.read<AuthCubit>().signUp(
      email: emailController.text.trim(),
      password: passwordController.text,
      username: usernameController.text.trim(),
    );

    // Store additional user info in Firestore after successful registration
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'customerId': user.uid,
          'customerName': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'image_base64': _base64Image,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save user data: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RestaurantsListScreen.routeName,
            (route) => false,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text("Register"),
          ),
          body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  width: 150,
                  child: Image.asset("assets/images/login.png"),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Register",
                  style: TextStyle(
                    color: Color.fromRGBO(54, 63, 99, 1),
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                UserImagePicker(_pickedImage),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Username:",
                        style: TextStyle(
                          color: Color.fromRGBO(54, 63, 99, 1),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        )),
                    const SizedBox(height: 12),
                    TextFormField(
                          controller: usernameController,
                          validator: (inputValue) {
                            String pattern = r"\s";
                            RegExp regex = RegExp(pattern);
                            if (inputValue == null || inputValue.isEmpty) {
                                return "This field is required";
                              }
                              if (regex.hasMatch(inputValue)) {
                                return "No white spaces is required in username";
                              }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_emailFocusNode);
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              errorStyle: const TextStyle(height: 0.8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Email:",
                        style: TextStyle(
                          color: Color.fromRGBO(54, 63, 99, 1),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        )),
                    const SizedBox(height: 12),
                    TextFormField(
                          controller: emailController,
                          validator: (inputValue) {
                            String pattern = r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
                            RegExp regex = RegExp(pattern);
                            if (inputValue == null || inputValue.isEmpty) {
                              return "This field is required";
                            }
                            if (!regex.hasMatch(inputValue)) {
                              //return AppLocalizations.of(context)!.fieldEmailErrMessage;
                              return "Email address is not valid";
                            }
                             return null;
                          },
                          textInputAction: TextInputAction.next,
                          focusNode: _emailFocusNode,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocusNode);
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              errorStyle: const TextStyle(height: 0.8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Password:",
                      style: TextStyle(
                        color: Color.fromRGBO(54, 63, 99, 1),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                          controller: passwordController,
                          validator: (inputValue) {
                            if (inputValue == null || inputValue.isEmpty) {
                                return "This field is required";
                              }
                              if (inputValue.length < 8 || inputValue.length > 40) {
                                return "Password must be between 8 to 40 characters";
                              }
                            return null;
                          },
                          obscureText: isVisible ? false : true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) async {
                            onSubmit();
                          },
                          focusNode: _passwordFocusNode,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: isVisible ? const Icon(Icons.visibility_off, size: 25) : const Icon(Icons.visibility, size: 25),
                                onPressed: () {
                                  setState(() {
                                    isVisible = !isVisible;
                                  });
                                },
                              ),
                              errorStyle: const TextStyle(height: 0.8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: confirmPasswordController,
                    validator: (inputValue) {
                      if (inputValue == null || inputValue.isEmpty) {
                        return "This field is required";
                      }
                      if (inputValue.length < 8 || inputValue.length > 40) {
                        return "Password must be between 8 to 40 characters";
                      }
                      return null;
                    },
                    obscureText: isVisible ? false : true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) async {
                      onSubmit();
                    },
                    decoration: InputDecoration(
                        errorStyle: const TextStyle(height: 0.8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color.fromRGBO(54, 63, 99, 1), width: 1),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.red, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(29, 159, 240, 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
                    ),
                    onPressed: isLoading ? null : () {
                      onSubmit();
                    },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Register",
                            style: TextStyle(
                              color: Color.fromRGBO(249, 251, 253, 1),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Login"),
                )
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }
}
