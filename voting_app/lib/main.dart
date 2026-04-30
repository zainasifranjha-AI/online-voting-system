import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

ValueNotifier<bool> isDark = ValueNotifier(false);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDark,
      builder: (_, value, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: value ? ThemeData.dark() : ThemeData.light(),
          home: LoginScreen(),
        );
      },
    );
  }
}