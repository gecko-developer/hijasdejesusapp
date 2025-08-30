import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// 🔐 Modern Logout Confirmation Dialog
/// Clean, minimal design with excellent UX
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const LogoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 32,
              offset: Offset(0, 16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎨 Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(32, 32, 32, 24),
              child: Column(
                children: [
                  // Icon Container
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.error50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppTheme.error500,
                      size: 36,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: Offset(0.6, 0.6),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .then(delay: 200.ms)
                      .shake(hz: 1.5, curve: Curves.easeInOut),
                  
                  SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Sign Out?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutral900,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),
                  
                  SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'You will need to sign in again to access your notifications and RFID features.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.neutral600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),
                ],
              ),
            ),

            // 🎯 Action Buttons Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: ModernButton(
                      text: 'Cancel',
                      isSecondary: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 400.ms)
                        .slideX(begin: -0.2, curve: Curves.easeOut),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // Sign Out Button
                  Expanded(
                    child: ModernButton(
                      text: 'Sign Out',
                      isPrimary: true,
                      isDanger: true,
                      icon: Icons.logout_rounded,
                      onPressed: () => Navigator.of(context).pop(true),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 400.ms)
                        .slideX(begin: 0.2, curve: Curves.easeOut),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .scale(
            begin: Offset(0.7, 0.7),
            curve: Curves.elasticOut,
            duration: 600.ms,
          )
          .fadeIn(duration: 300.ms),
    );
  }
}

/// 🎯 Modern Button Component
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isSecondary;
  final bool isDanger;
  final bool isLoading;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isSecondary = false,
    this.isDanger = false,
    this.isLoading = false,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.isDanger && widget.isPrimary) {
      return _isPressed ? AppTheme.error700 : AppTheme.error500;
    }
    if (widget.isPrimary) {
      return _isPressed ? AppTheme.primary600 : AppTheme.primary500;
    }
    if (widget.isSecondary) {
      return _isPressed ? AppTheme.neutral100 : AppTheme.neutral50;
    }
    return AppTheme.neutral50;
  }

  Color get _textColor {
    if (widget.isPrimary) return Colors.white;
    if (widget.isDanger) return AppTheme.error500;
    return AppTheme.neutral700;
  }

  Color get _borderColor {
    if (widget.isSecondary) {
      return _isPressed ? AppTheme.neutral200 : AppTheme.neutral100;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            }
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
            }
          : null,
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 52,
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border.all(
                  color: _borderColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: (widget.isDanger ? AppTheme.error500 : AppTheme.primary500)
                              .withOpacity(0.25),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _textColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: _textColor,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
