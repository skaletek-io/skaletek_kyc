import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skaletek_kyc/src/config/app_config.dart';
import 'package:skaletek_kyc/src/ui/core/kyc_document_upload.dart';
import 'package:skaletek_kyc/src/ui/core/kyc_face_verification.dart';
import 'package:skaletek_kyc/src/ui/layout/body.dart';
import 'package:skaletek_kyc/src/ui/shared/app_color.dart';
import 'package:skaletek_kyc/src/models/kyc_api_models.dart';
import 'package:skaletek_kyc/src/services/kyc_service.dart';
import 'package:skaletek_kyc/src/models/kyc_result.dart';
import 'package:skaletek_kyc/src/services/kyc_state_provider.dart';
import 'layout/header.dart';

class KYCVerificationScreen extends StatefulWidget {
  final KYCConfig config;
  final Function(KYCResult)? onExit;

  const KYCVerificationScreen({super.key, required this.config, this.onExit});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  KYCStep currentStep = KYCStep.document;
  final KYCService _kycService = KYCService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  @override
  void dispose() {
    _kycService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      // Get the state provider from context
      final stateProvider = Provider.of<KYCStateProvider>(
        context,
        listen: false,
      );

      // Initialize service with state provider and error handlers
      await _kycService.initialize(
        widget.config,
        stateProvider: stateProvider,
        onComplete: (KYCResult result) {
          if (mounted) {
            if (widget.onExit != null) {
              widget.onExit!(result);
            } else {
              Navigator.of(context).pop(result);
            }
          }
        },

        onShowSnackbar: (String message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColor.text,
                duration: Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error initializing: $e')));
      }
    }
  }

  void _goToNextStep() {
    if (currentStep == KYCStep.document) {
      setState(() {
        currentStep = KYCStep.liveness;
      });
    }
  }

  void _goToPreviousStep() {
    if (currentStep == KYCStep.liveness) {
      setState(() {
        currentStep = KYCStep.document;
      });
    }
  }

  Widget _getCurrentStepWidget() {
    switch (currentStep) {
      case KYCStep.document:
        return KYCDocumentUpload(
          onNext: _goToNextStep,
          kycService: _kycService,
          userInfo: widget.config.userInfo,
          customization: widget.config.customization,
        );
      case KYCStep.liveness:
        return KYCFaceVerification(
          onBack: _goToPreviousStep,
          onNext: _goToNextStep,
          kycService: _kycService,
          userInfo: widget.config.userInfo,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColor.init(widget.config.customization);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: KYCHeader(
        logoUrl: widget.config.customization.logoUrl,
        onClose: () {
          if (widget.onExit != null) {
            widget.onExit!(KYCResult.failure(status: KYCStatus.cancelled));
          } else {
            Navigator.of(
              context,
            ).pop(KYCResult.failure(status: KYCStatus.cancelled));
          }
        },
      ),
      body: KYCBody(
        child: SingleChildScrollView(child: _getCurrentStepWidget()),
      ),
    );
  }
}
