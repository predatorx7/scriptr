import 'package:interpolation/interpolation.dart';

String interpolateValues(String template, Map<String, Object?> data) {
  final i = Interpolation(
    option: InterpolationOption(
      prefix: r'${',
    ),
  );

  return i.eval(template, data);
}
