/// Audit action types recorded in partner_action_logs.
enum PartnerActionType {
  create,
  update,
  addContact,
  removeContact,
  transform,
  deactivate,
  reactivate,
  delete;

  /// Parses wire values (`add_contact`) or Dart names (`addContact`).
  static PartnerActionType parse(String raw) {
    return switch (raw) {
      'create' => PartnerActionType.create,
      'update' => PartnerActionType.update,
      'add_contact' || 'addContact' => PartnerActionType.addContact,
      'remove_contact' || 'removeContact' => PartnerActionType.removeContact,
      'transform' => PartnerActionType.transform,
      'deactivate' => PartnerActionType.deactivate,
      'reactivate' => PartnerActionType.reactivate,
      'delete' => PartnerActionType.delete,
      _ => throw ArgumentError.value(raw, 'raw', 'Unknown partner action type'),
    };
  }
}
