import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://vleaqmiyihlginevgfmw.supabase.co';
const supabaseAnonKey =
    'sb_publishable_7D6mwaP16HzmYQTtr71icQ__JksJ9KJ';

// এখানে তোমার Admin-এর email বসাবে
const adminEmail = 'sahadathossain99978@gmail.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const KanchanpurApp());
}

final supabase = Supabase.instance.client;

class KanchanpurApp extends StatelessWidget {
  const KanchanpurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'কাঞ্চনপুর স্পোর্টিং ক্লাব',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF283593),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      showMsg('ইমেইল ও পাসওয়ার্ড দিন।');
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } on AuthException catch (e) {
      showMsg(e.message);
    } catch (e) {
      showMsg('Login ব্যর্থ হয়েছে।');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset(
                  'assets/club_logo.png',
                  width: 150,
                ),

                const SizedBox(height: 12),

                const Text(
                  'কাঞ্চনপুর স্পোর্টিং ক্লাব',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  'এটি একটি ক্রীড়া ও স্বেচ্ছাসেবী সংগঠন',
                ),

                const SizedBox(height: 28),

                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'পাসওয়ার্ড',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'নতুন সদস্য? Signup করুন',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP
// ============================================================

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  Future<void> signup() async {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty) {
      showMsg('সব ঘর পূরণ করুন।');
      return;
    }

    if (!email.text.contains('@')) {
      showMsg('সঠিক ইমেইল দিন।');
      return;
    }

    if (password.text.length < 6) {
      showMsg('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await supabase.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        data: {
          'full_name': name.text.trim(),
          'phone': phone.text.trim(),
        },
      );

      if (!mounted) return;

      if (result.session != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
          (route) => false,
        );
      } else {
        showMsg(
          'Signup সফল হয়েছে। Email verify করে Login করুন।',
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      showMsg(e.message);
    } catch (e) {
      showMsg('Signup ব্যর্থ হয়েছে।');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন সদস্য নিবন্ধন'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'নতুন সদস্য তৈরি করুন',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'পূর্ণ নাম',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'মোবাইল নম্বর',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'ইমেইল',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'পাসওয়ার্ড',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : signup,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Signup'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  bool get isAdmin {
    final userEmail = supabase.auth.currentUser?.email;

    return userEmail != null &&
        userEmail.toLowerCase() == adminEmail.toLowerCase();
  }

  Future<void> logout(BuildContext context) async {
    await supabase.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('কাঞ্চনপুর স্পোর্টিং ক্লাব'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Image.asset(
              'assets/club_logo.png',
              width: 190,
            ),
          ),

          const Center(
            child: Text(
              'কাঞ্চনপুর স্পোর্টিং ক্লাব',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Center(
            child: Text(
              'এটি একটি ক্রীড়া ও স্বেচ্ছাসেবী সংগঠন',
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text(
                'নতুন সদস্যের জন্য আবেদন',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ApplicationPage(),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.payments),
              title: const Text(
                'মাসিক চাঁদা / ডোনেশন',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentPage(),
                  ),
                );
              },
            ),
          ),

          if (isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                ),
                title: const Text('Admin Panel'),
                subtitle: const Text(
                  'শুধু Admin-এর জন্য',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPage(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// MEMBER APPLICATION
// ============================================================

class ApplicationPage extends StatefulWidget {
  const ApplicationPage({super.key});

  @override
  State<ApplicationPage> createState() =>
      _ApplicationPageState();
}

class _ApplicationPageState
    extends State<ApplicationPage> {
  final c = <String, TextEditingController>{
    'নাম': TextEditingController(),
    'পিতার নাম': TextEditingController(),
    'মাতার নাম': TextEditingController(),
    'জন্মসাল': TextEditingController(),
    'এনআইডি/জন্মনিবন্ধন নাম্বার':
        TextEditingController(),
    'জেলা': TextEditingController(),
    'থানা': TextEditingController(),
    'গ্রাম': TextEditingController(),
    'মোবাইল নাম্বার': TextEditingController(),
  };

  String blood = 'A+';
  XFile? photo;
  bool loading = false;

  Future<void> pickPhoto() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (p != null) {
      setState(() {
        photo = p;
      });
    }
  }

  Future<void> submit() async {
    if (supabase.auth.currentUser == null) {
      showMsg('আগে Login করুন।');
      return;
    }

    for (final controller in c.values) {
      if (controller.text.trim().isEmpty) {
        showMsg('সব তথ্য পূরণ করুন।');
        return;
      }
    }

    setState(() => loading = true);

    try {
      await supabase.from('applications').insert({
        'user_id': supabase.auth.currentUser!.id,
        'name': c['নাম']!.text.trim(),
        'father_name':
            c['পিতার নাম']!.text.trim(),
        'mother_name':
            c['মাতার নাম']!.text.trim(),
        'birth_year':
            c['জন্মসাল']!.text.trim(),
        'nid_or_birth_registration':
            c['এনআইডি/জন্মনিবন্ধন নাম্বার']!
                .text
                .trim(),
        'district':
            c['জেলা']!.text.trim(),
        'upazila':
            c['থানা']!.text.trim(),
        'village':
            c['গ্রাম']!.text.trim(),
        'phone':
            c['মোবাইল নাম্বার']!.text.trim(),
        'blood_group': blood,
        'status': 'pending',
      });

      if (!mounted) return;

      showMsg(
        'আবেদন সফলভাবে জমা হয়েছে।',
      );

      Navigator.pop(context);
    } on PostgrestException catch (e) {
      showMsg(
        'আবেদন সংরক্ষণ হয়নি: ${e.message}',
      );
    } catch (e) {
      showMsg('আবেদন জমা দিতে সমস্যা হয়েছে।');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget field(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: c[label],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'নতুন সদস্যের জন্য আবেদন',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: field('নাম'),
              ),

              const SizedBox(width: 12),

              Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: photo == null
                        ? null
                        : FileImage(
                            File(photo!.path),
                          ),
                    child: photo == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                          )
                        : null,
                  ),

                  TextButton(
                    onPressed: pickPhoto,
                    child: const Text(
                      'ছবি আপলোড',
                    ),
                  ),
                ],
              ),
            ],
          ),

          for (final x in [
            'পিতার নাম',
            'মাতার নাম',
            'জন্মসাল',
            'এনআইডি/জন্মনিবন্ধন নাম্বার',
            'জেলা',
            'থানা',
            'গ্রাম',
          ])
            field(x),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: blood,
            decoration: const InputDecoration(
              labelText: 'রক্তের গ্রুপ',
              border: OutlineInputBorder(),
            ),
            items: [
              'A+',
              'A-',
              'B+',
              'B-',
              'AB+',
              'AB-',
              'O+',
              'O-',
            ]
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(x),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  blood = v;
                });
              }
            },
          ),

          field('মোবাইল নাম্বার'),

          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAYMENT
// ============================================================

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() =>
      _PaymentPageState();
}

class _PaymentPageState
    extends State<PaymentPage> {
  String method = 'বিকাশ';

  final amount = TextEditingController();
  final trx = TextEditingController();

  bool loading = false;

  Future<void> submitPayment() async {
    if (supabase.auth.currentUser == null) {
      showMsg('আগে Login করুন।');
      return;
    }

    if (amount.text.trim().isEmpty ||
        trx.text.trim().isEmpty) {
      showMsg(
        'টাকার পরিমাণ ও Transaction ID দিন।',
      );
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.from('payments').insert({
        'user_id':
            supabase.auth.currentUser!.id,
        'method': method,
        'amount':
            double.tryParse(amount.text.trim()) ?? 0,
        'transaction_id':
            trx.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;

      showMsg(
        'পেমেন্ট তথ্য জমা হয়েছে।',
      );

      amount.clear();
      trx.clear();
    } on PostgrestException catch (e) {
      showMsg(
        'পেমেন্ট সংরক্ষণ হয়নি: ${e.message}',
      );
    } catch (e) {
      showMsg(
        'পেমেন্ট জমা দিতে সমস্যা হয়েছে।',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    amount.dispose();
    trx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'মাসিক চাঁদা / ডোনেশন',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'মাসিক চাঁদা / ডোনেশন',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'বিকাশ',
                  groupValue: method,
                  title: const Text('বিকাশ'),
                  subtitle: const Text(
                    'Personal • 01897173332',
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => method = v);
                    }
                  },
                ),

                RadioListTile<String>(
                  value: 'নগদ',
                  groupValue: method,
                  title: const Text('নগদ'),
                  subtitle: const Text(
                    'Personal • 01897173332',
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => method = v);
                    }
                  },
                ),

                RadioListTile<String>(
                  value: 'রকেট',
                  groupValue: method,
                  title: const Text('রকেট'),
                  subtitle: const Text(
                    '01897173332',
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => method = v);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: amount,
            keyboardType:
                TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'টাকার পরিমাণ',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: trx,
            decoration: const InputDecoration(
              labelText: 'Transaction ID',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          FilledButton(
            onPressed:
                loading ? null : submitPayment,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Payment Submit'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN PANEL
// ============================================================

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() =>
      _AdminPageState();
}

class _AdminPageState
    extends State<AdminPage> {
  int applications = 0;
  int payments = 0;
  int members = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final apps = await supabase
          .from('applications')
          .select('id');

      final pays = await supabase
          .from('payments')
          .select('id');

      final profiles = await supabase
          .from('profiles')
          .select('id');

      if (!mounted) return;

      setState(() {
        applications = (apps as List).length;
        payments = (pays as List).length;
        members = (profiles as List).length;
      });
    } catch (e) {
      showMsg(
        'Admin data পাওয়া যায়নি।',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                adminCard(
                  Icons.assignment,
                  'Applications',
                  '$applications',
                  'Pending / Approved / Rejected',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AdminApplicationsPage(),
                      ),
                    );
                  },
                ),

                adminCard(
                  Icons.payments,
                  'Payments',
                  '$payments',
                  'Transaction verification',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AdminPaymentsPage(),
                      ),
                    );
                  },
                ),

                adminCard(
                  Icons.people,
                  'Members',
                  '$members',
                  'Approved member list',
                  () {},
                ),

                adminCard(
                  Icons.bar_chart,
                  'Reports',
                  '—',
                  'Monthly collection report',
                  () {},
                ),
              ],
            ),
    );
  }

  Widget adminCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// ADMIN APPLICATION LIST
// ============================================================

class AdminApplicationsPage
    extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage>
      createState() =>
          _AdminApplicationsPageState();
}

class _AdminApplicationsPageState
    extends State<AdminApplicationsPage> {
  List<Map<String, dynamic>> rows = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final data = await supabase
          .from('applications')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) return;

      setState(() {
        rows =
            List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      showMsg(
        'Applications পড়া যায়নি।',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> changeStatus(
    String id,
    String status,
  ) async {
    try {
      await supabase
          .from('applications')
          .update({
            'status': status,
          })
          .eq('id', id);

      await load();
    } catch (e) {
      showMsg(
        'Status পরিবর্তন হয়নি।',
      );
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Applications',
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : rows.isEmpty
              ? const Center(
                  child: Text(
                    'কোনো আবেদন নেই।',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder:
                        (context, index) {
                      final row =
                          rows[index];

                      final id =
                          row['id'].toString();

                      final name =
                          row['name']
                                  ?.toString() ??
                              'নাম নেই';

                      final phone =
                          row['phone']
                                  ?.toString() ??
                              '';

                      final status =
                          row['status']
                                  ?.toString() ??
                              'pending';

                      return Card(
                        margin:
                            const EdgeInsets.all(
                                8),
                        child: ListTile(
                          leading:
                              const CircleAvatar(
                            child:
                                Icon(Icons.person),
                          ),
                          title:
                              Text(name),
                          subtitle: Text(
                            '$phone\nStatus: $status',
                          ),
                          isThreeLine: true,
                          trailing:
                              PopupMenuButton<
                                  String>(
                            onSelected:
                                (value) {
                              changeStatus(
                                id,
                                value,
                              );
                            },
                            itemBuilder:
                                (_) =>
                                    const [
                              PopupMenuItem(
                                value:
                                    'approved',
                                child:
                                    Text(
                                  'Approve',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'rejected',
                                child:
                                    Text(
                                  'Reject',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'pending',
                                child:
                                    Text(
                                  'Pending',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ============================================================
// ADMIN PAYMENT LIST
// ============================================================

class AdminPaymentsPage
    extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage>
      createState() =>
          _AdminPaymentsPageState();
}

class _AdminPaymentsPageState
    extends State<AdminPaymentsPage> {
  List<Map<String, dynamic>> rows = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final data = await supabase
          .from('payments')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) return;

      setState(() {
        rows =
            List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      showMsg(
        'Payments পড়া যায়নি।',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> changeStatus(
    String id,
    String status,
  ) async {
    try {
      await supabase
          .from('payments')
          .update({
            'status': status,
          })
          .eq('id', id);

      await load();
    } catch (e) {
      showMsg(
        'Payment status পরিবর্তন হয়নি।',
      );
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : rows.isEmpty
              ? const Center(
                  child: Text(
                    'কোনো payment নেই।',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder:
                        (context, index) {
                      final row =
                          rows[index];

                      final id =
                          row['id'].toString();

                      final method =
                          row['method']
                                  ?.toString() ??
                              '';

                      final amount =
                          row['amount']
                                  ?.toString() ??
                              '0';

                      final trx =
                          row['transaction_id']
                                  ?.toString() ??
                              '';

                      final status =
                          row['status']
                                  ?.toString() ??
                              'pending';

                      return Card(
                        margin:
                            const EdgeInsets.all(
                                8),
                        child: ListTile(
                          leading:
                              const Icon(
                            Icons.payments,
                          ),
                          title: Text(
                            '$method • ৳$amount',
                          ),
                          subtitle: Text(
                            'Transaction: $trx\nStatus: $status',
                          ),
                          isThreeLine: true,
                          trailing:
                              PopupMenuButton<
                                  String>(
                            onSelected:
                                (value) {
                              changeStatus(
                                id,
                                value,
                              );
                            },
                            itemBuilder:
                                (_) =>
                                    const [
                              PopupMenuItem(
                                value:
                                    'approved',
                                child:
                                    Text(
                                  'Approve',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'rejected',
                                child:
                                    Text(
                                  'Reject',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'pending',
                                child:
                                    Text(
                                  'Pending',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
