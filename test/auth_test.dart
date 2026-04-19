import 'package:flutter_test/flutter_test.dart';
import 'package:helpdesk_app/core/utils/validators.dart';

void main() {
  group('Validators - Auth', () {
    test('email valid should return null', () {
      expect(Validators.email('test@email.com'), isNull);
    });

    test('email invalid should return error', () {
      expect(Validators.email('invalid-email'), isNotNull);
    });

    test('email empty should return error', () {
      expect(Validators.email(''), isNotNull);
    });

    test('password valid (8+ chars) should return null', () {
      expect(Validators.password('password123'), isNull);
    });

    test('password too short should return error', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('confirm password match should return null', () {
      expect(Validators.confirmPassword('pass123!', 'pass123!'), isNull);
    });

    test('confirm password mismatch should return error', () {
      expect(Validators.confirmPassword('pass123!', 'different'), isNotNull);
    });

    test('username valid should return null', () {
      expect(Validators.username('john_doe'), isNull);
    });

    test('username too short should return error', () {
      expect(Validators.username('ab'), isNotNull);
    });

    test('required field empty should return error', () {
      expect(Validators.required(''), isNotNull);
    });

    test('required field filled should return null', () {
      expect(Validators.required('some value'), isNull);
    });
  });
}
