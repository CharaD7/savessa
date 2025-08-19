enum Role { admin, member }

extension RoleX on Role {
  static Role fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'admin':
      case 'manager':
      case 'savings_manager':
        return Role.admin;
      case 'member':
      case 'contributor':
      case 'savings_contributor':
      case 'user':
      default:
        return Role.member;
    }
  }

  static String normalizeLabel(String? value) {
    final r = fromString(value);
    return r == Role.admin ? 'admin' : 'member';
  }
}
