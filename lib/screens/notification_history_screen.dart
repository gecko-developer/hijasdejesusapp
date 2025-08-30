import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  _NotificationHistoryScreenState createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> 
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _listController;
  late AnimationController _searchController;
  late Animation<double> _listAnimation;
  late Animation<Offset> _searchAnimation;
  
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _markAllAsRead();
  }

  void _setupAnimations() {
    _listController = AnimationController(
      duration: AppTheme.durationMedium,
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: AppTheme.durationMedium,
      vsync: this,
    );

    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: AppTheme.emphasizedDecelerate),
    );

    _searchAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _searchController, curve: AppTheme.bounceOut));

    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchController.forward();
      } else {
        _searchController.reverse();
        _searchTextController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please login to view notifications',
            style: AppTheme.body1.copyWith(color: AppTheme.neutral500),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: CustomScrollView(
          slivers: [
            // 🎨 Professional App Bar with Search
            _buildProfessionalAppBar(),
            
            // 📊 Enhanced Stats Card
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _listAnimation,
                child: _buildStatsCard(),
              ).animate().slideY(begin: 0.3, duration: AppTheme.durationMedium),
            ),
            
            // 🔍 Professional Search Bar
            if (_isSearching)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _searchAnimation,
                  child: _buildSearchBar(),
                ),
              ),
            
            // 📋 Enhanced Notifications List
            _buildNotificationsList(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radius8,
            boxShadow: AppTheme.elevation2,
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.neutral700,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Notification History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral700,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: _isSearching ? AppTheme.primary500 : Colors.white,
              borderRadius: AppTheme.radius8,
              boxShadow: AppTheme.elevation2,
            ),
            child: Icon(
              Icons.search,
              color: _isSearching ? Colors.white : AppTheme.neutral700,
              size: 20,
            ),
          ),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.radius8,
            ),
            child: Icon(
              Icons.filter_list,
              color: AppTheme.neutral700,
              size: 20,
            ),
          ),
          onPressed: () {
            // TODO: Implement filtering
          },
        ),
        SizedBox(width: AppTheme.space8),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(AppTheme.space16),
      padding: EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radius16,
        boxShadow: AppTheme.elevation4,
      ),
      child: StreamBuilder<List<NotificationItem>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              padding: EdgeInsets.all(AppTheme.space16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary500),
                ),
              ),
            );
          }

          final notifications = snapshot.data!;
          final totalCount = notifications.length;
          final unreadCount = notifications.where((n) => !n.isRead).length;
          final todayCount = notifications.where((n) => 
            n.time.day == DateTime.now().day && 
            n.time.month == DateTime.now().month && 
            n.time.year == DateTime.now().year
          ).length;

          return Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  totalCount.toString(),
                  Icons.notifications,
                  AppTheme.primary500,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.neutral200,
                margin: EdgeInsets.symmetric(horizontal: AppTheme.space16),
              ),
              Expanded(
                child: _buildStatItem(
                  'Unread',
                  unreadCount.toString(),
                  Icons.mark_email_unread,
                  AppTheme.warning500,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.neutral200,
                margin: EdgeInsets.symmetric(horizontal: AppTheme.space16),
              ),
              Expanded(
                child: _buildStatItem(
                  'Today',
                  todayCount.toString(),
                  Icons.today,
                  AppTheme.success500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppTheme.radius12,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: AppTheme.space8),
        Text(
          value,
          style: AppTheme.headline2.copyWith(
            color: AppTheme.neutral800,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: AppTheme.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: TextField(
        controller: _searchTextController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search notifications...',
          hintStyle: AppTheme.body2.copyWith(color: AppTheme.neutral400),
          prefixIcon: Icon(Icons.search, color: AppTheme.neutral400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.neutral400),
                  onPressed: () {
                    _searchTextController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: AppTheme.radius12,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
        ),
        style: AppTheme.body1.copyWith(color: AppTheme.neutral800),
      ),
    );
  }

  Widget _buildNotificationsList(String userId) {
    return StreamBuilder<List<NotificationItem>>(
      stream: _notificationService.getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary500),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(AppTheme.space16),
              padding: EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.error50,
                borderRadius: AppTheme.radius16,
                border: Border.all(color: AppTheme.error500.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.error500,
                    size: 48,
                  ),
                  SizedBox(height: AppTheme.space12),
                  Text(
                    'Error loading notifications',
                    style: AppTheme.subtitle1.copyWith(
                      color: AppTheme.error700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.space8),
                  Text(
                    'Please try again later',
                    style: AppTheme.body2.copyWith(color: AppTheme.error500),
                  ),
                ],
              ),
            ),
          );
        }

        List<NotificationItem> notifications = snapshot.data ?? [];

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          notifications = notifications.where((notification) {
            return notification.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   notification.body.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (notifications.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(AppTheme.space16),
              padding: EdgeInsets.all(AppTheme.space40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: AppTheme.radius16,
                boxShadow: AppTheme.elevation2,
              ),
              child: Column(
                children: [
                  Icon(
                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.notifications_none,
                    color: AppTheme.neutral400,
                    size: 64,
                  ),
                  SizedBox(height: AppTheme.space16),
                  Text(
                    _searchQuery.isNotEmpty 
                        ? 'No notifications found'
                        : 'No notifications yet',
                    style: AppTheme.subtitle1.copyWith(
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.space8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try adjusting your search terms'
                        : 'Notifications will appear here when you receive them',
                    style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, index)
                  .animate(delay: (100 * index).ms)
                  .slideX(begin: 0.3, duration: AppTheme.durationMedium)
                  .fadeIn(duration: AppTheme.durationMedium);
            },
            childCount: notifications.length,
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    final isUnread = !notification.isRead;
    final timestamp = notification.time;
    final timeAgo = _getTimeAgo(timestamp);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space6,
      ),
      child: Card(
        elevation: 0,
        color: Colors.white.withOpacity(isUnread ? 1.0 : 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radius16,
          side: BorderSide(
            color: isUnread ? AppTheme.primary500.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppTheme.radius16,
          onTap: () async {
            if (isUnread && notification.id != null) {
              await _notificationService.markAsRead(notification.id!);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(AppTheme.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(top: AppTheme.space8, right: AppTheme.space12),
                  decoration: BoxDecoration(
                    color: isUnread ? AppTheme.primary500 : AppTheme.neutral300,
                    shape: BoxShape.circle,
                  ),
                ),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTheme.subtitle1.copyWith(
                                color: AppTheme.neutral800,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                      if (notification.body.isNotEmpty) ...[
                        SizedBox(height: AppTheme.space6),
                        Text(
                          notification.body,
                          style: AppTheme.body2.copyWith(
                            color: AppTheme.neutral600,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: AppTheme.space8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.neutral400,
                          ),
                          SizedBox(width: AppTheme.space4),
                          Text(
                            _formatDateTime(timestamp),
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.neutral400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
