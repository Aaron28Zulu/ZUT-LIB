import '../models/enums.dart';

/// Actions from the permissions matrix (SRS section 4).
enum Permission {
  viewResources,
  manageResources,
  borrow,
  processLoans,
  useStudyAssistant,
  manageStudyContent,
  manageUsers,
  viewTenantReports,

  /// Librarians see the loans and resources part of the tenant dashboard only.
  viewLibraryReports,
  manageTenants,
  demoControls,
  sendFeedback,
  viewFeedback,
}

const Map<Role, Set<Permission>> permissionMatrix = {
  Role.student: {
    Permission.viewResources,
    Permission.borrow,
    Permission.useStudyAssistant,
    Permission.sendFeedback,
  },
  Role.librarian: {
    Permission.viewResources,
    Permission.manageResources,
    Permission.processLoans,
    Permission.manageStudyContent,
    Permission.viewLibraryReports,
  },
  Role.institutionAdmin: {
    Permission.viewResources,
    Permission.manageResources,
    Permission.processLoans,
    Permission.manageStudyContent,
    Permission.manageUsers,
    Permission.viewTenantReports,
    Permission.viewLibraryReports,
    Permission.viewFeedback,
  },
  Role.platformAdmin: {
    Permission.manageTenants,
    Permission.demoControls,
  },
};

bool roleAllows(Role role, Permission p) =>
    permissionMatrix[role]?.contains(p) ?? false;
