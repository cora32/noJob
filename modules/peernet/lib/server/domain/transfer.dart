import 'dart:convert';

class VersionData {
  final int dbVersion;
  final int dbTimestamp;

  VersionData({required this.dbVersion, required this.dbTimestamp});

  Map<String, dynamic> toJson() => {
    'dbVersion': dbVersion,
    'dbTimestamp': dbTimestamp,
  };

  factory VersionData.fromJson(String source) =>
      VersionData.fromMap(json.decode(source));

  factory VersionData.fromMap(Map<String, dynamic> map) => VersionData(
    dbVersion: map['dbVersion'] as int,
    dbTimestamp: map['dbTimestamp'] as int,
  );
}

class PeerData {
  final String ip;

  PeerData({required this.ip});
}
