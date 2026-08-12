import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://vleaqmiyihlginevgfmw.supabase.co';
const supabasePublishableKey =
    'sb_publishable_7D6mwaP16HzmYQTtr71icQ__JksJ9KJ';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

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
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E6E2)),
          ),
        ),
      ),
      home: const AppController(),
    );
  }
}

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  User? user;
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();

    supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        _loadSession();
      }

      if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          user = null;
          profile = null;
          loading = false;
        });
      }
    });
  }

  Future<void> _loadSession() async {
    final current = supabase.auth.currentUser;

    if (current == null) {
      if (mounted) {
        setState(() {
          user = null;
          profile = null;
          loading = false;
        });
      }
      return;
    }

    try {
      final row = await supabase
          .from('profiles')
          .select()
          .eq('id', current.id)
          .maybeSingle();

      // Auth user আছে কিন্তু profiles-এ account নেই।
      // তাই কখনোই Home Page খুলবে না।
      if (row == null) {
        await supabase.auth.signOut();

        if (mounted) {
          setState(() {
            user = null;
            profile = null;
            loading = false;
          });
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        user = current;
        profile = Map<String, dynamic>.from(row);
        loading = false;
      });
    } on AuthException catch (_) {
      await supabase.auth.signOut();

      if (mounted) {
        setState(() {
          user = null;
          profile = null;
          loading = false;
        });
      }
    } catch (_) {
      // Internet / Supabase connection সমস্যা হলে
      // কোনোভাবেই Home Page খুলবে না।
      if (mounted) {
        setState(() {
          user = null;
          profile = null;
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Auth সফল না হলে Login Page
    if (user == null || profile == null) {
      return const AuthPage();
    }

    final isAdmin = profile!['role']?.toString() == 'admin';

    if (isAdmin) {
      return AdminHomePage(
        username: profile!['name']?.toString() ?? 'Admin',
        onLogout: () async {
          await supabase.auth.signOut();
        },
      );
    }

    return HomePage(
      username: profile!['name']?.toString() ?? 'Member',
      phone: profile!['phone']?.toString() ?? '',
      onLogout: () async {
        await supabase.auth.signOut();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool signup = false;
  bool hidePassword = true;
  bool busy = false;

  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  String normalizePhone(String value) {
    var p = value.trim().replaceAll(RegExp(r'[\s-]'), '');

    if (p.startsWith('+88')) {
      p = p.substring(3);
    }

    if (p.startsWith('88') && p.length == 13) {
      p = p.substring(2);
    }

    return p;
  }

  String authEmail(String mobile) {
    return '${normalizePhone(mobile)}@ksc.app';
  }

  Future<void> submit() async {
    final username = name.text.trim();
    final mobile = normalizePhone(phone.text);
    final pass = password.text;

    // Signup-এর সময় Username বাধ্যতামূলক
    if (signup && username.isEmpty) {
      _msg('Username দিন।');
      return;
    }

    if (mobile.isEmpty || pass.isEmpty) {
      _msg('Mobile Number ও Password দিন।');
      return;
    }

    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(mobile)) {
      _msg('সঠিক ১১ সংখ্যার বাংলাদেশি মোবাইল নাম্বার দিন।');
      return;
    }

    if (pass.length < 6) {
      _msg('Password কমপক্ষে ৬ অক্ষরের হতে হবে।');
      return;
    }

    if (busy) return;

    setState(() {
      busy = true;
    });

    try {
      final email = authEmail(mobile);

      if (signup) {
        // =========================
        // নতুন Account তৈরি
        // =========================

        final result = await supabase.auth.signUp(
          email: email,
          password: pass,
          data: {
            'username': username,
            'phone': mobile,
          },
        );

        final created = result.user;

        if (created == null) {
          throw Exception('Account তৈরি করা যায়নি।');
        }

        // Email confirmation বন্ধ থাকলে সরাসরি session পাওয়া যাবে
        if (result.session != null) {
          await supabase.from('profiles').upsert({
            'id': created.id,
            'name': username,
            'phone': mobile,
            'role': 'member',
          });

          if (!mounted) return;

          _msg('Account সফলভাবে তৈরি হয়েছে।');
        } else {
          if (!mounted) return;

          _msg(
            'Account তৈরি হয়েছে। Email confirmation সম্পন্ন করে Login করুন।',
          );

          setState(() {
            signup = false;
          });
        }
      } else {
        // =========================
        // Login
        // =========================

        // পুরোনো session থাকলে আগে সম্পূর্ণ Sign Out
        await supabase.auth.signOut();

        // Supabase Authentication দিয়ে সত্যিকারের Login
        final result = await supabase.auth.signInWithPassword(
          email: email,
          password: pass,
        );

        final loggedUser = result.user;

        // Supabase authentication সফল না হলে Home Page নয়
        if (loggedUser == null || result.session == null) {
          throw Exception('Mobile Number অথবা Password ভুল।');
        }

        // Login সফল হলেও profiles-এ account না থাকলে Home Page নয়
        final profileRow = await supabase
            .from('profiles')
            .select()
            .eq('id', loggedUser.id)
            .maybeSingle();

        if (profileRow == null) {
          await supabase.auth.signOut();
          throw Exception(
            'এই account-এর profile পাওয়া যায়নি। Admin-এর সাথে যোগাযোগ করুন।',
          );
        }

        if (!mounted) return;

        _msg('Login সফল হয়েছে।');
      }
    } on AuthException catch (e) {
      if (mounted) {
        _msg(
          e.message.isEmpty
              ? 'Mobile Number অথবা Password ভুল।'
              : e.message,
        );
      }
    } catch (e) {
      if (mounted) {
        _msg(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  void _msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  const _Logo(size: 105),

                  const SizedBox(height: 14),

                  const Text(
                    'কাঞ্চনপুর স্পোর্টিং ক্লাব',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'এটি একটি ক্রীড়া ও সেচ্ছাসেবী সংগঠন',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            signup
                                ? 'নতুন একাউন্ট খুলুন'
                                : 'Login করুন',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (signup) ...[
                            TextField(
                              controller: name,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],

                          TextField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                              ),
                              hintText: '01XXXXXXXXX',
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextField(
                            controller: password,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
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
                            ),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: busy ? null : submit,
                              child: busy
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                          CircularProgressIndicator(),
                                    )
                                  : Text(
                                      signup
                                          ? 'Signup'
                                          : 'Login',
                                    ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    setState(() {
                                      signup = !signup;
                                    });
                                  },
                            child: Text(
                              signup
                                  ? 'আগে account থাকলে Login করুন'
                                  : 'নতুন account খুলুন',
                            ),
                          ),
                        ],
                      ),
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

class HomePage extends StatelessWidget {
  final String username;
  final String phone;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.username,
    required this.phone,
    required this.onLogout,
  });

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('কাঞ্চনপুর স্পোর্টিং ক্লাব'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _open(context, const LeaderboardPage()),
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('প্রোফাইল'),
              onTap: () => _open(
                context,
                ProfilePage(username: username, phone: phone),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('লিডার বোর্ড'),
              onTap: () => _open(context, const LeaderboardPage()),
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('মাসিক চাঁদা'),
              onTap: () => _open(
                context,
                const PaymentPage(
                  title: 'মাসিক চাঁদা',
                  type: 'chanda',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('ডোনেশন'),
              onTap: () => _open(
                context,
                const PaymentPage(
                  title: 'ডোনেশন',
                  type: 'donation',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('কাঞ্চনপুরের পরিচিতি'),
              onTap: () => _open(
                context,
                const InfoPage(
                  title: 'কাঞ্চনপুরের পরিচিতি',
                  text:
                      'কাঞ্চনপুর আমাদের প্রিয় এলাকা। এর মানুষ, সংস্কৃতি, ঐতিহ্য ও সামাজিক সম্প্রীতি আমাদের গর্ব।',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('ক্লাবের পরিচিতি'),
              onTap: () => _open(
                context,
                const InfoPage(
                  title: 'ক্লাবের পরিচিতি',
                  text:
                      'কাঞ্চনপুর স্পোর্টিং ক্লাব একটি ক্রীড়া ও স্বেচ্ছাসেবী সংগঠন। খেলাধুলা, সামাজিক সেবা ও সুন্দর সমাজ গঠনে সদস্যদের একসঙ্গে কাজ করার জন্য এই প্ল্যাটফর্ম।',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('গ্যালারী'),
              onTap: () => _open(context, const GalleryPage()),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () => _open(context, const AboutPage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 35),
        children: [
            const _Logo(size: 105),
            const SizedBox(height: 12),
            const Text(
              'কাঞ্চনপুর স্পোর্টিং ক্লাব',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'এটি একটি ক্রীড়া ও সেচ্ছাসেবী সংগঠন',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            const _RunningMessage(),
            const SizedBox(height: 22),
            const Text(
              'কাঞ্চনপুর স্পোর্টিং ক্লাবের সদস্যের জন্য আবেদন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _open(context, const ApplicationPage()),
              icon: const Icon(Icons.person_add),
              label: const Text('আবেদন করুন'),
            ),
            const SizedBox(height: 20),
            const _StatusCard(
              title: 'সদস্য আবেদন',
              value: 'আবেদন করুন এবং Admin-এর যাচাইয়ের অপেক্ষা করুন',
              icon: Icons.assignment_ind,
            ),
            const SizedBox(height: 10),
            const _StatusCard(
              title: 'মাসিক চাঁদা',
              value: 'বিকাশ / নগদ / রকেট — Send Money',
              icon: Icons.payments,
            ),
            const SizedBox(height: 10),
            const _StatusCard(
              title: 'লিডার বোর্ড',
              value: 'প্রতি ১০০ টাকা = ১% অগ্রগতি',
              icon: Icons.emoji_events,
            ),
          ],
        ),
    );
  }
}

class ApplicationPage extends StatefulWidget {
  const ApplicationPage({super.key});

  @override
  State<ApplicationPage> createState() => _ApplicationPageState();
}

class _ApplicationPageState extends State<ApplicationPage> {
  final name = TextEditingController();
  final father = TextEditingController();
  final mother = TextEditingController();
  final birthYear = TextEditingController();
  final nid = TextEditingController();
  final division = TextEditingController();
  final district = TextEditingController();
  final thana = TextEditingController();
  final postCode = TextEditingController();
  final village = TextEditingController();
  final blood = TextEditingController();
  final mobile = TextEditingController();

  XFile? image;
  bool busy = false;

  @override
  void dispose() {
    for (final c in [
      name,
      father,
      mother,
      birthYear,
      nid,
      division,
      district,
      thana,
      postCode,
      village,
      blood,
      mobile,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (selected != null && mounted) setState(() => image = selected);
  }

  Future<void> submit() async {
    final fields = [
      name,
      father,
      mother,
      birthYear,
      nid,
      division,
      district,
      thana,
      postCode,
      village,
      blood,
      mobile,
    ];

    if (fields.any((c) => c.text.trim().isEmpty)) {
      _msg('সব তথ্য পূরণ করুন।');
      return;
    }

    final current = supabase.auth.currentUser;
    if (current == null) {
      _msg('আগে Login করুন।');
      return;
    }

    setState(() => busy = true);

    try {
      String? imageUrl;

      if (image != null) {
        final Uint8List bytes = await image!.readAsBytes();
        final ext = image!.name.contains('.')
            ? image!.name.split('.').last.toLowerCase()
            : 'jpg';
        final path = '${current.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

        await supabase.storage.from('member-photos').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: 'image/$ext',
              ),
            );

        imageUrl =
            supabase.storage.from('member-photos').getPublicUrl(path);
      }

      await supabase.from('member_applications').insert({
        'user_id': current.id,
        'username': current.userMetadata?['username']?.toString() ?? '',
        'name': name.text.trim(),
        'father_name': father.text.trim(),
        'mother_name': mother.text.trim(),
        'birth_year': birthYear.text.trim(),
        'nid': nid.text.trim(),
        'division': division.text.trim(),
        'district': district.text.trim(),
        'thana': thana.text.trim(),
        'post_code': postCode.text.trim(),
        'village': village.text.trim(),
        'blood_group': blood.text.trim(),
        'mobile': mobile.text.trim(),
        'image_url': imageUrl,
        'status': 'Pending',
      });

      if (!mounted) return;
      _msg('আবেদন সফলভাবে জমা হয়েছে। Admin যাচাই করবে।');
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সদস্য হওয়ার আবেদন')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field('নাম', name)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 100,
                  height: 115,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 30),
                            SizedBox(height: 5),
                            Text('ছবি আপলোড'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.green.shade50,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              image!.name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          field('পিতার নাম', father),
          field('মাতার নাম', mother),
          field('জন্মসাল', birthYear, keyboard: TextInputType.number),
          field('এনআইডি/জন্মনিবন্ধন নাম্বার', nid),
          field('বিভাগ', division),
          field('জেলা', district),
          field('থানা', thana),
          field('পোষ্ট কোড', postCode, keyboard: TextInputType.number),
          field('গ্রাম', village),
          field('রক্তের গ্রুপ', blood),
          field('মোবাইল নাম্বার', mobile, keyboard: TextInputType.phone),
          const SizedBox(height: 5),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: busy ? null : submit,
              icon: const Icon(Icons.send),
              label: Text(busy ? 'জমা হচ্ছে...' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final String title;
  final String type;

  const PaymentPage({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final amount = TextEditingController();
  final account = TextEditingController();
  final transaction = TextEditingController();

  String month = 'জানুয়ারি';
  String method = 'বিকাশ';
  bool busy = false;

  final months = const [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  @override
  void dispose() {
    amount.dispose();
    account.dispose();
    transaction.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final current = supabase.auth.currentUser;
    if (current == null) {
      _msg('আগে Login করুন।');
      return;
    }

    final parsedAmount = double.tryParse(amount.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      _msg('সঠিক টাকার পরিমাণ দিন।');
      return;
    }
    if (account.text.trim().isEmpty || transaction.text.trim().isEmpty) {
      _msg('Account Number ও Transaction ID দিন।');
      return;
    }

    setState(() => busy = true);

    try {
      await supabase.from('payments').insert({
        'user_id': current.id,
        'username': current.userMetadata?['username']?.toString() ?? '',
        'type': widget.type,
        'method': method,
        'amount': parsedAmount,
        'month': month,
        'account': account.text.trim(),
        'transaction_id': transaction.text.trim(),
        'status': 'Pending',
      });

      if (!mounted) return;
      _msg('Payment তথ্য জমা হয়েছে। Admin যাচাই করবে।');
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'পেমেন্ট করুন',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'বিকাশ', label: Text('বিকাশ')),
              ButtonSegment(value: 'নগদ', label: Text('নগদ')),
              ButtonSegment(value: 'রকেট', label: Text('রকেট')),
            ],
            selected: {method},
            onSelectionChanged: (v) => setState(() => method = v.first),
          ),
          const SizedBox(height: 15),
          const Text(
            'শুধু মাত্র Send Money গ্রহণ করা হয়।',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('01897173332'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  // Clipboard is intentionally not imported in this compact version.
                  _msg('নাম্বার: 01897173332');
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'টাকার পরিমাণ'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: month,
            decoration: const InputDecoration(labelText: 'মাসের নাম'),
            items: months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => month = v ?? month),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: account,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'একাউন্ট নাম্বার'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: transaction,
            decoration: const InputDecoration(labelText: 'ট্রানজেকশন আইডি'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy ? 'জমা হচ্ছে...' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await supabase
          .from('payments')
          .select('username, amount')
          .eq('status', 'Approved');

      final totals = <String, double>{};
      for (final row in data) {
        final name = row['username']?.toString() ?? 'Member';
        final amount = double.tryParse(row['amount'].toString()) ?? 0;
        totals[name] = (totals[name] ?? 0) + amount;
      }

      final list = totals.entries.map((e) {
        final percent = (e.value / 100).floor();
        String level;
        if (percent >= 300) {
          level = 'DIAMOND';
        } else if (percent >= 200) {
          level = 'PLATINUM';
        } else if (percent >= 100) {
          level = 'GOLD';
        } else {
          level = 'SILVER';
        }

        return {
          'username': e.key,
          'amount': e.value,
          'percent': percent,
          'level': level,
        };
      }).toList();

      list.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );

      if (mounted) {
        setState(() {
          rows = list;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leaderboard error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('লিডার বোর্ড')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? const Center(child: Text('Approved payment এখনো নেই।'))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (_, index) {
                      final r = rows[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            r['username'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${r['amount']} টাকা • ${r['percent']}% অগ্রগতি',
                          ),
                          trailing: Text(
                            r['level'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const AdminHomePage({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int tab = 0;
  bool loading = true;
  List<Map<String, dynamic>> applications = [];
  List<Map<String, dynamic>> payments = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final a = await supabase
          .from('member_applications')
          .select()
          .order('created_at', ascending: false);

      final p = await supabase
          .from('payments')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        applications = List<Map<String, dynamic>>.from(a);
        payments = List<Map<String, dynamic>>.from(p);
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin data error: $e')),
        );
      }
    }
  }

  Future<void> updateApplication(String id, String status) async {
    try {
      await supabase
          .from('member_applications')
          .update({'status': status})
          .eq('id', id);
      await load();
    } catch (e) {
      _msg(e.toString());
    }
  }

  Future<void> updatePayment(String id, String status) async {
    try {
      await supabase
          .from('payments')
          .update({'status': status})
          .eq('id', id);
      await load();
    } catch (e) {
      _msg(e.toString());
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingApps =
        applications.where((e) => e['status'] == 'Pending').length;
    final pendingPayments =
        payments.where((e) => e['status'] == 'Pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: tab,
              children: [
                ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text(
                      'স্বাগতম ${widget.username}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _AdminStat(
                            title: 'আবেদন',
                            value: '${applications.length}',
                            icon: Icons.people,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AdminStat(
                            title: 'Pending',
                            value: '$pendingApps',
                            icon: Icons.pending_actions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _AdminStat(
                            title: 'Payments',
                            value: '${payments.length}',
                            icon: Icons.payments,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AdminStat(
                            title: 'Payment Pending',
                            value: '$pendingPayments',
                            icon: Icons.hourglass_top,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _applicationsTab(),
                _paymentsTab(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Payments',
          ),
        ],
      ),
    );
  }

  Widget _applicationsTab() {
    if (applications.isEmpty) {
      return const Center(child: Text('কোনো আবেদন নেই।'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: applications.length,
      itemBuilder: (_, i) {
        final a = applications[i];
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.person),
            title: Text(a['name']?.toString() ?? ''),
            subtitle: Text(
              '${a['mobile'] ?? ''} • ${a['status'] ?? ''}',
            ),
            childrenPadding: const EdgeInsets.all(15),
            children: [
              _detail('Username', a['username']),
              _detail('পিতার নাম', a['father_name']),
              _detail('মাতার নাম', a['mother_name']),
              _detail('জন্মসাল', a['birth_year']),
              _detail('NID/জন্মনিবন্ধন', a['nid']),
              _detail('বিভাগ', a['division']),
              _detail('জেলা', a['district']),
              _detail('থানা', a['thana']),
              _detail('পোষ্ট কোড', a['post_code']),
              _detail('গ্রাম', a['village']),
              _detail('রক্তের গ্রুপ', a['blood_group']),
              _detail('মোবাইল', a['mobile']),
              if ((a['image_url'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Image.network(
                    a['image_url'].toString(),
                    height: 150,
                    errorBuilder: (_, __, ___) =>
                        const Text('ছবি দেখা যায়নি'),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          updateApplication(a['id'].toString(), 'Rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          updateApplication(a['id'].toString(), 'Approved'),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentsTab() {
    if (payments.isEmpty) {
      return const Center(child: Text('কোনো payment নেই।'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: payments.length,
      itemBuilder: (_, i) {
        final p = payments[i];
        return Card(
          child: ListTile(
            title: Text(
              '${p['type'] == 'chanda' ? 'চাঁদা' : 'Donation'} • ${p['amount']} টাকা',
            ),
            subtitle: Text(
              '${p['username'] ?? ''}\n'
              '${p['method'] ?? ''} • ${p['month'] ?? ''}\n'
              'Account: ${p['account'] ?? ''}\n'
              'TXID: ${p['transaction_id'] ?? ''}\n'
              'Status: ${p['status'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) =>
                  updatePayment(p['id'].toString(), v),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'Approved',
                  child: Text('Approve'),
                ),
                PopupMenuItem(
                  value: 'Rejected',
                  child: Text('Reject'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label: ${value ?? ''}'),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AdminStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String username;
  final String phone;

  const ProfilePage({
    super.key,
    required this.username,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(username),
            subtitle: Text(phone),
          ),
        ),
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  final String title;
  final String text;

  const InfoPage({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, height: 1.7),
            ),
          ),
        ),
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('গ্যালারী')),
      body: const Center(
        child: Text(
          'গ্যালারীর ছবি Admin Panel থেকে যুক্ত করার ব্যবস্থা পরের ধাপে করা হবে।',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'এই Apps টি কাঞ্চনপুর মানুষদের জন্য বানানো হয়েছে।\n\n'
            'Apps. SEO- শাহাদাত হোসেন রাজু\n'
            'প্রচার সম্পাদক, কাঞ্চনপুর স্পোর্টিং ক্লাব',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.8),
          ),
        ),
      ),
    );
  }
}

class _RunningMessage extends StatefulWidget {
  const _RunningMessage();

  @override
  State<_RunningMessage> createState() => _RunningMessageState();
}

class _RunningMessageState extends State<_RunningMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          return Align(
            alignment: Alignment(1.8 - controller.value * 3.6, 0),
            child: child,
          );
        },
        child: const Text(
          'আসুন সবাই মিলে গড়ি সুন্দর ও নিরপেক্ষ সমাজ / মাদক কে না বলুন।',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;

  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/club_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: const Icon(
          Icons.sports_soccer,
          size: 48,
          color: Colors.green,
        ),
      ),
    );
  }
}
