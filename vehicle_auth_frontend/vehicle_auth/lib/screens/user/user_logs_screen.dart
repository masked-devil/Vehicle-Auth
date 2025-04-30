import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import 'dart:ui';

class UserLogsScreen extends StatefulWidget {
  const UserLogsScreen({super.key});

  @override
  State<UserLogsScreen> createState() => _UserLogsScreenState();
}

class _UserLogsScreenState extends State<UserLogsScreen> {
  List<dynamic> allLogs = [];
  String selectedCategory = 'All';
  bool isLoading = true;
  List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> categories = ['All', 'owner', 'guest', 'delivery', 'emergency', 'other'];

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
  setState(() => isLoading = true);

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User ID not found')),
    );
    setState(() => isLoading = false);
    return;
  }

  try {
    final response = await UserService.getUserLogs(userId);

    // Convert UTC to IST and add ist_date/ist_datetime
    for (var log in response) {
      try {
        final utcDateTime = DateTime.parse('${log["date"].split('-').reversed.join('-')}T${log["time"]}Z');
        final istDateTime = utcDateTime.toLocal();
        log['ist_datetime'] = istDateTime;
        log['ist_date'] ='${istDateTime.year.toString().padLeft(4, '0')}-${istDateTime.month.toString().padLeft(2, '0')}-${istDateTime.day.toString().padLeft(2, '0')}';
      } catch (_) {
        // Ignore any date parsing error
      }
    }

    // Sort logs (latest first)
    response.sort((a, b) {
      try {
        return b['ist_datetime'].compareTo(a['ist_datetime']);
      } catch (_) {
        return 0;
      }
    });

    setState(() {
      allLogs = response;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}


  List<dynamic> get filteredLogs {
    if (selectedCategory == 'All') return allLogs;
    return allLogs.where((log) => log['category'] == selectedCategory).toList();
  }

  Map<String, List<dynamic>> groupLogsByDate(List<dynamic> logs) {
    Map<String, List<dynamic>> grouped = {};
    for (var log in logs) {
      String date = log['ist_date'] ?? log['date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(log);
    }
    return grouped;
  }

  String formatDateToReadable(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final date = DateTime(year, month, day);
      final monthName = months[month - 1];
      final suffix = getDaySuffix(day);

      return '$day$suffix $monthName $year';
    } catch (e) {
      return dateStr;
    }
  }

  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String formatUtcTimeToReadable(String dateStr, String timeStr) {
    try {
      final utcDateTime = DateTime.parse(
        '${dateStr.split('-').reversed.join('-')}T$timeStr' + 'Z',
      );
      final istDateTime = utcDateTime.toLocal();
      return DateFormat('hh:mm a').format(istDateTime);
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsGrouped = groupLogsByDate(filteredLogs);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Logs')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat[0].toUpperCase() + cat.substring(1)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLogs.isEmpty
                      ? const Center(child: Text('No logs available'))
                      : ListView(
                          children: logsGrouped.entries.map((entry) {
                            final logs = entry.value;
                            final firstLog = logs.first;
                            final headerDate = firstLog['ist_datetime'] != null
                                ? formatDateToReadable(firstLog['ist_date'])
                                : formatDateToReadable(entry.key);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  color: const Color.fromARGB(255, 48, 48, 48),
                                  child: Center(
                                    child: Text(
                                      headerDate,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2,),
                                ...logs.map((log) {
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(
                                        "Gate Opened for ${log['category']} at ${formatUtcTimeToReadable(log['date'], log['time'])}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
