import 'package:ansicolor/ansicolor.dart';
import 'package:source_span/source_span.dart';

import '../../../../../utils/string_extension.dart';
import '../../../metrics/models/metric_value.dart';
import '../../../metrics/models/metric_value_level.dart';
import '../../../models/issue.dart';
import '../../../models/severity.dart';

class LintConsoleReporterHelper {
  static final _colorPens = {
    MetricValueLevel.alarm: AnsiPen()..red(),
    MetricValueLevel.warning: AnsiPen()..yellow(),
    MetricValueLevel.noted: AnsiPen()..blue(),
    MetricValueLevel.none: AnsiPen()..white(),
  };

  static const _humanReadableLabel = {
    MetricValueLevel.alarm: 'ALARM',
    MetricValueLevel.warning: 'WARNING',
    MetricValueLevel.noted: 'NOTED',
    MetricValueLevel.none: '',
  };

  final _severityPens = {
    Severity.error: AnsiPen()..red(bold: true),
    Severity.warning: AnsiPen()..yellow(bold: true),
    Severity.performance: AnsiPen()..cyan(),
    Severity.style: AnsiPen()..blue(),
    Severity.none: AnsiPen()..white(),
  };

  String getIssueMessage(Issue issue, String severity) {
    final position = _getPosition(issue.location);
    final rule = [issue.ruleId, issue.documentation].join(' ');

    return '$severity${[issue.message, position, rule].join(' : ')}';
  }

  String getSeverity(Severity severity) {
    final color = _severityPens[severity];

    if (color != null) {
      return color(_normalize(
        severity != Severity.none ? severity.toString().capitalize() : '',
      ));
    }

    throw StateError('Unexpected severity.');
  }

  String getMetricReport(MetricValue<num> metric, String humanReadableName) {
    final color = _colorPens[metric.level];

    if (color != null) {
      final value = metric.value.toInt();

      return '$humanReadableName: ${color('$value')}';
    }

    throw StateError('Unexpected violation level.');
  }

  String getMetricMessage(
    MetricValueLevel violationLevel,
    String source,
    Iterable<String> violations,
  ) {
    final color = _colorPens[violationLevel];
    final label = _humanReadableLabel[violationLevel];

    if (color != null && label != null) {
      final normalizedLabel = _normalize(label);

      return '${color(normalizedLabel)}$source - ${violations.join(', ')}';
    }

    throw StateError('Unexpected violation level.');
  }

  String _getPosition(SourceSpan location) =>
      '${location.start.line}:${location.start.column}';

  String _normalize(String s) => s.padRight(8);
}
