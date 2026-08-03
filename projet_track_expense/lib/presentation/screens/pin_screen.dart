import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/core/utils/pin_helper.dart';
import 'package:projet_track_expense/core/utils/biometric_helper.dart';
import 'package:projet_track_expense/presentation/screens/dashboard_screen.dart';

class PinScreen extends ConsumerStatefulWidget {
  final bool isCreating;

  const PinScreen({super.key, required this.isCreating});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final PinHelper _pinHelper = PinHelper();
  final BiometricHelper _biometricHelper = BiometricHelper();

  // Variables pour le processus de création
  bool _isConfirming = false;
  String? _firstPin;

  // Variables pour le clavier
  final List<int> _enteredDigits = [];
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
    _checkBiometrics();
  }

  Future<void> _checkLockoutStatus() async {
    if (await _pinHelper.isLockedOut()) {
      final remaining = await _pinHelper.getLockoutTimeRemaining();
      setState(() {
        _isLockedOut = true;
        _lockoutSeconds = remaining;
      });
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_lockoutSeconds > 0 && mounted) {
        setState(() {
          _lockoutSeconds--;
        });
        _startLockoutTimer();
      } else if (mounted) {
        setState(() {
          _isLockedOut = false;
        });
      }
    });
  }

  Future<void> _checkBiometrics() async {
    final supported = await _biometricHelper.isBiometricSupported();
    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
      });
    }
  }

  void _onDigitPressed(int digit) {
    if (_isLockedOut) return;
    if (_enteredDigits.length >= 4) return;

    setState(() {
      _enteredDigits.add(digit);
    });

    if (_enteredDigits.length == 4) {
      _submitPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _enteredDigits.removeLast();
      });
    }
  }

  Future<void> _submitPin() async {
    final pin = _enteredDigits.map((e) => e.toString()).join();

    if (widget.isCreating) {
      // Mode CRÉATION
      if (!_isConfirming) {
        // Première saisie
        setState(() {
          _firstPin = pin;
          _isConfirming = true;
          _enteredDigits.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmez votre code PIN'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // Deuxième saisie (Confirmation)
        if (_firstPin == pin) {
          await _pinHelper.savePin(pin);
          _navigateToDashboard();
        } else {
          // Les PINs ne correspondent pas
          setState(() {
            _isConfirming = false;
            _firstPin = null;
            _enteredDigits.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les codes PIN ne correspondent pas. Réessayez.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Mode CONNEXION
      final isValid = await _pinHelper.verifyPin(pin);
      if (isValid) {
        _navigateToDashboard();
      } else {
        final attempts = await _pinHelper.getRemainingAttempts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PIN incorrect. Tentatives restantes : $attempts'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _enteredDigits.clear();
          });
          if (await _pinHelper.isLockedOut()) {
            await _checkLockoutStatus();
          }
        }
      }
    }
  }

  Future<void> _handleBiometrics() async {
    final success = await _biometricHelper.authenticateWithDefaultMessage();
    if (success) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildDot(int index) {
    final isFilled = index < _enteredDigits.length;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
      ),
    );
  }

  String _getInstructionText() {
    if (_isLockedOut) return '';
    if (widget.isCreating) {
      return _isConfirming ? 'Confirmez votre code PIN' : 'Créez votre code PIN (4 chiffres)';
    }
    return 'Entrez votre code PIN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _getInstructionText(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isLockedOut) ...[
                    const SizedBox(height: 12),
                    Text(
                      'App verrouillée. Réessayez dans $_lockoutSeconds secondes',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => _buildDot(index)),
                  ),
                ],
              ),
            ),
            
            if (!_isLockedOut) ...[
              _buildNumPad(),
              const SizedBox(height: 8),
              if (_isBiometricSupported && !widget.isCreating)
                IconButton(
                  icon: const Icon(Icons.fingerprint, size: 40),
                  onPressed: _handleBiometrics,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNumPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int j = 1; j <= 3; j++)
                    _buildNumKey(i * 3 + j),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const SizedBox(width: 60),
                _buildNumKey(0),
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: _onDeletePressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumKey(int number) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextButton(
        onPressed: () => _onDigitPressed(number),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}