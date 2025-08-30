import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../firebase_msg.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/logout_dialog.dart';
import 'rfid_link_screen.dart';
import 'notification_history_screen.dart';

/// 🏠 World-Class Notification Home Screen
/// Features: Smooth animations, professional design, excellent UX
class NotificationHome extends StatefulWidget {
  const NotificationHome({super.key});

  @override
  _NotificationHomeState createState() => _NotificationHomeState();
}

class _NotificationHomeState extends State<NotificationHome> 
    with TickerProviderStateMixin {
  final FirebaseMsg _firebaseMsg = FirebaseMsg();
  final NotificationService _notificationService = NotificationService();
  final List<NotificationItem> _notifications = [];
  final GlobalKey<LiquidPullToRefreshState> _refreshKey = GlobalKey();
  
  late AnimationController _statsController;
  late AnimationController _fabController;
  late Animation<double> _statsAnimation;
  late Animation<double> _fabAnimation;
  
  int _totalNotifications = 0;
  int _todayNotifications = 0;
  int _unreadNotifications = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNotifications();
  }

  void _setupAnimations() {
    _statsController = AnimationController(
      duration: AppTheme.durationLong,
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: AppTheme.durationMedium,
      vsync: this,
    );

    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: AppTheme.emphasizedDecelerate,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: AppTheme.easeOut,
    );

    // Start animations
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _statsController.forward();
        _fabController.forward();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await _firebaseMsg.initFirebaseMessaging();
      _loadNotifications();
      _setupNotificationListener();
    } catch (e) {
      print('Error initializing notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupNotificationListener() {
    _notificationService.getNotifications().listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications.clear();
          _notifications.addAll(notifications.take(5)); // Show latest 5
          _updateStats(notifications);
          _isLoading = false;
        });
      }
    });
  }

  void _updateStats(List<NotificationItem> allNotifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _totalNotifications = allNotifications.length;
    _todayNotifications = allNotifications.where((n) {
      final notificationDate = DateTime(n.time.year, n.time.month, n.time.day);
      return notificationDate.isAtSameMomentAs(today);
    }).length;
    _unreadNotifications = allNotifications.where((n) => !n.isRead).length;
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    // Simulate loading for smooth animation
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await LogoutDialog.show(context);
    if (shouldSignOut == true) {
      try {
        // Remove FCM token before signing out (handled by the firebase service)
        await FirebaseAuth.instance.signOut();
        // Navigation will be handled by AuthGate
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.error500,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _statsController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: LiquidPullToRefresh(
        key: _refreshKey,
        onRefresh: _loadNotifications,
        color: AppTheme.primary500,
        backgroundColor: AppTheme.neutral50,
        height: 100,
        animSpeedFactor: 2,
        showChildOpacityTransition: false,
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildStatsSection(),
            _buildQuickActions(),
            _buildRecentNotifications(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary500.withOpacity(0.1),
                AppTheme.primary300.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: AppTheme.body2.copyWith(
                                color: AppTheme.neutral600,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 400.ms)
                                .slideY(begin: 0.3, curve: AppTheme.emphasizedDecelerate),
                            SizedBox(height: AppTheme.space4),
                            Text(
                              userName,
                              style: AppTheme.headline2.copyWith(
                                color: AppTheme.neutral900,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideY(begin: 0.3, curve: AppTheme.emphasizedDecelerate),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.elevation4,
                        ),
                        child: IconButton(
                          onPressed: _handleSignOut,
                          icon: Icon(
                            Icons.logout_rounded,
                            color: AppTheme.error500,
                            size: 24,
                          ),
                          tooltip: 'Sign Out',
                        ),
                      )
                          .animate()
                          .scale(delay: 500.ms, duration: 300.ms)
                          .then()
                          .shimmer(duration: 2.seconds, color: AppTheme.primary200),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: AnimatedBuilder(
          animation: _statsAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - _statsAnimation.value)),
              child: Opacity(
                opacity: _statsAnimation.value,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        _totalNotifications.toString(),
                        Icons.notifications_outlined,
                        AppTheme.primary500,
                        0,
                      ),
                    ),
                    SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _buildStatCard(
                        'Today',
                        _todayNotifications.toString(),
                        Icons.today_outlined,
                        AppTheme.success500,
                        100,
                      ),
                    ),
                    SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _buildStatCard(
                        'Unread',
                        _unreadNotifications.toString(),
                        Icons.mark_email_unread_outlined,
                        AppTheme.warning500,
                        200,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, int delay) {
    return Container(
      padding: EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radius16,
        boxShadow: AppTheme.elevation2,
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppTheme.radius8,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: AppTheme.space8),
          Text(
            value,
            style: AppTheme.headline3.copyWith(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppTheme.space4),
          Text(
            title,
            style: AppTheme.caption.copyWith(
              color: AppTheme.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 600 + delay), duration: 400.ms)
        .slideY(begin: 0.3, curve: AppTheme.emphasizedDecelerate)
        .then()
        .shimmer(delay: Duration(milliseconds: 1000 + delay), duration: 1.5.seconds);
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.headline3.copyWith(
                color: AppTheme.neutral900,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 400.ms)
                .slideX(begin: -0.2, curve: AppTheme.emphasizedDecelerate),
            SizedBox(height: AppTheme.space16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Link RFID Card',
                    'Connect your card',
                    Icons.credit_card_rounded,
                    AppTheme.primaryGradient,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RFIDLinkScreen()),
                    ),
                    0,
                  ),
                ),
                SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildActionCard(
                    'View History',
                    'All notifications',
                    Icons.history_rounded,
                    AppTheme.successGradient,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationHistoryScreen()),
                    ),
                    100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
    int delay,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppTheme.radius16,
        boxShadow: AppTheme.elevation4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radius16,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                SizedBox(height: AppTheme.space12),
                Text(
                  title,
                  style: AppTheme.subtitle1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppTheme.space4),
                Text(
                  subtitle,
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 900 + delay), duration: 400.ms)
        .slideY(begin: 0.3, curve: AppTheme.emphasizedDecelerate)
        .then()
        .shimmer(delay: Duration(milliseconds: 1200 + delay), duration: 2.seconds);
  }

  Widget _buildRecentNotifications() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notifications',
                  style: AppTheme.headline3.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms)
                    .slideX(begin: -0.2, curve: AppTheme.emphasizedDecelerate),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationHistoryScreen()),
                  ),
                  child: Text('View All'),
                )
                    .animate()
                    .fadeIn(delay: 1100.ms, duration: 400.ms)
                    .slideX(begin: 0.2, curve: AppTheme.emphasizedDecelerate),
              ],
            ),
            SizedBox(height: AppTheme.space16),
            if (_isLoading) _buildLoadingState(),
            if (!_isLoading && _notifications.isEmpty) _buildEmptyState(),
            if (!_isLoading && _notifications.isNotEmpty) _buildNotificationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.space12),
          padding: EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radius12,
            boxShadow: AppTheme.elevation1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: AppTheme.radius4,
                ),
              ),
              SizedBox(height: AppTheme.space8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: AppTheme.radius4,
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1.5.seconds, color: AppTheme.neutral100);
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radius16,
        boxShadow: AppTheme.elevation2,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppTheme.neutral400,
            ),
          ),
          SizedBox(height: AppTheme.space16),
          Text(
            'No notifications yet',
            style: AppTheme.subtitle1.copyWith(
              color: AppTheme.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppTheme.space8),
          Text(
            'Link your RFID card to start receiving notifications',
            style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1200.ms, duration: 600.ms)
        .slideY(begin: 0.2, curve: AppTheme.emphasizedDecelerate);
  }

  Widget _buildNotificationsList() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: AppTheme.durationMedium,
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: _notifications.map((notification) {
            return _buildNotificationCard(notification);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radius12,
        boxShadow: AppTheme.elevation2,
        border: Border.all(
          color: notification.isRead ? Colors.transparent : AppTheme.primary200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Mark as read
            if (notification.id != null) {
              _notificationService.markAsRead(notification.id!);
            }
          },
          borderRadius: AppTheme.radius12,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.radius12,
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppTheme.subtitle1.copyWith(
                          color: AppTheme.neutral900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (notification.body.isNotEmpty) ...[
                        SizedBox(height: AppTheme.space4),
                        Text(
                          notification.body,
                          style: AppTheme.body2.copyWith(
                            color: AppTheme.neutral600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: AppTheme.space8),
                      Text(
                        _formatTime(notification.time),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primary500,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scaleXY(begin: 0.8, end: 1.2, duration: 1.seconds)
                      .then()
                      .scaleXY(begin: 1.2, end: 0.8, duration: 1.seconds),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RFIDLinkScreen()),
            ),
            backgroundColor: AppTheme.primary500,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: Icon(Icons.add_card_rounded),
            label: Text(
              'Link Card',
              style: AppTheme.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
