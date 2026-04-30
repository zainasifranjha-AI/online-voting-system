import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class WinnerScreen extends StatefulWidget {
  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  var winner;

  @override
  void initState() {
    super.initState();
    fetchWinner();
  }

  Future fetchWinner() async {
    var res = await http.get(
      Api.uri('/api/results'),
    );

    var data = jsonDecode(res.body);

    if (data.isNotEmpty) {
      setState(() {
        winner = data[0]; // 🔥 highest vote
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Winner")),
      body: Center(
        child: winner == null
            ? const Text("No winner yet")
            : Card(
                elevation: 10,
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🏆 WINNER",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        winner['name'],
                        style: const TextStyle(fontSize: 20),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        winner['position'] ?? "",
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Votes: ${winner['votes']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}