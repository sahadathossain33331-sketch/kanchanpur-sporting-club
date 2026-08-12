import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ClubApp());
}

const String functionUrl =
    'https://vleaqmiyihlginevgfmw.supabase.co/functions/v1/hyper-function';

class ClubApp extends StatelessWidget {
  const ClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kanchanpur Sporting Club',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  bool loading = false;
  bool hidePassword = true;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 01XXXXXXXXX / 8801XXXXXXXXX / +8801XXXXXXXXX
  // সবগুলোকে 01XXXXXXXXX এ রূপান্তর করবে।
  String normalizePhone(String value) {
    var phone = value.trim().replaceAll(RegExp(r'[\s-]'), '');

    if (phone.startsWith('+880')) {
      phone = '0${phone.substring(4)}';
    }

    if (phone.startsWith('880')) {
      phone = '0${phone.substring(3)}';
    }

    return phone;
  }

  void showMessage(String text, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ------------------------------------------------------
  // Supabase request
  // ------------------------------------------------------
  Future<http.Response> sendRequest(
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(functionUrl);

    // প্রথম চেষ্টা
    try {
      return await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Kanchanpur-Sporting-Club/1.0',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      // প্রথম request ব্যর্থ হলে 2 সেকেন্ড অপেক্ষা
      // করে দ্বিতীয়বার চেষ্টা করবে।
      await Future.delayed(const Duration(seconds: 2));

      return await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Kanchanpur-Sporting-Club/1.0',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    }
  }

  Future<void> submit() async {
    if (loading) return;

    final userName = nameController.text.trim();
    final phone = normalizePhone(phoneController.text);
    final password = passwordController.text;

    // Signup হলে Name লাগবে
    if (!isLogin && userName.isEmpty) {
      showMessage('User Name দিন।');
      return;
    }

    // বাংলাদেশি ফোন নম্বর যাচাই
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(phone)) {
      showMessage('সঠিক ১১ সংখ্যার Phone Number দিন।');
      return;
    }

    // Password
    if (password.length < 6) {
      showMessage('Password কমপক্ষে ৬ অক্ষরের হতে হবে।');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
    });

    try {
      final Map<String, dynamic> body = {
        'action': isLogin ? 'login' : 'signup',
        'phone': phone,
        'password': password,
      };

      if (!isLogin) {
        body['name'] = userName;
      }

      final response = await sendRequest(body);

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      if (!mounted) return;

      // --------------------------------------------------
      // সফল
      // --------------------------------------------------
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        if (isLogin) {
          final user = data['user'] is Map
              ? Map<String, dynamic>.from(data['user'])
              : <String, dynamic>{};

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                userName: (user['name'] ?? 'Member').toString(),
                phone: (user['phone'] ?? phone).toString(),
              ),
            ),
          );
        } else {
          // Signup সফল হলে Login page দেখাবে
          showMessage(
            data['message']?.toString() ??
                'Account সফলভাবে তৈরি হয়েছে। এখন Login করুন।',
            success: true,
          );

          setState(() {
            isLogin = true;
            passwordController.clear();
          });
        }
      } else {
        showMessage(
          data['error']?.toString() ??
              data['message']?.toString() ??
              'Server error (${response.statusCode})',
        );
      }
    } on http.ClientException catch (e) {
      showMessage(
        'Network error: ${e.message}\nআবার চেষ্টা করুন।',
      );
    } catch (e) {
      final error = e.toString();

      if (error.contains('Failed host lookup')) {
        showMessage(
          'Supabase server খুঁজে পাওয়া যাচ্ছে না। '
          'Mobile data/Wi-Fi পরিবর্তন করে আবার চেষ্টা করুন।',
        );
      } else if (error.contains('TimeoutException')) {
        showMessage(
          'Server response দিতে বেশি সময় নিচ্ছে। '
          'কিছুক্ষণ পর আবার চেষ্টা করুন।',
        );
      } else {
        showMessage('Connection error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLogin ? 'সদস্য Login' : 'নতুন সদস্য নিবন্ধন',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 64,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Kanchanpur Sporting Club',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Signup হলে Name দেখাবে
                  if (!isLogin) ...[
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'User Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],

                  // Phone
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '01XXXXXXXXX',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText:
                          isLogin ? 'Password' : 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Main button
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Login <-> Signup
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              isLogin = !isLogin;
                              passwordController.clear();
                            });
                          },
                    child: Text(
                      isLogin
                          ? 'নতুন সদস্য? Sign Up করুন'
                          : 'আগে থেকেই অ্যাকাউন্ট আছে? Login করুন',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// HOME PAGE
// ======================================================

class HomePage extends StatelessWidget {
  final String userName;
  final String phone;

  const HomePage({
    super.key,
    required this.userName,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanchanpur Sporting Club'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthPage(),
                ),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 42,
              child: Icon(
                Icons.person,
                size: 48,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Login সফল হয়েছে!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              userName,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              phone,
              style: const TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Kanchanpur Sporting Club-এ স্বাগতম।',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
