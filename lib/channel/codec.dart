//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of beacons;

class _Codec {
  static BeaconsResult decodeResult(String data) =>
      _JsonCodec.resultFromJson(json.decode(data));

  static RangingResult decodeRangingResult(String data) =>
      _JsonCodec.rangingResultFromJson(json.decode(data));

  static MonitoringResult decodeMonitoringResult(String data) =>
      _JsonCodec.monitoringResultFromJson(json.decode(data));

  static String encodePermission(LocationPermission permission) =>
      platformSpecific(
        android: _Codec.encodeEnum(permission.android),
        ios: _Codec.encodeEnum(permission.ios),
      );

  static String encodeStatusRequest(_StatusRequest request) =>
      json.encode(_JsonCodec.statusRequestToJson(request));

  static String encodeDataRequest(_DataRequest request) =>
      json.encode(_JsonCodec.dataRequestToJson(request));

  static String encodeEnum(dynamic value) {
    return value.toString().split('.').last;
  }

  // see: https://stackoverflow.com/questions/49611724/dart-how-to-json-decode-0-as-double
  static double parseJsonNumber(dynamic value) {
    return value.runtimeType == int ? (value as int).toDouble() : value;
  }

  static String platformSpecific({
    @required String android,
    @required String ios,
  }) {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else {
      throw new BeaconsException(
          'Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}

class _JsonCodec {
  static BeaconsResult resultFromJson(Map<String, dynamic> json) =>
      new BeaconsResult._(
        json['isSuccessful'],
        json['error'] != null ? resultErrorFromJson(json['error']) : null,
      );

  static BeaconsResultError resultErrorFromJson(Map<String, dynamic> json) {
    final BeaconsResultErrorType type = _mapResultErrorTypeJson(json['type']);

    final BeaconsResultError error = new BeaconsResultError._(
      type,
      json['message'],
      null,
    );

    if (json.containsKey('fatal') && json['fatal']) {
      throw new BeaconsException(error.message);
    }

    return error;
  }

  static RangingResult rangingResultFromJson(Map<String, dynamic> json) =>
      new RangingResult._(
        json['isSuccessful'],
        json['error'] != null ? resultErrorFromJson(json['error']) : null,
        json['region'] != null ? beaconRegionFromJson(json['region']) : null,
        json['data'] != null
            ? (json['data'] as List<dynamic>)
                .map((it) => beaconFromJson(it as Map<String, dynamic>))
                .toList()
            : null,
      );

  static MonitoringResult monitoringResultFromJson(Map<String, dynamic> json) =>
      new MonitoringResult._(
        json['isSuccessful'],
        json['error'] != null ? resultErrorFromJson(json['error']) : null,
        json['region'] != null ? beaconRegionFromJson(json['region']) : null,
        json['data'] != null ? monitoringEventFromJson(json['data']) : null,
      );

  static Beacon beaconFromJson(Map<String, dynamic> json) => new Beacon._(
      json['proximityUUID'],
      json['major'],
      json['minor'],
      _Codec.parseJsonNumber(json['accuracy']),
      json['rssi'],
      proximityFromJson(json['proximity']));

  static BeaconRegion beaconRegionFromJson(Map<String, dynamic> json) =>
      new BeaconRegion(
        proximityUUID: json['proximityUUID'],
        identifier: json['identifier'],
        major: json['major'],
        minor: json['minor'],
      );

  static BeaconProximity proximityFromJson(String jsonValue) {
    switch (jsonValue) {
      case 'unknown':
        return BeaconProximity.unknown;
      case 'immediate':
        return BeaconProximity.immediate;
      case 'near':
        return BeaconProximity.near;
      case 'far':
        return BeaconProximity.far;
      default:
        assert(false, 'cannot parse json to BeaconProximity: $jsonValue');
        return null;
    }
  }

  static MonitoringEvent monitoringEventFromJson(String jsonValue) {
    switch (jsonValue) {
      case 'enter':
        return MonitoringEvent.enter;
      case 'exit':
        return MonitoringEvent.exit;
      default:
        assert(false, 'cannot parse json to MonitoringEvent: $jsonValue');
        return null;
    }
  }

  static Map<String, dynamic> statusRequestToJson(_StatusRequest request) => {
        'ranging': request.ranging,
        'monitoring': request.monitoring,
        'permission': _Codec.encodePermission(request.permission),
      };

  static Map<String, dynamic> dataRequestToJson(_DataRequest request) => {
        'region': regionToJson(request.region),
        'permission': _Codec.encodePermission(request.permission),
        'inBackground': request.inBackground,
      };

  static Map<String, dynamic> regionToJson(BeaconRegion region) => {
        'proximityUUID': region.proximityUUID,
        'identifier': region.identifier,
        'major': region.major,
        'minor': region.minor,
      };
}