import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';

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
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
    );

    _searchAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _searchController, curve: Curves.easeOutBack));

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
            // 🎨 Modern App Bar with Search
            _buildModernAppBar(),
            
            // 📊 Quick Stats
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _listAnimation,
                child: _buildStatsCard(),
              ),
            ),
            
            // 🔍 Search Bar
            if (_isSearching)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _searchAnimation,
                  child: _buildSearchBar(),
                ),
              ),
            
            // 📋 Notifications List
            _buildNotificationsList(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
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
          style: AppTheme.headline2.copyWith(
            color: AppTheme.neutral700,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
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
              _isSearching ? Icons.close : Icons.search,
              color: _isSearching ? Colors.white : AppTheme.neutral700,
              size: 20,
            ),
          ),
          onPressed: _toggleSearch,
          tooltip: _isSearching ? 'Close Search' : 'Search Notifications',
        ),
        
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: AppTheme.error500.withOpacity(0.1),
              borderRadius: AppTheme.radius8,
            ),
            child: Icon(
              Icons.delete_sweep,
              color: AppTheme.error500,
              size: 20,
            ),
          ),
          onPressed: () => _showClearDialog(),
          tooltip: 'Clear All',
        ),
        
        SizedBox(width: AppTheme.space8),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(AppTheme.space16),
      child: AnimatedCard(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppTheme.radius16,
          ),
          padding: EdgeInsets.all(AppTheme.space20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppTheme.radius16,
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              SizedBox(width: AppTheme.space16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Archive',
                      style: AppTheme.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppTheme.space4),
                    StreamBuilder<List<NotificationItem>>(
                      stream: _notificationService.getNotifications(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            'Loading...',
                            style: AppTheme.body2.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          );
                        }
                        
                        final totalCount = snapshot.data!.length;
                        return Text(
                          '$totalCount notification${totalCount == 1 ? '' : 's'} stored',
                          style: AppTheme.body2.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppTheme.radius24,
                ),
                child: Text(
                  'ALL READ',
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: AnimatedCard(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radius16,
            border: Border.all(color: AppTheme.primary500.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _searchTextController,
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search notifications...',
              hintStyle: AppTheme.body2.copyWith(color: AppTheme.neutral500),
              prefixIcon: Icon(Icons.search, color: AppTheme.primary500),
              suffixIcon: _searchTextController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.neutral500),
                      onPressed: () {
                        _searchTextController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
            ),
            style: AppTheme.body2.copyWith(color: AppTheme.neutral700),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(String userId) {
    return StreamBuilder<List<NotificationItem>>(
      stream: _notificationService.getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: _buildLoadingState(),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(),
          );
        }

        final allNotifications = snapshot.data!
            .where((notification) {
              if (_searchQuery.isEmpty) return true;
              return notification.title.toLowerCase().contains(_searchQuery) ||
                     notification.body.toLowerCase().contains(_searchQuery);
            })
            .toList();

        if (allNotifications.isEmpty && _searchQuery.isNotEmpty) {
          return SliverToBoxAdapter(
            child: _buildNoSearchResults(),
          );
        }

        // Group notifications by date
        final groupedNotifications = _groupNotificationsByDate(allNotifications);

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entries = groupedNotifications.entries.toList();
              final dateKey = entries[index].key;
              final notifications = entries[index].value;

              return AnimatedBuilder(
                animation: _listAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _listAnimation.value)),
                    child: Opacity(
                      opacity: _listAnimation.value,
                      child: _buildDateSection(dateKey, notifications),
                    ),
                  );
                },
              );
            },
            childCount: groupedNotifications.length,
          ),
        );
      },
    );
  }

  Widget _buildDateSection(String dateKey, List<NotificationItem> notifications) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            margin: EdgeInsets.only(bottom: AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.primary500.withOpacity(0.1),
              borderRadius: AppTheme.radius24,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primary500,
                ),
                SizedBox(width: AppTheme.space8),
                Text(
                  dateKey,
                  style: AppTheme.subtitle2.copyWith(
                    color: AppTheme.primary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: AppTheme.space8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary500,
                    borderRadius: AppTheme.radius32,
                  ),
                  child: Text(
                    '${notifications.length}',
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Notifications for this date
          ...notifications.map((notification) => _buildNotificationCard(notification)),
          
          SizedBox(height: AppTheme.space16),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.space12),
      child: AnimatedCard(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.radius16,
            border: Border.all(
              color: AppTheme.neutral200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.radius16,
                ),
                child: Icon(
                  Icons.nfc,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              SizedBox(width: AppTheme.space16),
              
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
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral700,
                            ),
                          ),
                        ),
                        Text(
                          _notificationService.formatTime(notification.time),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: AppTheme.space4),
                    
                    Text(
                      notification.body,
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.neutral500,
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.space8),
                    
                    Row(
                      children: [
                        StatusChip(
                          label: 'ARCHIVED',
                          color: AppTheme.neutral500,
                          icon: Icons.archive,
                        ),
                        Spacer(),
                        if (notification.id != null)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppTheme.error500,
                              size: 18,
                            ),
                            onPressed: () => _deleteNotification(notification.id!),
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.all(4),
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
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppTheme.space48),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary500),
          ),
          SizedBox(height: AppTheme.space24),
          Text(
            'Loading notifications...',
            style: AppTheme.body1.copyWith(color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(AppTheme.space48),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: AppTheme.error500.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error500,
            ),
          ),
          SizedBox(height: AppTheme.space24),
          Text(
            'Error loading notifications',
            style: AppTheme.headline3.copyWith(
              color: AppTheme.error500,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.space8),
          Text(
            error,
            style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppTheme.space48),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 64,
              color: AppTheme.neutral500,
            ),
          ),
          SizedBox(height: AppTheme.space24),
          Text(
            'No notifications yet',
            style: AppTheme.headline3.copyWith(
              color: AppTheme.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.space8),
          Text(
            'Your notification history will appear here once you start receiving RFID scans',
            style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      padding: EdgeInsets.all(AppTheme.space48),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: AppTheme.warning500.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.warning500,
            ),
          ),
          SizedBox(height: AppTheme.space24),
          Text(
            'No results found',
            style: AppTheme.headline3.copyWith(
              color: AppTheme.warning500,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.space8),
          Text(
            'Try adjusting your search terms or clear the search to see all notifications',
            style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, List<NotificationItem>> _groupNotificationsByDate(
      List<NotificationItem> notifications) {
    final Map<String, List<NotificationItem>> grouped = {};
    
    for (final notification in notifications) {
      final dateKey = _formatDateKey(notification.time);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(notification);
    }
    
    // Sort by date (most recent first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        // Parse the date keys and compare
        final aDate = DateTime.parse(a.value.first.time.toIso8601String().split('T')[0]);
        final bDate = DateTime.parse(b.value.first.time.toIso8601String().split('T')[0]);
        return bDate.compareTo(aDate);
      });
    
    return Map.fromEntries(sortedEntries);
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: AppTheme.success500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: AppTheme.error500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showClearDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radius16,
        ),
        title: Text(
          'Clear All Notifications',
          style: AppTheme.headline3.copyWith(
            color: AppTheme.neutral700,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all notification history? This action cannot be undone.',
          style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTheme.subtitle1.copyWith(color: AppTheme.neutral500),
            ),
          ),
          GradientButton(
            text: 'Clear All',
            gradient: AppTheme.errorGradient,
            onPressed: () => Navigator.of(context).pop(true),
            width: 100,
            height: 40,
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _notificationService.clearAllNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: AppTheme.success500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
            backgroundColor: AppTheme.error500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
