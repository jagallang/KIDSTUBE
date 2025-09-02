import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/channel.dart';
import '../core/interfaces/i_storage_service.dart';

/// Cloud backup service for subscription channels and user data
/// Uses HTTP endpoints for backup and restore operations
class CloudBackupService {
  static const String _backupEndpoint = 'https://jsonbin.io/v3/b';
  static const String _apiKey = '\$2a\$10\$placeholder'; // Replace with actual API key
  static const String _backupIdKey = 'cloud_backup_id';
  static const String _lastBackupKey = 'last_backup_time';
  static const String _deviceIdKey = 'device_id';
  
  final IStorageService _storageService;
  
  CloudBackupService({required IStorageService storageService})
      : _storageService = storageService;
  
  /// Generate or get device ID for backup identification
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      // Generate unique device ID based on timestamp and random
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomBytes = List.generate(8, (index) => timestamp % 256);
      deviceId = sha256.convert(randomBytes).toString().substring(0, 16);
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }
  
  /// Create backup data structure
  Future<Map<String, dynamic>> _createBackupData() async {
    try {
      final channels = await _storageService.loadChannels();
      final deviceId = await _getDeviceId();
      
      return {
        'version': '1.0.0',
        'deviceId': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'dataType': 'kidstube_backup',
        'data': {
          'channels': channels.map((channel) => channel.toJson()).toList(),
          'channelCount': channels.length,
          'categories': _extractCategories(channels),
        },
        'metadata': {
          'appVersion': '1.1.04',
          'platform': Platform.operatingSystem,
          'backupSize': channels.length,
        }
      };
    } catch (e) {
      throw Exception('Failed to create backup data: $e');
    }
  }
  
  /// Extract unique categories from channels
  List<String> _extractCategories(List<Channel> channels) {
    final categories = channels.map((channel) => channel.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  /// Backup data to cloud
  Future<BackupResult> backupToCloud() async {
    try {
      final backupData = await _createBackupData();
      
      // For demonstration, using JSONBin.io (replace with your preferred service)
      final response = await http.post(
        Uri.parse(_backupEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _apiKey,
          'X-Bin-Name': 'KidsTube-Backup-${await _getDeviceId()}',
        },
        body: json.encode(backupData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final backupId = responseData['metadata']['id'];
        
        // Save backup ID and timestamp locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_backupIdKey, backupId);
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
        
        return BackupResult(
          success: true,
          backupId: backupId,
          timestamp: DateTime.now(),
          channelCount: backupData['data']['channelCount'],
          message: 'Backup completed successfully',
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return BackupResult(
        success: false,
        error: e.toString(),
        message: 'Backup failed: ${e.toString()}',
      );
    }
  }
  
  /// Restore data from cloud
  Future<RestoreResult> restoreFromCloud({String? backupId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      backupId ??= prefs.getString(_backupIdKey);
      
      if (backupId == null) {
        throw Exception('No backup ID found. Please create a backup first.');
      }
      
      final response = await http.get(
        Uri.parse('$_backupEndpoint/$backupId/latest'),
        headers: {
          'X-Master-Key': _apiKey,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final backupData = responseData['record'];
        
        // Validate backup data
        if (!_validateBackupData(backupData)) {
          throw Exception('Invalid backup data format');
        }
        
        // Extract channels data
        final channelsData = backupData['data']['channels'] as List;
        final channels = channelsData
            .map((channelJson) => Channel.fromJson(channelJson))
            .toList();
        
        // Save restored channels
        await _storageService.saveChannels(channels);
        
        return RestoreResult(
          success: true,
          channelCount: channels.length,
          categories: List<String>.from(backupData['data']['categories']),
          backupDate: DateTime.parse(backupData['timestamp']),
          message: 'Restore completed successfully',
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return RestoreResult(
        success: false,
        error: e.toString(),
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }
  
  /// Validate backup data structure
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      return data.containsKey('version') &&
             data.containsKey('timestamp') &&
             data.containsKey('data') &&
             data['data'].containsKey('channels') &&
             data['data']['channels'] is List;
    } catch (e) {
      return false;
    }
  }
  
  /// Get backup status and information
  Future<BackupStatus> getBackupStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupId = prefs.getString(_backupIdKey);
      final lastBackupString = prefs.getString(_lastBackupKey);
      
      if (backupId == null || lastBackupString == null) {
        return BackupStatus(
          hasBackup: false,
          message: 'No backup found',
        );
      }
      
      final lastBackup = DateTime.parse(lastBackupString);
      final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
      
      // Check if backup exists in cloud
      final response = await http.head(
        Uri.parse('$_backupEndpoint/$backupId/latest'),
        headers: {'X-Master-Key': _apiKey},
      );
      
      final backupExists = response.statusCode == 200;
      
      return BackupStatus(
        hasBackup: backupExists,
        backupId: backupId,
        lastBackup: lastBackup,
        daysSinceBackup: daysSinceBackup,
        needsBackup: daysSinceBackup > 7, // Suggest backup if older than 7 days
        message: backupExists 
            ? 'Backup available (${daysSinceBackup} days old)'
            : 'Backup not found in cloud',
      );
    } catch (e) {
      return BackupStatus(
        hasBackup: false,
        error: e.toString(),
        message: 'Error checking backup status',
      );
    }
  }
  
  /// Delete cloud backup
  Future<bool> deleteBackup({String? backupId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      backupId ??= prefs.getString(_backupIdKey);
      
      if (backupId == null) return false;
      
      final response = await http.delete(
        Uri.parse('$_backupEndpoint/$backupId'),
        headers: {'X-Master-Key': _apiKey},
      );
      
      if (response.statusCode == 200) {
        // Clear local backup info
        await prefs.remove(_backupIdKey);
        await prefs.remove(_lastBackupKey);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }
  
  /// Auto backup if needed (call periodically)
  Future<void> autoBackupIfNeeded() async {
    try {
      final status = await getBackupStatus();
      
      if (!status.hasBackup || status.needsBackup) {
        print('Skipping auto backup (temporarily disabled for debugging)...');
        // Temporarily disabled to avoid HTTP 404 errors
        // final result = await backupToCloud();
        // 
        // if (result.success) {
        //   print('Auto backup completed: ${result.channelCount} channels');
        // } else {
        //   print('Auto backup failed: ${result.error}');
        // }
      }
    } catch (e) {
      print('Auto backup check failed: $e');
    }
  }
}

/// Result of backup operation
class BackupResult {
  final bool success;
  final String? backupId;
  final DateTime? timestamp;
  final int? channelCount;
  final String message;
  final String? error;
  
  BackupResult({
    required this.success,
    this.backupId,
    this.timestamp,
    this.channelCount,
    required this.message,
    this.error,
  });
  
  @override
  String toString() {
    return 'BackupResult(success: $success, message: $message, channels: $channelCount)';
  }
}

/// Result of restore operation
class RestoreResult {
  final bool success;
  final int? channelCount;
  final List<String>? categories;
  final DateTime? backupDate;
  final String message;
  final String? error;
  
  RestoreResult({
    required this.success,
    this.channelCount,
    this.categories,
    this.backupDate,
    required this.message,
    this.error,
  });
  
  @override
  String toString() {
    return 'RestoreResult(success: $success, message: $message, channels: $channelCount)';
  }
}

/// Status of backup system
class BackupStatus {
  final bool hasBackup;
  final String? backupId;
  final DateTime? lastBackup;
  final int? daysSinceBackup;
  final bool needsBackup;
  final String message;
  final String? error;
  
  BackupStatus({
    required this.hasBackup,
    this.backupId,
    this.lastBackup,
    this.daysSinceBackup,
    this.needsBackup = false,
    required this.message,
    this.error,
  });
  
  @override
  String toString() {
    return 'BackupStatus(hasBackup: $hasBackup, needsBackup: $needsBackup, message: $message)';
  }
}