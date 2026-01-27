import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';

class AdminEditTaskScreen extends StatefulWidget {
  final Map taskData;
  const AdminEditTaskScreen({super.key, required this.taskData});

  @override
  State<AdminEditTaskScreen> createState() => _AdminEditTaskScreenState();
}

class _AdminEditTaskScreenState extends State<AdminEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk input teks
  late TextEditingController _agendaController;
  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _dayaController;
  
  // State untuk tanggal
  String? _tglPasang;
  String? _tglBongkar;
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF1A56F0);

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data awal dari database
    _agendaController = TextEditingController(text: widget.taskData['id_pelanggan']);
    _namaController = TextEditingController(text: widget.taskData['nama_pelanggan']);
    _alamatController = TextEditingController(text: widget.taskData['alamat']);
    _dayaController = TextEditingController(text: widget.taskData['daya'].toString());
    _tglPasang = widget.taskData['tgl_pasang'];
    _tglBongkar = widget.taskData['tgl_bongkar'];
  }

  // Fungsi untuk menampilkan DatePicker
  Future<void> _pickDate(bool isPasang) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(isPasang ? _tglPasang! : _tglBongkar!),
      firstDate: DateTime(2025), // Sesuai tahun tugas Anda
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        String formatted = DateFormat('yyyy-MM-dd').format(picked);
        if (isPasang) {
          _tglPasang = formatted;
        } else {
          _tglBongkar = formatted;
        }
      });
    }
  }

  // Fungsi utama untuk menyimpan perubahan
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final int taskId = widget.taskData['id'];
      final String teknisi = widget.taskData['teknisi'];

      try {
        // 1. VALIDASI BEBAN KERJA (Maksimal 2 jadwal per hari)
        // Cek ketersediaan untuk tanggal pasang baru
        bool pasangOk = await TaskService().isTechnicianAvailable(taskId, teknisi, _tglPasang!);
        // Cek ketersediaan untuk tanggal bongkar baru
        bool bongkarOk = await TaskService().isTechnicianAvailable(taskId, teknisi, _tglBongkar!);

        if (!pasangOk || !bongkarOk) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text("Gagal: Teknisi ini sudah memiliki 2 jadwal pada tanggal yang dipilih!"),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 2. Jika validasi lolos, eksekusi Update ke Supabase
        await TaskService().updateTask(taskId, {
          'id_pelanggan': _agendaController.text,
          'nama_pelanggan': _namaController.text,
          'alamat': _alamatController.text,
          'daya': _dayaController.text,
          'tgl_pasang': _tglPasang,
          'tgl_bongkar': _tglBongkar,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data penugasan berhasil diperbarui")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Edit Data Penugasan"),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Input ID Pelanggan / Nomor Agenda
              _buildTextField(_agendaController, "ID Pelanggan / Nomor Agenda", Icons.assignment_ind),
              
              // Input Nama Pelanggan
              _buildTextField(_namaController, "Nama Pelanggan", Icons.person),
              
              // Input Alamat
              _buildTextField(_alamatController, "Alamat Lengkap", Icons.map, maxLines: 2),
              
              // Input Daya
              _buildTextField(_dayaController, "Daya (VA)", Icons.bolt, isNumber: true),
              
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              
              // Selector Tanggal Pasang
              _buildDatePickerTile("Rencana Tanggal Pasang", _tglPasang!, () => _pickDate(true)),
              
              const SizedBox(height: 10),
              
              // Selector Tanggal Bongkar
              _buildDatePickerTile("Rencana Tanggal Bongkar", _tglBongkar!, () => _pickDate(false)),
              
              const SizedBox(height: 40),
              
              // Tombol Simpan
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Simpan Perubahan", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Text Field
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) => v!.isEmpty ? "Bidang ini tidak boleh kosong" : null,
      ),
    );
  }

  // Widget Helper untuk Date Selector Tile
  Widget _buildDatePickerTile(String label, String date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4E8)),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(date)), 
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        trailing: Icon(Icons.calendar_today_rounded, color: primaryBlue, size: 22),
        onTap: onTap,
      ),
    );
  }
}