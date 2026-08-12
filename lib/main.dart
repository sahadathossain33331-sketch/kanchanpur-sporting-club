import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  bool loggedIn = false;
  String username = '';
  String phone = '';
  bool admin = false;

  final List<MemberApplication> applications = [];
  final List<PaymentRecord> payments = [];

  void login(String name, String mobile, bool isAdmin) {
    setState(() {
      loggedIn = true;
      username = name;
      phone = mobile;
      admin = isAdmin;
    });
  }

  void logout() {
    setState(() {
      loggedIn = false;
      username = '';
      phone = '';
      admin = false;
    });
  }

  void addApplication(MemberApplication item) {
    setState(() => applications.add(item));
  }

  void addPayment(PaymentRecord item) {
    setState(() => payments.add(item));
  }

  void updateApplication(int index, String status) {
    setState(() => applications[index].status = status);
  }

  void updatePayment(int index, String status) {
    setState(() => payments[index].status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return AuthPage(onLogin: login);
    }

    if (admin) {
      return AdminHomePage(
        applications: applications,
        payments: payments,
        onApplicationStatus: updateApplication,
        onPaymentStatus: updatePayment,
        onLogout: logout,
      );
    }

    return HomePage(
      username: username,
      phone: phone,
      applications: applications,
      payments: payments,
      onApplication: addApplication,
      onPayment: addPayment,
      onLogout: logout,
    );
  }
}

class AuthPage extends StatefulWidget {
  final void Function(String, String, bool) onLogin;

  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool signup = false;
  bool hidePassword = true;
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

  void submit() {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সব তথ্য পূরণ করুন।')),
      );
      return;
    }

    // Demo admin login for the first UI build.
    // Production version should use Supabase Auth and a secure admin role.
    final isAdmin =
        name.text.trim().toLowerCase() == 'admin' &&
        password.text.trim() == 'admin123';

    widget.onLogin(name.text.trim(), phone.text.trim(), isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  _Logo(size: 105),
                  const SizedBox(height: 16),
                  const Text(
                    'কাঞ্চনপুর স্পোর্টিং ক্লাব',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'এটি একটি ক্রীড়া ও সেচ্ছাসেবী সংগঠন',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 35),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            signup ? 'নতুন একাউন্ট খুলুন' : 'Login করুন',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: name,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.person_outline),
                              hintText: 'আপনার username',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                              hintText: '01XXXXXXXXX',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => hidePassword = !hidePassword),
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: submit,
                              child: Text(signup ? 'Signup' : 'Login'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => signup = !signup),
                            child: Text(
                              signup
                                  ? 'আগে থেকেই একাউন্ট আছে? Login করুন'
                                  : 'নতুন একাউন্ট খুলতে Signup করুন',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Admin demo login: username admin, password admin123',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black45),
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

class HomePage extends StatefulWidget {
  final String username;
  final String phone;
  final List<MemberApplication> applications;
  final List<PaymentRecord> payments;
  final void Function(MemberApplication) onApplication;
  final void Function(PaymentRecord) onPayment;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.username,
    required this.phone,
    required this.applications,
    required this.payments,
    required this.onApplication,
    required this.onPayment,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: _AppDrawer(
        username: widget.username,
        onLogout: widget.onLogout,
        onProfile: () => Navigator.pop(context),
        onLeaderboard: () => _open(const LeaderboardPage()),
        onChanda: () => _open(PaymentPage(
          title: 'মাসিক চাঁদা',
          type: PaymentType.chanda,
          phone: widget.phone,
          onSubmit: widget.onPayment,
        )),
        onDonation: () => _open(PaymentPage(
          title: 'ডোনেশন',
          type: PaymentType.donation,
          phone: widget.phone,
          onSubmit: widget.onPayment,
        )),
        onKanchanpur: () => _open(const InfoPage(
          title: 'কাঞ্চনপুরের পরিচিতি',
          text:
              'কাঞ্চনপুর আমাদের প্রিয় এলাকা। এর মানুষ, সংস্কৃতি, ঐতিহ্য ও সামাজিক সম্প্রীতি আমাদের গর্ব।',
        )),
        onClub: () => _open(const InfoPage(
          title: 'ক্লাবের পরিচিতি',
          text:
              'কাঞ্চনপুর স্পোর্টিং ক্লাব একটি ক্রীড়া ও স্বেচ্ছাসেবী সংগঠন। খেলাধুলা, সামাজিক সেবা ও সুন্দর সমাজ গঠনে সদস্যদের একসঙ্গে কাজ করার জন্য এই প্ল্যাটফর্ম।',
        )),
        onGallery: () => _open(const GalleryPage()),
        onAbout: () => _open(const AboutPage()),
      ),
      appBar: AppBar(
        title: const Text('কাঞ্চনপুর স্পোর্টিং ক্লাব'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _open(const LeaderboardPage()),
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 35),
          children: [
            const SizedBox(height: 5),
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
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const _RunningMessage(),
            const SizedBox(height: 25),
            const Text(
              'কাঞ্চনপুর স্পোর্টিং ক্লাবের সদস্যের জন্য আবেদন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _open(MemberApplicationPage(
                  username: widget.username,
                  onSubmit: widget.onApplication,
                )),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('আবেদন করুন'),
              ),
            ),
            const SizedBox(height: 22),
            _StatusCard(
              title: 'আমার আবেদন',
              icon: Icons.fact_check_outlined,
              value: _myApplicationStatus(),
            ),
            const SizedBox(height: 10),
            _StatusCard(
              title: 'আমার পেমেন্ট',
              icon: Icons.payments_outlined,
              value: '${widget.payments.length}টি জমা দেওয়া হয়েছে',
            ),
          ],
        ),
      ),
    );
  }

  String _myApplicationStatus() {
    final mine =
        widget.applications.where((e) => e.username == widget.username).toList();
    if (mine.isEmpty) return 'এখনো আবেদন করা হয়নি';
    return mine.last.status;
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _AppDrawer extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  final VoidCallback onProfile;
  final VoidCallback onLeaderboard;
  final VoidCallback onChanda;
  final VoidCallback onDonation;
  final VoidCallback onKanchanpur;
  final VoidCallback onClub;
  final VoidCallback onGallery;
  final VoidCallback onAbout;

  const _AppDrawer({
    required this.username,
    required this.onLogout,
    required this.onProfile,
    required this.onLeaderboard,
    required this.onChanda,
    required this.onDonation,
    required this.onKanchanpur,
    required this.onClub,
    required this.onGallery,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
              child: const Column(
                children: [
                  _Logo(size: 80),
                  SizedBox(height: 10),
                  Text(
                    'কাঞ্চনপুর স্পোর্টিং ক্লাব',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('প্রোফাইল'),
              subtitle: Text(username),
              onTap: onProfile,
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text('লিডার বোর্ড'),
              onTap: onLeaderboard,
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('মাসিক চাঁদা'),
              onTap: onChanda,
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('ডোনেশন'),
              onTap: onDonation,
            ),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('কাঞ্চনপুরের পরিচিতি'),
              onTap: onKanchanpur,
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('ক্লাবের পরিচিতি'),
              onTap: onClub,
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('গ্যালারী'),
              onTap: onGallery,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: onAbout,
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
    );
  }
}

class MemberApplicationPage extends StatefulWidget {
  final String username;
  final void Function(MemberApplication) onSubmit;

  const MemberApplicationPage({
    super.key,
    required this.username,
    required this.onSubmit,
  });

  @override
  State<MemberApplicationPage> createState() => _MemberApplicationPageState();
}

class _MemberApplicationPageState extends State<MemberApplicationPage> {
  final formKey = GlobalKey<FormState>();
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
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (result != null) setState(() => image = result);
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    widget.onSubmit(
      MemberApplication(
        username: widget.username,
        name: name.text.trim(),
        fatherName: father.text.trim(),
        motherName: mother.text.trim(),
        birthYear: birthYear.text.trim(),
        nid: nid.text.trim(),
        division: division.text.trim(),
        district: district.text.trim(),
        thana: thana.text.trim(),
        postCode: postCode.text.trim(),
        village: village.text.trim(),
        bloodGroup: blood.text.trim(),
        mobile: mobile.text.trim(),
        imagePath: image?.path,
        status: 'Pending',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('আবেদন সফলভাবে জমা হয়েছে। Admin যাচাই করবেন।')),
    );
    Navigator.pop(context);
  }

  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? '$label পূরণ করুন' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সদস্য হওয়ার আবেদন')),
      body: Form(
        key: formKey,
        child: ListView(
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
                            child: Image.file(
                              File(image!.path),
                              fit: BoxFit.cover,
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
                onPressed: submit,
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PaymentType { chanda, donation }

class PaymentPage extends StatefulWidget {
  final String title;
  final PaymentType type;
  final String phone;
  final void Function(PaymentRecord) onSubmit;

  const PaymentPage({
    super.key,
    required this.title,
    required this.type,
    required this.phone,
    required this.onSubmit,
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

  void submit() {
    if (amount.text.trim().isEmpty ||
        account.text.trim().isEmpty ||
        transaction.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সব payment তথ্য পূরণ করুন।')),
      );
      return;
    }

    widget.onSubmit(
      PaymentRecord(
        username: widget.phone,
        type: widget.type,
        method: method,
        amount: double.tryParse(amount.text.trim()) ?? 0,
        month: month,
        account: account.text.trim(),
        transactionId: transaction.text.trim(),
        status: 'Pending',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment জমা হয়েছে। Admin যাচাই করবেন।')),
    );
    Navigator.pop(context);
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
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('শুধু মাত্র Send Money গ্রহণ করা হয়'),
              subtitle: const Text(
                '01897173332',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                tooltip: 'Copy',
                onPressed: () {
                  // Clipboard can be added later without changing the page design.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('নাম্বার: 01897173332')),
                  );
                },
                icon: const Icon(Icons.copy),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'টাকার পরিমাণ',
              prefixIcon: Icon(Icons.currency_exchange),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: month,
            decoration: const InputDecoration(
              labelText: 'মাসের নাম',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
            items: months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => month = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: account,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'যে Account Number থেকে পাঠিয়েছেন',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: transaction,
            decoration: const InputDecoration(
              labelText: 'Transaction ID',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: submit,
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = [
      ('সদস্য ১', 24000.0),
      ('সদস্য ২', 15700.0),
      ('সদস্য ৩', 8500.0),
      ('সদস্য ৪', 4200.0),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('লিডার বোর্ড')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, size: 55),
                  SizedBox(height: 8),
                  Text(
                    '২ বছরের Leaderboard',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'প্রতি ১০০ টাকা Approved payment = ১%',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(demo.length, (i) {
            final percent = (demo[i].$2 / 100).clamp(0, 100);
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(demo[i].$1),
                subtitle: Text(
                  '${demo[i].$2.toStringAsFixed(0)} টাকা • ${percent.toStringAsFixed(0)}%',
                ),
                trailing: Text(
                  levelFor(percent.toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          const Text(
            'Level: SILVER → GOLD → PLATINUM → DIAMOND',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String levelFor(double percent) {
  if (percent >= 300) return 'DIAMOND';
  if (percent >= 200) return 'PLATINUM';
  if (percent >= 100) return 'GOLD';
  return 'SILVER';
}

class AdminHomePage extends StatefulWidget {
  final List<MemberApplication> applications;
  final List<PaymentRecord> payments;
  final void Function(int, String) onApplicationStatus;
  final void Function(int, String) onPaymentStatus;
  final VoidCallback onLogout;

  const AdminHomePage({
    super.key,
    required this.applications,
    required this.payments,
    required this.onApplicationStatus,
    required this.onPaymentStatus,
    required this.onLogout,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          _adminDashboard(),
          _applications(),
          _payments(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
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

  Widget _adminDashboard() {
    final pendingApps =
        widget.applications.where((e) => e.status == 'Pending').length;
    final pendingPayments =
        widget.payments.where((e) => e.status == 'Pending').length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'স্বাগতম Admin',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _AdminStat(
                title: 'আবেদন',
                value: '${widget.applications.length}',
                icon: Icons.person_add_alt_1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AdminStat(
                title: 'Pending',
                value: '$pendingApps',
                icon: Icons.hourglass_top,
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
                value: '${widget.payments.length}',
                icon: Icons.payments,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AdminStat(
                title: 'Payment Pending',
                value: '$pendingPayments',
                icon: Icons.pending_actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'এটি প্রথম build-এর Admin UI। Production version-এ Supabase database ও secure admin role যুক্ত করে এই তথ্য সব ডিভাইস থেকে দেখা ও যাচাই করা হবে।',
            ),
          ),
        ),
      ],
    );
  }

  Widget _applications() {
    if (widget.applications.isEmpty) {
      return const Center(child: Text('কোনো আবেদন এখনো নেই।'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.applications.length,
      itemBuilder: (context, index) {
        final a = widget.applications[index];
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.person),
            title: Text(a.name),
            subtitle: Text('${a.mobile} • ${a.status}'),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              _detail('পিতার নাম', a.fatherName),
              _detail('মাতার নাম', a.motherName),
              _detail('জন্মসাল', a.birthYear),
              _detail('NID/জন্মনিবন্ধন', a.nid),
              _detail('ঠিকানা', '${a.village}, ${a.thana}, ${a.district}'),
              _detail('বিভাগ', a.division),
              _detail('রক্তের গ্রুপ', a.bloodGroup),
              _detail('মোবাইল', a.mobile),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onApplicationStatus(index, 'Rejected');
                        setState(() {});
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onApplicationStatus(index, 'Approved');
                        setState(() {});
                      },
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

  Widget _payments() {
    if (widget.payments.isEmpty) {
      return const Center(child: Text('কোনো payment এখনো নেই।'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.payments.length,
      itemBuilder: (context, index) {
        final p = widget.payments[index];
        return Card(
          child: ListTile(
            title: Text(
              '${p.type == PaymentType.chanda ? 'চাঁদা' : 'Donation'} • ${p.amount.toStringAsFixed(0)} টাকা',
            ),
            subtitle: Text(
              '${p.method} • ${p.month}\nAccount: ${p.account}\nTXID: ${p.transactionId}\nStatus: ${p.status}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                widget.onPaymentStatus(index, v);
                setState(() {});
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Approved', child: Text('Approve')),
                PopupMenuItem(value: 'Rejected', child: Text('Reject')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String a, String b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('$a: $b'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  final String title;
  final String text;

  const InfoPage({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(text, style: const TextStyle(fontSize: 17, height: 1.7)),
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
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (_, index) {
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo, size: 55),
                  const SizedBox(height: 8),
                  Text('ছবি ${index + 1}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
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
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(username),
            subtitle: Text(phone),
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
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    animation = CurvedAnimation(parent: controller, curve: Curves.linear);
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
        animation: animation,
        builder: (_, child) {
          return Align(
            alignment: Alignment(
              1.8 - (animation.value * 3.6),
              0,
            ),
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

class MemberApplication {
  final String username;
  final String name;
  final String fatherName;
  final String motherName;
  final String birthYear;
  final String nid;
  final String division;
  final String district;
  final String thana;
  final String postCode;
  final String village;
  final String bloodGroup;
  final String mobile;
  final String? imagePath;
  String status;

  MemberApplication({
    required this.username,
    required this.name,
    required this.fatherName,
    required this.motherName,
    required this.birthYear,
    required this.nid,
    required this.division,
    required this.district,
    required this.thana,
    required this.postCode,
    required this.village,
    required this.bloodGroup,
    required this.mobile,
    required this.imagePath,
    required this.status,
  });
}

class PaymentRecord {
  final String username;
  final PaymentType type;
  final String method;
  final double amount;
  final String month;
  final String account;
  final String transactionId;
  String status;

  PaymentRecord({
    required this.username,
    required this.type,
    required this.method,
    required this.amount,
    required this.month,
    required this.account,
    required this.transactionId,
    required this.status,
  });
}
