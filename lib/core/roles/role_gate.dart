import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/core/roles/role.dart';

/// Simple role-based visibility gate. Wrap UI that should only be visible
/// to certain roles (e.g., Role.admin).
class RoleGate extends StatelessWidget {
  final List<Role> allow;
  final Widget child;
  final Widget? fallback;
  final bool maintainSpace; // if true, shows fallback or SizedBox.shrink

  const RoleGate({
    super.key,
    required this.allow,
    required this.child,
    this.fallback,
    this.maintainSpace = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: true);
    final role = RoleX.fromString(auth.role);
    final permitted = allow.contains(role);
    if (permitted) return child;
    if (fallback != null) return fallback!;
    return maintainSpace ? const SizedBox.shrink() : const SizedBox.shrink();
  }
}
