import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/fcm_token_service.dart';
import '../services/user_service.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FCMTokenService _tokenService = FCMTokenService();
  final UserService _userService = UserService();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Create account
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // Save user details to Firestore
        await _userService.saveUserDetails(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
      }
      await _tokenService.saveTokenToFirestore();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email address.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    } else if (error.contains('weak-password')) {
      return 'Password should be at least 6 characters long.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.space24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: AppTheme.space48),
                  
                  // 🎨 Header Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(),
                  ),
                  
                  SizedBox(height: AppTheme.space48),
                  
                  // 📝 Form Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildForm(),
                  ),
                  
                  SizedBox(height: AppTheme.space32),
                  
                  // ⚠️ Error Message
                  if (_errorMessage != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildErrorMessage(),
                    ),
                  
                  SizedBox(height: AppTheme.space24),
                  
                  // 🚀 Submit Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildSubmitButton(),
                  ),
                  
                  SizedBox(height: AppTheme.space24),
                  
                  // 🔄 Toggle Mode
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildToggleMode(),
                  ),
                  
                  SizedBox(height: AppTheme.space48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 🎯 Logo/Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppTheme.elevation16,
          ),
          child: Icon(
            Icons.security_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: AppTheme.space24),
        
        // 📱 App Title
        Text(
          'RFID Security',
          style: AppTheme.headline1.copyWith(
            color: AppTheme.neutral700,
            fontWeight: FontWeight.w800,
          ),
        ),
        
        SizedBox(height: AppTheme.space8),
        
        // 📄 Subtitle
        Text(
          _isLogin 
              ? 'Welcome back! Sign in to continue.' 
              : 'Create your account to get started.',
          style: AppTheme.body1.copyWith(
            color: AppTheme.neutral500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return AnimatedCard(
      padding: EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          // 👤 Name Fields (Sign Up only) - Vertical Layout
          if (!_isLogin) ...[
            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Enter your first name',
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required';
                }
                if (value.trim().length < 2) {
                  return 'First name must be at least 2 characters';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.space20),
            
            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Enter your last name',
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                if (value.trim().length < 2) {
                  return 'Last name must be at least 2 characters';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.space20),
            
            // 📱 Phone Number (Optional)
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Enter your phone number',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.space20),
          ],
          
          // �📧 Email Field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          
          SizedBox(height: AppTheme.space20),
          
          // 🔒 Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              hintText: 'Enter your password',
            ),
            obscureText: _obscurePassword,
            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          // 🔒 Confirm Password Field (Sign Up only)
          if (!_isLogin) ...[
            SizedBox(height: AppTheme.space20),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                hintText: 'Confirm your password',
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedCard(
      color: AppTheme.error50,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.error500,
            size: 20,
          ),
          SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTheme.body2.copyWith(color: AppTheme.error500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GradientButton(
      text: _isLogin ? 'Sign In' : 'Create Account',
      icon: _isLogin ? Icons.login : Icons.person_add,
      onPressed: _submit,
      isLoading: _isLoading,
      width: double.infinity,
      height: 56,
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: AppTheme.button.copyWith(
              color: AppTheme.primary500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
