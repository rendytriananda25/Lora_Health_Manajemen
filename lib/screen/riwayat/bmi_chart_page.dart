import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class BmiChartPage extends StatefulWidget {
  const BmiChartPage({super.key});

  @override
  State<BmiChartPage> createState() => _BmiChartPageState();
}

class _BmiChartPageState extends State<BmiChartPage> {
  List<Map<String, dynamic>> _bmiHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBmiHistory();
  }

  Future<void> _fetchBmiHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref('users/${user.uid}/history');
      final snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null) {
        setState(() => _isLoading = false);
        return;
      }

      final raw = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> result = [];

      raw.forEach((key, value) {
        try {
          final entry = Map<String, dynamic>.from(value as Map);
          final type = entry['type']?.toString().toUpperCase() ?? '';
          final activity = entry['activity']?.toString().toUpperCase() ?? '';

          if (type == 'BMI' || activity.contains('BMI')) {
            final weight = (entry['weight'] as num?)?.toDouble();
            final timeStr = entry['time']?.toString();

            if (weight != null && timeStr != null) {
              entry['date_obj'] = DateTime.parse(timeStr);
              entry['weight_val'] = weight;
              result.add(entry);
            }
          }
        } catch (_) {}
      });

      result.sort((a, b) =>
          (a['date_obj'] as DateTime).compareTo(b['date_obj'] as DateTime));

      setState(() {
        _bmiHistory = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetch BMI history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CEK BMI',
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008BFF)))
          : _bmiHistory.isEmpty
              ? _buildEmpty(theme)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── GRAFIK ──────────────────────────────────────
                      _buildWeightChart(theme),

                      const SizedBox(height: 28),

                      // ── RIWAYAT TANGGAL ──────────────────────────────
                      Text(
                        'Riwayat Pengecekan',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDateList(theme),
                    ],
                  ),
                ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GRAFIK BERAT BADAN
  // ─────────────────────────────────────────────────────────────
  Widget _buildWeightChart(ThemeProvider theme) {
    final data = _bmiHistory.length > 10
        ? _bmiHistory.sublist(_bmiHistory.length - 10)
        : _bmiHistory;

    final weights = data.map((e) => e['weight_val'] as double).toList();
    final rawMin = weights.reduce((a, b) => a < b ? a : b);
    final rawMax = weights.reduce((a, b) => a > b ? a : b);
    final minW = rawMin - 3;
    final maxW = rawMax + 3;
    final range = (maxW - minW).clamp(1.0, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: theme.boxColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.textColor.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header grafik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Berat Badan (kg)',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF008BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rawMin.toStringAsFixed(1)} – ${rawMax.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Color(0xFF008BFF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // CHART BARS
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final w = data[i]['weight_val'] as double;
                final ratio = ((w - minW) / range).clamp(0.04, 1.0);
                final isLast = i == data.length - 1;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nilai berat
                        Text(
                          w.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF008BFF),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 60),
                          curve: Curves.easeOut,
                          height: 140 * ratio,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFF008BFF),
                                const Color(0xFF008BFF).withOpacity(0.45),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Garis separator
          const SizedBox(height: 8),
          Divider(color: theme.textColor.withOpacity(0.06), height: 1),
          const SizedBox(height: 8),

          // Label tanggal di bawah bar
          Row(
            children: List.generate(data.length, (i) {
              final date = data[i]['date_obj'] as DateTime;
              final isLast = i == data.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 6),
                  child: Text(
                    '${date.day}/${date.month}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.38),
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RIWAYAT TANGGAL (simpel, fokus ke waktu pengecekan)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDateList(ThemeProvider theme) {
    final reversed = _bmiHistory.reversed.toList();

    return Column(
      children: List.generate(reversed.length, (i) {
        final entry = reversed[i];
        final date = entry['date_obj'] as DateTime;
        final weight = (entry['weight_val'] as double).toStringAsFixed(1);
        final status = (entry['status'] ?? 'Normal').toString();
        final bmi = entry['bmi_score']?.toString() ?? '--';

        final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
        final timeStr = DateFormat('HH:mm').format(date);
        final statusColor = _statusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.boxColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.textColor.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // Dot status
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),

              // Tanggal & jam
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: theme.textColor.withOpacity(0.38),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.38),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Berat & status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$weight kg',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'BMI $bmi',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('UNDER') || s.contains('KURANG')) return Colors.blue;
    if (s.contains('NORMAL') || s.contains('IDEAL')) return Colors.green;
    if (s.contains('OBES')) return Colors.red;
    if (s.contains('OVER')) return Colors.orange;
    return Colors.green;
  }

  Widget _buildEmpty(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 64,
            color: theme.textColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat CEK BMI',
            style: TextStyle(
              color: theme.textColor.withOpacity(0.38),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cek BMI kamu dulu di menu BMI',
            style: TextStyle(
              color: theme.textColor.withOpacity(0.24),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
