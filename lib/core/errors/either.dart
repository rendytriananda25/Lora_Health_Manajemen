import 'package:lora_1/core/errors/failures.dart';

/// ═══════════════════════════════════════════════════════════════
/// Either — Tipe data yang merepresentasikan 2 kemungkinan hasil:
/// Left (Failure) atau Right (Success).
///
/// Dipakai oleh UseCase dan Repository agar TIDAK PERNAH throw exception.
/// Widget tinggal cek: result.isLeft ? tampilkan error : tampilkan data.
/// ═══════════════════════════════════════════════════════════════

class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;

  const Either._left(this._left) : _right = null, _isLeft = true;
  const Either._right(this._right) : _left = null, _isLeft = false;

  /// Buat Either sukses (Right).
  factory Either.right(R value) => Either._right(value);

  /// Buat Either gagal (Left).
  factory Either.left(L value) => Either._left(value);

  /// True jika hasil gagal (Left / Failure).
  bool get isLeft => _isLeft;

  /// True jika hasil sukses (Right / Data).
  bool get isRight => !_isLeft;

  /// Ambil data Failure (hanya panggil kalau isLeft == true).
  L get left => _left as L;

  /// Ambil data sukses (hanya panggil kalau isRight == true).
  R get right => _right as R;

  /// Pattern matching — eksekusi fungsi sesuai hasilnya.
  /// ```dart
  /// result.fold(
  ///   (failure) => showError(failure.message),
  ///   (data) => showData(data),
  /// );
  /// ```
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    if (_isLeft) return onLeft(_left as L);
    return onRight(_right as R);
  }
}

/// Alias untuk kemudahan — hampir semua UseCase mengembalikan ini.
typedef Result<T> = Either<Failure, T>;
