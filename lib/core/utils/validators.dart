import 'package:get/get.dart';
import '../constants/translation_keys.dart';

abstract class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TKeys.validationRequired.tr;
    }
    if (!GetUtils.isEmail(value.trim())) {
      return TKeys.validationEmailInvalid.tr;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return TKeys.validationRequired.tr;
    }
    if (value.length < 8) {
      return TKeys.validationPasswordMin.tr;
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return TKeys.validationRequired.tr;
    }
    if (value != original) {
      return TKeys.validationPasswordNoMatch.tr;
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TKeys.validationRequired.tr;
    }
    if (value.trim().length < 2) {
      return TKeys.validationNameMin.tr;
    }
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TKeys.validationRequired.tr;
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TKeys.validationRequired.tr;
    }
    if (!GetUtils.isURL(value.trim())) {
      return TKeys.validationUrlInvalid.tr;
    }
    return null;
  }
}
