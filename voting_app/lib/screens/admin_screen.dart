import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../api.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  TextEditingController name = TextEditingController();
  TextEditingController position = TextEditingController();

  DateTime? start;
  DateTime? end;
  DateTime? savedStart;
  DateTime? savedEnd;

  XFile? image;
  final ImagePicker picker = ImagePicker();
  Uint8List? imageBytes;
  bool isSubmittingCandidate = false;
  bool isSavingTime = false;
  bool isClearingElection = false;
  bool isLoadingSavedTime = false;

  @override
  void initState() {
    super.initState();
    fetchSavedTime();
  }

  Future<void> fetchSavedTime() async {
    setState(() => isLoadingSavedTime = true);

    try {
      final res = await http.get(
        Api.uri('/api/get-voting-time'),
      );
      final data = jsonDecode(res.body);

      if (!mounted) return;

      final parsedStart = data['start_time'] != null
          ? DateTime.parse(data['start_time']).toLocal()
          : null;
      final parsedEnd = data['end_time'] != null
          ? DateTime.parse(data['end_time']).toLocal()
          : null;

      setState(() {
        savedStart = parsedStart;
        savedEnd = parsedEnd;

        // If admin hasn't picked new values yet, prefill from saved values.
        start ??= parsedStart;
        end ??= parsedEnd;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load saved time: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoadingSavedTime = false);
      }
    }
  }

  String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    int hour = local.hour;
    final period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return "$day-$month-$year  $hour:$minute $period";
  }

  // 📸 IMAGE PICK
  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        image = picked;
        imageBytes = bytes;
      });
    }
  }

  void clearImage() {
    setState(() {
      image = null;
      imageBytes = null;
    });
  }

  // ➕ ADD CANDIDATE
  Future addCandidate() async {
    if (name.text.isEmpty || position.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => isSubmittingCandidate = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Api.uri('/api/candidates'),
      );

      request.fields['name'] = name.text;
      request.fields['position'] = position.text;

      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'symbol',
            imageBytes!,
            filename: image?.name ?? 'candidate-symbol.png',
          ),
        );
      }

      var response = await request.send();
      var body = await response.stream.bytesToString();

      debugPrint(body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Candidate Added")),
        );

        name.clear();
        position.clear();
        clearImage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $body")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmittingCandidate = false);
      }
    }
  }

  // ⏰ SAVE TIME
  Future saveTime() async {
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select both date & time")),
      );
      return;
    }

    if (!end!.isAfter(start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() => isSavingTime = true);

    try {
      await http.post(
        Api.uri('/api/set-voting-time'),
        body: {
          "start_time": start!.toIso8601String(),
          "end_time": end!.toIso8601String(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time Saved")),
      );
      await fetchSavedTime();
    } finally {
      if (mounted) {
        setState(() => isSavingTime = false);
      }
    }
  }

  Future<void> clearElection() async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Clear election data?"),
            content: const Text(
              "This will remove all candidates, uploaded icons, votes, and the saved timer.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Clear"),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClear) return;

    setState(() => isClearingElection = true);

    try {
      final response = await http.post(
        Api.uri('/api/clear-election'),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        name.clear();
        position.clear();
        clearImage();

        setState(() {
          start = null;
          end = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Election cleared")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Unable to clear election")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isClearingElection = false);
      }
    }
  }

  // 🔥 DATE + TIME PICKER (START)
  Future pickStart() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      if (!mounted) return;

      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          start = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // 🔥 DATE + TIME PICKER (END)
  Future pickEnd() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      if (!mounted) return;

      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          end = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ================= ADD CANDIDATE =================
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Candidate",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter the candidate details and choose an icon image.",
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: position,
                      decoration: const InputDecoration(
                        labelText: "Position",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.how_to_vote_outlined),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.blueGrey.shade50,
                            backgroundImage:
                                imageBytes != null ? MemoryImage(imageBytes!) : null,
                            child: imageBytes == null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.blueGrey,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            image == null
                                ? "No candidate icon selected"
                                : image!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isSubmittingCandidate ? null : pickImage,
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: Text(
                                  image == null ? "Add Candidate Icon" : "Change Icon",
                                ),
                              ),
                              if (image != null)
                                OutlinedButton.icon(
                                  onPressed: isSubmittingCandidate ? null : clearImage,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text("Remove Icon"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmittingCandidate ? null : addCandidate,
                        icon: isSubmittingCandidate
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          isSubmittingCandidate
                              ? "Adding Candidate..."
                              : "Add Candidate",
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ================= TIME =================
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text("Election Timing",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Saved on server",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: "Refresh",
                          onPressed: isLoadingSavedTime ? null : fetchSavedTime,
                          icon: isLoadingSavedTime
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        savedStart == null || savedEnd == null
                            ? "Not set yet"
                            : "${formatDateTime(savedStart!)}  →  ${formatDateTime(savedEnd!)}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton(
                      onPressed: pickStart,
                      child: Text(start == null
                          ? "Select Start Date & Time"
                          : formatDateTime(start!)),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: pickEnd,
                      child: Text(end == null
                          ? "Select End Date & Time"
                          : formatDateTime(end!)),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSavingTime ? null : saveTime,
                        child: Text(
                          isSavingTime ? "Saving..." : "Save Time",
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isClearingElection ? null : clearElection,
                        icon: isClearingElection
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                        label: Text(
                          isClearingElection
                              ? "Clearing election..."
                              : "Clear All Candidates And Votes",
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}