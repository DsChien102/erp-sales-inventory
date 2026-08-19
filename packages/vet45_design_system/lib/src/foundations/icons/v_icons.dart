import 'package:flutter/widgets.dart';

/// Danh sách icon semantic được Design System công khai
enum VIcons {
  // Navigation & Directional Icons (Định nghĩa hướng rõ ràng cho RTL)
  arrowLeft,
  arrowRight,
  chevronLeft,
  chevronRight,
  chevronDown,
  chevronUp,
  chevronRightRounded,
  chevronLeftRounded,
  arrowBack,
  arrowForward,
  arrowForwardRounded,
  expandLess,
  expandMore,
  expandLessRounded,
  arrowDropUp,
  arrowDropDown,

  // Action & Common Icons
  search,
  add,
  addCircle,
  close,
  delete,
  edit,
  refresh,
  moreVert,
  moreHoriz,
  tune,
  swapVert,
  download,
  power,
  powerOff,
  unplug,
  check,
  logout,
  visibility,
  visibilityOff,

  // Status & Feedback
  warning,
  error,
  success,
  info,
  shield,
  cloud,
  cloudOff,
  cloudUpload,
  fileUp,
  fileSpreadsheet,

  // Domain & Business Specific Icons
  calendar,
  phone,
  location,
  people,
  group,
  home,
  receipt,
  inventory,
  store,
  notification,
  apartment,
  person,
  personAdd,
  personCheck,
  personRemove,
  description,
  gridView,
  stickyNote,
  accountBalanceWallet,
  warehouse,
  straighten,
  chart,
  image,
  camera,
  clipboard,
  history,
  inbox,
  ban,
  play,
  restore,
  tag,
  coins,
  gripVertical,
  trendingUp,
  trendingDown,
  listView,
  checkList,
  circle,
  lock,
  key,
  settings,
  star,
  mail,
  truck,
  creditCard,
  briefcase,
  pause,
  contact,
  bolt,
  qrCode,
  printer,
  share2,
  fileCheck,
  receiptText,
  send,
  minus,
  banknoteArrowDown,
  badgePercent,
  scanLine,
  clock,
  clipboardClock,
  rotateCcwKey,
  fileXCorner,
  pencil,
  save,
}

/// Lucide font glyphs used by [VIcons].
///
/// Defined locally (instead of importing `LucideIcons`) so Flutter web/DDC does
/// not initialize the ~125k-line generated `lucide_icons.dart` and hit
/// [StackOverflowError] on first icon access. Font assets still come from the
/// `lucide_icons_flutter` package dependency.
abstract final class _Lucide {
  static const arrowLeft = IconData(
    57416,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const arrowRight = IconData(
    57417,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const chevronLeft = IconData(
    57454,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const chevronRight = IconData(
    57455,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const chevronDown = IconData(
    57453,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const chevronUp = IconData(
    57456,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const search = IconData(
    57681,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const plus = IconData(
    57661,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const plusCircle = IconData(
    57473,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const x = IconData(
    57778,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const trash2 = IconData(
    57742,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const edit3 = IconData(
    57648,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const refreshCw = IconData(
    57669,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const moreVertical = IconData(
    57527,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const moreHorizontal = IconData(
    57526,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const slidersHorizontal = IconData(
    58010,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const arrowUpDown = IconData(
    58237,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const download = IconData(
    57522,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const power = IconData(
    57664,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const powerOff = IconData(
    57865,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const unplug = IconData(
    58461,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const check = IconData(
    57452,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const logOut = IconData(
    57614,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const eye = IconData(
    57530,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const eyeOff = IconData(
    57531,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const alertTriangle = IconData(
    57747,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const circleX = IconData(
    57476,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const checkCircle2 = IconData(
    57894,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const info = IconData(
    57593,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const shield = IconData(
    57688,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const cloud = IconData(
    57480,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const cloudOff = IconData(
    57485,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const cloudUpload = IconData(
    57489,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const fileUp = IconData(
    58154,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const fileSpreadsheet = IconData(
    58150,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const calendar = IconData(
    57443,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const phone = IconData(
    57651,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const mapPin = IconData(
    57617,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const users = IconData(
    57764,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const home = IconData(
    57589,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const receipt = IconData(
    58323,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const box = IconData(
    57441,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const store = IconData(
    58340,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const bell = IconData(
    57433,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const building2 = IconData(
    58000,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const user = IconData(
    57759,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const userPlus = IconData(
    57762,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const userCheck = IconData(
    57760,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const userX = IconData(
    57763,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const fileText = IconData(
    57548,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const grid = IconData(
    57577,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const stickyNote = IconData(
    58115,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const wallet = IconData(
    57860,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const warehouse = IconData(
    58342,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const ruler = IconData(
    57675,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const lineChart = IconData(
    58021,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const image = IconData(
    57590,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const camera = IconData(
    57444,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const clipboardList = IconData(
    57478,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const history = IconData(
    57845,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const inbox = IconData(
    57591,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const ban = IconData(
    57425,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const play = IconData(
    57660,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const rotateCcw = IconData(
    57672,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const tag = IconData(
    57727,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const coins = IconData(
    57495,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const gripVertical = IconData(
    57579,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const trendingUp = IconData(
    57745,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const trendingDown = IconData(
    57744,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const list = IconData(
    57606,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const listChecks = IconData(
    57808,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const circle = IconData(
    57462,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const lock = IconData(
    57611,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const key = IconData(
    57597,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const settings = IconData(
    57684,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const star = IconData(
    57718,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const mail = IconData(
    57615,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const truck = IconData(
    57748,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const creditCard = IconData(
    57514,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const briefcase = IconData(
    57442,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const pause = IconData(
    57646,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const contact = IconData(
    57500,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const zap = IconData(
    57780,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const qrCode = IconData(
    57823,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const printer = IconData(
    57665,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const share2 = IconData(
    57686,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const fileCheck = IconData(
    57537,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const receiptText = IconData(
    58796,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const send = IconData(
    57682,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const minus = IconData(
    57620,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const banknoteArrowDown = IconData(
    58956,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const badgePercent = IconData(
    58489,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const scanLine = IconData(
    57944,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const clock = IconData(
    57479,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const clipboardClock = IconData(
    59016,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const fileX = IconData(
    57549,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const pencil = IconData(
    57849,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
  static const save = IconData(
    57677,
    fontFamily: 'Lucide',
    fontPackage: 'lucide_icons_flutter',
  );
}

/// Extension helper để ánh xạ từ [VIcons] sang [IconData] của Lucide Icons
extension VIconsExtension on VIcons {
  IconData get value {
    switch (this) {
      // Navigation & Directional Icons
      case VIcons.arrowLeft:
      case VIcons.arrowBack:
        return _Lucide.arrowLeft;
      case VIcons.arrowRight:
      case VIcons.arrowForward:
      case VIcons.arrowForwardRounded:
        return _Lucide.arrowRight;
      case VIcons.chevronLeft:
      case VIcons.chevronLeftRounded:
        return _Lucide.chevronLeft;
      case VIcons.chevronRight:
      case VIcons.chevronRightRounded:
        return _Lucide.chevronRight;
      case VIcons.chevronDown:
      case VIcons.expandMore:
      case VIcons.arrowDropDown:
        return _Lucide.chevronDown;
      case VIcons.chevronUp:
      case VIcons.expandLess:
      case VIcons.expandLessRounded:
      case VIcons.arrowDropUp:
        return _Lucide.chevronUp;

      // Action & Common Icons
      case VIcons.search:
        return _Lucide.search;
      case VIcons.add:
        return _Lucide.plus;
      case VIcons.addCircle:
        return _Lucide.plusCircle;
      case VIcons.close:
        return _Lucide.x;
      case VIcons.delete:
        return _Lucide.trash2;
      case VIcons.edit:
        return _Lucide.edit3;
      case VIcons.refresh:
        return _Lucide.refreshCw;
      case VIcons.moreVert:
        return _Lucide.moreVertical;
      case VIcons.moreHoriz:
        return _Lucide.moreHorizontal;
      case VIcons.tune:
        return _Lucide.slidersHorizontal;
      case VIcons.swapVert:
        return _Lucide.arrowUpDown;
      case VIcons.download:
        return _Lucide.download;
      case VIcons.power:
        return _Lucide.power;
      case VIcons.powerOff:
        return _Lucide.powerOff;
      case VIcons.unplug:
        return _Lucide.unplug;
      case VIcons.check:
        return _Lucide.check;
      case VIcons.logout:
        return _Lucide.logOut;
      case VIcons.visibility:
        return _Lucide.eye;
      case VIcons.visibilityOff:
        return _Lucide.eyeOff;

      // Status & Feedback
      case VIcons.warning:
        return _Lucide.alertTriangle;
      case VIcons.error:
        return _Lucide.circleX;
      case VIcons.success:
        return _Lucide.checkCircle2;
      case VIcons.info:
        return _Lucide.info;
      case VIcons.shield:
        return _Lucide.shield;
      case VIcons.cloud:
        return _Lucide.cloud;
      case VIcons.cloudOff:
        return _Lucide.cloudOff;
      case VIcons.cloudUpload:
        return _Lucide.cloudUpload;
      case VIcons.fileUp:
        return _Lucide.fileUp;
      case VIcons.fileSpreadsheet:
        return _Lucide.fileSpreadsheet;

      // Domain & Business Specific Icons
      case VIcons.calendar:
        return _Lucide.calendar;
      case VIcons.phone:
        return _Lucide.phone;
      case VIcons.location:
        return _Lucide.mapPin;
      case VIcons.people:
      case VIcons.group:
        return _Lucide.users;
      case VIcons.home:
        return _Lucide.home;
      case VIcons.receipt:
        return _Lucide.receipt;
      case VIcons.inventory:
        return _Lucide.box;
      case VIcons.store:
        return _Lucide.store;
      case VIcons.notification:
        return _Lucide.bell;
      case VIcons.apartment:
        return _Lucide.building2;
      case VIcons.person:
        return _Lucide.user;
      case VIcons.personAdd:
        return _Lucide.userPlus;
      case VIcons.personCheck:
        return _Lucide.userCheck;
      case VIcons.personRemove:
        return _Lucide.userX;
      case VIcons.description:
        return _Lucide.fileText;
      case VIcons.gridView:
        return _Lucide.grid;
      case VIcons.stickyNote:
        return _Lucide.stickyNote;
      case VIcons.accountBalanceWallet:
        return _Lucide.wallet;
      case VIcons.warehouse:
        return _Lucide.warehouse;
      case VIcons.straighten:
        return _Lucide.ruler;
      case VIcons.chart:
        return _Lucide.lineChart;
      case VIcons.image:
        return _Lucide.image;
      case VIcons.camera:
        return _Lucide.camera;
      case VIcons.clipboard:
        return _Lucide.clipboardList;
      case VIcons.history:
        return _Lucide.history;
      case VIcons.inbox:
        return _Lucide.inbox;
      case VIcons.ban:
        return _Lucide.ban;
      case VIcons.play:
        return _Lucide.play;
      case VIcons.restore:
        return _Lucide.rotateCcw;
      case VIcons.tag:
        return _Lucide.tag;
      case VIcons.coins:
        return _Lucide.coins;
      case VIcons.gripVertical:
        return _Lucide.gripVertical;
      case VIcons.trendingUp:
        return _Lucide.trendingUp;
      case VIcons.trendingDown:
        return _Lucide.trendingDown;
      case VIcons.listView:
        return _Lucide.list;
      case VIcons.checkList:
        return _Lucide.listChecks;
      case VIcons.circle:
        return _Lucide.circle;
      case VIcons.lock:
        return _Lucide.lock;
      case VIcons.key:
        return _Lucide.key;
      case VIcons.settings:
        return _Lucide.settings;
      case VIcons.star:
        return _Lucide.star;
      case VIcons.mail:
        return _Lucide.mail;
      case VIcons.truck:
        return _Lucide.truck;
      case VIcons.creditCard:
        return _Lucide.creditCard;
      case VIcons.briefcase:
        return _Lucide.briefcase;
      case VIcons.pause:
        return _Lucide.pause;
      case VIcons.contact:
        return _Lucide.contact;
      case VIcons.bolt:
        return _Lucide.zap;
      case VIcons.qrCode:
        return _Lucide.qrCode;
      case VIcons.printer:
        return _Lucide.printer;
      case VIcons.share2:
        return _Lucide.share2;
      case VIcons.fileCheck:
        return _Lucide.fileCheck;
      case VIcons.receiptText:
        return _Lucide.receiptText;
      case VIcons.send:
        return _Lucide.send;
      case VIcons.minus:
        return _Lucide.minus;
      case VIcons.banknoteArrowDown:
        return _Lucide.banknoteArrowDown;
      case VIcons.badgePercent:
        return _Lucide.badgePercent;
      case VIcons.scanLine:
        return _Lucide.scanLine;
      case VIcons.clock:
        return _Lucide.clock;
      case VIcons.clipboardClock:
        return _Lucide.clipboardClock;
      case VIcons.rotateCcwKey:
        return _Lucide.rotateCcw;
      case VIcons.fileXCorner:
        return _Lucide.fileX;
      case VIcons.pencil:
        return _Lucide.pencil;
      case VIcons.save:
        return _Lucide.save;
    }
  }
}
