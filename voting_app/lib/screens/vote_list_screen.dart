import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class VoteListScreen extends StatefulWidget {
  @override
  State<VoteListScreen> createState() => _VoteListScreenState();
}

class _VoteListScreenState extends State<VoteListScreen> {
  List votes = [];

  @override
  void initState() {
    super.initState();
    fetchVotes();
  }

  Future fetchVotes() async {
    var res = await http.get(
      Api.uri('/api/votes'),
    );

    setState(() {
      votes = jsonDecode(res.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vote List")),
      body: ListView.builder(
        itemCount: votes.length,
        itemBuilder: (_, i) {
          var v = votes[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(v['user']['name']),
              subtitle: Text("Voted: ${v['candidate']['name']}"),
            ),
          );
        },
      ),
    );
  }
}