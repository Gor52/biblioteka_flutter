import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/app_user.dart';
import '../core/api_exceptions.dart';

class AuthProvider extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kSessionStart = 'auth_session_start';
  static const _maxSessionHours = 12; 

  final SharedPreferences _prefs;
  final Dio _dio;
  
  AppUser? _user;
  String? _accessToken;
  Timer? _maxSessionTimer;

  AuthProvider(this._prefs, this._dio);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final sessionStartStr = _prefs.getString(_kSessionStart);

    if (access == null) return;

    if (sessionStartStr != null) {
      final start = DateTime.tryParse(sessionStartStr);
      if (start != null && DateTime.now().difference(start).inHours >= _maxSessionHours) {
        await logout();
        return;
      } else if (start != null) {
        _startMaxSessionTimer(start);
      }
    }

    _accessToken = access;
    try {
      final response = await _dio.get('/auth/me', options: Options(headers: {'Authorization': 'Bearer $_accessToken'}));
      _user = AppUser.fromJson(response.data);

      // ========================================================
      // ВРЕМЕННЫЙ ХАК ДЛЯ ПУНКТА 17 (ОТЧЕТ: ПОДМЕНА РОЛИ)
      // Читаем фейковое значение из LocalStorage. 
      // Flutter автоматически ищет ключ с префиксом 'flutter.'
      // ========================================================
      final hackedRole = _prefs.getString('hacked_role');
      if (hackedRole == 'admin' && _user != null) {
        _user = AppUser(
          id: _user!.id, 
          username: _user!.username, 
          fullName: _user!.fullName, 
          email: _user!.email, 
          role: Role.admin // Принудительно ставим роль админа для UI
        );
      }
      // ========================================================

    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && refresh != null) {
        try {
          await refreshTokens(refreshFallback: refresh);
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
    }
    notifyListeners();
  }

  Future<void> register(String username, String password, String fullName) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'fullName': fullName,
      });
      
      final result = AuthResult.fromJson(response.data);
      _accessToken = result.accessToken;

      await _prefs.setString(_kAccess, result.accessToken);
      await _prefs.setString(_kRefresh, result.refreshToken);

      final meResponse = await _dio.get(
        '/auth/me', 
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'})
      );
      _user = AppUser.fromJson(meResponse.data);

      final now = DateTime.now();
      await _prefs.setString(_kSessionStart, now.toIso8601String());
      _startMaxSessionTimer(now);

      notifyListeners();
    } on DioException catch (e) {
      throw mapDioError(e); 
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      final result = AuthResult.fromJson(response.data);
      _accessToken = result.accessToken;

      await _prefs.setString(_kAccess, result.accessToken);
      await _prefs.setString(_kRefresh, result.refreshToken);

      final meResponse = await _dio.get(
        '/auth/me', 
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'})
      );
      _user = AppUser.fromJson(meResponse.data);

      final now = DateTime.now();
      await _prefs.setString(_kSessionStart, now.toIso8601String());
      _startMaxSessionTimer(now);

      notifyListeners();
    } on DioException catch (e) {
      throw mapDioError(e); 
    }
  }

  Future<void> refreshTokens({String? refreshFallback}) async {
    final refresh = refreshFallback ?? _prefs.getString(_kRefresh);
    if (refresh == null) throw const UnauthorizedException();

    try {
      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
      final result = AuthResult.fromJson(response.data);

      _accessToken = result.accessToken;
      _user = result.user;
      
      await _prefs.setString(_kAccess, result.accessToken);
      await _prefs.setString(_kRefresh, result.refreshToken);
      notifyListeners();
    } on DioException catch (_) {
      await logout();
      throw const UnauthorizedException('Сессия истекла');
    }
  }

  Future<void> logout() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {} 
    }

    _user = null;
    _accessToken = null;
    _maxSessionTimer?.cancel();
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kSessionStart);
    await _prefs.remove('hacked_role'); 
    notifyListeners();
  }

  void _startMaxSessionTimer(DateTime startTime) {
    _maxSessionTimer?.cancel();
    final expireTime = startTime.add(const Duration(hours: _maxSessionHours));
    final durationLeft = expireTime.difference(DateTime.now());
    
    if (durationLeft.isNegative) {
      logout();
    } else {
      _maxSessionTimer = Timer(durationLeft, logout);
    }
  }

  @override
  void dispose() {
    _maxSessionTimer?.cancel();
    super.dispose();
  }
}