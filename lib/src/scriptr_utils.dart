import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scriptr/src/logging.dart';
import 'package:yaml/yaml.dart';

import 'errors.dart';

const supportedConfigExtensions = <String>[
  'yaml',
  'yml',
  'json',
];

const defaultConfigFileNames = <String>[
  'scriptr.yaml',
  'scriptr.yml',
  'scriptr.json',
];

final logger = logging('scriptr_utils.dart');

bool hasValidConfigFileExtension(String path) {
  final lowerCasedPath = path.toLowerCase();
  return supportedConfigExtensions.any((ext) {
    return lowerCasedPath.endsWith(ext);
  });
}

bool isValidConfigFileName(String path) {
  final comparablePath = path.toLowerCase().trim();
  return defaultConfigFileNames.contains(comparablePath);
}

Future<String?> getContentsFromFile(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsString();
}

Future<String?> getContentsFromNetwork(String path) async {
  final url = Uri.parse(path);
  final response = await http.get(url);
  final statusCode = response.statusCode;
  if (statusCode < 200 || statusCode >= 300 || response.body.isEmpty) {
    return null;
  }

  return response.body;
}

Future<String> getScriptContentFromUri(String uri) async {
  if (uri.contains('http')) {
    final networkFileContent = await getContentsFromNetwork(uri);
    if (networkFileContent != null) {
      return networkFileContent;
    }
  } else {
    final fileSystemEntityContent = await getContentsFromFile(uri);
    if (fileSystemEntityContent != null) {
      return fileSystemEntityContent;
    }
  }
  throw ConfigNotFound('Could not find config at "$uri"');
}

Future<String> getScriptContentFromCurrentDirectory() async {
  final files = Directory.current.listSync().whereType<File>().where((entity) {
    return hasValidConfigFileExtension(entity.path);
  }).where((entity) {
    return isValidConfigFileName(entity.path);
  });
  for (final file in files) {
    final data = await getContentsFromFile(file.path);
    if (data != null) {
      return data;
    }
  }
  throw ConfigNotFound(
    'Could not find a default config file in the current directory. Default files can be named ${defaultConfigFileNames.join(", ")}.',
  );
}

Future<String?> getScriptContentFromArgs(List<String> args) async {
  final log = logger('getScriptContentFromArgs');
  if (args.isEmpty) return null;
  final configFileName = args.first;

  log.finest('Testing `$configFileName` for config file');
  if (!configFileName.startsWith('-')) {
    if (hasValidConfigFileExtension(configFileName)) {
      log.finer('`$configFileName` has a valid config extension');
      return getScriptContentFromUri(configFileName);
    }
  }

  return null;
}

Future<String> getScriptContent([
  List<String>? args,
]) async {
  String? scriptContent =
      args != null ? await getScriptContentFromArgs(args) : null;
  scriptContent ??= await getScriptContentFromCurrentDirectory();
  return scriptContent;
}

Map<String, Object?> getScriptContentAsMap(String content) {
  final log = logger('getScriptContentAsMap');
  final couldBeJson = content.trimLeft().startsWith('{');
  log.finest('Could this script content be json?: $couldBeJson');

  if (couldBeJson) {
    try {
      return json.decode(content);
    } catch (e, s) {
      log.fine('Failed to decode data as json', e, s);
    }
  }

  try {
    final map = loadYaml(content);
    if (map is Map<String, Object?>) {
      // will be supported in future
      return map;
    } else if (map is YamlMap) {
      // .castAsMap()
      return yamlToMap(map);
    }
    throw ArgumentError.value(
      'Yaml config must always have a root key-value data',
    );
  } catch (e, s) {
    log.fine('Failed to decode file as YAML', e, s);
  }

  throw InvalidConfig('Failed to decode the config');
}

Map<String, Object?> yamlToMap(YamlMap map) {
  final data = <String, Object>{...map.cast<String, Object>()};
  for (final key in data.keys) {
    final value = data[key];
    if (value is YamlMap) {
      data[key] = yamlToMap(value);
    }
  }
  return data;
}
