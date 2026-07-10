/// Partner-owned permission codes for RBAC metadata, manifests, and seeds.
abstract final class PartnerPermissions {
  static const view = 'partner.view';
  static const detailView = 'partner.detail.view';
  static const create = 'partner.create';
  static const update = 'partner.update';
  static const contactManage = 'partner.contact.manage';
  static const transform = 'partner.transform';
  static const statusManage = 'partner.status.manage';
  static const delete = 'partner.delete';
  static const historyView = 'partner.history.view';
}
