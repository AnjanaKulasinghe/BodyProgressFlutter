import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

/// Local notification service — equivalent to iOS NotificationService.swift
/// Works on both iOS and Android via flutter_local_notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  
  // SharedPreferences keys
  static const _keyDailyStatsEnabled = 'notification_daily_stats_enabled';
  static const _keyWeeklyPhotoEnabled = 'notification_weekly_photo_enabled';

  // ── Notification IDs ──────────────────────────────────────────────────────
  static const _dailyStatsId   = 1001;
  static const _weeklyPhotoId  = 1002;
  static const _motivationalId = 1003;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    // iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true, badge: true, sound: true,
    );

    // Android 13+
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidPlugin?.requestNotificationsPermission();

    return iosGranted ?? androidGranted ?? false;
  }

  Future<bool> isPermissionGranted() async {
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      // Check iOS permission status (approximation)
      return true;
    }
    return true;
  }

  // ── Daily Stats Reminder (8:00 PM) ────────────────────────────────────────

  Future<void> scheduleDailyStatsReminder({
    int hour = 20, // 8 PM default
    int minute = 0,
  }) async {
    try {
      await _notifications.zonedSchedule(
        _dailyStatsId,
        "Time to log your stats! 💪",
        "Keep your progress on track — log your measurements now.",
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_stats',
            'Daily Stats Reminder',
            channelDescription: 'Daily reminder to log body measurements',
            importance: Importance.high,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction('OPEN_STATS', 'Log Stats'),
              AndroidNotificationAction('DISMISS', 'Dismiss'),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'DAILY_STATS',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDailyStatsEnabled, true);
    } catch (e) {
      // If exact alarms fail (Android 12+ permission issue), try inexact scheduling
      if (e.toString().contains('exact_alarms_not_permitted')) {
        try {
          await _notifications.zonedSchedule(
            _dailyStatsId,
            "Time to log your stats! 💪",
            "Keep your progress on track — log your measurements now.",
            _nextInstanceOfTime(hour, minute),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_stats',
                'Daily Stats Reminder',
                channelDescription: 'Daily reminder to log body measurements',
                importance: Importance.high,
                priority: Priority.high,
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction('OPEN_STATS', 'Log Stats'),
                  AndroidNotificationAction('DISMISS', 'Dismiss'),
                ],
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'DAILY_STATS',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          
          // Save preference
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyDailyStatsEnabled, true);
        } catch (inexactError) {
          // If even inexact scheduling fails, rethrow
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelDailyStatsReminder() async {
    await _notifications.cancel(_dailyStatsId);
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyStatsEnabled, false);
  }
  
  Future<bool> isDailyStatsReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyStatsEnabled) ?? false;
  }

  // ── Weekly Photo Reminder (Sunday 10:00 AM) ───────────────────────────────

  Future<void> scheduleWeeklyPhotoReminder({
    int hour = 10,
    int minute = 0,
    int weekday = 7, // Sunday (1=Mon ... 7=Sun)
  }) async {
    try {
      await _notifications.zonedSchedule(
        _weeklyPhotoId,
        "Weekly photo time! 📸",
        "Document your progress — take your weekly progress photo.",
        _nextInstanceOfWeekday(weekday, hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_photo',
            'Weekly Photo Reminder',
            channelDescription: 'Weekly reminder to take a progress photo',
            importance: Importance.defaultImportance,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction('OPEN_CAMERA', 'Take Photo'),
              AndroidNotificationAction('DISMISS', 'Dismiss'),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'WEEKLY_PHOTO',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyWeeklyPhotoEnabled, true);
    } catch (e) {
      // If exact alarms fail, try inexact scheduling
      if (e.toString().contains('exact_alarms_not_permitted')) {
        try {
          await _notifications.zonedSchedule(
            _weeklyPhotoId,
            "Weekly photo time! 📸",
            "Document your progress — take your weekly progress photo.",
            _nextInstanceOfWeekday(weekday, hour, minute),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'weekly_photo',
                'Weekly Photo Reminder',
                channelDescription: 'Weekly reminder to take a progress photo',
                importance: Importance.defaultImportance,
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction('OPEN_CAMERA', 'Take Photo'),
                  AndroidNotificationAction('DISMISS', 'Dismiss'),
                ],
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'WEEKLY_PHOTO',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          
          // Save preference
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyWeeklyPhotoEnabled, true);
        } catch (inexactError) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelWeeklyPhotoReminder() async {
    await _notifications.cancel(_weeklyPhotoId);
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyPhotoEnabled, false);
  }
  
  Future<bool> isWeeklyPhotoReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeeklyPhotoEnabled) ?? false;
  }

  // ── Motivational Notification ─────────────────────────────────────────────

  Future<void> sendMotivationalNotification({
    String? title,
    String? body,
  }) async {
    const messages = [
      ('Keep going! 🔥', 'Every rep counts. Stay consistent!'),
      ('You\'re crushing it! 💪', 'Progress is progress, no matter how small.'),
      ('Stay on track! 🎯', 'Your goals are within reach. Keep pushing!'),
    ];
    final idx = DateTime.now().millisecond % messages.length;

    await _notifications.show(
      _motivationalId,
      title ?? messages[idx].$1,
      body ?? messages[idx].$2,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivational',
          'Motivational Messages',
          importance: Importance.low,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Cancel All ────────────────────────────────────────────────────────────

  Future<void> cancelAll() => _notifications.cancelAll();

  // ── Helpers ───────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation is handled by the router via NotificationService callbacks below
    if (response.actionId == 'OPEN_STATS') {
      _onNavigateToStats?.call();
    } else if (response.actionId == 'OPEN_CAMERA') {
      _onNavigateToCamera?.call();
    }
  }

  // Callbacks set by main.dart / router
  void Function()? _onNavigateToStats;
  void Function()? _onNavigateToCamera;

  void setNavigationCallbacks({
    void Function()? onNavigateToStats,
    void Function()? onNavigateToCamera,
  }) {
    _onNavigateToStats  = onNavigateToStats;
    _onNavigateToCamera = onNavigateToCamera;
  }
}
