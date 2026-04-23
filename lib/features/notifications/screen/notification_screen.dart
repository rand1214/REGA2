import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String text;
  final DateTime createdAt;
  final String userType;
  final int displayDuration;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.userType,
    this.displayDuration = 5,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      userType: json['user_type'] as String? ?? 'all',
      displayDuration: json['display_duration'] as int? ?? 5,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabaseService.supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      final items = (response as List)
          .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = now.difference(date);
    final dayDiff =
        today.difference(DateTime(date.year, date.month, date.day)).inDays;

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (dayDiff == 0) {
      final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final m = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    }
    if (dayDiff == 1) return 'Yesterday';
    if (dayDiff < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (date.year == now.year) return '${months[date.month - 1]} ${date.day}';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        body: Column(
          children: [
            _buildHeader(scale),
            Expanded(child: _buildBody(scale)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E7BBF), Color(0xFF0E5A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20 * scale),
          bottomRight: Radius.circular(20 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B8C).withValues(alpha: 0.3),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
            spreadRadius: -4 * scale,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Pattern Layer
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20 * scale),
                bottomRight: Radius.circular(20 * scale),
              ),
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/icons/blue-traffic-pattern-for-bg.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          // Decorative Circle Layer
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content Layer
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 18 * scale,
                right: 18 * scale,
                top: 12 * scale,
                bottom: 14 * scale,
              ),
              child: Row(
                children: [
                  // Balancer for back button
                  SizedBox(width: 38 * scale),
                  const Spacer(),
                  // Title
                  Text(
                    'ئاگادارییەکان',
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      color: Colors.white,
                      fontSize: 17 * scale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  // Back button (Right side in RTL)
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38 * scale,
                      height: 38 * scale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12 * scale),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2C6EA3), Color(0xFF1F5E8E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12 * scale,
                            offset: Offset(0, 4 * scale),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0080C8),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_error != null) {
      return _buildCenteredState(
        scale: scale,
        icon: Icons.wifi_off_rounded,
        iconColor: Colors.red.shade300,
        label: 'هەڵەیەک ڕوویدا',
        sublabel: 'تکایە دووبارە هەوڵ بدەرەوە',
        action: GestureDetector(
          onTap: _loadNotifications,
          child: Container(
            margin: EdgeInsets.only(top: 20 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 28 * scale,
              vertical: 13 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0080C8),
              borderRadius: BorderRadius.circular(14 * scale),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0080C8).withValues(alpha: 0.35),
                  blurRadius: 12 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Text(
              'دووبارە هەوڵ بدەرەوە',
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 14 * scale,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF0080C8),
        strokeWidth: 2.5,
        onRefresh: _loadNotifications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Center(
              child: _buildCenteredState(
                scale: scale,
                icon: Icons.inbox_rounded,
                iconColor: const Color(0xFF9CA3AF),
                label: 'هیچ ئاگادارییەک نییە',
                sublabel: 'کاتێک ئاگادارییەکت هات ئێرە دەردەکەوێت',
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0080C8),
      strokeWidth: 2.5,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          16 * scale,
          16 * scale,
          32 * scale,
        ),
        itemCount: _notifications.length,
        itemBuilder: (context, index) => _buildCard(_notifications[index], scale),
      ),
    );
  }

  Widget _buildCenteredState({
    required double scale,
    required IconData icon,
    required Color iconColor,
    required String label,
    String? sublabel,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52 * scale, color: iconColor),
            SizedBox(height: 20 * scale),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 17 * scale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            if (sublabel != null) ...[
              SizedBox(height: 8 * scale),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 13 * scale,
                  color: const Color(0xFF9CA3AF),
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  Widget _buildCard(NotificationItem item, double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 10 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14 * scale),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 10 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20 * scale,
                    height: 20 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0080C8),
                      borderRadius: BorderRadius.circular(5 * scale),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      size: 13 * scale,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    'ئاگاداری',
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 11 * scale,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 11 * scale,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              if (item.title.isNotEmpty)
                Text(
                  item.title,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              if (item.title.isNotEmpty && item.text.isNotEmpty) SizedBox(height: 3 * scale),
              if (item.text.isNotEmpty)
                Text(
                  item.text,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: 12 * scale,
                    color: const Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}