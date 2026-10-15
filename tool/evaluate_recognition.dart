import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:steviai/features/recognition/domain/recognition_evaluation.dart';

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.showHelp) {
    stdout.writeln(_Options.usage);
    return;
  }

  final config = await _readObject(options.configPath, label: 'config');
  final manifest = await _readObject(options.manifestPath, label: 'manifest');
  final endpoint = _requiredString(
    config,
    'STEV_RECOGNITION_ENDPOINT',
    options.configPath,
  );
  final supabaseUrl = _requiredString(
    config,
    'SUPABASE_URL',
    options.configPath,
  );
  final apiKey = _requiredString(
    config,
    'SUPABASE_PUBLISHABLE_KEY',
    options.configPath,
  );
  final token = config['STEV_RECOGNITION_TOKEN'] as String?;
  final catalogIds = await _loadCatalogIds(supabaseUrl, apiKey);
  final cases = _parseCases(manifest, options.manifestPath);
  final manifestDirectory = File(options.manifestPath).absolute.parent;
  final client = http.Client();
  final outcomes = <RecognitionEvaluationOutcome>[];

  stdout.writeln(
    'Evaluating ${cases.length} cases against ${catalogIds.length} catalog drinks...',
  );
  try {
    for (var index = 0; index < cases.length; index++) {
      final testCase = cases[index];
      final image = File(
        _resolveImagePath(manifestDirectory, testCase.imagePath),
      );
      final stopwatch = Stopwatch()..start();
      List<String> predictedIds = const [];
      String? error;
      try {
        final bytes = await image.readAsBytes();
        final response = await client
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'apikey': apiKey,
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'imageBase64': base64Encode(bytes),
                'mimeType': _mimeType(bytes, image.path),
                'catalogIds': catalogIds,
              }),
            )
            .timeout(Duration(seconds: options.timeoutSeconds));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          error = 'HTTP ${response.statusCode}: ${response.body}';
        } else {
          predictedIds = _candidateIds(response.body);
        }
      } catch (exception) {
        error = exception.toString();
      } finally {
        stopwatch.stop();
      }

      final outcome = RecognitionEvaluationOutcome(
        testCase: RecognitionEvaluationCase(
          id: testCase.id,
          expectedDrinkId: testCase.expectedDrinkId,
        ),
        predictedIds: predictedIds,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: error,
      );
      outcomes.add(outcome);
      final result = error != null
          ? 'ERROR'
          : testCase.expectedDrinkId == null
          ? (predictedIds.isEmpty ? 'REJECTED' : 'FALSE POSITIVE')
          : (predictedIds.firstOrNull == testCase.expectedDrinkId
                ? 'TOP-1'
                : predictedIds.contains(testCase.expectedDrinkId)
                ? 'TOP-3'
                : 'MISS');
      stdout.writeln(
        '[${index + 1}/${cases.length}] ${testCase.id}: $result '
        '(${stopwatch.elapsedMilliseconds} ms)',
      );
    }
  } finally {
    client.close();
  }

  final report = RecognitionEvaluationReport.fromOutcomes(outcomes);
  final reportJson = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'endpoint': endpoint,
    'manifest': File(options.manifestPath).absolute.path,
    'metrics': report.toJson(),
    'outcomes': [
      for (final outcome in outcomes)
        {
          'id': outcome.testCase.id,
          'expectedDrinkId': outcome.testCase.expectedDrinkId,
          'predictedIds': outcome.predictedIds,
          'latencyMs': outcome.latencyMs,
          'error': outcome.error,
        },
    ],
  };
  final output = File(options.outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsString(
    const JsonEncoder.withIndent('  ').convert(reportJson),
  );

  stdout
    ..writeln('')
    ..writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()))
    ..writeln('Report written to ${output.absolute.path}');
  if (report.requestErrors > 0) exitCode = 2;
}

Future<List<String>> _loadCatalogIds(String supabaseUrl, String apiKey) async {
  final url = Uri.parse('$supabaseUrl/rest/v1/drinks')
      .replace(queryParameters: {'select': 'id', 'verified': 'eq.true'});
  final response = await http.get(url, headers: {'apikey': apiKey});
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw FormatException(
      'Catalog request failed (${response.statusCode}): ${response.body}',
    );
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! List) throw const FormatException('Catalog is not a list.');
  final ids = decoded
      .whereType<Map>()
      .map((row) => row['id'])
      .whereType<String>()
      .toSet()
      .toList(growable: false);
  if (ids.isEmpty) throw const FormatException('Published catalog is empty.');
  return ids;
}

Future<Map<String, dynamic>> _readObject(
  String path, {
  required String label,
}) async {
  final decoded = jsonDecode(await File(path).readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$label must contain a JSON object.');
  }
  return decoded;
}

String _requiredString(Map<String, dynamic> object, String key, String path) {
  final value = object[key];
  if (value is! String || value.isEmpty || value.contains('YOUR_')) {
    throw FormatException('$key is missing or still a placeholder in $path.');
  }
  return value;
}

List<_ManifestCase> _parseCases(Map<String, dynamic> manifest, String path) {
  final rawCases = manifest['cases'];
  if (rawCases is! List || rawCases.isEmpty) {
    throw FormatException('$path must contain a non-empty cases list.');
  }
  return rawCases
      .map((raw) {
        if (raw is! Map || raw['id'] is! String || raw['image'] is! String) {
          throw FormatException(
            'Every case in $path needs string id and image.',
          );
        }
        final expected = raw['expectedDrinkId'];
        if (expected != null && expected is! String) {
          throw FormatException('expectedDrinkId must be a string or null.');
        }
        return _ManifestCase(
          id: raw['id'] as String,
          imagePath: raw['image'] as String,
          expectedDrinkId: expected as String?,
        );
      })
      .toList(growable: false);
}

List<String> _candidateIds(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map || decoded['candidates'] is! List) {
    throw const FormatException('Response has no candidates list.');
  }
  return (decoded['candidates'] as List)
      .whereType<Map>()
      .map((candidate) => candidate['id'])
      .whereType<String>()
      .take(3)
      .toList(growable: false);
}

String _resolveImagePath(Directory base, String path) {
  if (File(path).isAbsolute) return path;
  return '${base.path}${Platform.pathSeparator}$path';
}

String _mimeType(Uint8List bytes, String path) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
    return 'image/webp';
  }
  if (path.toLowerCase().endsWith('.heic')) return 'image/heic';
  return 'image/jpeg';
}

class _ManifestCase {
  const _ManifestCase({
    required this.id,
    required this.imagePath,
    required this.expectedDrinkId,
  });

  final String id;
  final String imagePath;
  final String? expectedDrinkId;
}

class _Options {
  const _Options({
    required this.configPath,
    required this.manifestPath,
    required this.outputPath,
    required this.timeoutSeconds,
    required this.showHelp,
  });

  static const usage = '''
Usage:
  dart run tool/evaluate_recognition.dart [options]

Options:
  --config <path>    Environment JSON (default: config/env.local.json)
  --manifest <path>  Evaluation manifest (default: tool/recognition_dataset/manifest.json)
  --output <path>    JSON report (default: build/recognition-evaluation/report.json)
  --timeout <sec>    Per-image timeout (default: 30)
  --help             Show this help
''';

  final String configPath;
  final String manifestPath;
  final String outputPath;
  final int timeoutSeconds;
  final bool showHelp;

  static _Options parse(List<String> arguments) {
    var config = 'config/env.local.json';
    var manifest = 'tool/recognition_dataset/manifest.json';
    var output = 'build/recognition-evaluation/report.json';
    var timeout = 30;
    var help = false;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') {
        help = true;
        continue;
      }
      if (!argument.startsWith('--') || index + 1 >= arguments.length) {
        throw FormatException('Unknown or incomplete option: $argument');
      }
      final value = arguments[++index];
      switch (argument) {
        case '--config':
          config = value;
        case '--manifest':
          manifest = value;
        case '--output':
          output = value;
        case '--timeout':
          timeout = int.parse(value);
          if (timeout <= 0) throw const FormatException('Timeout must be > 0.');
        default:
          throw FormatException('Unknown option: $argument');
      }
    }
    return _Options(
      configPath: config,
      manifestPath: manifest,
      outputPath: output,
      timeoutSeconds: timeout,
      showHelp: help,
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
