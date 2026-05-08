import 'package:flutter/foundation.dart';

@immutable
class Country {
  final String commonName;
  final String officialName;
  final String flagEmoji;
  final String region;
  final String subregion;
  final String capital;
  final int population;
  final double area;
  final List<String> currencies;
  final List<String> languages;
  final List<String> timezones;
  final String alpha3Code;

  const Country({
    required this.commonName,
    required this.officialName,
    required this.flagEmoji,
    required this.region,
    required this.subregion,
    required this.capital,
    required this.population,
    required this.area,
    required this.currencies,
    required this.languages,
    required this.timezones,
    required this.alpha3Code,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    final nameObj = json['name'] as Map<String, dynamic>? ?? {};
    final commonName = (nameObj['common'] as String?) ?? 'Unknown';
    final officialName = (nameObj['official'] as String?) ?? 'Unknown';

    final flagEmoji = (json['flag'] as String?) ?? '🏳';

    final region = (json['region'] as String?) ?? '';
    final subregion = (json['subregion'] as String?) ?? '';

    // capital is an array — take the first item
    final capitalList = json['capital'] as List<dynamic>?;
    final capital = (capitalList != null && capitalList.isNotEmpty)
        ? (capitalList.first as String?) ?? 'N/A'
        : 'N/A';

    final population = (json['population'] as int?) ?? 0;
    final area = ((json['area'] as num?) ?? 0).toDouble();

    // currencies is a map of code -> { name, symbol }
    final currenciesMap = json['currencies'] as Map<String, dynamic>?;
    final currencies = currenciesMap != null
        ? currenciesMap.entries.map((e) {
            final details = e.value as Map<String, dynamic>? ?? {};
            final name = (details['name'] as String?) ?? e.key;
            final symbol = (details['symbol'] as String?) ?? '';
            return symbol.isNotEmpty ? '$name ($symbol)' : name;
          }).toList()
        : <String>[];

    // languages is a map of code -> name
    final languagesMap = json['languages'] as Map<String, dynamic>?;
    final languages = languagesMap != null
        ? languagesMap.values.map((v) => (v as String?) ?? '').toList()
        : <String>[];

    final timezoneList = json['timezones'] as List<dynamic>?;
    final timezones = timezoneList != null
        ? timezoneList.map((t) => (t as String?) ?? '').toList()
        : <String>[];

    final alpha3Code = (json['cca3'] as String?) ?? '';

    return Country(
      commonName: commonName,
      officialName: officialName,
      flagEmoji: flagEmoji,
      region: region,
      subregion: subregion,
      capital: capital,
      population: population,
      area: area,
      currencies: currencies,
      languages: languages,
      timezones: timezones,
      alpha3Code: alpha3Code,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': {'common': commonName, 'official': officialName},
      'flag': flagEmoji,
      'region': region,
      'subregion': subregion,
      'capital': [capital],
      'population': population,
      'area': area,
      'currencies': currencies,
      'languages': languages,
      'timezones': timezones,
      'cca3': alpha3Code,
    };
  }

  Country copyWith({
    String? commonName,
    String? officialName,
    String? flagEmoji,
    String? region,
    String? subregion,
    String? capital,
    int? population,
    double? area,
    List<String>? currencies,
    List<String>? languages,
    List<String>? timezones,
    String? alpha3Code,
  }) {
    return Country(
      commonName: commonName ?? this.commonName,
      officialName: officialName ?? this.officialName,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      region: region ?? this.region,
      subregion: subregion ?? this.subregion,
      capital: capital ?? this.capital,
      population: population ?? this.population,
      area: area ?? this.area,
      currencies: currencies ?? this.currencies,
      languages: languages ?? this.languages,
      timezones: timezones ?? this.timezones,
      alpha3Code: alpha3Code ?? this.alpha3Code,
    );
  }
}
