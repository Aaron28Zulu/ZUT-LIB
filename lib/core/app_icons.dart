import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every icon the app shows, named by meaning rather than by glyph.
///
/// Screens use these instead of `Icons.*` so the icon set can change in one
/// place (docs/DESIGN_CONVENTIONS.md, "Icons"). Lucide is a thin-stroke set
/// that matches the flat look; there is no filled/outlined pair, so selected
/// navigation items are marked by the indicator and label weight instead.
abstract final class AppIcons {
  // Navigation
  static const IconData home = LucideIcons.house;
  static const IconData search = LucideIcons.search;
  static const IconData study = LucideIcons.graduationCap;
  static const IconData loans = LucideIcons.clipboardList;
  static const IconData profile = LucideIcons.userRound;
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData scan = LucideIcons.scanQrCode;
  static const IconData institution = LucideIcons.building2;
  static const IconData addInstitution = LucideIcons.building;
  static const IconData demoControls = LucideIcons.slidersHorizontal;
  static const IconData library = LucideIcons.libraryBig;

  // Content
  static const IconData paper = LucideIcons.bookOpenText;
  static const IconData pdf = LucideIcons.fileText;
  static const IconData course = LucideIcons.notebookTabs;
  static const IconData courses = LucideIcons.listTree;
  static const IconData quiz = LucideIcons.listChecks;
  static const IconData flashcards = LucideIcons.layers;
  static const IconData plan = LucideIcons.calendarDays;
  static const IconData event = LucideIcons.calendar;
  static const IconData progress = LucideIcons.chartLine;
  static const IconData assistant = LucideIcons.circleHelp;
  static const IconData feedback = LucideIcons.messageSquareText;
  static const IconData chat = LucideIcons.messageCircle;
  static const IconData copies = LucideIcons.package;
  static const IconData qr = LucideIcons.qrCode;
  static const IconData history = LucideIcons.history;
  static const IconData time = LucideIcons.clock;
  static const IconData target = LucideIcons.target;

  // People and access
  static const IconData users = LucideIcons.users;
  static const IconData userSearch = LucideIcons.userSearch;
  static const IconData userAdd = LucideIcons.userPlus;
  static const IconData roleReview = LucideIcons.shieldCheck;
  static const IconData admin = LucideIcons.shieldUser;
  static const IconData signIn = LucideIcons.logIn;
  static const IconData signOut = LucideIcons.logOut;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.fileUp;
  static const IconData attach = LucideIcons.paperclip;
  static const IconData filter = LucideIcons.slidersHorizontal;
  static const IconData sort = LucideIcons.arrowDownUp;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData reset = LucideIcons.rotateCcw;
  static const IconData settings = LucideIcons.settings;
  static const IconData bookmark = LucideIcons.bookmark;
  static const IconData bookmarked = LucideIcons.bookmarkCheck;
  static const IconData show = LucideIcons.eye;
  static const IconData hide = LucideIcons.eyeOff;
  static const IconData next = LucideIcons.chevronRight;
  static const IconData previous = LucideIcons.chevronLeft;
  static const IconData forward = LucideIcons.arrowRight;

  // Status
  static const IconData notifications = LucideIcons.bell;
  static const IconData done = LucideIcons.circleCheck;
  static const IconData cancelled = LucideIcons.circleX;
  static const IconData warning = LucideIcons.circleAlert;
  static const IconData info = LucideIcons.info;
  static const IconData noResults = LucideIcons.searchX;
  static const IconData pending = LucideIcons.clock;
}
