import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _alarmPlaying = false;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'locker_alert_channel',
      'Locker Alerts',
      description: 'Alerts when locker drawer is opened',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showAlert() async {
    await _localNotif.show(
      1,
      '🔴 Locker रक्षक — ALERT!',
      'Drawer movement detected! Check immediately.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'locker_alert_channel',
          'Locker Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> playAlarm() async {
    if (_alarmPlaying) return;
    _alarmPlaying = true;
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
  }

  Future<void> stopAlarm() async {
    if (!_alarmPlaying) return;
    _alarmPlaying = false;
    await _audioPlayer.stop();
  }

  bool get isAlarmPlaying => _alarmPlaying;
}
