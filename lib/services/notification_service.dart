import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      null, // Menggunakan ikon default sistem
      [
        NotificationChannel(
          channelKey: 'pesta_channel',
          channelName: 'Notifikasi PESTA',
          channelDescription: 'Peringatan tugas pemasangan dan pembongkaran',
          defaultColor: const Color(0xFF1A56F0),
          importance:
              NotificationImportance.Max, // Muncul sebagai pop-up di atas layar
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );

    // Meminta izin notifikasi saat inisialisasi
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> showInstantNotification(Map<String, dynamic> task) async {
    // 1. Ambil data jenis_tugas dari alias SQL atau kolom status
    String jenis = (task['jenis_tugas'] ?? task['status'] ?? "")
        .toString()
        .toLowerCase();

    String title = "Tugas PESTA Baru!";
    String body =
        "Agenda ${task['id_pelanggan']} untuk ${task['nama_pelanggan']}";
    NotificationCategory category = NotificationCategory.Reminder;

    // 2. Logika Penentuan Isi Notifikasi Berdasarkan Jenis
    if (jenis.contains("pemasangan")) {
      title = "🔔 Reminder Pemasangan!";
      body =
          "Ada jadwal pemasangan baru untuk pelanggan ${task['nama_pelanggan']}";
      category = NotificationCategory.Status;
    } else if (jenis.contains("pembongkaran")) {
      title = "⚠️ Reminder Pembongkaran!";
      body = "Waktunya pembongkaran untuk pelanggan ${task['nama_pelanggan']}";
      category = NotificationCategory.Alarm;
    }

    print("LOG: Memicu notifikasi instan [$jenis]"); // Debugging di terminal

    // 3. Eksekusi Notifikasi
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        // Gunakan kombinasi ID unik agar notifikasi pemasangan & pembongkaran tidak menimpa satu sama lain
        id:
            int.parse(task['id'].toString()) +
            (jenis.contains("pemasangan") ? 100 : 200),
        channelKey: 'pesta_channel',
        title: title,
        body: body,
        category: category,
        largeIcon:
            'resource://drawable/logopln', // Pastikan file ada di android/app/src/main/res/drawable
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true, // Layar menyala saat notif masuk
        payload: {'id': task['id'].toString()},
      ),
    );
  }
}
