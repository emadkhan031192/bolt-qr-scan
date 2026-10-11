// Official GS1 prefix table: 3-digit prefix string -> country/region name.
// Pure Dart: no Flutter imports.

/// Individual (non-range) GS1 prefix assignments.
const Map<String, String> _gs1SingleCodes = <String, String>{
  '380': 'GS1 Bulgaria',
  '383': 'GS1 Slovenia',
  '385': 'GS1 Croatia',
  '387': 'GS1 Bosnia and Herzegovina',
  '389': 'GS1 Montenegro',
  '390': 'GS1 Italy',
  '470': 'GS1 Kyrgyzstan',
  '471': 'GS1 Taiwan',
  '474': 'GS1 Estonia',
  '475': 'GS1 Latvia',
  '476': 'GS1 Azerbaijan',
  '477': 'GS1 Lithuania',
  '478': 'GS1 Uzbekistan',
  '479': 'GS1 Sri Lanka',
  '480': 'GS1 Philippines',
  '481': 'GS1 Belarus',
  '482': 'GS1 Ukraine',
  '483': 'GS1 Turkmenistan',
  '484': 'GS1 Mongolia',
  '485': 'GS1 Armenia',
  '486': 'GS1 Georgia',
  '487': 'GS1 Kazakhstan',
  '488': 'GS1 Tajikistan',
  '489': 'GS1 Hong Kong',
  '528': 'GS1 Lebanon',
  '529': 'GS1 Cyprus',
  '531': 'GS1 North Macedonia',
  '535': 'GS1 Malta',
  '539': 'GS1 Ireland',
  '560': 'GS1 Portugal',
  '569': 'GS1 Iceland',
  '590': 'GS1 Poland',
  '594': 'GS1 Romania',
  '599': 'GS1 Hungary',
  '603': 'GS1 Ghana',
  '604': 'GS1 Senegal',
  '608': 'GS1 Bahrain',
  '609': 'GS1 Mauritius',
  '611': 'GS1 Morocco',
  '613': 'GS1 Algeria',
  '615': 'GS1 Nigeria',
  '616': 'GS1 Kenya',
  '618': 'GS1 Ivory Coast',
  '619': 'GS1 Tunisia',
  '620': 'GS1 Tanzania',
  '621': 'GS1 Syria',
  '622': 'GS1 Egypt',
  '623': 'GS1 Brunei',
  '624': 'GS1 Libya',
  '625': 'GS1 Jordan',
  '626': 'GS1 Iran',
  '627': 'GS1 Kuwait',
  '628': 'GS1 Saudi Arabia',
  '629': 'GS1 UAE',
  '630': 'GS1 Qatar',
  '631': 'GS1 Namibia',
  '632': 'GS1 Rwanda',
  '729': 'GS1 Israel',
  '740': 'GS1 Guatemala',
  '741': 'GS1 El Salvador',
  '742': 'GS1 Honduras',
  '743': 'GS1 Nicaragua',
  '744': 'GS1 Costa Rica',
  '745': 'GS1 Panama',
  '746': 'GS1 Dominican Republic',
  '750': 'GS1 Mexico',
  '759': 'GS1 Venezuela',
  '773': 'GS1 Uruguay',
  '775': 'GS1 Peru',
  '777': 'GS1 Bolivia',
  '780': 'GS1 Chile',
  '784': 'GS1 Paraguay',
  '785': 'GS1 Peru',
  '786': 'GS1 Ecuador',
  '850': 'GS1 Cuba',
  '858': 'GS1 Slovakia',
  '859': 'GS1 Czechia',
  '860': 'GS1 Serbia',
  '865': 'GS1 Mongolia',
  '867': 'GS1 North Korea',
  '880': 'GS1 South Korea',
  '884': 'GS1 Cambodia',
  '885': 'GS1 Thailand',
  '888': 'GS1 Singapore',
  '890': 'GS1 India',
  '893': 'GS1 Vietnam',
  '894': 'GS1 Bangladesh',
  '899': 'GS1 Indonesia',
  '950': 'GS1 Global Office',
  '951': 'GS1 Global Office',
  '955': 'GS1 Malaysia',
  '958': 'GS1 Macau',
  '962': 'GS1 Global Office',
  '969': 'GS1 Pakistan',
  '977': 'ISSN (serials)',
  '980': 'GS1 Global Office',
};

/// Look up the country/region name for a 3-digit GS1 prefix string.
///
/// Covers the complete official table, including the assigned ranges
/// (000-139, 200-299, 300-379, 400-440, 450-459, 490-499, 500-509, 520-521,
/// 540-549, 570-579, 600-601, 640-649, 690-699, 700-709, 730-739, 754-755,
/// 760-769, 770-771, 778-779, 789-790, 800-839, 840-849, 868-869, 870-879,
/// 900-919, 930-939, 940-949, 960-961, 978-979, 981-983, 990-999).
/// Returns null for unassigned prefixes.
String? gs1Country(String prefix3) {
  if (prefix3.length != 3) return null;
  final int? code = int.tryParse(prefix3);
  if (code == null) return null;

  if (_inRange(code, 0, 19)) return 'GS1 US';
  if (_inRange(code, 20, 29)) return 'Restricted distribution';
  if (_inRange(code, 30, 39)) return 'GS1 US';
  if (_inRange(code, 40, 49)) return 'Restricted distribution';
  if (_inRange(code, 50, 59)) return 'Coupons';
  if (_inRange(code, 60, 139)) return 'GS1 US';
  if (_inRange(code, 200, 299)) return 'Restricted distribution';
  if (_inRange(code, 300, 379)) return 'GS1 France';
  if (_inRange(code, 400, 440)) return 'GS1 Germany';
  if (_inRange(code, 450, 459)) return 'GS1 Japan';
  if (_inRange(code, 460, 469)) return 'GS1 Russia';
  if (_inRange(code, 490, 499)) return 'GS1 Japan';
  if (_inRange(code, 500, 509)) return 'GS1 UK';
  if (_inRange(code, 520, 521)) return 'GS1 Greece';
  if (_inRange(code, 540, 549)) return 'GS1 Belgium & Luxembourg';
  if (_inRange(code, 570, 579)) return 'GS1 Denmark';
  if (_inRange(code, 600, 601)) return 'GS1 South Africa';
  if (_inRange(code, 640, 649)) return 'GS1 Finland';
  if (_inRange(code, 690, 699)) return 'GS1 China';
  if (_inRange(code, 700, 709)) return 'GS1 Norway';
  if (_inRange(code, 730, 739)) return 'GS1 Sweden';
  if (_inRange(code, 754, 755)) return 'GS1 Canada';
  if (_inRange(code, 760, 769)) return 'GS1 Switzerland';
  if (_inRange(code, 770, 771)) return 'GS1 Colombia';
  if (_inRange(code, 778, 779)) return 'GS1 Argentina';
  if (_inRange(code, 789, 790)) return 'GS1 Brazil';
  if (_inRange(code, 800, 839)) return 'GS1 Italy';
  if (_inRange(code, 840, 849)) return 'GS1 Spain';
  if (_inRange(code, 868, 869)) return 'GS1 Turkey';
  if (_inRange(code, 870, 879)) return 'GS1 Netherlands';
  if (_inRange(code, 900, 919)) return 'GS1 Austria';
  if (_inRange(code, 930, 939)) return 'GS1 Australia';
  if (_inRange(code, 940, 949)) return 'GS1 New Zealand';
  if (_inRange(code, 960, 961)) return 'GS1 UK Office';
  if (_inRange(code, 978, 979)) return 'Bookland (ISBN books)';
  if (_inRange(code, 981, 983)) return 'GS1 coupons';
  if (_inRange(code, 990, 999)) return 'GS1 coupons';

  return _gs1SingleCodes[prefix3];
}

/// True when [code] lies within [start]..[end] inclusive.
bool _inRange(int code, int start, int end) => code >= start && code <= end;
