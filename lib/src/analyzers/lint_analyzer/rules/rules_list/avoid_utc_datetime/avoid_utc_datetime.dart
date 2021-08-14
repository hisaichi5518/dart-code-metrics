import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../../../../../utils/node_utils.dart';
import '../../../models/internal_resolved_unit_result.dart';
import '../../../models/issue.dart';
import '../../../models/severity.dart';
import '../../models/rule.dart';
import '../../models/rule_documentation.dart';
import '../../rule_utils.dart';

const _details = '''
**AVOID** using Avoid UTC DateTime.

**BAD:**
```
DateTime.utc(2019);
DateTime(2019).toUtc();
timestamp.toDateTime();
DateTime.fromMicrosecondsSinceEpoch(..., isUtc: true);
DateTime.fromMillisecondsSinceEpoch(..., isUtc: true);
```
**GOOD:**
```
DateTime(2019);
DateTime(2019).toLocal();
timestamp.toDateTime().toLocal();
DateTime.fromMicrosecondsSinceEpoch(..., isUtc: false);
DateTime.fromMillisecondsSinceEpoch(..., isUtc: false);
```
''';

class AvoidUtcDateTimeRule extends Rule {
  static const String ruleId = 'avoid-utc-datetime';

  static const _warningMessage = "Don't Use DateTime.utc().";

  AvoidUtcDateTimeRule([Map<String, Object> config = const {}])
      : super(
          id: ruleId,
          documentation: const RuleDocumentation(
            name: 'Avoid utc datetime',
            brief: _details,
          ),
          severity: readSeverity(config, Severity.error),
          excludes: readExcludes(config),
        );

  @override
  Iterable<Issue> check(InternalResolvedUnitResult source) {
    final _visitor = _Visitor();

    source.unit.visitChildren(_visitor);

    return _visitor.errorNodes
        .map((parameter) => createIssue(
              rule: this,
              location: nodeLocation(
                node: parameter,
                source: source,
                withCommentOrMetadata: true,
              ),
              message: _warningMessage,
            ))
        .toList(growable: false);
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  final errorNodes = <AstNode>[];

  @override
  void visitConstructorName(ConstructorName node) {
    // DateTime.utc() を禁止する
    if (node.toSource() == 'DateTime.utc' &&
        node.staticElement?.library.name == 'dart.core') {
      errorNodes.add(node);
    }

    // isUtc: true の場合はエラー
    final hasIsUtc = node.parent?.childEntities
            .any((entity) => entity.toString().contains('isUtc: true')) ??
        false;
    if ((node.toSource() == 'DateTime.fromMillisecondsSinceEpoch' ||
            node.toSource() == 'DateTime.fromMicrosecondsSinceEpoch') &&
        hasIsUtc) {
      errorNodes.add(node);
    }
    super.visitConstructorName(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // DateTime#toUtc を呼ぶのを禁止する
    if (node.target?.staticType?.toString() == 'DateTime' &&
        node.methodName.name == 'toUtc' &&
        node.staticType?.element?.library?.name == 'dart.core') {
      errorNodes.add(node.methodName);
    }

    // Timestamp#toDateTime() の次に toLocal() が呼ばれていない場合はエラー
    if (node.target?.staticType?.toString() == 'Timestamp' &&
        node.methodName.name == 'toDateTime' &&
        !(node.parent.toString().contains(r'toDateTime().toLocal()') ||
            node.parent.toString().contains(r'toDateTime()?.toLocal()'))) {
      errorNodes.add(node);
    }

    super.visitMethodInvocation(node);
  }
}
