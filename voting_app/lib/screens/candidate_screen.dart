import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'admin_screen.dart';
import 'result_screen.dart';
import 'vote_list_screen.dart';
import 'winner_screen.dart';
import '../api.dart';

class CandidateScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const CandidateScreen({super.key, required this.user});

  @override
  State<CandidateScreen> createState() => _CandidateScreenState();
}

class _CandidateScreenState extends State<CandidateScreen> {
  List candidates = [];

  // Store times in UTC for consistent comparisons.
  DateTime? startTimeUtc;
  DateTime? endTimeUtc;
  DateTime nowTimeUtc = DateTime.now().toUtc();
  Timer? clockTimer;
  Timer? refreshTimer;
  bool isLoadingCandidates = true;

  bool get canOpenAdmin {
    final role = widget.user['role']?.toString().toLowerCase();
    final name = widget.user['name']?.toString().toLowerCase() ?? '';
    final email = widget.user['email']?.toString().toLowerCase() ?? '';

    return role == 'admin' || name == 'admin' || email.contains('admin');
  }

  @override
  void initState() {
    super.initState();
    refreshData();
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        nowTimeUtc = DateTime.now().toUtc();
      });
    });
    refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshData(showLoader: false);
    });
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshData({bool showLoader = true}) async {
    await Future.wait([
      fetchCandidates(showLoader: showLoader),
      fetchTime(),
    ]);
  }

  // 📥 GET CANDIDATES
  Future<void> fetchCandidates({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => isLoadingCandidates = true);
    }

    var res = await http.get(
      Api.uri('/api/candidates'),
    );

    if (!mounted) return;

    setState(() {
      candidates = jsonDecode(res.body);
      isLoadingCandidates = false;
    });
  }

  // ⏳ GET TIME
  Future<void> fetchTime() async {
    try {
      var res = await http.get(
        Api.uri('/api/get-voting-time'),
      );

      var data = jsonDecode(res.body);

      if (!mounted) return;

      setState(() {
        startTimeUtc = data['start_time'] != null
            ? DateTime.parse(data['start_time']).toUtc()
            : null;
        endTimeUtc = data['end_time'] != null
            ? DateTime.parse(data['end_time']).toUtc()
            : null;
      });
    } catch (e) {
      debugPrint("Time fetch error: $e");
    }
  }

  // 🕒 FORMAT AM/PM
  String formatDateTime(DateTime dt) {
    // Convert to local only for display.
    final local = dt.toLocal();
    int hour = local.hour;
    String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    String minute = local.minute.toString().padLeft(2, '0');

    return "$hour:$minute $period";
  }

  String get votingStatus {
    if (startTimeUtc == null || endTimeUtc == null) {
      return "Voting time is not set";
    }

    if (nowTimeUtc.isBefore(startTimeUtc!)) {
      return "Voting has not started yet";
    }

    if (nowTimeUtc.isAfter(endTimeUtc!)) {
      return "Voting has ended";
    }

    return "Voting is live";
  }

  bool get canVoteNow {
    if (startTimeUtc == null || endTimeUtc == null) {
      return false;
    }

    return !nowTimeUtc.isBefore(startTimeUtc!) &&
        !nowTimeUtc.isAfter(endTimeUtc!);
  }

  String get remainingLabel {
    if (startTimeUtc == null || endTimeUtc == null) {
      return "Admin has not configured the election timer yet.";
    }

    if (nowTimeUtc.isBefore(startTimeUtc!)) {
      return "Starts in ${formatDuration(startTimeUtc!.difference(nowTimeUtc))}";
    }

    if (nowTimeUtc.isAfter(endTimeUtc!)) {
      return "Election time is over.";
    }

    return "Time remaining: ${formatDuration(endTimeUtc!.difference(nowTimeUtc))}";
  }

  String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;

    if (totalSeconds <= 0) {
      return "0s";
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    }

    if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    }

    return "${seconds}s";
  }

  // 🗳️ VOTE
  Future<void> vote(dynamic id) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    var res = await http.post(
      Api.uri('/api/vote'),
      body: {
        "user_id": widget.user['id'].toString(),
        "candidate_id": id.toString(),
      },
    );

    var data = jsonDecode(res.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? "Error")),
    );

    refreshData(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0f2027), Color(0xff203a43), Color(0xff2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: refreshData,
            child: Column(
              children: [

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Hi ${widget.user['name']}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  "Vote Your Candidate",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),

                // 🔥 TIME BOX
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      Text(
                        votingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        remainingLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (startTimeUtc != null)
                        Text(
                          "Starts at ${formatDateTime(startTimeUtc!)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),

                      const SizedBox(height: 4),

                      if (endTimeUtc != null)
                        Text(
                          "Ends at ${formatDateTime(endTimeUtc!)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

                // GRID
                Expanded(
                  child: isLoadingCandidates
                      ? const Center(child: CircularProgressIndicator())
                      : candidates.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    "No candidates available yet",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(10),
                              itemCount: candidates.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.85,
                              ),
                              itemBuilder: (context, i) {
                                var c = candidates[i];

                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withValues(alpha: 0.08),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.12),
                                        backgroundImage: (c['symbol'] != null &&
                                                c['symbol']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? NetworkImage(c['symbol'])
                                            : null,
                                        child: (c['symbol'] == null ||
                                                c['symbol']
                                                    .toString()
                                                    .isEmpty)
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              )
                                            : null,
                                        onBackgroundImageError: (_, __) {
                                          // Keep the card usable if the uploaded icon URL fails.
                                        },
                                      ),

                                      const SizedBox(height: 10),

                                      Text(
                                        c['name'] ?? "",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        c['position'] ?? "",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      SizedBox(
                                        width: 90,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                          ),
                                          onPressed: canVoteNow
                                              ? () => vote(c['id'])
                                              : null,
                                          child: const Text("Vote"),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),

      endDrawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text("Menu")),
            if (canOpenAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text("Admin Panel"),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                  refreshData(showLoader: false);
                },
              ),
            if (canOpenAdmin) const Divider(height: 1),
            ListTile(
              title: const Text("Results"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResultScreen()),
                );
              },
            ),
            ListTile(
              title: const Text("Vote List"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VoteListScreen()),
                );
              },
            ),
            ListTile(
              title: const Text("Winner"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WinnerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}