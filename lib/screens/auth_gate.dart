import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';
import 'wallet_screen.dart';
import '../repositories/txn_repository.dart';
import '../state/wallet_state.dart';

// Shows the login screen when nobody is signed in, the wallet otherwise.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // A stream: the current user now, and again at every login / logout.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        final user = snapshot.data!;
        return ChangeNotifierProvider<WalletState>(
          create: (_) => WalletState(TxnRepository(user.uid)),
          child: const WalletScreen(),
        );
      },
    );
  }
}
