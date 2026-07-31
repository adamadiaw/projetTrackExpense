import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  // Clé statique pour stocker la clé de chiffrement de manière sécurisée
  static const String _keyStorageKey = 'aes_encryption_key';
  static const String _ivStorageKey = 'aes_encryption_iv';

  // Stockage sécurisé (les données sont chiffrées par le système d'exploitation)
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Singleton pour éviter de recréer la clé à chaque fois
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  // Variables pour garder la clé et le IV en mémoire (pour performance)
  encrypt.Key? _key;
  encrypt.IV? _iv;

  // Initialiser ou récupérer la clé de chiffrement
  Future<void> _initKeys() async {
    if (_key != null && _iv != null) return;

    // 1. Essayer de récupérer la clé existante
    String? storedKey = await _storage.read(key: _keyStorageKey);
    String? storedIv = await _storage.read(key: _ivStorageKey);

    if (storedKey != null && storedIv != null) {
      // Si elle existe, on l'utilise
      _key = encrypt.Key.fromBase64(storedKey);
      _iv = encrypt.IV.fromBase64(storedIv);
    } else {
      // 2. Si c'est la première fois, on génère une clé et un IV aléatoires
      final randomKey = encrypt.Key.fromSecureRandom(32); // 32 bytes = 256 bits
      final randomIv = encrypt.IV.fromSecureRandom(16);   // 16 bytes = 128 bits

      // On les stocke dans le stockage sécurisé
      await _storage.write(key: _keyStorageKey, value: randomKey.base64);
      await _storage.write(key: _ivStorageKey, value: randomIv.base64);

      _key = randomKey;
      _iv = randomIv;
    }
  }

  // ==========================================
  // CHIFFRER UN TEXTE
  // ==========================================
  Future<String> encryptText(String plainText) async {
    await _initKeys();
    
    // Si le texte est vide, on retourne vide
    if (plainText.isEmpty) return '';

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc)
    );
    
    return encrypter.encrypt(plainText, iv: _iv!).base64;
  }

  // ==========================================
  // DÉCHIFFRER UN TEXTE
  // ==========================================
  Future<String> decryptText(String encryptedText) async {
    await _initKeys();

    // Si le texte est vide, on retourne vide
    if (encryptedText.isEmpty) return '';

    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key!, mode: encrypt.AESMode.cbc)
      );
      
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return encrypter.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      // Si le déchiffrement échoue (ex: données corrompues), on retourne une chaîne vide
      return '';
    }
  }

  // ==========================================
  // UTILITAIRES POUR LES MONTANTS (double)
  // ==========================================
  Future<String> encryptAmount(double amount) async {
    // On convertit le montant en String pour le chiffrer
    return await encryptText(amount.toString());
  }

  Future<double> decryptAmount(String encryptedAmount) async {
    final decryptedStr = await decryptText(encryptedAmount);
    // On tente de reconvertir en double
    try {
      return double.parse(decryptedStr);
    } catch (e) {
      return 0.0; // Valeur par défaut si erreur
    }
  }
}