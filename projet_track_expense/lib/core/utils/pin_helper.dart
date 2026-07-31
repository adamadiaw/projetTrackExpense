import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinHelper {
  // Clés pour le stockage sécurisé
  static const String _pinStorageKey = 'user_pin_code';
  static const String _attemptsStorageKey = 'pin_failed_attempts';
  static const String _lockUntilStorageKey = 'pin_lock_until_timestamp';

  // Stockage sécurisé
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Seuil de verrouillage
  static const int _maxAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 5);

  // ==========================================
  // GESTION DU PIN
  // ==========================================

  /// Vérifie si un PIN a déjà été créé
  Future<bool> isPinCreated() async {
    final pin = await _storage.read(key: _pinStorageKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Crée ou met à jour le PIN
  Future<void> savePin(String newPin) async {
    await _storage.write(key: _pinStorageKey, value: newPin);
    // Réinitialiser le compteur de tentatives lors d'un changement de PIN
    await resetAttempts();
  }

  /// Vérifie si le PIN saisi est correct
  Future<bool> verifyPin(String inputPin) async {
    // 1. Vérifier si l'application est actuellement bloquée
    if (await isLockedOut()) {
      return false;
    }

    // 2. Récupérer le PIN stocké
    final storedPin = await _storage.read(key: _pinStorageKey);
    
    // Si le PIN n'existe pas (cas d'erreur), on considère que c'est faux
    if (storedPin == null || storedPin.isEmpty) {
      return false;
    }

    // 3. Comparer les PINs
    if (storedPin == inputPin) {
      // Succès : on réinitialise le compteur de tentatives
      await resetAttempts();
      return true;
    } else {
      // Échec : on incrémente le compteur
      await _incrementFailedAttempts();
      return false;
    }
  }

  // ==========================================
  // GESTION DES TENTATIVES ET DU VERROUILLAGE
  // ==========================================

  /// Réinitialise le compteur de tentatives
  Future<void> resetAttempts() async {
    await _storage.write(key: _attemptsStorageKey, value: '0');
    await _storage.delete(key: _lockUntilStorageKey);
  }

  /// Incrémente le compteur de tentatives échouées
  Future<void> _incrementFailedAttempts() async {
    final attemptsStr = await _storage.read(key: _attemptsStorageKey);
    int attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    attempts++;

    // Sauvegarder le nouveau compteur
    await _storage.write(key: _attemptsStorageKey, value: attempts.toString());

    // Si on atteint le maximum, on verrouille
    if (attempts >= _maxAttempts) {
      final lockUntil = DateTime.now().add(_lockDuration).millisecondsSinceEpoch;
      await _storage.write(key: _lockUntilStorageKey, value: lockUntil.toString());
    }
  }

  /// Vérifie si l'application est actuellement bloquée
  Future<bool> isLockedOut() async {
    final lockUntilStr = await _storage.read(key: _lockUntilStorageKey);
    if (lockUntilStr == null || lockUntilStr.isEmpty) {
      return false;
    }

    final lockUntil = int.tryParse(lockUntilStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Si le timestamp de déblocage est dans le futur, c'est qu'on est bloqué
    if (now < lockUntil) {
      return true;
    } else {
      // Le temps est écoulé, on peut réinitialiser le verrouillage
      await resetAttempts();
      return false;
    }
  }

  /// Retourne le nombre de tentatives restantes avant verrouillage
  Future<int> getRemainingAttempts() async {
    final attemptsStr = await _storage.read(key: _attemptsStorageKey);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    return _maxAttempts - attempts;
  }

  /// Retourne le temps restant avant déblocage (en secondes), 0 si non bloqué
  Future<int> getLockoutTimeRemaining() async {
    if (!(await isLockedOut())) return 0;

    final lockUntilStr = await _storage.read(key: _lockUntilStorageKey);
    final lockUntil = int.tryParse(lockUntilStr ?? '0') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final remaining = (lockUntil - now) ~/ 1000; // en secondes
    return remaining > 0 ? remaining : 0;
  }
}