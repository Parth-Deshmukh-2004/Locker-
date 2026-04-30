import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class LockerFirebaseService {
  static final LockerFirebaseService _instance = LockerFirebaseService._internal();
  factory LockerFirebaseService() => _instance;
  LockerFirebaseService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference get _mpuRef     => _db.ref('MPU6050');
  DatabaseReference get _alertRef   => _db.ref('MPU6050/Alert');
  DatabaseReference get _controlRef => _db.ref('MPU6050/Control');

  Stream<LockerData> get lockerStream {
    return _mpuRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return LockerData.fromMap(data ?? {});
    });
  }

  Future<void> setControl(bool isOn) async {
    await _controlRef.set(isOn ? 'ON' : 'OFF');
  }

  Future<void> acknowledgeAlert() async {
    await _alertRef.set('NORMAL');
  }
}

class LockerData {
  final double accelX;
  final double accelY;
  final double accelZ;
  final bool isAlert;
  final bool isOn;

  LockerData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.isAlert,
    required this.isOn,
  });

  factory LockerData.fromMap(Map<dynamic, dynamic> map) {
    return LockerData(
      accelX:  (map['AccelX'] as num?)?.toDouble() ?? 0.0,
      accelY:  (map['AccelY'] as num?)?.toDouble() ?? 0.0,
      accelZ:  (map['AccelZ'] as num?)?.toDouble() ?? 0.0,
      isAlert: map['Alert']?.toString() == 'ALERT',
      isOn:    map['Control']?.toString() != 'OFF',
    );
  }
}
