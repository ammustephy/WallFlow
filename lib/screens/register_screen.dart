import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).register(_emailController.text, _passwordController.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created! Sign in to continue.'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        // Extract message from Exception objects
        String message = error.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $message')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Colors.black, AppTheme.darkBg],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 900),
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: (value - 0.8) * 5,
                            child: Transform.scale(scale: value, child: child),
                          );
                        },
                        child: Column(
                          children: [
                            Center(
                              child: Image.asset(
                                'Assets/Images/WF_Logo_Outlined.png',
                                height: 50,
                                width: 50,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Welcome to\n',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'WallFlow',
                                    style: GoogleFonts.syncopate(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start your journey with us',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 60),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        validator: (val) => val!.length < 6
                            ? 'Password must be at least 6 chars'
                            : null,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _submit,
                        child: Consumer<AuthProvider>(
                          builder: (ctx, auth, _) => auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
