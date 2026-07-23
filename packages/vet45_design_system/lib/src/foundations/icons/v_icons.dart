import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  settings,
  star,
  mail,
  truck,
  creditCard,
  briefcase,
  pause,
  contact,
  bolt,
}

/// Extension helper để ánh xạ từ [VIcons] sang [IconData] của Lucide Icons
extension VIconsExtension on VIcons {
  IconData get value {
    switch (this) {
      // Navigation & Directional Icons
      case VIcons.arrowLeft:
      case VIcons.arrowBack:
        return LucideIcons.arrowLeft;
      case VIcons.arrowRight:
      case VIcons.arrowForward:
      case VIcons.arrowForwardRounded:
        return LucideIcons.arrowRight;
      case VIcons.chevronLeft:
      case VIcons.chevronLeftRounded:
        return LucideIcons.chevronLeft;
      case VIcons.chevronRight:
      case VIcons.chevronRightRounded:
        return LucideIcons.chevronRight;
      case VIcons.chevronDown:
      case VIcons.expandMore:
      case VIcons.arrowDropDown:
        return LucideIcons.chevronDown;
      case VIcons.chevronUp:
      case VIcons.expandLess:
      case VIcons.expandLessRounded:
      case VIcons.arrowDropUp:
        return LucideIcons.chevronUp;

      // Action & Common Icons
      case VIcons.search:
        return LucideIcons.search;
      case VIcons.add:
        return LucideIcons.plus;
      case VIcons.addCircle:
        return LucideIcons.plusCircle;
      case VIcons.close:
        return LucideIcons.x;
      case VIcons.delete:
        return LucideIcons.trash2;
      case VIcons.edit:
        return LucideIcons.edit3;
      case VIcons.refresh:
        return LucideIcons.refreshCw;
      case VIcons.moreVert:
        return LucideIcons.moreVertical;
      case VIcons.moreHoriz:
        return LucideIcons.moreHorizontal;
      case VIcons.tune:
        return LucideIcons.slidersHorizontal;
      case VIcons.swapVert:
        return LucideIcons.arrowUpDown;
      case VIcons.download:
        return LucideIcons.download;
      case VIcons.power:
        return LucideIcons.power;
      case VIcons.powerOff:
        return LucideIcons.powerOff;
      case VIcons.check:
        return LucideIcons.check;
      case VIcons.logout:
        return LucideIcons.logOut;
      case VIcons.visibility:
        return LucideIcons.eye;
      case VIcons.visibilityOff:
        return LucideIcons.eyeOff;

      // Status & Feedback
      case VIcons.warning:
        return LucideIcons.alertTriangle;
      case VIcons.error:
        return LucideIcons.alertCircle;
      case VIcons.success:
        return LucideIcons.checkCircle2;
      case VIcons.info:
        return LucideIcons.info;
      case VIcons.shield:
        return LucideIcons.shield;
      case VIcons.cloud:
        return LucideIcons.cloud;
      case VIcons.cloudOff:
        return LucideIcons.cloudOff;
      case VIcons.cloudUpload:
        return LucideIcons.cloudUpload;
      case VIcons.fileUp:
        return LucideIcons.fileUp;
      case VIcons.fileSpreadsheet:
        return LucideIcons.fileSpreadsheet;

      // Domain & Business Specific Icons
      case VIcons.calendar:
        return LucideIcons.calendar;
      case VIcons.phone:
        return LucideIcons.phone;
      case VIcons.location:
        return LucideIcons.mapPin;
      case VIcons.people:
      case VIcons.group:
        return LucideIcons.users;
      case VIcons.home:
        return LucideIcons.home;
      case VIcons.receipt:
        return LucideIcons.receipt;
      case VIcons.inventory:
        return LucideIcons.box;
      case VIcons.store:
        return LucideIcons.store;
      case VIcons.notification:
        return LucideIcons.bell;
      case VIcons.apartment:
        return LucideIcons.building2;
      case VIcons.person:
        return LucideIcons.user;
      case VIcons.personAdd:
        return LucideIcons.userPlus;
      case VIcons.description:
        return LucideIcons.fileText;
      case VIcons.gridView:
        return LucideIcons.grid;
      case VIcons.stickyNote:
        return LucideIcons.stickyNote;
      case VIcons.accountBalanceWallet:
        return LucideIcons.wallet;
      case VIcons.warehouse:
        return LucideIcons.warehouse;
      case VIcons.straighten:
        return LucideIcons.ruler;
      case VIcons.chart:
        return LucideIcons.lineChart;
      case VIcons.image:
        return LucideIcons.image;
      case VIcons.camera:
        return LucideIcons.camera;
      case VIcons.clipboard:
        return LucideIcons.clipboardList;
      case VIcons.history:
        return LucideIcons.history;
      case VIcons.inbox:
        return LucideIcons.inbox;
      case VIcons.ban:
        return LucideIcons.ban;
      case VIcons.play:
        return LucideIcons.play;
      case VIcons.restore:
        return LucideIcons.rotateCcw;
      case VIcons.tag:
        return LucideIcons.tag;
      case VIcons.coins:
        return LucideIcons.coins;
      case VIcons.gripVertical:
        return LucideIcons.gripVertical;
      case VIcons.trendingUp:
        return LucideIcons.trendingUp;
      case VIcons.trendingDown:
        return LucideIcons.trendingDown;
      case VIcons.listView:
        return LucideIcons.list;
      case VIcons.checkList:
        return LucideIcons.listChecks;
      case VIcons.circle:
        return LucideIcons.circle;
      case VIcons.lock:
        return LucideIcons.lock;
      case VIcons.settings:
        return LucideIcons.settings;
      case VIcons.star:
        return LucideIcons.star;
      case VIcons.mail:
        return LucideIcons.mail;
      case VIcons.truck:
        return LucideIcons.truck;
      case VIcons.creditCard:
        return LucideIcons.creditCard;
      case VIcons.briefcase:
        return LucideIcons.briefcase;
      case VIcons.pause:
        return LucideIcons.pause;
      case VIcons.contact:
        return LucideIcons.contact;
      case VIcons.bolt:
        return LucideIcons.zap;
    }
  }
}
