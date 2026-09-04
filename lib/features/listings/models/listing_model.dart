class ListingModel {
  final String? id;
  final String ownerId;
  final String phone;
  final int rent;
  final int deposit;
  final String area;

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

  final String propertyKind;
  final String furnishingStatus;
  final String parkingType;
  final String propertyType;

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
      'owner_id': ownerId,
      'phone': phone,
      'rent': rent,
      'deposit': deposit,
      'area': area,
      'property_category': propertyCategory,
      'city': city,
      'sub_area': subArea,
      'landmark': landmark,
      'distance_km': distanceKm,
      'size_sqft': sizeSqft,
      'floor': floor,
      'occupancy': occupancy,
      'facilities': facilities,
      'allowed_tenants': allowedTenants,
      'restrictions': restrictions,
      'availability': availability,
      'property_kind': propertyKind,
      'furnishing_status': furnishingStatus,
      'parking_type': parkingType,
      'built_up_area': builtUpArea,
      'super_built_up_area': superBuiltUpArea,
      'plot_area': plotArea,
      'total_floors': totalFloors,
      'ceiling_height': ceilingHeight,
      'frontage': frontage,
      'road_width': roadWidth,
      'suitable_for': suitableFor,
      'utilities': utilities,
      'building_grade': buildingGrade,
      'building_age': buildingAge,
      'possession': possession,
      'ownership': ownership,
      'visibility': visibility,
      'room_type': roomType,
      'gender_pref': genderPref,
      'toilet_type': toiletType,
      'photos': photos,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'report_count': reportCount,
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
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

    double? parseNullableDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val == 0.0 ? null : val;
      if (val is int) return val == 0 ? null : val.toDouble();
      if (val is String) {
        final parsed = double.tryParse(val);
        return (parsed == null || parsed == 0.0) ? null : parsed;
      }
      return null;
    }

    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ListingModel(
      id: id,
      ownerId: (map['owner_id'] ?? map['ownerId'])?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      rent: parseInt(map['rent']),
      deposit: parseInt(map['deposit']),
      area: map['area']?.toString() ?? '',
      propertyCategory: (map['property_category'] ?? map['propertyCategory'])?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      subArea: (map['sub_area'] ?? map['subArea'])?.toString() ?? '',
      landmark: map['landmark']?.toString() ?? '',
      distanceKm: parseDouble(map['distance_km'] ?? map['distanceKm']),
      sizeSqft: parseInt(map['size_sqft'] ?? map['sizeSqft']),
      floor: map['floor']?.toString() ?? '',
      occupancy: parseInt(map['occupancy']) == 0 ? 1 : parseInt(map['occupancy']),
      facilities: parseList(map['facilities']),
      allowedTenants: parseList(map['allowed_tenants'] ?? map['allowedTenants']),
      restrictions: parseList(map['restrictions']),
      availability: map['availability']?.toString() ?? 'Immediate',
      propertyKind: (map['property_kind'] ?? map['propertyKind'])?.toString() ?? 'residential',
      furnishingStatus: (map['furnishing_status'] ?? map['furnishingStatus'])?.toString() ?? 'unfurnished',
      parkingType: (map['parking_type'] ?? map['parkingType'])?.toString() ?? 'none',
      builtUpArea: (map['built_up_area'] ?? map['builtUpArea'])?.toString() ?? '',
      superBuiltUpArea: (map['super_built_up_area'] ?? map['superBuiltUpArea'])?.toString() ?? '',
      plotArea: (map['plot_area'] ?? map['plotArea'])?.toString() ?? '',
      totalFloors: (map['total_floors'] ?? map['totalFloors'])?.toString() ?? '',
      ceilingHeight: (map['ceiling_height'] ?? map['ceilingHeight'])?.toString() ?? '',
      frontage: map['frontage']?.toString() ?? '',
      roadWidth: (map['road_width'] ?? map['roadWidth'])?.toString() ?? '',
      suitableFor: parseList(map['suitable_for'] ?? map['suitableFor']),
      utilities: parseList(map['utilities']),
      buildingGrade: (map['building_grade'] ?? map['buildingGrade'])?.toString() ?? '',
      buildingAge: (map['building_age'] ?? map['buildingAge'])?.toString() ?? '',
      possession: map['possession']?.toString() ?? '',
      ownership: map['ownership']?.toString() ?? '',
      visibility: parseList(map['visibility']),
      roomType: (map['room_type'] ?? map['roomType'])?.toString() ?? 'single',
      genderPref: (map['gender_pref'] ?? map['genderPref'])?.toString() ?? 'any',
      toiletType: (map['toilet_type'] ?? map['toiletType'])?.toString() ?? 'shared',
      photos: parseList(map['photos']),
      active: map['active'] == true,
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']),
      expiresAt: parseDateTime(map['expires_at'] ?? map['expiresAt']),
      lat: parseNullableDouble(map['lat']),
      lng: parseNullableDouble(map['lng']),
      reportCount: parseInt(map['report_count'] ?? map['reportCount']),
    );
  }
}
