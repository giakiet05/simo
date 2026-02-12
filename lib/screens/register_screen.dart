import 'package:flutter/material.dart';
import '../utils/supabase.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'simo://auth-callback/',
      );

      if (mounted) {
        // Check if email confirmation is required
        final user = response.user;
        if (user != null && user.confirmedAt == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!\n\nVui lòng kiểm tra email để xác nhận tài khoản trước khi đăng nhập.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Bạn có thể đăng nhập ngay.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Đăng ký thất bại';

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('user already registered') ||
            errorStr.contains('already registered')) {
          errorMessage = 'Email này đã được đăng ký.\nVui lòng sử dụng email khác hoặc đăng nhập.';
        } else if (errorStr.contains('password') &&
                   errorStr.contains('weak')) {
          errorMessage = 'Mật khẩu quá yếu.\nVui lòng sử dụng mật khẩu mạnh hơn.';
        } else if (errorStr.contains('network') ||
                   errorStr.contains('fetch')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
        } else if (errorStr.contains('database')) {
          errorMessage = 'Lỗi hệ thống.\nVui lòng thử lại sau.';
        } else {
          errorMessage = 'Đăng ký thất bại: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng ký để đồng bộ dữ liệu trên nhiều thiết bị',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    helperText: 'Tối thiểu 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt',
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Mật khẩu phải có ít nhất 1 chữ thường';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Mật khẩu phải có ít nhất 1 chữ số';
                    }
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Đăng ký',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
