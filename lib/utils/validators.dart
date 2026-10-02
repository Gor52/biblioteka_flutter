class AppValidators {
  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Это поле обязательно для заполнения';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите E-mail';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Введите корректный адрес E-mail';
    }
    return null;
  }

  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите год';
    }
    final intYear = int.tryParse(value.trim());
    if (intYear == null) {
      return 'Год должен быть числом';
    }
    final currentYear = DateTime.now().year;
    if (intYear < 1000 || intYear > currentYear) {
      return 'Год должен быть между 1000 и $currentYear';
    }
    return null;
  }

  static String? positiveInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите значение';
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return 'Введите целое число';
    }
    if (num <= 0) {
      return 'Значение должно быть больше нуля';
    }
    return null;
  }

  static String? isbn(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите ISBN';
    }
    final clean = value.replaceAll(RegExp(r'[-\s]'), '');
    
    if (int.tryParse(clean) == null) {
      return 'ISBN должен состоять только из цифр (допускаются дефисы)';
    }
    if (clean.length != 10 && clean.length != 13) {
      return 'Длина ISBN должна быть 10 или 13 цифр (без учета дефисов)';
    }
    return null;
  }
}