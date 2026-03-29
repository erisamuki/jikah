import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/unit_model.dart';
import '../services/database_service.dart';

class PropertyProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<PropertyModel> _properties = [];
  List<UnitModel> _units = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  String? _error;

  List<PropertyModel> get properties => _properties;
  List<UnitModel> get units => _units;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load properties for landlord
  void loadPropertiesForLandlord(String landlordId) {
    _dbService.getPropertiesByLandlord(landlordId).listen((propertyList) {
      _properties = propertyList;
      notifyListeners();
    });
  }

  // Load units for property
  void loadUnitsForProperty(String propertyId) {
    _dbService.getUnitsByProperty(propertyId).listen((unitList) {
      _units = unitList;
      notifyListeners();
    });
  }

  // Load all units for landlord
  void loadUnitsForLandlord(String landlordId) {
    _dbService.getUnitsByLandlord(landlordId).listen((unitList) {
      _units = unitList;
      notifyListeners();
    });
  }

  // Create property
  Future<bool> createProperty({
    required String landlordId,
    required String name,
    required String location,
    required PropertyType type,
    String? address,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      PropertyModel property = PropertyModel(
        id: '', // Will be set by Firestore
        landlordId: landlordId,
        name: name,
        location: location,
        type: type,
        address: address,
        description: description,
        createdAt: DateTime.now(),
      );

      String? propertyId = await _dbService.createProperty(property);
      
      _isLoading = false;
      if (propertyId == null) {
        _error = 'Failed to create property';
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create unit
  Future<bool> createUnit({
    required String propertyId,
    required String landlordId,
    required String unitNumber,
    required double rentAmount,
    String? description,
    int? paymentDueDay,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UnitModel unit = UnitModel(
        id: '', // Will be set by Firestore
        propertyId: propertyId,
        landlordId: landlordId,
        unitNumber: unitNumber,
        rentAmount: rentAmount,
        description: description,
        paymentDueDay: paymentDueDay ?? 1,
        createdAt: DateTime.now(),
      );

      String? unitId = await _dbService.createUnit(unit);
      
      _isLoading = false;
      if (unitId == null) {
        _error = 'Failed to create unit';
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update property
  Future<bool> updateProperty(String propertyId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool success = await _dbService.updateProperty(propertyId, data);
    
    _isLoading = false;
    if (!success) {
      _error = 'Failed to update property';
    }
    notifyListeners();
    return success;
  }

  // Update unit
  Future<bool> updateUnit(String unitId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool success = await _dbService.updateUnit(unitId, data);
    
    _isLoading = false;
    if (!success) {
      _error = 'Failed to update unit';
    }
    notifyListeners();
    return success;
  }

  // Delete property
  Future<bool> deleteProperty(String propertyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool success = await _dbService.deactivateProperty(propertyId);
    
    _isLoading = false;
    if (!success) {
      _error = 'Failed to delete property';
    }
    notifyListeners();
    return success;
  }

  // Delete unit
  Future<bool> deleteUnit(String unitId, String propertyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool success = await _dbService.deleteUnit(unitId, propertyId);
    
    _isLoading = false;
    if (!success) {
      _error = 'Failed to delete unit';
    }
    notifyListeners();
    return success;
  }

  // Select property
  void selectProperty(PropertyModel? property) {
    _selectedProperty = property;
    if (property != null) {
      loadUnitsForProperty(property.id);
    }
    notifyListeners();
  }

  // Get units for specific property
  List<UnitModel> getUnitsForProperty(String propertyId) {
    return _units.where((unit) => unit.propertyId == propertyId).toList();
  }

  // Get vacant units count
  int get vacantUnitsCount => _units.where((u) => u.status == UnitStatus.vacant).length;

  // Get occupied units count
  int get occupiedUnitsCount => _units.where((u) => u.status == UnitStatus.occupied).length;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}