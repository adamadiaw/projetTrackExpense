import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/core/utils/pin_helper.dart';
import 'package:projet_track_expense/presentation/screens/pin_screen.dart';
import 'package:projet_track_expense/presentation/providers/repository_providers.dart';
import 'package:projet_track_expense/data/repositories/impl/seed_categories.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final PinHelper _pinHelper = PinHelper();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 🟢 ÉTAPE 1 : Initialiser les catégories par défaut (avant toute navigation)
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await CategorySeeder.seedCategories(repo);
    } catch (e) {
      // En cas d'erreur, on ignore pour l'instant pour ne pas bloquer l'app
    }

    // 🟢 ÉTAPE 2 : Vérifier le PIN
    final isPinCreated = await _pinHelper.isPinCreated();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PinScreen(
            isCreating: !isPinCreated,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'ProjetTrackExpense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}