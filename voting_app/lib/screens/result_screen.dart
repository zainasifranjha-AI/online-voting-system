import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class ResultScreen extends StatefulWidget {
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List results = [];

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future fetchResults() async {
    var res = await http.get(
      Api.uri('/api/results'),
    );

    setState(() {
      results = jsonDecode(res.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (_, i) {
          var c = results[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(c['name']),
              subtitle: Text(c['position'] ?? ""),
              trailing: Text("Votes: ${c['votes']}"),
            ),
          );
        },
      ),
    );
  }
}