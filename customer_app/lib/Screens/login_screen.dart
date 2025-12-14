import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './register_screen.dart';
import './restaurants_list.dart';
import './password_reset_screen.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();

  bool isVisible = false;

  void onSubmit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Enter valid values to continue"),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    _formKey.currentState!.save();

    context.read<AuthCubit>().signIn(
          email: emailController.text,
          password: passwordController.text,
        );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating),
          );
        } else if (state is AuthAuthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RestaurantsListScreen()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
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
                      "Login",
                      style: TextStyle(
                        color: Color.fromRGBO(54, 63, 99, 1),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 30),
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
                          enabled: !isLoading,
                          validator: (inputValue) {
                            String pattern =
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
                            RegExp regex = RegExp(pattern);
                            if (inputValue == null || inputValue.isEmpty) {
                              return "This field is required";
                            }
                            if (!regex.hasMatch(inputValue)) {
                              return "Email address is not valid";
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_emailFocusNode);
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              errorStyle: const TextStyle(height: 0.8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Color.fromRGBO(54, 63, 99, 1),
                                    width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(200, 255, 115, 0),
                                    width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16)),
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
                          enabled: !isLoading,
                          validator: (inputValue) {
                            if (inputValue == null || inputValue.isEmpty) {
                              return "This field is required";
                            }
                            if (inputValue.length < 8 ||
                                inputValue.length > 40) {
                              return "Password must be between 8 to 40 characters";
                            }
                            return null;
                          },
                          obscureText: isVisible ? false : true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) async {
                            if (!isLoading) onSubmit();
                          },
                          focusNode: _emailFocusNode,
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: isVisible
                                    ? const Icon(Icons.visibility_off, size: 25)
                                    : const Icon(Icons.visibility, size: 25),
                                onPressed: () {
                                  setState(() {
                                    isVisible = !isVisible;
                                  });
                                },
                              ),
                              errorStyle: const TextStyle(height: 0.8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Color.fromRGBO(54, 63, 99, 1),
                                    width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(200, 255, 115, 0),
                                    width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFFA55C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(48)),
                        ),
                        onPressed: isLoading ? null : onSubmit,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Color.fromRGBO(249, 251, 253, 1),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.of(context)
                                  .pushNamed(RegisterScreen.routeName);
                            },
                      child: const Text("Register"),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const PasswordResetScreen()));
                            },
                      child: const Text('Forgot password?'),
                    ),
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