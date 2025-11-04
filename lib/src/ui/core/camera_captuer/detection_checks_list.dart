import 'package:flutter/material.dart';
import 'package:skaletek_kyc/src/models/kyc_api_models.dart';

class DetectionChecksList extends StatelessWidget {
  final DetectionChecks detectionChecks;
  final double top;
  final String? spoofType;

  const DetectionChecksList({
    required this.detectionChecks,
    required this.top,
    this.spoofType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final checks = <List<dynamic>>[
      ['darkness', detectionChecks.darkness],
      ['brightness', detectionChecks.brightness],
      ['blur', detectionChecks.blur],
      ['glare', detectionChecks.glare],
    ];

    // Add spoof detection check at the bottom if spoofType is not 'real' and not null
    if (spoofType != null && spoofType != 'real') {
      // Add spoof check at the end with fail status
      checks.add(['spoof', DetectionCheckResult.fail, spoofType]);
    }
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: checks.map((entry) {
          final key = entry[0] as String;
          final value = entry[1] as DetectionCheckResult;
          String label;

          // Handle spoof detection separately
          if (key == 'spoof') {
            final spoofTypeValue = entry.length > 2 ? entry[2] as String : '';
            if (spoofTypeValue == 'screen') {
              label = 'Print detected';
            } else if (spoofTypeValue == 'print') {
              label = 'Screen detected';
            } else {
              label = '';
            }
          } else {
            // Handle regular checks
            switch (value) {
              case DetectionCheckResult.fail:
                label = DetectionChecks.failLabels[key]!;
                break;
              case DetectionCheckResult.pass:
                label = DetectionChecks.labels[key]!;
                break;
              case DetectionCheckResult.warn:
                label = DetectionChecks.labels[key]!;
                break;
              case DetectionCheckResult.none:
                label = DetectionChecks.labels[key]!;
                break;
            }
          }

          return _DetectionCheckItem(label: label, result: value);
        }).toList(),
      ),
    );
  }
}

class _DetectionCheckItem extends StatelessWidget {
  final String label;
  final DetectionCheckResult result;
  const _DetectionCheckItem({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white.withValues(alpha: 0.85);
    Color textColor = const Color(0xFF222B45);
    Widget icon;
    switch (result) {
      case DetectionCheckResult.pass:
        icon = Icon(Icons.check_circle, color: Color(0xFF039754), size: 22);
        break;
      case DetectionCheckResult.fail:
        icon = Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFD92C20),
          size: 22,
        );
        break;
      case DetectionCheckResult.warn:
        icon = Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFF79009),
          size: 22,
        );
        break;
      case DetectionCheckResult.none:
        icon = Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFD9D9D9), width: 2),
          ),
        );
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
