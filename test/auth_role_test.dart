import 'package:flutter_test/flutter_test.dart';
import 'package:biblioteka_vga/models/app_user.dart';
import 'package:biblioteka_vga/state/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Проверки контроля доступа (Роли)', () {
    test('1. Гость (не авторизован) не имеет доступа к ролям', () async {
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthProvider(prefs, Dio());
      
      expect(auth.isAuthenticated, false);
      expect(auth.has(Role.reader), false);
      expect(auth.has(Role.admin), false);
    });

    test('2. Роль Reader имеет доступ к Reader, но не к Librarian', () async {
      final user = AppUser(id: 1, username: 'test', fullName: 'Test', email: 'test@t.ru', role: Role.reader);
      expect(user.role.level >= Role.reader.level, true);
      expect(user.role.level >= Role.librarian.level, false);
    });

    test('3. Роль Librarian имеет доступ к Reader и Librarian, но не Admin', () {
      final user = AppUser(id: 2, username: 'lib', fullName: 'Lib', email: 'l@t.ru', role: Role.librarian);
      expect(user.role.level >= Role.reader.level, true);
      expect(user.role.level >= Role.librarian.level, true);
      expect(user.role.level >= Role.admin.level, false);
    });

    test('4. Роль Admin имеет доступ ко всем уровням', () {
      final user = AppUser(id: 3, username: 'adm', fullName: 'Adm', email: 'a@t.ru', role: Role.admin);
      expect(user.role.level >= Role.reader.level, true);
      expect(user.role.level >= Role.librarian.level, true);
      expect(user.role.level >= Role.admin.level, true);
    });

    test('5. Парсинг неизвестной роли дает Reader по умолчанию', () {
      final role = Role.fromString('hacker');
      expect(role, Role.reader);
    });
  });
}