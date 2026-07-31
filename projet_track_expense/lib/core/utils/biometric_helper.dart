import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  // Instance du plugin d'authentification locale
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ==========================================
  // VÉRIFICATION DE LA DISPONIBILITÉ
  // ==========================================

  /// Vérifie si le device supporte la biométrie
  Future<bool> isBiometricSupported() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Récupère la liste des types de biométrie disponibles (ex: Fingerprint, Face ID)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Retourne un booléen indiquant si l'empreinte digitale est disponible
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Retourne un booléen indiquant si la reconnaissance faciale est disponible
  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  // ==========================================
  // AUTHENTIFICATION
  // ==========================================

  /// Tente une authentification biométrique
  /// 
  /// [reason]: Le message affiché à l'utilisateur (ex: "Veuillez scanner votre empreinte")
  /// [stickyAuth]: Si true, l'authentification persiste tant que l'app est en premier plan
  Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      // On vérifie d'abord si la biométrie est disponible
      if (!(await isBiometricSupported())) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true, // On force uniquement la biométrie (pas de PIN système)
        ),
      );

      return authenticated;
    } catch (e) {
      // Si l'utilisateur annule ou si une erreur survient
      return false;
    }
  }

  /// Version simplifiée : authentifie avec un message par défaut
  Future<bool> authenticateWithDefaultMessage() async {
    return await authenticate(
      reason: 'Veuillez vous authentifier pour accéder à vos données financières',
    );
  }

  // ==========================================
  // UTILITAIRE POUR LE STOCKAGE DES PRÉFÉRENCES
  // ==========================================

  /// Indique si l'utilisateur a activé la biométrie dans les paramètres
  /// (À utiliser avec le stockage sécurisé ou SharedPreferences)
  Future<bool> isBiometricEnabledInSettings() async {
    // NOTE: Pour l'instant, cette fonction retourne false par défaut.
    // Nous la connecterons à un vrai stockage (comme Preferences) dans l'écran des paramètres.
    return false;
  }

  /// Sauvegarde l'état de l'activation de la biométrie
  Future<void> setBiometricEnabledInSettings(bool enabled) async {
    // NOTE: Cette fonction sera remplie quand nous aurons l'écran des paramètres.
    // Elle stockera l'état dans le stockage sécurisé ou dans un fichier de préférences.
  }
}