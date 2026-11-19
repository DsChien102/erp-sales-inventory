import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'i_command.dart';

abstract class CommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;

  @protected
  CommandBase([String? id]) : id = id ?? const Uuid().v4();
}
