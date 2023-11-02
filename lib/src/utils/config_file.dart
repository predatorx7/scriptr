import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scriptr/src/logging.dart';
import 'package:yaml/yaml.dart';

import '../errors.dart';
import '../flags.dart';

const defaultConfigFileNames = <String>[
  'scriptr.yaml',
  'scriptr.yml',
  'scriptr.json',
];

final logger = mainLogger('scriptr_utils.dart');

bool hasValidConfigFileExtension(String path) {
  final lowerCasedPath = path.toLowerCase();
  return defaultConfigFileNames.any((ext) {
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

Future<String> getConfigContentFromUri(String uri) async {
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

Future<String> getConfigContentFromCurrentDirectory() async {
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
    'Could not find a default config file in the current directory.',
  );
}

Future<String> getConfigContentFromArgs(List<String> args) async {
  final log = logger('getScriptContentFromArgs');
  for (final maybeConfigFileName in args) {
    log.finest('Checking if `$maybeConfigFileName` is a config file');
    // Flags are allowed at any position. If this is a flag, then we continue
    // checking next arguments.
    if (isMaybeFlag(maybeConfigFileName)) continue;
    // If this isn't a flag, and doesn't have correct file extension then this
    // could be arguments for script file in current directory. We break here because
    // config file cannot be in the arguments after this.
    if (!hasValidConfigFileExtension(maybeConfigFileName)) break;
    final configFileName = maybeConfigFileName;
    log.finer('`$configFileName` has a valid config extension');
    return getConfigContentFromUri(configFileName);
  }
  throw ConfigNotFound(
    'Could not find a valid config file path in command line arguments.',
  );
}

/// Finds the correct script file using arguments, current location where scriptr is executed, and returns that script file's contents
Future<String> getConfigContent([
  List<String>? args,
]) async {
  String? scriptContent;

  final errors = <ScriptrError>[];

  if (args != null && args.isNotEmpty) {
    try {
      scriptContent = await getConfigContentFromArgs(args);
    } on ScriptrError catch (e) {
      errors.add(e);
    }
  }
  if (scriptContent == null) {
    try {
      scriptContent = await getConfigContentFromCurrentDirectory();
    } on ScriptrError catch (e) {
      errors.add(e);
    }
  }
  if (scriptContent == null) {
    throw ScriptrError.merge(
      errors,
      reason: 'No valid script found in arguments or current directory',
      lastMessage:
          '! Scriptr config file can be named ${defaultConfigFileNames.join(", ")}',
    );
  }
  return scriptContent;
}

/// Returns [Map] after parsing [content] as yaml or json.
Map<String, Object?> getConfigContentAsMap(String content) {
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
