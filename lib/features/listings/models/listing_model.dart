import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String? id;
  final String ownerId;
  final String phone;
  final int rent;
  final int deposit;
  final String area;

  // Naye Fields (Jo UI me the par Model me nahi the)
  final String propertyCategory;
  final String city;
  final String subArea;
  final String landmark;
  final double distanceKm;
  final int sizeSqft;
  final String floor;
  final int occupancy;
  final List<String> facilities;
  final List<String> allowedTenants;
  final List<String> restrictions;
  final String availability;

  // Property Kind (Residential ya Commercial)
  final String propertyKind; // 'residential' | 'commercial'

  // Naye Property Fields (Residential)
  final String furnishingStatus;
  final String parkingType;
  final String propertyType;

  // Commercial Fields
  final String builtUpArea;
  final String superBuiltUpArea;
  final String plotArea;
  final String totalFloors;
  final String ceilingHeight;
  final String frontage;
  final String roadWidth;
  final List<String> suitableFor;
  final List<String> utilities;
  final String buildingGrade;
  final String buildingAge;
  final String possession;
  final String ownership;
  final List<String> visibility;

  // Purane Defaults
  final String roomType;
  final String genderPref;
  final String toiletType;
  final List<String> photos;
  final bool active;
  final DateTime createdAt;
  final DateTime expiresAt;
  final double? lat;
  final double? lng;
  final int reportCount;

  ListingModel({
    this.id,
    required this.ownerId,
    this.phone = '',
    required this.rent,
    required this.deposit,
    required this.area,
    this.propertyCategory = '',
    this.city = '',
    this.subArea = '',
    this.landmark = '',
    this.distanceKm = 0.0,
    this.sizeSqft = 0,
    this.floor = '',
    this.occupancy = 1,
    this.facilities = const [],
    this.allowedTenants = const [],
    this.restrictions = const [],
    this.availability = '',
    this.propertyKind = 'residential',
    this.furnishingStatus = 'unfurnished',
    this.parkingType = 'none',
    this.propertyType = '',
    this.builtUpArea = '',
    this.superBuiltUpArea = '',
    this.plotArea = '',
    this.totalFloors = '',
    this.ceilingHeight = '',
    this.frontage = '',
    this.roadWidth = '',
    this.suitableFor = const [],
    this.utilities = const [],
    this.buildingGrade = '',
    this.buildingAge = '',
    this.possession = '',
    this.ownership = '',
    this.visibility = const [],
    this.roomType = 'single',
    this.genderPref = 'any',
    this.toiletType = 'shared',
    this.photos = const [],
    this.active = true,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.lat,
    this.lng,
    this.reportCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 30));

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'phone': phone,
      'rent': rent,
      'deposit': deposit,
      'area': area,
      'propertyCategory': propertyCategory,
      'city': city,
      'subArea': subArea,
      'landmark': landmark,
      'distanceKm': distanceKm,
      'sizeSqft': sizeSqft,
      'floor': floor,
      'occupancy': occupancy,
      'facilities': facilities,
      'allowedTenants': allowedTenants,
      'restrictions': restrictions,
      'availability': availability,
      'propertyKind': propertyKind,
      'furnishingStatus': furnishingStatus,
      'parkingType': parkingType,
      'propertyType': propertyType,
      'builtUpArea': builtUpArea,
      'superBuiltUpArea': superBuiltUpArea,
      'plotArea': plotArea,
      'totalFloors': totalFloors,
      'ceilingHeight': ceilingHeight,
      'frontage': frontage,
      'roadWidth': roadWidth,
      'suitableFor': suitableFor,
      'utilities': utilities,
      'buildingGrade': buildingGrade,
      'buildingAge': buildingAge,
      'possession': possession,
      'ownership': ownership,
      'visibility': visibility,
      'roomType': roomType,
      'genderPref': genderPref,
      'toiletType': toiletType,
      'photos': photos,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'lat': lat,
      'lng': lng,
      'reportCount': reportCount,
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
    // 🔥 BULLETPROOF PARSERS: Koi field String ho ya Int, app crash nahi hoga!
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return ListingModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      rent: parseInt(map['rent']),
      deposit: parseInt(map['deposit']),
      area: map['area']?.toString() ?? '',
      propertyCategory: map['propertyCategory']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      subArea: map['subArea']?.toString() ?? '',
      landmark: map['landmark']?.toString() ?? '',
      distanceKm: parseDouble(map['distanceKm']),
      sizeSqft: parseInt(map['sizeSqft']),
      floor: map['floor']?.toString() ?? '',
      occupancy:
          parseInt(map['occupancy']) == 0 ? 1 : parseInt(map['occupancy']),
      facilities: parseList(map['facilities']),
      allowedTenants: parseList(map['allowedTenants']),
      restrictions: parseList(map['restrictions']),
      availability: map['availability']?.toString() ?? 'Immediate',
      propertyKind: map['propertyKind']?.toString() ?? 'residential',
      furnishingStatus: map['furnishingStatus']?.toString() ?? 'unfurnished',
      parkingType: map['parkingType']?.toString() ?? 'none',
      propertyType: map['propertyType']?.toString() ?? '',
      builtUpArea: map['builtUpArea']?.toString() ?? '',
      superBuiltUpArea: map['superBuiltUpArea']?.toString() ?? '',
      plotArea: map['plotArea']?.toString() ?? '',
      totalFloors: map['totalFloors']?.toString() ?? '',
      ceilingHeight: map['ceilingHeight']?.toString() ?? '',
      frontage: map['frontage']?.toString() ?? '',
      roadWidth: map['roadWidth']?.toString() ?? '',
      suitableFor: parseList(map['suitableFor']),
      utilities: parseList(map['utilities']),
      buildingGrade: map['buildingGrade']?.toString() ?? '',
      buildingAge: map['buildingAge']?.toString() ?? '',
      possession: map['possession']?.toString() ?? '',
      ownership: map['ownership']?.toString() ?? '',
      visibility: parseList(map['visibility']),
      roomType: map['roomType']?.toString() ?? 'single',
      genderPref: map['genderPref']?.toString() ?? 'any',
      toiletType: map['toiletType']?.toString() ?? 'shared',
      photos: parseList(map['photos']),
      active: map['active'] == true || map['status'] == 'active',
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null && map['expiresAt'] is Timestamp
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      lat: parseDouble(map['lat']),
      lng: parseDouble(map['lng']),
      reportCount: parseInt(map['reportCount']),
    );
  }
}
