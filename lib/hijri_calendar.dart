library hijri;

import 'package:hijri/digits_converter.dart';
import 'hijri_array.dart';
import 'package:quiver/core.dart';

class HijriAndGregorianDate {
  late HijriDate hijriDate;
  late DateTime gregorianDate;
  late int? adjustDays;

  HijriAndGregorianDate.fromGregorianDate(DateTime date, int? offset) {
    gregorianDate = date;
    adjustDays = offset;
    if (adjustDays != null) {
      date = adjustDays! < 0 ?
        date.subtract(Duration(days: adjustDays! * -1)) :
        date.add(Duration(days: adjustDays!));
    }
    hijriDate = HijriDate().getHijriDate(date);
  }

  HijriAndGregorianDate.fromHijriDate(HijriDate hDate, int? offset) {
    hijriDate = hDate;
    adjustDays = offset;
    DateTime date = hijriDate.hijriToGregorian(hDate.hYear, hDate.hMonth, hDate.hDay);
    if (adjustDays != null) {
      date = adjustDays! > 0 ?
        date.subtract(Duration(days: adjustDays!)) :
        date.add(Duration(days: adjustDays! * -1));
    }
    gregorianDate = date;
  }


  bool isAfter(HijriAndGregorianDate other, bool _hijriHasPreference) {
    if (_hijriHasPreference) {
      if (hijriDate.hYear > other.hijriDate.hYear) {
        return true;
      } else if (hijriDate.hYear < other.hijriDate.hYear) {
        return false;
      } else if (hijriDate.hMonth > other.hijriDate.hMonth) {
        return true;
      } else if (hijriDate.hMonth < other.hijriDate.hMonth) {
        return false;
      } else if (hijriDate.hDay > other.hijriDate.hDay) {
        return true;
      } else {
        return false;
      }
    }else {
      return gregorianDate.isAfter(other.gregorianDate);
    }
  }

  bool isBefore(HijriAndGregorianDate other, bool _hijriHasPreference) {
    if (_hijriHasPreference) {
      if (hijriDate.hYear < other.hijriDate.hYear) {
        return true;
      } else if (hijriDate.hYear > other.hijriDate.hYear) {
        return false;
      } else if (hijriDate.hMonth < other.hijriDate.hMonth) {
        return true;
      } else if (hijriDate.hMonth > other.hijriDate.hMonth) {
        return false;
      } else if (hijriDate.hDay < other.hijriDate.hDay) {
        return true;
      } else {
        return false;
      }
    }else {
      return gregorianDate.isBefore(other.gregorianDate);
    }
  }

  bool isBeforeMonth(HijriAndGregorianDate month, bool _hijriHasPreference) {
    if (_hijriHasPreference) {
      if (hijriDate.hYear == month.hijriDate.hYear) {
        return hijriDate.hMonth < month.hijriDate.hMonth;
      } else {
        return isBefore(month, _hijriHasPreference);
      }
    } else {
      if (gregorianDate.year == month.gregorianDate.year) {
        return gregorianDate.month < month.gregorianDate.month;
      } else {
        return gregorianDate.isBefore(month.gregorianDate);
      }
    }
  }

  bool isAfterMonth(HijriAndGregorianDate month, bool _hijriHasPreference) {
    if (_hijriHasPreference) {
      if (hijriDate.hYear == month.hijriDate.hYear) {
        return hijriDate.hMonth > month.hijriDate.hMonth;
      } else {
        return isAfter(month, _hijriHasPreference);
      }
    } else {
      if (gregorianDate.year == month.gregorianDate.year) {
        return gregorianDate.month > month.gregorianDate.month;
      } else {
        return gregorianDate.isAfter(month.gregorianDate);
      }
    }
  }

  int weekday() {
    return gregorianDate.weekday;
  }

  HijriAndGregorianDate firstDayOfMonth(bool _hijriHasPreference) {
    if (_hijriHasPreference) {
      HijriDate tmp = hijriDate;
      tmp.hDay = 1;
      return HijriAndGregorianDate.fromHijriDate(tmp, adjustDays);
    } else {
      return HijriAndGregorianDate.fromGregorianDate(
          DateTime.utc(gregorianDate.year, gregorianDate.month, 1), adjustDays);
    }
  }

  HijriAndGregorianDate lastDayOfMonth(bool _hijriHasPreference) {
    if (_hijriHasPreference) {
      HijriDate tmp = hijriDate;
      tmp.hDay = tmp.lastDayOfHijriMonth();
      return HijriAndGregorianDate.fromHijriDate(tmp, adjustDays);
    } else {
      final date = gregorianDate.month < 12
          ? DateTime.utc(gregorianDate.year, gregorianDate.month + 1, 1)
          : DateTime.utc(gregorianDate.year + 1, 1, 1);
      return HijriAndGregorianDate.fromGregorianDate(date.subtract(const Duration(days: 1)),adjustDays);
    }
  }

}

class HijriAndGregorianDateRange {
  /// Creates a date range for the given start and end [HijriAndGregorianDateRange].
  HijriAndGregorianDateRange({
    required this.start,
    required this.end,
  }) : assert(start != null),
        assert(end != null),
        assert(!start.gregorianDate.isAfter(end.gregorianDate));

  /// The start of the range of dates.
  final HijriAndGregorianDate start;

  /// The end of the range of dates.
  final HijriAndGregorianDate end;

  /// Returns a [Duration] of the time between [start] and [end].
  ///
  /// See [DateTime.difference] for more details.
  Duration get duration => end.gregorianDate.difference(start.gregorianDate);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is HijriAndGregorianDateRange
        && other.start == start
        && other.end == end;
  }

  @override
  int get hashCode => hash2(start.hashCode, end.hashCode);

  @override
  String toString() => '$start.gregorianDate - $end.gregorianDate';

}

class HijriDate {
  late int hDay = 1;
  late int hMonth = 1;
  late int hYear = 1440;
  static late String language = 'en';
  late int? wkDay = null;
  Map<int, int>? adjustments = null;

  static Map<String, Map<String, Map<int, String>>> _local = {
    'en': {
      'long': monthNames,
      'short': monthShortNames,
      'days': wdNames,
      'short_days': shortWdNames
    },
    'ar': {
      'long': arMonthNames,
      'short': arMonthShortNames,
      'days': arWkNames,
      'short_days': arShortWdNames
    },
  };

  HijriDate({
    this.hDay = 1,
    this.hMonth = 1,
    this.hYear = 1400,
    language = 'en',
    this.wkDay = null,
    this.adjustments = null,
  });

  HijriDate.fromDate(DateTime date) {
    this.adjustments = null;
    language = 'en';

    HijriDate tmp = getHijriDate(date);
    this.hYear = tmp.hYear;
    this.hMonth = tmp.hMonth;
    this.hDay = tmp.hDay;
    this.wkDay = date.weekday;

  }

  HijriDate getHijriDate (DateTime date) {
    return this._gregorianToHijri(date);
  }

  int lastDayOfHijriMonth() {
    return _getDaysInMonth();
  }

  int _getDaysInMonth() {
    int i = _getNewMoonMJDNIndex(this.hYear, this.hMonth);
    return _ummalquraDataIndex(i)! - _ummalquraDataIndex(i - 1)!;
  }

  int _getNewMoonMJDNIndex(int hy, int hm) {
    int cYears = hy - 1, totalMonths = (cYears * 12) + 1 + (hm - 1);
    return totalMonths - 16260;
  }

  // Consider switching to the factory pattern
  factory HijriDate.setLocal(String locale) {
    language = locale;
    return HijriDate();
  }

  HijriDate.addLocale(String locale, Map<String, Map<int, String>> names) {
    _local[locale] = names;
  }

  @override
  String toString() {
    String dateFormat = "dd/mm/yyyy";
    if (language == "ar") dateFormat = "yyyy/mm/dd";

    return this._format(dateFormat);
  }

  String toFormat(String form) {
    return _format(form);
  }

  HijriDate _gregorianToHijri(DateTime date) {
    //This code the modified version of R.H. van Gent Code, it can be found at http://www.staff.science.uu.nl/~gent0113/islam/ummalqura.htm
    // read calendar data
    int day = date.day;
    int month = date.month; // Here we enter the Index of the month (which starts with Zero)
    int year = date.year;

    int m = month;
    int y = year;

    // append January and February to the previous year (i.e. regard March as
    // the first month of the year in order to simplify leapday corrections)
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    // determine offset between Julian and Gregorian calendar
    int a = (y / 100).floor();
    int jgc = a - (a / 4.0).floor() - 2;

    // compute Chronological Julian Day Number (CJDN)
    int cjdn = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day -
        jgc -
        1524;

    a = ((cjdn - 1867216.25) / 36524.25).floor();
    jgc = a - (a / 4.0).floor() + 1;
    int b = cjdn + jgc + 1524;
    int c = ((b - 122.1) / 365.25).floor();
    int d = (365.25 * c).floor();
    month = ((b - d) / 30.6001).floor();
    day = (b - d) - (30.6001 * month).floor();

    if (month > 13) {
      c += 1;
      month -= 12;
    }

    month -= 1;
    year = c - 4716;

    // compute Modified Chronological Julian Day Number (MCJDN)
    int mcjdn = cjdn - 2400000;

    // the MCJDN's of the start of the lunations in the Umm al-Qura calendar are stored in 'islamcalendar_dat.js'
    int i;
    for (i = 0; i < ummAlquraDateArray.length; i++) {
      if (_ummalquraDataIndex(i)! > mcjdn) break;
    }

    // compute and output the Umm al-Qura calendar date
    int iln = i + 16260;
    int ii = ((iln - 1) / 12).floor();
    int iy = ii + 1;
    int im = iln - 12 * ii;
    int id = mcjdn - _ummalquraDataIndex(i - 1)! + 1;
    int ml = _ummalquraDataIndex(i)! - _ummalquraDataIndex(i - 1)!;
    //lengthOfMonth = ml;
    // generalized modulo function (n mod m) also valid for negative values of n
    int wd = ((cjdn + 1 % 7) + 7) % 7;

    return HijriDate(hYear: iy, hMonth: im, hDay: id, wkDay: wd == 0 ? 7 : wd);
  }

  String _format(String newFormat) {
    late String dayString;
    late String monthString;
    late String yearString;

    if (language == 'ar') {
      dayString = DigitsConverter.convertWesternNumberToEastern(this.hDay);
      monthString = DigitsConverter.convertWesternNumberToEastern(this.hMonth);
      yearString = DigitsConverter.convertWesternNumberToEastern(this.hYear);
    } else {
      dayString = this.hDay.toString();
      monthString = this.hMonth.toString();
      yearString = this.hYear.toString();
    }

    if (newFormat.contains("dd")) {
      newFormat = newFormat.replaceFirst("dd", dayString);
    } else {
      if (newFormat.contains("d")) {
        newFormat = newFormat.replaceFirst("d", this.hDay.toString());
      }
    }

    //=========== Day Name =============//
    // Friday
    if (newFormat.contains("DDDD")) {
      newFormat = newFormat.replaceFirst(
          "DDDD", "${_local[language]!['days']![this.wkDay ?? this._weekDay()]}");

      // Fri
    } else if (newFormat.contains("DD")) {
      newFormat = newFormat.replaceFirst(
          "DD", "${_local[language]!['short_days']![this.wkDay ?? this._weekDay()]}");
    }

    //============== Month ========================//
    // 1
    if (newFormat.contains("mm")) {
      newFormat = newFormat.replaceFirst("mm", monthString);
    } else {
      newFormat = newFormat.replaceFirst("m", monthString);
    }

    // Muharram
    if (newFormat.contains("MMMM")) {
      newFormat =
          newFormat.replaceFirst("MMMM", _local[language]!['long']![this.hMonth]!);
    } else {
      if (newFormat.contains("MM")) {
        newFormat =
            newFormat.replaceFirst("MM", _local[language]!['short']![this.hMonth]!);
      }
    }

    //================= Year ========================//
    if (newFormat.contains("yyyy")) {
      newFormat = newFormat.replaceFirst("yyyy", yearString);
    } else {
      newFormat = newFormat.replaceFirst("yy", yearString.substring(2, 4));
    }
    return newFormat;
  }

  int? _ummalquraDataIndex(int index) {
    if (index < 0 || index >= ummAlquraDateArray.length) {
      throw ArgumentError(
          "Valid date should be between 1356 AH (14 March 1937 CE) to 1500 AH (16 November 2077 CE)");
    }

    if (this.adjustments != null && this.adjustments!.containsKey(index + 16260)) {
      return adjustments![index + 16260];
    }

    return ummAlquraDateArray[index];
  }

  int _weekDay() {
    DateTime wkDay = hijriToGregorian(this.hYear, this.hMonth, this.hDay);
    return wkDay.weekday;
  }

  DateTime hijriToGregorian(int year, int month, int day) {
    int iy = year;
    int im = month;
    int id = day;
    int ii = iy - 1;
    int iln = (ii * 12) + 1 + (im - 1);
    int i = iln - 16260;
    int mcjdn = id + _ummalquraDataIndex(i - 1)! - 1;
    int julianDate = mcjdn + 2400000;

    //source from: http://keith-wood.name/calendars.html
    int z = (julianDate + 0.5).floor();
    int a = ((z - 1867216.25) / 36524.25).floor();
    a = z + 1 + a - (a / 4).floor();
    int b = a + 1524;
    int c = ((b - 122.1) / 365.25).floor();
    int d = (365.25 * c).floor();
    int e = ((b - d) / 30.6001).floor();
    day = b - d - (e * 30.6001).floor();
    //var wd = _gMod(julianDate + 1, 7) + 1;
    month = e - (e > 13.5 ? 13 : 1);
    year = c - (month > 2.5 ? 4716 : 4715);
    if (year <= 0) {
      year--;
    } // No year zero

    return DateTime(year,month,day);
  }
}