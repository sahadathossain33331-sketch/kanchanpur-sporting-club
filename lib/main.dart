import 'package:flutter/material.dart';

void main() {
  runApp(const KanchanpurApp());
}

class KanchanpurApp extends StatelessWidget {
  const KanchanpurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'কাঞ্চনপুর স্পোর্টিং ক্লাব',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('কাঞ্চনপুর স্পোর্টিং ক্লাব'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_soccer,
              size: 90,
            ),
            const SizedBox(height: 25),
            const Text(
              'কাঞ্চনপুর স্পোর্টিং ক্লাব',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'এটি একটি ক্রীড়া ও স্বেচ্ছাসেবী সংগঠন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: () {},
              child: const Text('শুরু করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
