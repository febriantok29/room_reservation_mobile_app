/// Base exception untuk semua error API
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'ApiException: $message';
}

/// Exception untuk error jaringan
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception untuk timeout
class TimeoutException extends ApiException {
  const TimeoutException(super.message, {super.originalError});

  @override
  String toString() => 'TimeoutException: $message';
}

/// Exception untuk error server (5xx)
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.originalError});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception untuk error client (4xx)
class ClientException extends ApiException {
  const ClientException(super.message, {super.statusCode, super.originalError});

  @override
  String toString() => 'ClientException: $message (Status: $statusCode)';
}

/// Exception untuk error unauthorized (401)
class UnauthorizedException extends ClientException {
  const UnauthorizedException(super.message, {super.originalError})
    : super(statusCode: 401);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception untuk error forbidden (403)
class ForbiddenException extends ClientException {
  const ForbiddenException(super.message, {super.originalError})
    : super(statusCode: 403);

  @override
  String toString() => 'ForbiddenException: $message';
}

/// Exception untuk error not found (404)
class NotFoundException extends ClientException {
  const NotFoundException(super.message, {super.originalError})
    : super(statusCode: 404);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception untuk error validasi data
class ValidationException extends ClientException {
  final Map<String, List<String>>? errors;

  const ValidationException(super.message, {this.errors, super.originalError})
    : super(statusCode: 422);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception untuk error conflict (409)
class ConflictException extends ClientException {
  const ConflictException(super.message, {super.originalError})
    : super(statusCode: 409);

  @override
  String toString() => 'ConflictException: $message';
}

/// Exception untuk error parsing JSON
class ParseException extends ApiException {
  const ParseException(super.message, {super.originalError});

  @override
  String toString() => 'ParseException: $message';
}
