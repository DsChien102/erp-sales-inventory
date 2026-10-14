class ReceiptActor {
  const ReceiptActor({required this.id, required this.name});
  final String id;
  final String name;
}

typedef ReceiptActorLoader = Future<ReceiptActor> Function();
