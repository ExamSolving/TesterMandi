import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/services/play_store_service.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/app_listing.dart';
import '../../domain/repositories/apps_repository.dart';
import '../../data/models/app_listing_model.dart';

enum BrowseQuickFilter { newest, mostTesters, needTester, unSwapped, swapped }

class AppsController extends GetxController {
  AppsController(this._repo);
  final AppsRepository _repo;

  static const _appInfoChannel = MethodChannel('com.appvora/app_info');

  StreamSubscription<List<AppListing>>? _allAppsSub;
  StreamSubscription<List<AppListing>>? _myAppsSub;

  final isLoading = false.obs;
  final allAppsLoaded = false.obs;
  final myAppsLoaded = false.obs;
  final myApps = <AppListing>[].obs;
  final allApps = <AppListing>[].obs;
  final selectedCategory = Rx<AppCategory?>(null);
  final browseSearch = ''.obs;
  final browseFilterCountry = Rx<String?>(null);
  final browseFilterLanguage = Rx<String?>(null);
  final browseQuickFilter = BrowseQuickFilter.newest.obs;

  // ── Multi-step form ────────────────────────────────────────────────────────
  /// 0 = Package  |  1 = Details  |  2 = Submit
  final currentStep = 0.obs;
  final editingAppId = Rx<String?>(null);

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final packageCtrl = TextEditingController();
  final optInCtrl = TextEditingController();
  final manualIconUrlCtrl = TextEditingController();
  final latestVersionCtrl = TextEditingController();
  final testingInstructionsCtrl = TextEditingController();

  final selectedAppCategory = Rx<AppCategory?>(null);
  final testersNeeded = 12.obs;
  final selectedMinAndroid = Rx<String?>(null);

  /// Must be confirmed on Step 3 before submitting.
  final groupConfirmed = false.obs;

  /// Multi-select country codes. 'All' means no specific country filter.
  final selectedCountries = <String>['All'].obs;

  /// Multi-select language names.
  final selectedLanguages = <String>['English'].obs;

  // ── Play Store / device lookup ─────────────────────────────────────────────
  final fetchedIconUrl = Rx<String?>(null);
  final isFetchingIcon = false.obs;
  final iconFetchFailed = false.obs;
  final isLookingUp = false.obs;
  final isCheckingDevice = false.obs;
  // null=not tried  true=found data  false=nothing found
  final lookupResult = Rx<bool?>(null);
  final fetchedIsPublic = false.obs;
  // null=not tried  true=found  false=not installed
  final deviceAppFound = Rx<bool?>(null);

  // ── Manually picked icon ───────────────────────────────────────────────────
  final pickedIconFile = Rx<XFile?>(null);

  // ── Duplicate package check ────────────────────────────────────────────────
  final packageAlreadyListed = false.obs;

  // ── Step validation ────────────────────────────────────────────────────────

  bool get _step1Valid =>
      packageCtrl.text.trim().contains('.') &&
      nameCtrl.text.trim().isNotEmpty;

  bool get _step2Valid => selectedAppCategory.value != null;

  void nextStep(BuildContext context) {
    if (currentStep.value == 0 && packageAlreadyListed.value) {
      _snack('This package ID is already listed on TesterMandi');
      return;
    }
    if (currentStep.value == 0 && !_step1Valid) {
      _snack('Please fill Package ID and App Name');
      return;
    }
    if (currentStep.value == 1 && !_step2Valid) {
      _snack('Please select a category for your app');
      return;
    }
    if (currentStep.value < 2) currentStep.value++;
  }

  void prevStep() {
    if (editingAppId.value != null && currentStep.value == 0) {
      Get.back();
      return;
    }
    if (currentStep.value > 0) currentStep.value--;
  }

  void fillFormForEdit(AppListing app) {
    _clearForm();
    editingAppId.value = app.id;
    nameCtrl.text = app.appName;
    descCtrl.text = app.description;
    packageCtrl.text = app.packageName;
    optInCtrl.text = app.optInUrl;
    latestVersionCtrl.text = app.latestVersion ?? '';
    testingInstructionsCtrl.text = app.testingInstructions ?? '';
    selectedAppCategory.value = app.category;
    testersNeeded.value = app.testersNeeded;
    selectedMinAndroid.value = app.minAndroidLevel;
    selectedCountries.value = List<String>.from(app.targetCountries);
    selectedLanguages.value = List<String>.from(app.appLanguages);
    if (app.iconUrl != null) fetchedIconUrl.value = app.iconUrl;
    groupConfirmed.value = true;
    currentStep.value = 0;
  }

  // ── Country / Language toggles ─────────────────────────────────────────────

  void toggleCountry(String code) {
    if (code == 'All') {
      selectedCountries.value = ['All'];
      return;
    }
    final list = List<String>.from(selectedCountries)..remove('All');
    if (list.contains(code)) {
      list.remove(code);
      if (list.isEmpty) list.add('All');
    } else {
      list.add(code);
    }
    selectedCountries.value = list;
  }

  void toggleLanguage(String lang) {
    final list = List<String>.from(selectedLanguages);
    if (list.contains(lang)) {
      if (list.length > 1) list.remove(lang);
    } else {
      list.add(lang);
    }
    selectedLanguages.value = list;
  }

  // ── Play Store + device lookup ─────────────────────────────────────────────

  /// Search handler: runs Play Store lookup, duplicate check, and device
  /// detection all in parallel.
  ///   Case 1 — public Play Store: fill name + description + icon from Play Store.
  ///   Case 2 — not public but installed on device: fill name + icon from device.
  ///   Case 3 — neither: show fill-manually error.
  Future<void> lookupAppDetails() async {
    final pkg = packageCtrl.text.trim();
    if (pkg.isEmpty || !pkg.contains('.')) return;

    isLookingUp.value = true;
    isCheckingDevice.value = true;
    lookupResult.value = null;
    fetchedIconUrl.value = null;
    iconFetchFailed.value = false;
    fetchedIsPublic.value = false;
    deviceAppFound.value = null;
    packageAlreadyListed.value = false;

    try {
      // Run all three sources simultaneously.
      final results = await Future.wait([
        PlayStoreService.fetchAppDetails(pkg),
        _repo.packageExists(pkg),
        _queryDeviceApp(pkg),
      ]);

      final details = results[0] as AppDetails;
      final alreadyListed = results[1] as bool;
      final deviceInfo = results[2] as _DeviceAppInfo?; // non-null means installed

      isCheckingDevice.value = false;

      if (alreadyListed) {
        packageAlreadyListed.value = true;
        lookupResult.value = false;
        iconFetchFailed.value = true;
        return;
      }

      if (details.hasAnyData) {
        // Case 1: publicly listed on Play Store.
        if (details.name != null && nameCtrl.text.trim().isEmpty) {
          nameCtrl.text = details.name!;
        }
        if (details.isPublic &&
            details.description != null &&
            descCtrl.text.trim().isEmpty) {
          descCtrl.text = details.description!;
        }
        // Use device icon if Play Store didn't provide one.
        if (details.iconUrl != null) {
          fetchedIconUrl.value = details.iconUrl;
          iconFetchFailed.value = false;
        } else if (deviceInfo?.iconFile != null) {
          pickedIconFile.value = deviceInfo!.iconFile;
          iconFetchFailed.value = false;
        } else {
          iconFetchFailed.value = true;
        }
        fetchedIsPublic.value = details.isPublic;
        deviceAppFound.value = deviceInfo != null;
        lookupResult.value = true;
      } else if (deviceInfo != null) {
        // Not on Play Store but installed on this device — closed testing APK.
        if (nameCtrl.text.trim().isEmpty) nameCtrl.text = deviceInfo.name;
        if (deviceInfo.iconFile != null) {
          pickedIconFile.value = deviceInfo.iconFile;
          iconFetchFailed.value = false;
        } else {
          iconFetchFailed.value = true;
        }
        deviceAppFound.value = true;
        lookupResult.value = true;
      } else {
        deviceAppFound.value = false;
        iconFetchFailed.value = true;
        lookupResult.value = false;
      }
    } catch (e) {
      debugPrint('[AppsController] lookupAppDetails error: $e');
      lookupResult.value = false;
      iconFetchFailed.value = true;
    } finally {
      isLookingUp.value = false;
      isCheckingDevice.value = false;
    }
  }

  /// Queries the device for an installed app. Returns name + icon file, or null.
  Future<_DeviceAppInfo?> _queryDeviceApp(String pkg) async {
    try {
      final raw = await _appInfoChannel
          .invokeMethod<Map>('isAppInstalled', {'packageId': pkg});
      if (raw == null || raw['installed'] != true) return null;

      final name = (raw['name'] as String?) ?? pkg;
      XFile? iconFile;

      final iconBase64 = raw['iconBase64'] as String?;
      if (iconBase64 != null && iconBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(iconBase64);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/device_icon_$pkg.png');
          await file.writeAsBytes(bytes);
          iconFile = XFile(file.path);
        } catch (_) {}
      }

      return _DeviceAppInfo(name: name, iconFile: iconFile);
    } catch (_) {
      return null;
    }
  }


  Future<void> pickIconFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    pickedIconFile.value = file;
    fetchedIconUrl.value = null;
    iconFetchFailed.value = false;
    manualIconUrlCtrl.clear();
  }

  Future<void> fetchIconForPackage() async {
    final pkg = packageCtrl.text.trim();
    if (pkg.isEmpty || !pkg.contains('.')) return;
    isFetchingIcon.value = true;
    fetchedIconUrl.value = null;
    iconFetchFailed.value = false;
    try {
      final url = await PlayStoreService.fetchIconUrl(pkg);
      fetchedIconUrl.value = url;
      iconFetchFailed.value = url == null;
    } catch (_) {
      iconFetchFailed.value = true;
    } finally {
      isFetchingIcon.value = false;
    }
  }

  // ── Browse helpers ─────────────────────────────────────────────────────────

  String get _uid => Get.find<AuthController>().currentUser.value?.uid ?? '';

  List<AppListing> get browsableApps =>
      allApps.where((a) => a.ownerId != _uid && !a.paused).toList();

  List<AppListing> get filteredBrowse {
    var list = browsableApps;

    final cat = selectedCategory.value;
    if (cat != null) list = list.where((a) => a.category == cat).toList();

    final country = browseFilterCountry.value;
    if (country != null) {
      list = list
          .where((a) =>
              a.targetCountries.contains('All') ||
              a.targetCountries.contains(country))
          .toList();
    }

    final lang = browseFilterLanguage.value;
    if (lang != null) {
      list = list.where((a) => a.appLanguages.contains(lang)).toList();
    }

    final q = browseSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((a) =>
              a.appName.toLowerCase().contains(q) ||
              a.ownerName.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q))
          .toList();
    }

    final uid = _uid;
    switch (browseQuickFilter.value) {
      case BrowseQuickFilter.newest:
        list = List.from(list)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BrowseQuickFilter.mostTesters:
        list = List.from(list)
          ..sort((a, b) => b.testerCount.compareTo(a.testerCount));
      case BrowseQuickFilter.needTester:
        list = (list.where((a) => !a.isFull).toList())
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BrowseQuickFilter.unSwapped:
        list = (list.where((a) => !a.testerIds.contains(uid)).toList())
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BrowseQuickFilter.swapped:
        list = (list.where((a) => a.testerIds.contains(uid)).toList())
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  int get activeBrowseFilterCount {
    int n = 0;
    if (selectedCategory.value != null) n++;
    if (browseFilterCountry.value != null) n++;
    if (browseFilterLanguage.value != null) n++;
    return n;
  }

  void setQuickFilter(BrowseQuickFilter f) => browseQuickFilter.value = f;

  void clearBrowseFilters() {
    selectedCategory.value = null;
    browseFilterCountry.value = null;
    browseFilterLanguage.value = null;
    browseQuickFilter.value = BrowseQuickFilter.newest;
  }

  void filterByLanguage(String? lang) => browseFilterLanguage.value = lang;

  Future<bool> checkIsInstalled(String packageName) async {
    try {
      final raw = await _appInfoChannel
          .invokeMethod<Map>('isAppInstalled', {'packageId': packageName});
      return raw?['installed'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> launchApp(String packageName) async {
    try {
      final result = await _appInfoChannel
          .invokeMethod<bool>('launchApp', {'packageId': packageName});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.currentUser, (_) => _resubscribe());
    if (auth.currentUser.value != null) _resubscribe();
  }

  void _resubscribe() {
    if (_uid.isEmpty) {
      _allAppsSub?.cancel();
      _myAppsSub?.cancel();
      return;
    }
    allAppsLoaded.value = false;
    myAppsLoaded.value = false;
    _allAppsSub?.cancel();
    _myAppsSub?.cancel();
    _allAppsSub = _repo.watchAllApps().listen(
      (apps) {
        allApps.value = apps;
        allAppsLoaded.value = true;
      },
      onError: (e) => debugPrint('[AppsController] watchAllApps error: $e'),
    );
    _myAppsSub = _repo.watchUserApps(_uid).listen(
      (apps) {
        myApps.value = apps;
        myAppsLoaded.value = true;
      },
      onError: (e) => debugPrint('[AppsController] watchUserApps error: $e'),
    );
  }

  @override
  void onClose() {
    _allAppsSub?.cancel();
    _myAppsSub?.cancel();
    nameCtrl.dispose();
    descCtrl.dispose();
    packageCtrl.dispose();
    optInCtrl.dispose();
    manualIconUrlCtrl.dispose();
    latestVersionCtrl.dispose();
    testingInstructionsCtrl.dispose();
    super.onClose();
  }

  Future<void> loadAll() async => _refresh();
  Future<void> refreshMyApps() async => _refresh();
  Future<void> refreshAll() async => _refresh();

  Future<void> _refresh() async {
    if (_uid.isEmpty) return;
    _resubscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void filterByCategory(AppCategory? cat) => selectedCategory.value = cat;
  void filterByCountry(String? country) => browseFilterCountry.value = country;
  void updateSearch(String q) => browseSearch.value = q;

  Future<bool> updateApp(
    String appId, {
    required String name,
    required String desc,
    required AppCategory category,
    String? version,
    String? minAndroid,
    required String optInUrl,
    String? instructions,
    required int testersNeeded,
    required List<String> countries,
    required List<String> languages,
  }) async {
    if (name.trim().isEmpty) {
      _snack('App name cannot be empty');
      return false;
    }
    isLoading.value = true;
    try {
      final fields = <String, dynamic>{
        'appName': name.trim(),
        'description': desc.trim(),
        'category': category.name,
        'optInUrl': optInUrl.trim(),
        'testersNeeded': testersNeeded,
        'targetCountries': countries,
        'appLanguages': languages,
        'latestVersion': (version ?? '').trim().isNotEmpty
            ? version!.trim()
            : FieldValue.delete(),
        'minAndroidLevel': minAndroid ?? FieldValue.delete(),
        'testingInstructions': (instructions ?? '').trim().isNotEmpty
            ? instructions!.trim()
            : FieldValue.delete(),
      };
      await _repo.updateApp(appId, fields);
      _snack('App updated!', success: true);
      return true;
    } catch (e) {
      debugPrint('[AppsController] updateApp error: $e');
      _snack('Failed to update app.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> togglePauseListing(AppListing app) async {
    final newPaused = !app.paused;
    try {
      await _repo.togglePauseListing(app.id, paused: newPaused);
      _snack(
        newPaused ? 'Listing paused — hidden from browse.' : 'Listing resumed — visible in browse.',
        success: true,
      );
    } catch (e) {
      debugPrint('[AppsController] togglePauseListing error: $e');
      _snack('Failed to update listing status.');
    }
  }

  /// Returns the posted app name on success, null on failure.
  Future<String?> submitApp() async {
    if (!formKey.currentState!.validate()) return null;

    // ── Edit mode: update existing listing ──────────────────────────────────
    final editId = editingAppId.value;
    if (editId != null) {
      final ok = await updateApp(
        editId,
        name: nameCtrl.text.trim(),
        desc: descCtrl.text.trim(),
        category: selectedAppCategory.value ?? AppCategory.other,
        version: latestVersionCtrl.text.trim().isEmpty
            ? null
            : latestVersionCtrl.text.trim(),
        minAndroid: selectedMinAndroid.value,
        optInUrl: optInCtrl.text.trim(),
        instructions: testingInstructionsCtrl.text.trim().isEmpty
            ? null
            : testingInstructionsCtrl.text.trim(),
        testersNeeded: testersNeeded.value,
        countries: List<String>.from(selectedCountries),
        languages: List<String>.from(selectedLanguages),
      );
      return ok ? nameCtrl.text.trim() : null;
    }

    // ── Add mode: create new listing ────────────────────────────────────────
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value!;
      final id = const Uuid().v4();

      // Upload picked icon to Storage if user chose a local file.
      String? resolvedIconUrl = fetchedIconUrl.value ??
          (manualIconUrlCtrl.text.trim().isNotEmpty
              ? manualIconUrlCtrl.text.trim()
              : null);
      final picked = pickedIconFile.value;
      if (picked != null) {
        final ref = FirebaseStorage.instance
            .ref('app_icons/${user.uid}/${packageCtrl.text.trim()}.jpg');
        final compressed = await ImageCompressor.compressIconBytes(
          await picked.readAsBytes(),
        );
        await ref.putData(
          compressed,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        resolvedIconUrl = await ref.getDownloadURL();
      }

      final postedName = nameCtrl.text.trim();
      await _repo.postApp(AppListingModel(
        id: id,
        ownerId: user.uid,
        ownerName: user.displayName,
        appName: postedName,
        description: descCtrl.text.trim(),
        packageName: packageCtrl.text.trim(),
        optInUrl: optInCtrl.text.trim(),
        category: selectedAppCategory.value ?? AppCategory.other,
        testersNeeded: testersNeeded.value,
        testerIds: const [],
        createdAt: Timestamp.now(),
        iconUrl: resolvedIconUrl,
        targetCountries: List<String>.from(selectedCountries),
        appLanguages: List<String>.from(selectedLanguages),
        latestVersion: latestVersionCtrl.text.trim().isEmpty
            ? null
            : latestVersionCtrl.text.trim(),
        minAndroidLevel: selectedMinAndroid.value,
        testingInstructions: testingInstructionsCtrl.text.trim().isEmpty
            ? null
            : testingInstructionsCtrl.text.trim(),
      ));
      _clearForm();

      // Fire-and-forget — don't block the return on a reload round-trip.
      loadAll().catchError((_) {});
      _repo.notifyNewAppListed(
        appId: id,
        appName: postedName,
        ownerName: user.displayName,
        ownerId: user.uid,
      ).catchError((_) {});

      return postedName;
    } catch (e) {
      _snack(TKeys.addAppError.tr);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called by AddAppView.dispose() so the form is always clean on close.
  void resetAddAppForm() => _clearForm();

  void _clearForm() {
    nameCtrl.clear();
    descCtrl.clear();
    packageCtrl.clear();
    optInCtrl.clear();
    manualIconUrlCtrl.clear();
    latestVersionCtrl.clear();
    testingInstructionsCtrl.clear();
    selectedAppCategory.value = null;
    testersNeeded.value = 12;
    selectedMinAndroid.value = null;
    selectedCountries.value = ['All'];
    selectedLanguages.value = ['English'];
    fetchedIconUrl.value = null;
    pickedIconFile.value = null;
    isFetchingIcon.value = false;
    iconFetchFailed.value = false;
    isLookingUp.value = false;
    isCheckingDevice.value = false;
    lookupResult.value = null;
    fetchedIsPublic.value = false;
    deviceAppFound.value = null;
    packageAlreadyListed.value = false;
    groupConfirmed.value = false;
    currentStep.value = 0;
    editingAppId.value = null;
  }

  void _snack(String msg, {bool success = false}) {
    Get.snackbar(
      '',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          success ? const Color(0xFF059669) : const Color(0xFFDC2626),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      titleText: const SizedBox.shrink(),
    );
  }
}

class _DeviceAppInfo {
  const _DeviceAppInfo({required this.name, this.iconFile});
  final String name;
  final XFile? iconFile;
}
