import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';

/// Exception thrown when the API rate limit is exceeded
class RateLimitException extends ApiException {
  RateLimitException([String? message])
    : super(message ?? 'Rate limit exceeded');
}
