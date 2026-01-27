import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class TaskService {
  final supabase = Supabase.instance.client;

  // 1. Fungsi Pencarian Global (Berdasarkan ID Pelanggan atau Nama)
  Future<List<dynamic>> searchTasks(String query) async {
    try {
      final response = await supabase
          .from('pesta_tasks')
          .select()
          .or('id_pelanggan.ilike.%$query%,nama_pelanggan.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response as List<dynamic>;
    } catch (e) {
      debugPrint("Error Search Task: $e");
      return [];
    }
  }

  // 2. Fungsi Validasi Workload (Limit 2 tugas/hari untuk teknisi tertentu)
  Future<bool> isTechnicianAvailable(int currentTaskId, String techUsername, String date) async {
    try {
      // Menghitung tugas pada tgl_pasang atau tgl_bongkar yang sama
      final response = await supabase
          .from('pesta_tasks')
          .select('id')
          .eq('teknisi', techUsername)
          .or('tgl_pasang.eq.$date,tgl_bongkar.eq.$date')
          .neq('id', currentTaskId); // Tidak menghitung tugas yang sedang di-edit

      final List<dynamic> tasks = response as List<dynamic>;
      // Jika tugas di hari tersebut kurang dari 2, maka tersedia
      return tasks.length < 2;
    } catch (e) {
      debugPrint("Error Check Workload: $e");
      return false;
    }
  }

  // 3. Fungsi Update Data Penugasan
  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    try {
      await supabase.from('pesta_tasks').update(data).eq('id', id);
    } catch (e) {
      debugPrint("Error Update Task di Supabase: $e");
      rethrow;
    }
  }
}