import 'package:lora_1/core/errors/failures.dart';


class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;

  const Either._left(this._left) : _right = null, _isLeft = true;
  const Either._right(this._right) : _left = null, _isLeft = false;

  factory Either.right(R value) => Either._right(value);

  factory Either.left(L value) => Either._left(value);

  bool get isLeft => _isLeft;

  bool get isRight => !_isLeft;

  L get left => _left as L;

  R get right => _right as R;

  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    if (_isLeft) return onLeft(_left as L);
    return onRight(_right as R);
  }
}

typedef Result<T> = Either<Failure, T>;
