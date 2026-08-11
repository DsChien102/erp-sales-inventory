import 'package:fpdart/fpdart.dart';

import 'failure.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;

typedef Result<T> = Either<Failure, T>;
