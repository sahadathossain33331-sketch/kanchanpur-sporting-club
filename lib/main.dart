import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://vleaqmiyihlginevgfmw.supabase.co';
const supabaseAnonKey = 'sb_publishable_7D6mwaP16HzmYQTtr71icQ__JksJ9KJ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const KanchanpurApp());
}

class KanchanpurApp extends StatelessWidget {
  const KanchanpurApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'কাঞ্চনপুর স্পোর্টিং ক্লাব',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF283593)),
    home: const LoginPage(),
  );
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Image.asset('assets/club_logo.png', width: 150),
        const SizedBox(height: 12),
        const Text('কাঞ্চনপুর স্পোর্টিং ক্লাব',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const Text('এটি একটি ক্রীড়া ও সেচ্ছাসেবী সংগঠন'),
        const SizedBox(height: 28),
        const TextField(decoration: InputDecoration(labelText:'মোবাইল/ইমেইল', border:OutlineInputBorder())),
        const SizedBox(height: 12),
        const TextField(obscureText:true, decoration:InputDecoration(labelText:'পাসওয়ার্ড', border:OutlineInputBorder())),
        const SizedBox(height:18),
        SizedBox(width:double.infinity,height:52,child:FilledButton(
          onPressed:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomePage())),
          child:const Text('Login'))),
        TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  },
  child: const Text('নতুন সদস্য? Signup করুন'),
),
      ]),
    ))),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('কাঞ্চনপুর স্পোর্টিং ক্লাব')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      Center(child:Image.asset('assets/club_logo.png',width:190)),
      const Center(child:Text('কাঞ্চনপুর স্পোর্টিং ক্লাব',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold))),
      const Center(child:Text('এটি একটি ক্রীড়া ও সেচ্ছাসেবী সংগঠন')),
      const SizedBox(height:24),
      Card(child:ListTile(
        leading:const Icon(Icons.assignment),title:const Text('নতুন সদস্যের জন্য আবেদন'),
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ApplicationPage())))),
      Card(child:ListTile(
        leading:const Icon(Icons.payments),title:const Text('মাসিক চাঁদা / ডোনেশন'),
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PaymentPage())))),
      Card(child:ListTile(
        leading:const Icon(Icons.admin_panel_settings),title:const Text('Admin Panel'),
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPage())))),
    ]),
  );
}

class ApplicationPage extends StatefulWidget {
  const ApplicationPage({super.key});
  @override State<ApplicationPage> createState()=>_ApplicationPageState();
}
class _ApplicationPageState extends State<ApplicationPage>{
  final c=<String,TextEditingController>{
    'নাম':TextEditingController(),'পিতার নাম':TextEditingController(),
    'মাতার নাম':TextEditingController(),'জন্মসাল':TextEditingController(),
    'এনআইডি/জন্মনিবন্ধন নাম্বার':TextEditingController(),'জেলা':TextEditingController(),
    'থানা':TextEditingController(),'গ্রাম':TextEditingController(),'মোবাইল নাম্বার':TextEditingController()
  };
  String blood='A+'; XFile? photo;

  Future<void> pick() async {
    final p=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:80);
    if(p!=null)setState(()=>photo=p);
  }

  Future<void> submit() async {
    // When Supabase is initialized, insert into `applications`.
    // Photo can be uploaded to Storage bucket `member-photos`.
    // This demo keeps the UI ready without pretending that a backend is live.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content:Text('আবেদন প্রস্তুত। Supabase সেটআপের পর অনলাইনে সংরক্ষণ হবে।')));
  }

  Widget f(String label)=>Padding(
    padding:const EdgeInsets.only(top:10),
    child:TextField(controller:c[label],decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('নতুন সদস্যের জন্য আবেদন')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:f('নাম')),
        const SizedBox(width:12),
        Column(children:[
          CircleAvatar(radius:42,backgroundImage:photo==null?null:FileImage(File(photo!.path)),
            child:photo==null?const Icon(Icons.person,size:40):null),
          TextButton(onPressed:pick,child:const Text('ছবি আপলোড')),
        ])
      ]),
      for(final x in ['পিতার নাম','মাতার নাম','জন্মসাল','এনআইডি/জন্মনিবন্ধন নাম্বার','জেলা','থানা','গ্রাম']) f(x),
      DropdownButtonFormField<String>(
        value:blood,decoration:const InputDecoration(labelText:'রক্তের গ্রুপ',border:OutlineInputBorder()),
        items:['A+','A-','B+','B-','AB+','AB-','O+','O-'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
        onChanged:(v)=>setState(()=>blood=v!)),
      f('মোবাইল নাম্বার'),
      const SizedBox(height:18),
      SizedBox(height:52,child:FilledButton(onPressed:submit,child:const Text('Submit')))
    ]));
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override State<PaymentPage> createState()=>_PaymentPageState();
}
class _PaymentPageState extends State<PaymentPage>{
  String method='বিকাশ';
  final amount=TextEditingController(); final trx=TextEditingController();

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('মাসিক চাঁদা / ডোনেশন')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('এটি আবেদন ফর্ম থেকে সম্পূর্ণ আলাদা পেমেন্ট সেকশন।',
        style:TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      Card(child:Column(children:[
        RadioListTile(value:'বিকাশ',groupValue:method,title:const Text('বিকাশ'),subtitle:const Text('Personal • 01897173332'),onChanged:(v)=>setState(()=>method=v!)),
        RadioListTile(value:'নগদ',groupValue:method,title:const Text('নগদ'),subtitle:const Text('Personal • 01897173332'),onChanged:(v)=>setState(()=>method=v!)),
        RadioListTile(value:'রকেট',groupValue:method,title:const Text('রকেট'),subtitle:const Text('01897173332'),onChanged:(v)=>setState(()=>method=v!)),
      ])),
      const SizedBox(height:12),
      TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'টাকার পরিমাণ',prefixText:'৳ ',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:trx,decoration:const InputDecoration(labelText:'Transaction ID',border:OutlineInputBorder())),
      const SizedBox(height:18),
      FilledButton(onPressed:(){
        if(amount.text.isEmpty||trx.text.isEmpty){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('টাকার পরিমাণ ও Transaction ID দিন।')));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('পেমেন্ট তথ্য জমা হয়েছে। Admin যাচাই করবেন।')));
      },child:const Text('Payment Submit')),
    ]));
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Admin Panel')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      const Card(child:ListTile(leading:Icon(Icons.assignment),title:Text('Applications'),subtitle:Text('Pending / Approved / Rejected'))),
      const Card(child:ListTile(leading:Icon(Icons.payments),title:Text('Payments'),subtitle:Text('Manual verification by Transaction ID'))),
      const Card(child:ListTile(leading:Icon(Icons.people),title:Text('Members'),subtitle:Text('Approved member list'))),
      const Card(child:ListTile(leading:Icon(Icons.bar_chart),title:Text('Reports'),subtitle:Text('Monthly collection and donation totals'))),
    ]));
}
