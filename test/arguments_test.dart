import 'package:scriptr/src/utils/arguments.dart';
import 'package:test/test.dart';

void main() {
  group('CLI arguments parsing', () {
    test('parsing empty string', () {
      expect(() => getExecutableAndArguments(''), throwsArgumentError);
      expect(() => getExecutableAndArguments(' '), throwsArgumentError);
    });

    test('parsing string with single executable', () {
      const someExecutable = 'someExecutable.exe';
      final result = getExecutableAndArguments(someExecutable);
      expect(
        result.executable,
        equals(someExecutable),
      );
      expect(
        result.arguments,
        isEmpty,
      );
      expect(
        getExecutableAndArguments('some\\ Executable.exe').executable,
        equals('some Executable.exe'),
      );
      expect(
        getExecutableAndArguments('"some Executable.exe"').executable,
        equals('some Executable.exe'),
      );
      expect(
        getExecutableAndArguments('"some\\ Executable.exe"').executable,
        equals('some Executable.exe'),
      );
      expect(
        getExecutableAndArguments('"some\' Executable.exe"').executable,
        equals('some\' Executable.exe'),
      );
      expect(
        getExecutableAndArguments('\'some Executable.exe\'').executable,
        equals('some Executable.exe'),
      );
      expect(
        getExecutableAndArguments('\'some\\ Executable.exe\'').executable,
        equals('some Executable.exe'),
      );
      expect(
        getExecutableAndArguments('\'some" Executable.exe\'').executable,
        equals('some" Executable.exe'),
      );
    });

    test('parsing string with executable and arguments', () {
      final res1 = getExecutableAndArguments(
        'someExe --hello world alpha beta',
      );
      expect(res1.executable, 'someExe');
      expect(res1.arguments, ['--hello', 'world', 'alpha', 'beta']);
      final res2 = getExecutableAndArguments(
        'someExe  --hello  world  alpha  beta',
      );
      expect(res2.executable, 'someExe');
      expect(res2.arguments, ['--hello', 'world', 'alpha', 'beta']);
      final res3 = getExecutableAndArguments(
        'someExe  --hel\\ lo  "wor ld"  alp\\\'ha  \'beta\'',
      );
      expect(res3.executable, 'someExe');
      expect(res3.arguments, ['--hel lo', 'wor ld', 'alp\'ha', 'beta']);
    });
  });
}
