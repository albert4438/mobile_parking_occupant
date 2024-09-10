import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/environment.dart';
import 'package:flutter_application_1/page/login_page.dart';
import 'package:flutter_application_1/page/home_page.dart';  // Import your home page
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: Environment.fileName);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),  // Start with LoginPage, navigate to HomePage on success
    );
  }
}
