import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationService {
  // 1. Inisialisasi Channel Notifikasi (Tetap Sesuai Struktur Asli)
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      null, // Menggunakan ikon default sistem
      [
        NotificationChannel(
          channelKey: 'pesta_channel',
          channelName: 'Notifikasi PESTA',
          channelDescription: 'Peringatan tugas pemasangan dan pembongkaran',
          defaultColor: const Color(0xFF1A56F0),
          importance: NotificationImportance.Max, // Muncul sebagai pop-up di atas layar
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );

    // Meminta izin notifikasi jika belum diizinkan
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // 2. Fungsi Memicu Notifikasi Instan (Revisi Logika H-1 & Agenda)
  static Future<void> showInstantNotification(Map<String, dynamic> task) async {
    // Ambil data status dan tanggal untuk menentukan jenis pesan
    String status = (task['status'] ?? "").toString().toLowerCase();
    String tglPasang = task['tgl_pasang'] ?? "";
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Label diperbarui menjadi Nomor Agenda
    String agenda = task['no_agenda'] ?? task['id_pelanggan'] ?? "-";
    String namaPlg = task['nama_pelanggan'] ?? "Pelanggan";

    String title = "Tugas PESTA Baru!";
    String body = "Agenda $agenda untuk $namaPlg";
    NotificationCategory category = NotificationCategory.Reminder;

    // Logika Penentuan Isi Notifikasi Berdasarkan Revisi H-1
    if (status.contains("pemasangan")) {
      category = NotificationCategory.Status;
      if (tglPasang != todayStr) {
        // Pesan khusus untuk penugasan H-1
        title = "🔔 Eksekusi Pemasangan (H-1)!";
        body = "Penugasan untuk $namaPlg (Agenda: $agenda) sudah bisa dieksekusi mulai hari ini.";
      } else {
        // Pesan untuk penugasan tepat di Hari-H
        title = "🔔 Reminder Pemasangan Hari Ini!";
        body = "Hari ini jadwal pemasangan untuk $namaPlg (Agenda: $agenda). Silakan lakukan konfirmasi.";
      }
    } else if (status.contains("pembongkaran")) {
      title = "⚠️ Reminder Pembongkaran!";
      body = "Waktunya pembongkaran untuk pelanggan $namaPlg (Agenda: $agenda).";
      category = NotificationCategory.Alarm;
    }

    debugPrint("LOG: Memicu notifikasi instan [$status] untuk Agenda $agenda");

    // 3. Eksekusi Pengiriman Notifikasi ke Sistem Android/iOS
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        // Gunakan kombinasi ID unik agar notifikasi tidak saling menimpa
        id: int.tryParse(task['id'].toString()) ?? DateTime.now().millisecond,
        channelKey: 'pesta_channel',
        title: title,
        body: body,
        category: category,
        // Pastikan file logopln.png ada di res/drawable
        largeIcon: 'resource://drawable/logopln', 
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true, // Layar otomatis menyala saat notif masuk
        payload: {'id': task['id'].toString()},
      ),
    );
  }

  // Helper untuk schedule (Tetap dipertahankan sesuai struktur aslimu)
  static void scheduleTaskNotification(dynamic task) {}
}