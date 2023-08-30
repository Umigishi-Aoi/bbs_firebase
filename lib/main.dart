import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  auth.User? currentUser;
  String error = 'no error';
  @override
  void initState() {
    auth.FirebaseAuth.instance.authStateChanges().listen((auth.User? user) {
      setState(() {
        currentUser = user;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(error),
              SizedBox(
                width: 300,
                height: 150,
                child: ElevatedButton(
                  onPressed: () async {
                    auth.GithubAuthProvider githubProvider =
                        auth.GithubAuthProvider();
                    try {
                      await auth.FirebaseAuth.instance
                          .signInWithRedirect(githubProvider);
                    } catch (e) {
                      error = e.toString();
                      setState(() {
                        
                      });
                    }
                  },
                  child: const Text('GitHub ログイン'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const BbsPage();
    }
  }
}

class BbsPage extends StatefulWidget {
  const BbsPage({
    super.key,
  });

  @override
  State<BbsPage> createState() => _BbsPageState();
}

class _BbsPageState extends State<BbsPage> {
  late Future<QuerySnapshot<Map<String, dynamic>>> data;
  late auth.User user;

  @override
  void initState() {
    user = auth.FirebaseAuth.instance.currentUser!;
    data = FirebaseFirestore.instance
        .collection('bbs')
        .orderBy('created_at', descending: true)
        .get();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              await auth.FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        title: const Text('掲示板'),
      ),
      body: FutureBuilder(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.data == null) {
            return const Text('データがありません');
          }
          final list = snapshot.data!.docs;

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index].data();
              final date = DateTime.parse(
                item['created_at'].toString(),
              ).toLocal().toString();
              return Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all()),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 64),
                          child: ClipOval(
                            child: Image.network(
                              item['avatar_url'].toString(),
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['nickname'].toString()),
                                    Text(
                                      date.substring(0, date.length - 7),
                                    ),
                                  ],
                                ),
                              ),
                              Text(item['content'].toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<Widget>(
              builder: (context) => const AddPage(),
            ),
          );
          data = FirebaseFirestore.instance
              .collection('bbs')
              .orderBy('created_at', descending: true)
              .get();
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({
    super.key,
  });

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController controller = TextEditingController();
  late auth.User user;

  @override
  void initState() {
    user = auth.FirebaseAuth.instance.currentUser!;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規投稿'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextField(
                maxLength: 150,
                maxLines: 5,
                minLines: 1,
                controller: controller,
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('bbs').add({
                    'uid': user.uid,
                    'created_at': DateTime.now().toString(),
                    'nickname': user.displayName,
                    'avatar_url': user.photoURL,
                    'content': controller.text,
                  });
                  if (!mounted) {
                    return;
                  }
                  Navigator.pop(context);
                },
                child: const Text('投稿する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
