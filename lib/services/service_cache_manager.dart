import 'package:fawran/Fawran4Hours/cleaning_service_screen.dart';
class ServiceCacheManager {
  static final ServiceCacheManager _instance = ServiceCacheManager._internal();
  factory ServiceCacheManager() => _instance;
  ServiceCacheManager._internal();

  // Cache for services by profession ID
  final Map<int, List<Service>> _servicesCache = {};
  final Map<int, DateTime> _cacheTimestamps = {};
  
  // Cache validity duration (optional - set to null for app-lifetime caching)
  static const Duration? cacheValidityDuration = null; // Cache until app closes
  
  /// Get cached services for a profession ID
  List<Service>? getCachedServices(int professionId) {
    if (!_servicesCache.containsKey(professionId)) {
      return null;
    }
    
    // If cache validity is set, check if cache is still valid
    if (cacheValidityDuration != null) {
      final cacheTime = _cacheTimestamps[professionId];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) > cacheValidityDuration!) {
        // Cache expired, remove it
        _servicesCache.remove(professionId);
        _cacheTimestamps.remove(professionId);
        return null;
      }
    }
    
    return List.from(_servicesCache[professionId]!);
  }
  
  /// Cache services for a profession ID
  void cacheServices(int professionId, List<Service> services) {
    _servicesCache[professionId] = List.from(services);
    _cacheTimestamps[professionId] = DateTime.now();
  }
  
  /// Check if services are cached for a profession ID
  bool hasValidCache(int professionId) {
    return getCachedServices(professionId) != null;
  }
  
  /// Clear cache for a specific profession ID
  void clearCache(int professionId) {
    _servicesCache.remove(professionId);
    _cacheTimestamps.remove(professionId);
  }
  
  /// Clear all cached services
  void clearAllCache() {
    _servicesCache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo() {
    return {
      'cached_professions': _servicesCache.keys.toList(),
      'cache_sizes': _servicesCache.map((key, value) => MapEntry(key.toString(), value.length)),
      'cache_timestamps': _cacheTimestamps.map((key, value) => MapEntry(key.toString(), value.toIso8601String())),
    };
  }
}