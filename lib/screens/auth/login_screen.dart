import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _staffIdController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedRole = 'staff'; // Default to staff
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (_selectedRole == 'manager') {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _errorMessage = "Please enter email and password");
        return;
      }
    } else {
      if (_staffIdController.text.isEmpty) {
        setState(() => _errorMessage = "Please enter your Staff Access ID");
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      if (_selectedRole == 'manager') {
        await authProv.signInWithEmail(_emailController.text, _passwordController.text);
        context.go('/manager');
      } else {
        await authProv.signInWithStaffId(_staffIdController.text);
        context.go('/staff');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            children: [
              // TOP SECTION
              Container(
                color: AppTheme.cfNavy,
                padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: AppTheme.cfRed, borderRadius: BorderRadius.circular(10)),
                          child: const Center(child: Icon(Icons.warning_rounded, color: Colors.white, size: 20)),
                        ),
                        const SizedBox(width: 12),
                        const Text("CrisisFlow", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text("Welcome back", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Sign in to access your role dashboard", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),

              // BODY SECTION
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.cfRed, fontSize: 13)),
                      ),

                    const Text("Select your division", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.cfNavy)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleCard(
                            id: 'staff',
                            title: 'Staff Duty',
                            sub: 'Requires Access ID',
                            icon: Icons.person_outline,
                            selectedColor: AppTheme.cfGreen,
                            selectedBg: const Color(0xFFF0FDF7),
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildRoleCard(
                            id: 'manager',
                            title: 'Manager',
                            sub: 'Requires Email & Pwd',
                            icon: Icons.dashboard_outlined,
                            selectedColor: AppTheme.cfNavy,
                            selectedBg: const Color(0xFFF1F5F9),
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_selectedRole == 'manager') ...[
                      const Text("Email address", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.cfNavy)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: "manager@venue.com"),
                      ),
                      const SizedBox(height: 16),
  
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.cfNavy)),
                           TextButton(
                             onPressed: () {},
                             style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                             child: const Text("Forgot?", style: TextStyle(fontSize: 12, color: AppTheme.cfMuted)),
                           ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.cfMuted),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const Text("Staff Access ID", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.cfNavy)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _staffIdController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Enter your 8-character ID",
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.cfMuted),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text("If you don't have an ID, contact your Manager to authorize you.", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                      const SizedBox(height: 24),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cfNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Sign in", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: AppTheme.cfBorder)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: AppTheme.cfMuted, fontSize: 11))),
                        Expanded(child: Container(height: 1, color: AppTheme.cfBorder)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go('/report'),
                        style: OutlinedButton.styleFrom(
                           side: const BorderSide(color: AppTheme.cfBorder),
                           foregroundColor: AppTheme.cfMuted,
                        ),
                        child: const Text("Report an emergency as guest", style: TextStyle(color: AppTheme.cfMuted)),
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String id, required String title, required String sub, required IconData icon, required Color selectedColor, required Color selectedBg}) {
    final bool isSelected = _selectedRole == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.white,
          border: Border.all(color: isSelected ? selectedColor : AppTheme.cfBorder, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: isSelected ? selectedColor : AppTheme.cfMuted),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? selectedColor : AppTheme.cfNavy)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.cfDim)),
          ],
        ),
      ),
    );
  }
}
