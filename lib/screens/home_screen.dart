import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class LockerHomeScreen extends StatefulWidget {
  const LockerHomeScreen({super.key});

  @override
  State<LockerHomeScreen> createState() => _LockerHomeScreenState();
}

class _LockerHomeScreenState extends State<LockerHomeScreen>
    with SingleTickerProviderStateMixin {
  final LockerFirebaseService _fb = LockerFirebaseService();
  final NotificationService _notif = NotificationService();

  LockerData _data = LockerData(
    accelX: 0, accelY: 0, accelZ: 0, isAlert: false, isOn: true,
  );

  bool _previousAlert = false;
  StreamSubscription? _subscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _subscription = _fb.lockerStream.listen((data) {
      if (data.isAlert && !_previousAlert) {
        _notif.playAlarm();
        _notif.showAlert();
      }
      if (!data.isAlert && _previousAlert) {
        _notif.stopAlarm();
      }
      _previousAlert = data.isAlert;
      setState(() => _data = data);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleControl() async {
    await _fb.setControl(!_data.isOn);
  }

  Future<void> _acknowledge() async {
    await _notif.stopAlarm();
    await _fb.acknowledgeAlert();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAlertCard(),
              const SizedBox(height: 20),
              _buildAccelCard(),
              const SizedBox(height: 20),
              _buildControlCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('🔒', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Locker रक्षक',       // ← UI name only here
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Smart Locker Monitor',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard() {
    final isAlert = _data.isAlert;
    final color   = isAlert ? const Color(0xFFFF3B30) : const Color(0xFF34C759);

    return ScaleTransition(
      scale: isAlert ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isAlert ? 0.2 : 0.05),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              isAlert ? '🔴' : '🟢',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              isAlert ? 'ALERT' : 'NORMAL',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAlert ? 'Drawer movement detected!' : 'Locker is secure',
              style: GoogleFonts.inter(fontSize: 14, color: color.withOpacity(0.8)),
            ),
            if (isAlert) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _acknowledge,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  'Acknowledge & Stop Alarm',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Accelerometer Data',
                style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
              const Spacer(),
              Text('m/s²', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 20),
          _buildAccelRow('X', _data.accelX, const Color(0xFFFF3B30)),
          const SizedBox(height: 14),
          _buildAccelRow('Y', _data.accelY, const Color(0xFF34C759)),
          const SizedBox(height: 14),
          _buildAccelRow('Z', _data.accelZ, const Color(0xFF0A84FF)),
        ],
      ),
    );
  }

  Widget _buildAccelRow(String axis, double value, Color color) {
    final barPercent = (value.abs() / 10.0).clamp(0.0, 1.0);
    final isHigh     = value.abs() > 6.88;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      axis,
                      style: GoogleFonts.inter(
                        color: color, fontWeight: FontWeight.w800, fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${value.toStringAsFixed(2)} m/s²',
                  style: GoogleFonts.inter(
                    color: isHigh ? const Color(0xFFFF3B30) : Colors.white,
                    fontWeight: isHigh ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (isHigh)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⚠️ HIGH',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF3B30), fontSize: 11, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: barPercent,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isHigh ? const Color(0xFFFF3B30) : color,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildControlCard() {
    final isOn  = _data.isOn;
    final color = isOn ? const Color(0xFF34C759) : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOn ? Icons.power_settings_new : Icons.power_off_outlined,
              color: color, size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Control',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                  ),
                ),
                Text(
                  isOn ? 'Device is ON — monitoring active' : 'Device is OFF — monitoring paused',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleControl,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 64, height: 34,
              decoration: BoxDecoration(
                color: isOn ? const Color(0xFF34C759) : const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(17),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 28, height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
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
