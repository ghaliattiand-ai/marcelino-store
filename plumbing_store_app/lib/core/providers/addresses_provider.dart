import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Address {
  final String id;
  final String name;
  final String street;
  final String city;
  final String phone;
  final bool isDefault;

  const Address({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.phone,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'street': street,
    'city': city,
    'phone': phone,
    'isDefault': isDefault,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    name: json['name'] as String,
    street: json['street'] as String,
    city: json['city'] as String,
    phone: json['phone'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  Address copyWith({
    String? id,
    String? name,
    String? street,
    String? city,
    String? phone,
    bool? isDefault,
  }) => Address(
    id: id ?? this.id,
    name: name ?? this.name,
    street: street ?? this.street,
    city: city ?? this.city,
    phone: phone ?? this.phone,
    isDefault: isDefault ?? this.isDefault,
  );
}

class AddressesProvider extends ChangeNotifier {
  static const _key = 'user_addresses';
  final List<Address> _addresses = [];

  List<Address> get addresses => List.unmodifiable(_addresses);
  int get count => _addresses.length;
  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      _addresses
        ..clear()
        ..addAll(list.map((json) => Address.fromJson(json)));
    }
    notifyListeners();
  }

  Future<void> addAddress(Address address) async {
    _addresses.add(address);
    notifyListeners();
    await _save();
  }

  Future<void> updateAddress(Address updated) async {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _addresses[index] = updated;
      notifyListeners();
      await _save();
    }
  }

  Future<void> removeAddress(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> setDefault(String id) async {
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_addresses.map((a) => a.toJson()).toList()));
  }
}
