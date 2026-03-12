// lib/features/auth/screens/forgot_password_screen.dart
//
// NEW SCREEN — 3-step password reset flow:
//   Step 1: Enter email → POST /api/auth/forgot-password
//   Step 2: Enter 6-digit OTP (sent to email)
//   Step 3: Enter new password → POST /api/auth/reset-password

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/core/constants/app_colors.dart';
import 'package:slot_wise_booking/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiService();

  // Step tracking: 1 = email, 2 = OTP, 3 = new password
  int _step = 1;

  final _emailCtrl    = TextEditingController();
  final _otpCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _obscure      = true;
  bool  _obscureConf  = true;
  bool  _isLoading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Request OTP ──────────────────────────────────
  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await _api.post('/auth/forgot-password', {'email': email});
      // Always advance regardless of whether email exists (prevents enumeration)
      setState(() => _step = 2);
    } catch (e) {
      setState(() => _error = 'Could not send OTP. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Step 2: Validate OTP and advance ────────────────────
  void _validateOtp() {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Please enter the 6-digit OTP from your email');
      return;
    }
    setState(() { _step = 3; _error = null; });
  }

  // ── Step 3: Reset password ───────────────────────────────
  Future<void> _resetPassword() async {
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await _api.post('/auth/reset-password', {
        'email':       _emailCtrl.text.trim(),
        'otp':         _otpCtrl.text.trim(),
        'newPassword': pass,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset! You can now log in.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // Back to login
    } catch (e) {
      // Backend returns 400 with message for bad/expired OTP
      setState(() => _error = 'Invalid or expired OTP. Please start over.');
      // Reset to step 1 so they can request a new OTP
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _step = 1; _error = null; });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              _StepIndicator(currentStep: _step),
              const SizedBox(height: 32),

              // Step content
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Enter your email address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text("We'll send a 6-digit OTP to reset your password.",
          style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _isLoading ? null : _requestOtp,
        child: _isLoading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Send OTP', style: TextStyle(fontSize: 16)),
      ),
    ],
  );

  Widget _buildStep2() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Enter your OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Check your email (${_emailCtrl.text}) for a 6-digit OTP. It expires in 10 minutes.',
          style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          labelText: 'OTP Code',
          border: OutlineInputBorder(),
          counterText: '',
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _validateOtp,
        child: const Text('Verify OTP', style: TextStyle(fontSize: 16)),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() { _step = 1; _error = null; }),
        child: const Text("Didn't get it? Resend OTP"),
      ),
    ],
  );

  Widget _buildStep3() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Set new password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Choose a strong password of at least 6 characters.',
          style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _passCtrl,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'New Password',
          prefixIcon: const Icon(Icons.lock_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      TextFormField(
        controller: _confirmCtrl,
        obscureText: _obscureConf,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          prefixIcon: const Icon(Icons.lock_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscureConf ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureConf = !_obscureConf),
          ),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        child: _isLoading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Reset Password', style: TextStyle(fontSize: 16)),
      ),
    ],
  );
}

// ── Step indicator widget ─────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final step      = i + 1;
        final isActive  = step == currentStep;
        final isDone    = step < currentStep;
        final color     = isDone || isActive ? AppColors.primary : Colors.grey[300]!;
        final textColor = isDone || isActive ? Colors.white : Colors.grey;

        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('$step',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: step < currentStep ? AppColors.primary : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}