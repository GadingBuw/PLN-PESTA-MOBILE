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
  
  // Controller untuk input teks (Lama, Baru, dan Revisi No Telp)
  late TextEditingController _agendaController;
  late TextEditingController _namaController;
  late TextEditingController _noTelpController; // Penambahan No Telp
  late TextEditingController _alamatController;
  late TextEditingController _dayaController;
  late TextEditingController _eMinController;
  late TextEditingController _kwhBayarController;
  late TextEditingController _standPasangController;
  late TextEditingController _standBongkarController;
  
  // State untuk tanggal
  String? _tglPasang;
  String? _tglBongkar;
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF1A56F0);

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data dari database
    _agendaController = TextEditingController(text: widget.taskData['no_agenda']);
    _namaController = TextEditingController(text: widget.taskData['nama_pelanggan']);
    _noTelpController = TextEditingController(text: widget.taskData['no_telp'] ?? ""); // Init No Telp
    _alamatController = TextEditingController(text: widget.taskData['alamat']);
    _dayaController = TextEditingController(text: widget.taskData['daya'].toString());
    
    // Inisialisasi kolom parameter teknis
    _eMinController = TextEditingController(text: (widget.taskData['e_min_kwh'] ?? 0).toString());
    _kwhBayarController = TextEditingController(text: (widget.taskData['kwh_terbayar'] ?? 0).toString());
    _standPasangController = TextEditingController(text: (widget.taskData['stand_pasang'] ?? 0).toString());
    _standBongkarController = TextEditingController(text: (widget.taskData['stand_bongkar'] ?? 0).toString());
    
    _tglPasang = widget.taskData['tgl_pasang'];
    _tglBongkar = widget.taskData['tgl_bongkar'];
  }

  // Fungsi untuk menampilkan DatePicker
  Future<void> _pickDate(bool isPasang) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(isPasang ? _tglPasang! : _tglBongkar!),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        String formatted = DateFormat('yyyy-MM-dd').format(picked);
        if (isPasang) _tglPasang = formatted; else _tglBongkar = formatted;
      });
    }
  }

  // Fungsi utama untuk menyimpan revisi data
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final int taskId = widget.taskData['id'];
      final String teknisi = widget.taskData['teknisi'];

      try {
        // 1. VALIDASI JADWAL (Maksimal 2 tugas per hari)
        bool pasangOk = await TaskService().isTechnicianAvailable(taskId, teknisi, _tglPasang!);
        bool bongkarOk = await TaskService().isTechnicianAvailable(taskId, teknisi, _tglBongkar!);

        if (!pasangOk || !bongkarOk) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text("Gagal: Teknisi ini sudah memiliki 2 jadwal di tanggal tersebut!"),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 2. Eksekusi Update ke Supabase termasuk data No Telp
        await TaskService().updateTask(taskId, {
          'no_agenda': _agendaController.text,
          'nama_pelanggan': _namaController.text,
          'no_telp': _noTelpController.text, // Simpan No Telp baru
          'alamat': _alamatController.text,
          'daya': _dayaController.text,
          'tgl_pasang': _tglPasang,
          'tgl_bongkar': _tglBongkar,
          'e_min_kwh': double.tryParse(_eMinController.text) ?? 0,
          'kwh_terbayar': double.tryParse(_kwhBayarController.text) ?? 0,
          'stand_pasang': double.tryParse(_standPasangController.text) ?? 0,
          'stand_bongkar': double.tryParse(_standBongkarController.text) ?? 0,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data penugasan berhasil direvisi")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text("Gagal memperbarui: $e")),
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
        title: const Text("Revisi Data Penugasan"),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Identitas Pelanggan
              _buildTextField(_agendaController, "Nomor Agenda", Icons.confirmation_number),
              _buildTextField(_namaController, "Nama Pelanggan", Icons.person),
              
              // FIELD BARU: Nomor Telepon
              _buildTextField(_noTelpController, "Nomor Telepon / WA", Icons.phone, isNumber: true),
              
              _buildTextField(_alamatController, "Alamat Lengkap", Icons.map, maxLines: 2),
              _buildTextField(_dayaController, "Daya (VA)", Icons.bolt, isNumber: true),
              
              const Divider(height: 30),
              const Text(
                "PARAMETER KWH & STAND METER", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 0.5)
              ),
              const SizedBox(height: 15),

              // Baris Input E-Min dan KWH Terbayar
              Row(
                children: [
                  Expanded(child: _buildTextField(_eMinController, "E Min KWH", Icons.low_priority, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_kwhBayarController, "KWH Terbayar", Icons.payments, isNumber: true)),
                ],
              ),

              // Baris Input Stand Pasang dan Stand Bongkar
              Row(
                children: [
                  Expanded(child: _buildTextField(_standPasangController, "Stand Pasang", Icons.shutter_speed, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_standBongkarController, "Stand Bongkar", Icons.speed, isNumber: true)),
                ],
              ),
              
              const Divider(height: 30),
              
              _buildDatePickerTile("Rencana Tanggal Pasang", _tglPasang!, () => _pickDate(true)),
              const SizedBox(height: 10),
              _buildDatePickerTile("Rencana Tanggal Bongkar", _tglBongkar!, () => _pickDate(false)),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SIMPAN PERUBAHAN DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E4E8))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryBlue)),
        ),
        validator: (v) => v!.isEmpty ? "Bidang ini wajib diisi" : null,
      ),
    );
  }

  // Widget Helper untuk Date Selector
  Widget _buildDatePickerTile(String label, String date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4E8)),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(date)), 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        trailing: Icon(Icons.calendar_today_rounded, color: primaryBlue, size: 18),
        onTap: onTap,
      ),
    );
  }
}