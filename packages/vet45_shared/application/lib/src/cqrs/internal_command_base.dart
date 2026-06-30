import 'package:meta/meta.dart';

import 'command_base.dart';

/// Base for durable module-internal commands (worker / inbox processing).
abstract class InternalCommandBase<TResult> extends CommandBase<TResult> {
  @protected
  InternalCommandBase([super.id]);
}
