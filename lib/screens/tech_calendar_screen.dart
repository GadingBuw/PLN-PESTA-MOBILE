import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/user_model.dart';

class TechCalendarScreen extends StatefulWidget {
  final UserModel user;
  const TechCalendarScreen({super.key, required this.user});

  @override
  State<TechCalendarScreen> createState() => _TechCalendarScreenState();
}

class _TechCalendarScreenState extends State<TechCalendarScreen> {
  // Gunakan Map<String, int>
  Map<String, int> workload = {};
  bool loading = true;
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchWorkload();
  }

  Future<void> _fetchWorkload() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl?action=get_tech_calendar&teknisi=${Uri.encodeComponent(widget.user.username)}",
        ),
      );

      debugPrint("Raw Response: ${response.body}");

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);

        setState(() {
          // Proses konversi dari Map<String, dynamic> ke Map<String, int> secara aman
          workload = decodedData.map(
            (key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0),
          );
          loading = false;
        });
      } else {
        setState(() {
          workload = {};
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Calendar: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Jadwal ${widget.user.nama}"),
        backgroundColor: const Color(0xFF1A56F0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkload,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildDaysOfWeek(),
                Expanded(child: _buildCalendarGrid()),
                _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
              () => currentMonth = DateTime(
                currentMonth.year,
                currentMonth.month - 1,
              ),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(currentMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
              () => currentMonth = DateTime(
                currentMonth.year,
                currentMonth.month + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final firstDayOffset =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday % 7;

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: daysInMonth + firstDayOffset,
      itemBuilder: (context, index) {
        if (index < firstDayOffset) return const SizedBox();

        final day = index - firstDayOffset + 1;
        final date = DateTime(currentMonth.year, currentMonth.month, day);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        int taskCount = workload[dateKey] ?? 0;
        bool isFull = taskCount >= 2;

        return Container(
          decoration: BoxDecoration(
            color: isFull
                ? Colors.red
                : (taskCount > 0 ? Colors.green.shade400 : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFull ? Colors.red : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$day",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (isFull || taskCount > 0)
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              if (taskCount > 0)
                Text(
                  "$taskCount Tugas",
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(Colors.red, "Penuh (>=2)"),
          _legendItem(Colors.green.shade400, "Tersedia"),
          _legendItem(Colors.grey.shade100, "Kosong"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    children: [
      Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}
