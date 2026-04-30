import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'candidate_screen.dart';
import '../api.dart';

// 🌙 Dark mode controller (global)
ValueNotifier<bool> isDark = ValueNotifier(false);

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isLogin = true;

  Future submit() async {
    var body = {
      "email": email.text,
      "password": password.text,
    };

    if (!isLogin) body["name"] = name.text;

    final uri = isLogin ? Api.uri('/api/login') : Api.uri('/api/register');
    var res = await http.post(uri, body: body);
    var data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CandidateScreen(user: data['user']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🎨 Background Gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin ? "Login" : "Register",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // 👉 Name field (only register)
                  if (!isLogin)
                    TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: "Name"),
                    ),

                  // 👉 Email
                  TextField(
                    controller: email,
                    decoration:
                        const InputDecoration(labelText: "Email"),
                  ),

                  // 👉 Password
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "Password"),
                  ),

                  const SizedBox(height: 15),

                  // 👉 Submit button
                  ElevatedButton(
                    onPressed: submit,
                    child: Text(isLogin ? "Login" : "Register"),
                  ),

                  // 👉 Switch Login/Register
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                      });
                    },
                    child: Text(isLogin
                        ? "Don't have account? Register"
                        : "Already have account? Login"),
                  ),

                  const SizedBox(height: 10),

                  // 🌙 Dark Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Dark Mode"),
                      Switch(
                        value: isDark.value,
                        onChanged: (v) {
                          isDark.value = v;
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}