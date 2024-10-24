import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../extensions/extensions.dart';
import 'alarm_notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<AlarmSettings> alarms;

  // ignore: cancel_subscriptions
  static StreamSubscription<AlarmSettings>? subscription;

  ///
  @override
  void initState() {
    super.initState();

    checkAndroidNotificationPermission();

    checkAndroidScheduleExactAlarmPermission();

    loadAlarms();

    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
  }

  ///
  Future<void> checkAndroidNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.status;

    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');

      final PermissionStatus res = await Permission.notification.request();

      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not '}granted',
      );
    }
  }

  ///
  Future<void> checkAndroidScheduleExactAlarmPermission() async {
    final PermissionStatus status = await Permission.scheduleExactAlarm.status;

    if (kDebugMode) {
      print('Schedule exact alarm permission: $status.');
    }

    if (status.isDenied) {
      if (kDebugMode) {
        print('Requesting schedule exact alarm permission...');
      }

      final PermissionStatus res =
          await Permission.scheduleExactAlarm.request();

      if (kDebugMode) {
        print(
            'Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted.');
      }
    }
  }

  ///
  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();

      alarms.sort((AlarmSettings a, AlarmSettings b) =>
          a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  ///
  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            AlarmNotificationScreen(alarmSettings: alarmSettings),
      ),
    );

    loadAlarms();
  }

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //

      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                // ignore: always_specify_types
                children: List.generate(
                  alarms.length,
                  (int index) => ListTile(
                    title: Text(alarms[index].dateTime.toString()),
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    final DateTime alarmDateTime =
                        DateTime.now().add(const Duration(seconds: 10));

                    setAlarm(alarmId: 1, alarmDateTime: alarmDateTime);
                  },
                  child: const Text('10s'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime alarmDateTime =
                        DateTime.now().add(const Duration(seconds: 20));

                    setAlarm(alarmId: 2, alarmDateTime: alarmDateTime);
                  },
                  child: const Text('20s'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    for (final Map<String, Object> element
                        in <Map<String, Object>>[
                      <String, Object>{
                        'id': 1,
                        'time': DateTime.now().add(const Duration(seconds: 10))
                      },
                      <String, Object>{
                        'id': 2,
                        'time': DateTime.now().add(const Duration(seconds: 20))
                      },
                    ]) {
                      setAlarm(
                        alarmId: element['id'].toString().toInt(),
                        alarmDateTime:
                            DateTime.parse(element['time'].toString()),
                      );
                    }
                  },
                  child: const Text('renzoku'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ///
  Future<void> setAlarm(
      {required int alarmId, required DateTime alarmDateTime}) async {
    final AlarmSettings alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarmDateTime,
      assetAudioPath: 'assets/blank.mp3',
      // ignore: avoid_redundant_argument_values
      loopAudio: true,
      // ignore: avoid_redundant_argument_values
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      notificationSettings: const NotificationSettings(
        title: 'This is the title',
        body: 'This is the body',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    loadAlarms();
  }

  ///
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(
      DiagnosticsProperty<StreamSubscription<AlarmSettings>?>(
        'subscription',
        subscription,
      ),
    );
  }
}
