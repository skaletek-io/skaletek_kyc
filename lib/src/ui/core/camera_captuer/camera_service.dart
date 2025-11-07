/*
///
/// A comprehensive service that handles real-time document detection and capture
/// for KYC (Know Your Customer) verification processes. Integrates with WebSocket-based
/// machine learning backends to provide live feedback on document positioning,
/// quality, and spoof detection capabilities.
///
/// ## 🐛 DEBUG FEATURE
/// **NOTE**: Debug features are currently commented out.
/// The _debugSaveImageToDevice() function can be used for debugging image quality.
/// See lines ~1115-1120 for how to enable image preview functionality.
///
/// ## Core Features
/// - **Real-time Detection**: Continuous analysis of camera frames for document presence
/// - **WebSocket Integration**: Seamless communication with ML backend services
/// - **Adaptive Performance**: Dynamic quality and interval adjustments based on network performance
/// - **Spoof Detection**: Identifies screen reflections and printouts
/// - **Image Processing**: Efficient YUV to RGB conversion with proper color handling
/// - **Auto-Rotation**: Automatic portrait orientation correction for Android cameras
/// - **Memory Management**: Optimized image processing with minimal memory footprint
///
/// ## Architecture Overview
/// ```
/// CameraController -> CameraService -> WebSocket Backend
///       |                 |                    |
///   Image Stream    Image Processing      ML Detection
///       |                 |                    |
///   YUV420 Frames   RGB + Rotation      Quality Analysis
///       |                 |                    |
///   Live Preview    JPEG Compression    Spoof Detection
/// ```
///
/// ## Performance Optimizations
/// - **Frame Rate Limiting**: Adaptive detection intervals (50ms-200ms)
/// - **JPEG Compression**: Dynamic quality scaling (30%-95%) based on network
/// - **Image Downsampling**: Adaptive scaling (40%-100%) for slower networks
/// - **Batch Processing**: Multiple frames sent before waiting for response
/// - **Connection Management**: Automatic reconnection with error handling
/// - **Debounced Updates**: Throttled UI feedback to prevent excessive rebuilds
///
/// ## Image Processing Pipeline
/// 1. **Camera Capture**: Raw camera frames in YUV420 (Android) or BGRA8888 (iOS) format
/// 2. **Color Conversion**: YUV to RGB with proper color space coefficients
/// 3. **Orientation Fix**: Automatic 90° rotation for Android portrait mode
/// 4. **Downsampling**: Optional scaling based on network conditions
/// 5. **JPEG Encoding**: Adaptive quality compression (default 50%)
/// 6. **WebSocket Send**: Binary image data sent to ML backend
///
/// ## Detection Quality Checks
/// - **Brightness**: Optimal lighting conditions validation
/// - **Contrast**: Prevents underexposed images
/// - **Blur**: Ensures sharp, readable documents
/// - **Glare**: Detects and prevents reflective surfaces
/// - **Spoof Detection**: Identifies screen and print attacks
///
/// ## WebSocket Communication Protocol
/// - **Outbound**: JPEG image data with adaptive quality (binary format)
/// - **Inbound**: Metadata with quality checks, spoof labels, and capture status
/// - **Error Handling**: Automatic reconnection with exponential backoff
/// - **Performance Tracking**: Network latency monitoring for adaptive optimization
///
/// ## Usage Example
/// ```dart
/// final service = CameraService(
///   cameraController: controller,
///   targetRect: documentArea,
///   screenSize: screenDimensions,
///   wsService: webSocketService, // Optional
///   onChecks: (checks) => handleQualityChecks(checks),
/// );
///
/// // Listen to feedback
/// service.feedbackStream.listen((feedback) {
///   updateUI(feedback);
/// });
///
/// // Listen to captures
/// service.captureStream.listen((file) {
///   processDocument(file);
/// });
///
/// service.connect();
/// ```
/// */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:open_file/open_file.dart';

import 'package:skaletek_kyc/src/models/kyc_api_models.dart';
import 'package:skaletek_kyc/src/utils/image_cropper.dart';
import 'package:skaletek_kyc/src/services/websocket_service.dart';
import 'package:skaletek_kyc/src/config/app_config.dart';

// =============================================================================
// DETECTION TIMING CONSTANTS
// =============================================================================

/// Default interval between detection requests - balanced performance/accuracy
const Duration _kDefaultDetectionInterval = Duration(milliseconds: 100);

/// Minimum detection interval for high-performance scenarios (fast network)
const Duration _kMinDetectionInterval = Duration(milliseconds: 50);

/// Maximum detection interval for low-performance scenarios (slow network)
const Duration _kMaxDetectionInterval = Duration(milliseconds: 200);

// =============================================================================
// IMAGE QUALITY CONSTANTS
// =============================================================================

/// Default PNG compression quality (0.0-1.0) - good balance of size/quality
const double _kDefaultImageQuality = 0.8;

/// Minimum quality for poor network conditions - maintains basic readability
const double _kMinImageQuality = 0.3;

/// Maximum quality for optimal network conditions - best image fidelity
const double _kMaxImageQuality = 0.95;

/// Default image scaling factor - full resolution
const double _kDefaultImageScale = 1.0;

/// Minimum scaling factor for poor network conditions - 40% of original size
const double _kMinImageScale = 0.4;

// =============================================================================
// PERFORMANCE MONITORING CONSTANTS
// =============================================================================

/// Maximum number of performance samples to maintain for averaging
const int _kMaxPerformanceSamples = 10;

/// Processing time threshold (ms) above which performance is considered poor
const double _kPoorPerformanceThreshold = 200.0;

/// Processing time threshold (ms) below which performance is considered good
const double _kGoodPerformanceThreshold = 100.0;

/// Network response time threshold (ms) above which network is considered slow
const double _kSlowNetworkThreshold = 800.0;

/// Network response time threshold (ms) below which network is considered fast
const double _kFastNetworkThreshold = 300.0;

// =============================================================================
// DETECTION AND CROPPING CONSTANTS
// =============================================================================

/// Padding (pixels) added around target area for manual capture cropping
const double _kCropPadding = 10.0;

/// Visual feedback states for UI overlay styling and user guidance
enum FeedbackState {
  /// Informational state - neutral blue/gray colors for general guidance
  info,

  /// Error state - red/orange colors for problems requiring user action
  error,

  /// Success state - green colors for optimal positioning/quality
  success,

  /// Warning state - yellow colors for problems requiring user action
  warning,
}

/// Predefined feedback messages for consistent user guidance
///
/// Provides standardized messages for different detection states and user actions.
/// Each message is designed to give clear, actionable guidance to help users
/// position their document correctly and understand system status.
///
/// ## Message Categories
/// - **Positioning**: Directional guidance for document placement
/// - **Quality**: Feedback about image conditions (lighting, focus, etc.)
/// - **Connection**: System status and connectivity information
/// - **Capture**: Confirmation and completion messages
enum FeedbackMessage {
  /// Default message when no document is detected or positioning is needed
  default_('Fit ID card in the box'),

  /// Success message when document is optimally positioned and capture is imminent
  good('Right spot! Hold steady'),

  /// Directional guidance - document appears too low in frame
  tooLow('Too low — raise it a bit.'),

  /// Directional guidance - document appears too high in frame
  tooHigh('Too high — lower it a bit.'),

  /// Directional guidance - document should be moved to user's left
  moveLeft('Move left slightly.'),

  /// Directional guidance - document should be moved to user's right
  moveRight('Move right slightly.'),

  /// Position is good but image quality needs improvement
  goodPositionBadQuality('Good position! Improve lighting and focus'),

  /// Initial connection establishment in progress
  connecting('Connecting…'),

  /// Connection lost, attempting automatic reconnection
  disconnected('Disconnected. Reconnecting…'),

  /// Connection failed, retry in progress
  connectionError('Connection error. Reconnecting…'),

  /// Server-side processing error occurred
  processingError('Processing error occurred'),

  /// Successful capture confirmation
  captured('Captured!'),

  blurQuality('Keep the camera steady to avoid blur.'),

  contrastQuality('Try moving to a brighter area'),

  brightnessQuality('Move to a brighter area'),

  glareQuality('Avoid reflections or tilt slightly.'),

  screen('We detected a screen reflection. Please use your physical ID.'),

  print('We detected a possible printout. Please use your original ID.');

  /// Creates a feedback message with the specified text
  const FeedbackMessage(this.text);

  /// The human-readable message text displayed to users
  final String text;
}

/// Wrapper for captured images with metadata about capture source
///
/// Distinguishes between manual captures (user-initiated) and automatic captures
/// (ML backend best_image). This allows downstream processing to skip redundant
/// detection/cropping for already-processed images.
class CapturedImage {
  /// The captured image file
  final XFile file;

  /// Whether this was automatically captured by ML backend (true) or manually by user (false)
  final bool isAutomatic;

  CapturedImage({required this.file, required this.isAutomatic});
}

/// Comprehensive feedback data structure for real-time detection updates
///
/// Encapsulates all information needed to provide user feedback during document
/// detection, including positioning guidance, quality checks, system status,
/// and visual overlay data.
///
/// ## Key Components
/// - **Message**: Human-readable guidance text
/// - **Quality Checks**: Detailed analysis results (brightness, blur, etc.)
/// - **System Status**: Connection and processing state indicators
/// - **Visual Data**: Bounding box coordinates for overlay rendering
/// - **UI State**: Feedback categorization for styling and behavior
///
/// ## Usage
/// This class is emitted through the feedback stream to update UI components
/// with real-time detection results and user guidance.
class DetectionFeedback {
  /// Human-readable message providing user guidance or system status
  final String message;

  /// Detailed quality analysis results from ML backend
  final DetectionChecks checks;

  /// Whether the system is currently analyzing an image
  final bool analyzing;

  /// Whether the system is attempting to establish connection
  final bool connecting;

  /// Whether the WebSocket connection is active and ready
  final bool connected;

  /// Bounding box coordinates of detected document (screen coordinates)
  /// Null if no document detected or detection failed
  final Rect? bbox;

  /// Categorized feedback state for UI styling and behavior
  final FeedbackState feedbackState;

  /// Capture progress ratio (0.0 to 1.0)
  final double progress;

  /// Total number of frames needed for capture
  final int totalFramesNeeded;

  /// Number of frames captured so far
  final int framesCaptured;

  /// Spoof detection type ('real', 'screen', 'print', or null)
  final String? spoofType;

  /// Type of the message
  final String? type;

  /// Status of the message
  final String? status;

  /// Creates a detection feedback instance with the specified parameters
  DetectionFeedback({
    required this.message,
    required this.checks,
    this.analyzing = false,
    this.connecting = false,
    this.connected = false,
    this.bbox,
    this.feedbackState = FeedbackState.info,
    this.progress = 0.0,
    this.totalFramesNeeded = 0,
    this.framesCaptured = 0,
    this.spoofType,
    this.type,
    this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionFeedback &&
        other.message == message &&
        other.checks == checks &&
        other.analyzing == analyzing &&
        other.connecting == connecting &&
        other.connected == connected &&
        other.bbox == bbox &&
        other.feedbackState == feedbackState &&
        other.progress == progress &&
        other.totalFramesNeeded == totalFramesNeeded &&
        other.framesCaptured == framesCaptured &&
        other.spoofType == spoofType;
  }

  @override
  int get hashCode => Object.hash(
    message,
    checks,
    analyzing,
    connecting,
    connected,
    bbox,
    feedbackState,
    progress,
    totalFramesNeeded,
    framesCaptured,
    spoofType,
  );
}

/// Performance monitoring and adaptive optimization system
///
/// Tracks both local processing and network performance to dynamically adjust
/// quality settings for optimal user experience across varying device capabilities
/// and network conditions.
///
/// ## Metrics Tracked (Every 2 Seconds)
/// - **Processing Time**: YUV→RGB conversion + rotation + JPEG encoding duration
/// - **Network Response Time**: Round-trip time for WebSocket request/response
/// - **Rolling Averages**: Last 10 samples for trend analysis
///
/// ## How It Works
/// 1. Tracks timing for every image processed and sent
/// 2. Every 2 seconds, checks averages against thresholds
/// 3. Adjusts quality/scale/interval based on performance
///
/// ## Adaptive Behaviors
/// - **Poor Performance** (>200ms processing OR >1000ms network):
///   - Reduces JPEG quality (down to 30%)
///   - Reduces image scale (down to 40%)
///   - Increases detection interval (up to 200ms)
/// - **Good Performance** (<100ms processing AND <500ms network):
///   - Increases JPEG quality (up to 95%)
///   - Increases image scale (up to 100%)
///   - Decreases detection interval (down to 50ms)
///
/// ## Sample Management
/// Maintains a rolling window of 10 most recent samples to ensure
/// adaptive behavior responds to current conditions, not historical averages.
class _PerformanceMetrics {
  /// Rolling buffer of processing times (milliseconds) for local operations
  final List<int> _processingTimes = [];

  /// Rolling buffer of network response times (milliseconds) for WebSocket operations
  final List<int> _networkResponseTimes = [];

  /// Records a local processing time measurement
  ///
  /// Automatically maintains the rolling window size by removing oldest samples
  /// when the buffer exceeds [_kMaxPerformanceSamples].
  ///
  /// [milliseconds] - Duration of the processing operation
  void addProcessingTime(int milliseconds) {
    _processingTimes.add(milliseconds);
    if (_processingTimes.length > _kMaxPerformanceSamples) {
      _processingTimes.removeAt(0);
    }
  }

  /// Records a network response time measurement
  ///
  /// Tracks round-trip time for WebSocket communication to enable
  /// adaptive compression and interval adjustments.
  ///
  /// [milliseconds] - Duration from request send to response received
  void addNetworkResponseTime(int milliseconds) {
    _networkResponseTimes.add(milliseconds);
    if (_networkResponseTimes.length > _kMaxPerformanceSamples) {
      _networkResponseTimes.removeAt(0);
    }
  }

  double get averageProcessingTime {
    if (_processingTimes.isEmpty) return 0;
    return _processingTimes.reduce((a, b) => a + b) / _processingTimes.length;
  }

  double get averageNetworkResponseTime {
    if (_networkResponseTimes.isEmpty) return 0;
    return _networkResponseTimes.reduce((a, b) => a + b) /
        _networkResponseTimes.length;
  }

  bool get isPerformancePoor =>
      averageProcessingTime > _kPoorPerformanceThreshold ||
      averageNetworkResponseTime > 1000;
  bool get isPerformanceGood =>
      averageProcessingTime < _kGoodPerformanceThreshold &&
      averageNetworkResponseTime < 500;
  bool get isNetworkSlow => averageNetworkResponseTime > _kSlowNetworkThreshold;
  bool get isNetworkFast => averageNetworkResponseTime < _kFastNetworkThreshold;
}

/// Comprehensive camera service for real-time document detection and capture
///
/// Orchestrates the entire document detection pipeline, from camera frame processing
/// to ML backend communication and user feedback generation. Provides adaptive
/// performance optimization and intelligent capture triggering.
///
/// ## Core Responsibilities
/// - **Camera Management**: Handles image stream processing and capture operations
/// - **WebSocket Communication**: Manages ML backend connectivity and data exchange
/// - **Performance Optimization**: Dynamically adjusts quality based on device/network performance
/// - **Coordinate Transformation**: Maps between camera, screen, and image coordinate systems
/// - **User Feedback**: Generates real-time positioning and quality guidance
/// - **Automatic Capture**: Intelligently triggers capture when conditions are optimal
///
/// ## Adaptive Features
/// - **Detection Intervals**: Adjusts from 50ms-200ms based on performance
/// - **Image Quality**: Scales compression from 30%-95% based on network conditions
/// - **Image Scaling**: Reduces resolution by up to 60% for poor connections
/// - **Connection Management**: Automatic reconnection with error handling
///
/// ## Streams
/// - **Feedback Stream**: Real-time detection feedback and positioning guidance
/// - **Capture Stream**: Successfully captured and processed document images
///
/// ## Lifecycle
/// 1. **Initialization**: Sets up camera, WebSocket, and performance monitoring
/// 2. **Connection**: Establishes ML backend connection and starts detection loop
/// 3. **Detection**: Continuous image processing and quality analysis
/// 4. **Feedback**: Real-time user guidance and system status updates
/// 5. **Capture**: Automatic or manual image capture with precise cropping
/// 6. **Disposal**: Cleanup of resources and connections
class CameraService {
  /// Camera controller for device camera access and image operations
  final CameraController cameraController;

  /// Target rectangle defining the document positioning area (screen coordinates)
  final Rect targetRect;

  /// Callback function for detection quality check updates
  final void Function(DetectionChecks) onChecks;

  /// Screen dimensions for coordinate transformation calculations
  final Size screenSize;

  // =============================================================================
  // ADAPTIVE CONFIGURATION
  // =============================================================================

  /// Current detection interval - dynamically adjusted based on performance
  Duration _currentDetectionInterval = _kDefaultDetectionInterval;

  /// Current image compression quality - adapted to network conditions
  double _currentImageQuality = _kDefaultImageQuality;

  /// Current image scaling factor - reduced for poor performance scenarios
  double _currentImageScale = _kDefaultImageScale;

  // =============================================================================
  // WEBSOCKET SERVICE MANAGEMENT
  // =============================================================================

  /// WebSocket service for ML backend communication
  final WebSocketService _wsService;

  /// Flag indicating if WebSocket service was provided externally
  final bool _wsServiceProvided;

  /// Subscription to WebSocket connection status changes
  StreamSubscription? _wsStatusSub;

  /// Subscription to WebSocket message stream
  StreamSubscription? _wsMessageSub;

  /// Subscription to WebSocket error events
  StreamSubscription? _wsErrorSub;

  // =============================================================================
  // TIMER MANAGEMENT
  // =============================================================================

  /// Timer for periodic detection requests
  Timer? _detectionTimer;

  /// Timer for steady positioning validation
  Timer? _steadyTimer;

  /// Timer for performance monitoring and adjustment
  Timer? _performanceTimer;

  /// Timer for debouncing UI feedback updates
  Timer? _debounceTimer;

  /// Timer for periodic capture state validation
  Timer? _periodicCaptureTimer;

  // =============================================================================
  // STATE MANAGEMENT
  // =============================================================================

  /// Flag indicating if a detection request is currently pending
  bool _pendingRequest = false;

  int _framesCaptured = 0;

  int _totalFramesNeeded = 3;

  double _progress = 0;

  int _imageSentCount = 0;

  final int _totalImageToSend = 3;

  /// Flag indicating if the service has been disposed
  bool _disposed = false;

  String? _spoofType;

  /// Timestamp of the last processed frame for rate limiting
  DateTime? _lastFrameTime;

  /// Timestamp when the current network request was initiated
  DateTime? _requestStartTime;

  /// Last received detection quality checks from ML backend
  DetectionChecks _lastChecks = const DetectionChecks();

  /// Last received bounding box coordinates (screen coordinates)
  Rect? _lastBbox;

  /// Performance metrics tracker for adaptive optimization
  final _performanceMetrics = _PerformanceMetrics();

  /// Stream controller for real-time detection feedback
  final _feedbackController = StreamController<DetectionFeedback>.broadcast();

  /// Stream controller for captured document images
  final _captureController = StreamController<CapturedImage>.broadcast();

  // =============================================================================
  // IMAGE PROCESSING STATE
  // =============================================================================

  /// Latest camera image for processing (updated by image stream)
  CameraImage? _latestCameraImage;

  /// Flag indicating if camera image stream is active
  bool _isStreaming = false;

  /// Creates a new camera service instance with the specified configuration
  ///
  /// ## Parameters
  /// - [cameraController]: Active camera controller for image operations
  /// - [targetRect]: Document positioning area in screen coordinates
  /// - [onChecks]: Callback for detection quality updates
  /// - [screenSize]: Screen dimensions for coordinate transformations
  /// - [wsService]: Optional external WebSocket service (creates own if null)
  /// - [environment]: Environment string for WebSocket URL ('dev', 'prod', 'sandbox'). Defaults to 'dev'
  CameraService({
    required this.cameraController,
    required this.targetRect,
    required this.onChecks,
    required this.screenSize,
    WebSocketService? wsService,
    String? environment,
  }) : _wsServiceProvided = wsService != null,
       _wsService =
           wsService ??
           WebSocketService(
             environment: environment ?? SkaletekEnvironment.dev.value,
           ) {
    // Initialize with optimized settings for real-device performance
    // These values will adapt automatically based on network conditions
    _currentImageQuality = 0.5; // 50% JPEG quality (can go 30%-95%)
    _currentImageScale = 0.6; // 60% resolution (can go 40%-100%)
    _currentDetectionInterval = Duration(
      milliseconds: 150,
    ); // 150ms interval (can go 50ms-200ms)

    _initWebSocketListeners();
    _startPerformanceMonitoring();
  }

  /// Stream of real-time detection feedback for UI updates
  Stream<DetectionFeedback> get feedbackStream => _feedbackController.stream;

  /// Stream of successfully captured and processed document images
  Stream<CapturedImage> get captureStream => _captureController.stream;

  /// Initializes WebSocket event listeners for ML backend communication
  ///
  /// Sets up comprehensive event handling for:
  /// - **Connection Status**: Manages connecting/connected/disconnected states
  /// - **Message Processing**: Handles detection results and quality analysis
  /// - **Error Handling**: Manages connection failures and processing errors
  /// - **Initial State**: Handles externally provided WebSocket services
  ///
  /// The listeners automatically update UI feedback and manage detection loops
  /// based on connection status changes.
  void _initWebSocketListeners() {
    // Check initial status for externally provided services
    if (_wsServiceProvided) {
      _handleInitialWebSocketStatus();
    }

    // Listen to connection status changes
    _wsStatusSub = _wsService.statusStream.listen((status) {
      switch (status) {
        case WebSocketStatus.connecting:
          _emitFeedback(
            DetectionFeedback(
              message: FeedbackMessage.connecting.text,
              checks: _lastChecks,
              connecting: true,
              connected: false,
              analyzing: false,
              feedbackState: FeedbackState.info,
            ),
          );
          break;
        case WebSocketStatus.connected:
          _pendingRequest = false;
          _emitFeedback(
            DetectionFeedback(
              message: FeedbackMessage.default_.text,
              checks: _lastChecks,
              connecting: false,
              connected: true,
              analyzing: false,
              feedbackState: FeedbackState.info,
            ),
          );
          _startDetectionLoop();
          break;
        case WebSocketStatus.disconnected:
          _pendingRequest = false;
          _detectionTimer?.cancel();
          _emitFeedback(
            DetectionFeedback(
              message: FeedbackMessage.disconnected.text,
              checks: _lastChecks,
              connecting: true,
              connected: false,
              analyzing: false,
              feedbackState: FeedbackState.info,
            ),
          );
          break;
        case WebSocketStatus.error:
          _pendingRequest = false;
          _detectionTimer?.cancel();
          _emitFeedback(
            DetectionFeedback(
              message: FeedbackMessage.connectionError.text,
              checks: _lastChecks,
              connecting: true,
              connected: false,
              analyzing: false,
              feedbackState: FeedbackState.error,
            ),
          );
          break;
      }
    });

    // Listen to WebSocket messages
    _wsMessageSub = _wsService.messageStream.listen(_onWsMessage);

    // Listen to WebSocket errors
    _wsErrorSub = _wsService.errorStream.listen((error) {
      developer.log('WebSocket error: $error');
    });
  }

  /// Handle initial WebSocket status for externally provided services
  void _handleInitialWebSocketStatus() {
    final currentStatus = _wsService.status;

    switch (currentStatus) {
      case WebSocketStatus.connected:
        // Service is already connected, emit connected state immediately
        _pendingRequest = false;
        _emitFeedback(
          DetectionFeedback(
            message: FeedbackMessage.default_.text,
            checks: _lastChecks,
            connecting: false,
            connected: true,
            analyzing: false,
            feedbackState: FeedbackState.info,
          ),
        );
        _startDetectionLoop();
        break;
      case WebSocketStatus.connecting:
        // Service is connecting, show connecting state
        _emitFeedback(
          DetectionFeedback(
            message: FeedbackMessage.connecting.text,
            checks: _lastChecks,
            connecting: true,
            connected: false,
            analyzing: false,
            feedbackState: FeedbackState.info,
          ),
        );
        break;
      case WebSocketStatus.disconnected:
      case WebSocketStatus.error:
        // Service is disconnected/error, show appropriate state
        _emitFeedback(
          DetectionFeedback(
            message: FeedbackMessage.disconnected.text,
            checks: _lastChecks,
            connecting: false,
            connected: false,
            analyzing: false,
            feedbackState: FeedbackState.info,
          ),
        );
        break;
    }
  }

  void connect() {
    if (_disposed) return;

    // Only connect if we created the WebSocket service ourselves
    // If it was provided externally, it should already be connected and handled in initialization
    if (!_wsServiceProvided) {
      _wsService.connect();
    }

    //Deprecated
    //Start periodic capture check as additional fallback
    // _startPeriodicCaptureCheck();
    // Note: For externally provided services, status is already handled in _handleInitialWebSocketStatus
  }

  void _onWsMessage(Map<String, dynamic> data) {
    if (_disposed) return;

    final processingStart = DateTime.now();

    // Track network response time for adaptive optimization
    if (_requestStartTime != null) {
      final networkResponseTime = processingStart
          .difference(_requestStartTime!)
          .inMilliseconds;
      _performanceMetrics.addNetworkResponseTime(networkResponseTime);
      // developer.log('Network response time: ${networkResponseTime}ms');
    }

    if (_pendingRequest) {
      _pendingRequest = false;
      _imageSentCount = 0;
    }

    try {
      // developer.log('Received message: $data');

      if (data['type'] == 'metadata') {
        _handleMetadataResponse(data);
        return;
      } else if (data['type'] == 'status' && data['status'] == 'complete') {
        _handleCompleteResponse(data);
        return;
      } else if (data['type'] == 'status' && data['status'] == 'captured') {
        _handleCapturedResponse(data);
        return;
      }
    } catch (e, stackTrace) {
      developer.log('Error processing WebSocket message: $e');
      developer.log('Stack trace: $stackTrace');
      developer.log('Message content: $data');

      // Emit error feedback to user
      _emitFeedback(
        DetectionFeedback(
          message: FeedbackMessage.processingError.text,
          checks: _lastChecks,
          connecting: false,
          connected: true,
          analyzing: false,
          feedbackState: FeedbackState.error,
        ),
      );
    }
  }

  /// Handles metadata response from WebSocket
  ///
  /// Processes quality checks, spoof detection, and generates appropriate
  /// user feedback based on detection results.
  void _handleMetadataResponse(Map<String, dynamic> data) {
    // Parse quality checks from metadata
    final qualityMetrics = data['quality_metrics'];
    final DetectionChecks checks;

    if (qualityMetrics is Map<String, dynamic>) {
      checks = DetectionChecks.fromMap(qualityMetrics);
    } else {
      checks = const DetectionChecks();
    }

    // developer.log(
    //   'Checks: blur=${checks.blur}, glare=${checks.glare}, '
    //   'brightness=${checks.brightness}, contrast=${checks.contrast}',
    // );

    onChecks(checks);
    _lastChecks = checks;

    // Get spoof label
    final spoofLabel = data['spoof_label'] as String?;
    _spoofType = spoofLabel;

    // Find first falsy check (FAIL or WARN)
    String? falsyCheck;
    if (checks.glare == DetectionCheckResult.fail ||
        checks.glare == DetectionCheckResult.warn) {
      falsyCheck = 'glare';
    } else if (checks.blur == DetectionCheckResult.fail ||
        checks.blur == DetectionCheckResult.warn) {
      falsyCheck = 'blur';
    } else if (checks.brightness == DetectionCheckResult.fail ||
        checks.brightness == DetectionCheckResult.warn) {
      falsyCheck = 'brightness';
    } else if (checks.contrast == DetectionCheckResult.fail ||
        checks.contrast == DetectionCheckResult.warn) {
      falsyCheck = 'contrast';
    }

    // Determine message based on spoof label or falsy check
    String message;
    FeedbackState feedbackState;

    if (spoofLabel != null && spoofLabel != 'real') {
      // Spoof detected
      if (spoofLabel == 'screen') {
        message = FeedbackMessage.screen.text;
      } else if (spoofLabel == 'print') {
        message = FeedbackMessage.print.text;
      } else {
        message = FeedbackMessage.default_.text;
      }
      feedbackState = FeedbackState.error;
    } else if (falsyCheck != null) {
      // Quality issue detected
      switch (falsyCheck) {
        case 'glare':
          message = FeedbackMessage.glareQuality.text;
          break;
        case 'blur':
          message = FeedbackMessage.blurQuality.text;
          break;
        case 'brightness':
          message = FeedbackMessage.brightnessQuality.text;
          break;
        case 'contrast':
          message = FeedbackMessage.contrastQuality.text;
          break;
        default:
          message = FeedbackMessage.default_.text;
      }
      feedbackState = FeedbackState.warning;
    } else {
      // All checks passed - document is in good position
      message = FeedbackMessage.good.text;
      feedbackState = FeedbackState.info;
    }

    //developer.log('Metadata response: $message');

    _emitFeedback(
      DetectionFeedback(
        message: message,
        checks: checks,
        connecting: false,
        connected: true,
        analyzing: false,
        feedbackState: feedbackState,
        bbox: _lastBbox, // Use last known bbox
        progress: _progress,
        totalFramesNeeded: _totalFramesNeeded,
        framesCaptured: _framesCaptured,
        spoofType: _spoofType,
        type: data['type'],
        status: data['status'],
      ),
    );
  }

  /// Handles captured status response from WebSocket
  ///
  /// Updates frame capture progress and provides feedback to user
  void _handleCapturedResponse(Map<String, dynamic> data) {
    // Update frame counts
    _totalFramesNeeded = (data['total_frames_needed'] as num?)?.toInt() ?? 3;
    _framesCaptured = (data['frames_captured'] as num?)?.toInt() ?? 0;

    // Calculate progress ratio (clamped between 0 and 1)
    final target = _totalFramesNeeded;
    final ratio = (_framesCaptured / target).clamp(0.0, 1.0);
    _progress = ratio;

    // developer.log(
    //   'Captured: $_framesCaptured/$_totalFramesNeeded frames (${(_progress * 100).toStringAsFixed(0)}%)',
    // );

    // Emit feedback with "inside" message
    _emitFeedback(
      DetectionFeedback(
        message: FeedbackMessage.good.text, // "inside" message
        checks: _lastChecks,
        connecting: false,
        connected: true,
        analyzing: false,
        feedbackState: FeedbackState.success,
        bbox: _lastBbox,
        progress: _progress,
        totalFramesNeeded: _totalFramesNeeded,
        framesCaptured: _framesCaptured,
        spoofType: _spoofType,
        type: data['type'],
        status: data['status'],
      ),
    );
  }

  /// Handles complete status response from WebSocket
  ///
  /// Processes the final captured image and spoof detection result
  /// Mirrors the React implementation pattern for consistency
  Future<void> _handleCompleteResponse(Map<String, dynamic> data) async {
    try {
      // Set spoof type from spoof.label (same as React: data?.spoof.label)
      final spoofData = data['spoof'];
      if (spoofData is Map<String, dynamic>) {
        _spoofType = spoofData['label'] as String?;
        // developer.log('Spoof detection result: $_spoofType');
      }

      // Process final captured image (same as React: data?.best_image)
      final bestImage = data['best_image'] as String?;

      if (bestImage != null && bestImage.isNotEmpty) {
        try {
          // Ensure image has proper data URL format (same as React pattern)
          String base64String;

          if (bestImage.startsWith('data:')) {
            // Has header - extract base64 part
            final parts = bestImage.split(',');
            if (parts.length > 1) {
              base64String = parts[1];
            } else {
              base64String = bestImage;
            }
          } else {
            // No header - raw base64
            base64String = bestImage;
          }

          // Decode base64 to bytes
          final bytes = base64Decode(base64String);

          // Detect actual image format from magic bytes for proper extension
          String extension =
              '.jpg'; // Default to jpg (same as React: "cropped_image.jpg")
          if (bytes.length >= 8) {
            // Check for PNG signature (89 50 4E 47)
            if (bytes[0] == 0x89 &&
                bytes[1] == 0x50 &&
                bytes[2] == 0x4E &&
                bytes[3] == 0x47) {
              extension = '.png';
            }
            // Check for JPEG signature (FF D8)
            else if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
              extension = '.jpg';
            }
          }

          // Create temporary file path (same as React: "cropped_image.jpg")
          final tempDir = Directory.systemTemp;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${tempDir.path}/cropped_image_$timestamp$extension';

          // Write bytes to file (same as React: base64ToFile)
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          // Create XFile and emit through capture stream (same as React: setCroppedFile)
          // Mark as automatic since this is from ML backend's best_image
          final xFile = XFile(filePath);
          _captureController.add(CapturedImage(file: xFile, isAutomatic: true));

          // developer.log(
          //   'Complete: Best image saved as $extension (${bytes.length} bytes, mime: $mimeType)',
          // );

          _emitFeedback(
            DetectionFeedback(
              message: FeedbackMessage.captured.text,
              checks: _lastChecks,
              connecting: false,
              connected: true,
              analyzing: false,
              feedbackState: FeedbackState.success,
              bbox: _lastBbox,
              progress: _progress,
              totalFramesNeeded: _totalFramesNeeded,
              framesCaptured: _framesCaptured,
              spoofType: _spoofType,
              type: data['type'],
              status: data['status'],
            ),
          );
        } catch (e) {
          developer.log('Error cropping image: $e', error: e);
        }
      } else {
        // Same as React: console.warn("best_image missing in complete status")
        developer.log(
          'Warning: best_image missing in complete status',
          level: 900, // Warning level
        );
      }
    } catch (e) {
      developer.log('Error handling complete response: $e', error: e);
    }
  }

  /// Starts the main detection loop for continuous document analysis
  ///
  /// Initiates periodic image processing and ML backend communication at
  /// adaptive intervals based on current performance metrics. The loop:
  ///
  /// ## Operations
  /// - **Image Stream**: Starts continuous camera frame capture
  /// - **Frame Processing**: Converts and crops images for ML analysis
  /// - **Rate Limiting**: Enforces minimum intervals to prevent overload
  /// - **Network Communication**: Sends optimized images to ML backend
  /// - **Performance Tracking**: Monitors timing for adaptive adjustments
  ///
  /// ## Adaptive Behavior
  /// The detection interval automatically adjusts from 50ms-200ms based on:
  /// - Device processing performance
  /// - Network response times
  /// - Overall system load

  void _startDetectionLoop() {
    _detectionTimer?.cancel();
    _startImageStream(); // Start image stream for silent capture

    _detectionTimer = Timer.periodic(_currentDetectionInterval, (_) async {
      if (_disposed || !_wsService.isConnected || _pendingRequest) return;

      // Frame rate limiting
      final now = DateTime.now();
      if (_lastFrameTime != null &&
          now.difference(_lastFrameTime!).inMilliseconds <
              _currentDetectionInterval.inMilliseconds) {
        return;
      }
      _lastFrameTime = now;

      _requestStartTime =
          DateTime.now(); // Track request start time for network

      try {
        if (_latestCameraImage != null) {
          // Track processing time
          final processingStart = DateTime.now();
          final arrayBuffer = await _processCameraImage(_latestCameraImage!);
          final processingEnd = DateTime.now();

          if (arrayBuffer != null && !_disposed) {
            // Record processing time for adaptive optimization
            final processingTime = processingEnd
                .difference(processingStart)
                .inMilliseconds;
            _performanceMetrics.addProcessingTime(processingTime);

            // developer.log(
            //   'Sending optimized image data: ${arrayBuffer.length} bytes',
            // );

            _wsService.send(arrayBuffer);
            _imageSentCount++;

            // DEBUG: Save 5th image for debugging purposes
            // _debugImageCounter++;
            // if (_debugImageCounter == 5) {
            //   developer.log("debugging image saved $_debugImageCounter");
            //   await _debugSaveImageToDevice(arrayBuffer);
            // }

            // developer.log('Image sent count: $_imageSentCount');

            if (_imageSentCount >= _totalImageToSend) {
              _pendingRequest = true;
              _imageSentCount = 0;
            }
          } else {
            _pendingRequest = false;
          }
        } else {
          _pendingRequest = false;
        }
      } catch (e) {
        _pendingRequest = false;
        developer.log('Error processing camera image: $e');
      }
    });
  }

  /// Start camera image stream for silent frame capture
  void _startImageStream() async {
    if (_isStreaming || _disposed) return;

    try {
      await cameraController.startImageStream((image) {
        _latestCameraImage = image;
      });
      _isStreaming = true;
      // developer.log('Image stream started');
    } catch (e) {
      developer.log('Error starting image stream: $e');
    }
  }

  /// Stop camera image stream
  void _stopImageStream() {
    if (!_isStreaming) return;

    try {
      cameraController.stopImageStream();
      _isStreaming = false;
      _latestCameraImage = null;
      // developer.log('Image stream stopped');
    } catch (e) {
      developer.log('Error stopping image stream: $e');
    }
  }

  // =============================================================================
  // DEBUG FUNCTIONS - FOR DEVELOPMENT ONLY
  // =============================================================================

  /// DEBUG: Saves and opens the exact image being sent to the endpoint
  ///
  /// **Purpose**: Verify that images have correct colors and orientation
  ///
  /// **What it saves**: The EXACT binary data sent over WebSocket (byte-for-byte)
  /// - Format: JPEG
  /// - Quality: Current adaptive quality (default 50%)
  /// - Scale: Current adaptive scale (default 60%)
  /// - Colors: Full RGB (not grayscale)
  /// - Orientation: Portrait (rotated 90°)
  ///
  /// **What it does**:
  /// 1. Saves image to temporary directory
  /// 2. Stops detection loop
  /// 3. Opens image in system photo viewer/gallery
  /// 4. Falls back to capture stream if viewer fails
  ///
  /// **To enable**:
  /// 1. Uncomment lines ~1115-1120 in _startDetectionLoop
  /// 2. Optionally add `int _debugImageCounter = 0;` field to track count
  ///
  /// **Use case**: Debugging color/rotation issues by viewing actual sent images
  // ignore: unused_element
  Future<void> _debugSaveImageToDevice(Uint8List imageBytes) async {
    try {
      // Save to temporary directory
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savePath = '${tempDir.path}/debug_kyc_preview_$timestamp.jpg';

      // Write the JPEG bytes to file
      final file = File(savePath);
      await file.writeAsBytes(imageBytes);

      developer.log(
        '🐛 DEBUG: EXACT ENDPOINT IMAGE saved!\n'
        '   📍 Path: $savePath\n'
        '   📦 Size: ${imageBytes.length} bytes (${(imageBytes.length / 1024).toStringAsFixed(2)} KB)\n'
        '   🎨 Quality: ${(_currentImageQuality * 100).round()}% JPEG compression\n'
        '   📏 Scale: ${(_currentImageScale * 100).round()}% of camera resolution\n'
        '   📸 Format: JPEG\n'
        '   \n'
        '   ✅ This is BYTE-FOR-BYTE what the endpoint receives!',
      );

      // Stop detection loop
      _detectionTimer?.cancel();
      _stopImageStream();
      developer.log('🐛 DEBUG: Detection stopped');

      // Open the image in system photo viewer/gallery
      final result = await OpenFile.open(savePath);
      developer.log(
        '🐛 DEBUG: Opening image in photo viewer - ${result.message}',
      );

      if (result.type != ResultType.done) {
        developer.log(
          '⚠️ DEBUG: Could not open image viewer: ${result.message}',
        );
        // Fallback: emit to capture stream for in-app preview
        final xFile = XFile(savePath);
        _captureController.add(CapturedImage(file: xFile, isAutomatic: false));
        developer.log('🐛 DEBUG: Fallback - emitted to capture stream');
      }
    } catch (e) {
      developer.log('🐛 DEBUG: Error opening debug image: $e', error: e);
    }
  }

  /// Processes camera images for ML backend analysis
  ///
  /// Converts raw camera frames to properly formatted JPEG images with correct
  /// color space and orientation. This is the main entry point for image processing
  /// in the detection loop.
  ///
  /// ## What It Does
  /// - Converts camera native format (YUV420/BGRA8888) to RGB
  /// - Fixes color issues (grayscale → full color)
  /// - Corrects orientation (sideways → portrait)
  /// - Applies adaptive quality and scaling
  /// - Encodes to JPEG format
  ///
  /// ## Default Settings (Optimized for Performance)
  /// - **Quality**: 50% JPEG compression
  /// - **Scale**: 60% of original resolution
  /// - **Format**: JPEG (smaller than PNG)
  ///
  /// ## Adaptive Behavior
  /// Quality and scale adjust automatically based on network performance:
  /// - **Good network**: Higher quality (up to 95%), full resolution
  /// - **Poor network**: Lower quality (down to 30%), reduced resolution (40%)
  ///
  /// ## Error Handling
  /// Returns null if processing fails, allowing the detection loop to continue
  /// with the next frame rather than breaking the entire pipeline.
  ///
  /// [image] - Raw camera image in YUV420 (Android) or BGRA8888 (iOS) format
  /// Returns JPEG bytes ready for ML backend, or null on error
  Future<Uint8List?> _processCameraImage(CameraImage image) async {
    final processingStart = DateTime.now();

    try {
      final jpegBytes = await _convertCameraImageToJpeg(image);

      // Track processing time for adaptive optimization
      final processingDuration = DateTime.now()
          .difference(processingStart)
          .inMilliseconds;
      _performanceMetrics.addProcessingTime(processingDuration);

      return jpegBytes;
    } catch (e) {
      developer.log('Error processing camera image: $e');
      return null;
    }
  }

  /// Converts CameraImage to JPEG with proper color space and orientation
  ///
  /// This is the core image processing function that fixes the two critical issues:
  /// 1. **Grayscale Problem**: Uses correct YUV to RGB conversion coefficients
  /// 2. **Rotation Problem**: Applies 90° clockwise rotation for Android portrait mode
  ///
  /// ## YUV to RGB Conversion
  /// Uses proper ITU-R BT.601 color space coefficients:
  /// - R = Y + 1.370705 * (V - 128)
  /// - G = Y - 0.337633 * (U - 128) - 0.698001 * (V - 128)
  /// - B = Y + 1.732446 * (U - 128)
  ///
  /// ## Processing Steps
  /// 1. Parse YUV420 or BGRA8888 planes from camera
  /// 2. Convert to RGB pixel-by-pixel with proper coefficients
  /// 3. Apply downsampling if scale < 1.0 (for slower networks)
  /// 4. Rotate 90° clockwise (Android cameras need this for portrait)
  /// 5. Encode as JPEG with current quality setting
  ///
  /// [image] - Raw camera image
  /// Returns JPEG bytes with correct colors and orientation
  Future<Uint8List> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      // Use image package directly for better YUV handling
      img.Image imgImage;

      if (image.format.group == ImageFormatGroup.yuv420) {
        // Convert YUV420 to RGB using image package (handles color correctly)
        final width = image.width;
        final height = image.height;

        // Create RGB image from YUV planes
        imgImage = img.Image(width: width, height: height);

        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];

        final yBuffer = yPlane.bytes;
        final uBuffer = uPlane.bytes;
        final vBuffer = vPlane.bytes;

        final uvRowStride = uPlane.bytesPerRow;
        final uvPixelStride = uPlane.bytesPerPixel ?? 1;

        for (int h = 0; h < height; h++) {
          for (int w = 0; w < width; w++) {
            final uvIndex = uvPixelStride * (w ~/ 2) + uvRowStride * (h ~/ 2);
            final yIndex = h * yPlane.bytesPerRow + w;

            final y = yBuffer[yIndex];
            final u = uBuffer[uvIndex];
            final v = vBuffer[uvIndex];

            // YUV to RGB conversion (proper coefficients)
            final r = (y + 1.370705 * (v - 128)).clamp(0, 255).round();
            final g = (y - 0.337633 * (u - 128) - 0.698001 * (v - 128))
                .clamp(0, 255)
                .round();
            final b = (y + 1.732446 * (u - 128)).clamp(0, 255).round();

            imgImage.setPixelRgba(w, h, r, g, b, 255);
          }
        }
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // Handle BGRA format
        final plane = image.planes[0];
        imgImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: plane.bytes.buffer,
          format: img.Format.uint8,
          numChannels: 4,
        );
      } else {
        throw Exception('Unsupported image format: ${image.format}');
      }

      // Apply downsampling if needed
      if (_currentImageScale < 1.0) {
        final newWidth = (imgImage.width * _currentImageScale).round();
        final newHeight = (imgImage.height * _currentImageScale).round();
        imgImage = img.copyResize(imgImage, width: newWidth, height: newHeight);
      }

      // Fix orientation: Rotate 90 degrees clockwise for portrait mode
      // Android cameras in portrait typically need this rotation
      imgImage = img.copyRotate(imgImage, angle: 90);

      // Encode as JPEG with current quality setting
      final jpegQuality = (_currentImageQuality * 100).round();
      final jpegBytes = img.encodeJpg(imgImage, quality: jpegQuality);

      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      developer.log('Error converting camera image to JPEG: $e');
      rethrow;
    }
  }

  /// Starts adaptive performance monitoring
  ///
  /// Monitors two key metrics every 2 seconds:
  /// 1. **Processing Time**: How long it takes to convert camera frames to JPEG
  /// 2. **Network Time**: Round-trip time for WebSocket communication
  ///
  /// Based on these metrics, automatically adjusts:
  /// - JPEG quality (30%-95%)
  /// - Image scale (40%-100%)
  /// - Detection interval (50ms-200ms)
  ///
  /// **Thresholds**:
  /// - Poor: Processing > 200ms OR Network > 1000ms
  /// - Good: Processing < 100ms AND Network < 500ms
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_disposed) return;

      _adjustPerformanceSettings();
    });
  }

  /// Adjusts quality settings based on performance metrics
  ///
  /// Uses rolling averages (last 10 samples) to determine:
  /// - Is performance poor? → Reduce quality/scale
  /// - Is performance good? → Increase quality/scale
  void _adjustPerformanceSettings() {
    final metrics = _performanceMetrics;

    if (metrics.isPerformancePoor || metrics.isNetworkSlow) {
      // Aggressive optimization for poor connections
      _reduceQualityForPoorConnection();

      // developer.log(
      //   'Poor performance detected - Network: ${metrics.averageNetworkResponseTime.toStringAsFixed(0)}ms, '
      //   'Processing: ${metrics.averageProcessingTime.toStringAsFixed(0)}ms',
      // );
    } else if (metrics.isPerformanceGood && metrics.isNetworkFast) {
      // Increase quality for good connections
      _increaseQualityForGoodConnection();

      // developer.log(
      //   'Good performance detected - Network: ${metrics.averageNetworkResponseTime.toStringAsFixed(0)}ms, '
      //   'Processing: ${metrics.averageProcessingTime.toStringAsFixed(0)}ms',
      // );
    }

    // developer.log(
    //   'Current settings: interval=${_currentDetectionInterval.inMilliseconds}ms, '
    //   'quality=${(_currentImageQuality * 100).toStringAsFixed(0)}%, '
    //   'scale=${(_currentImageScale * 100).toStringAsFixed(0)}% (JPEG format)',
    // );
  }

  void _reduceQualityForPoorConnection() {
    bool settingsChanged = false;

    // Increase detection interval to reduce network load
    if (_currentDetectionInterval < _kMaxDetectionInterval) {
      _currentDetectionInterval = Duration(
        milliseconds: (_currentDetectionInterval.inMilliseconds * 1.3).round(),
      );
      _restartDetectionLoop();
      settingsChanged = true;
    }

    // Reduce image quality
    if (_currentImageQuality > _kMinImageQuality) {
      _currentImageQuality = (_currentImageQuality * 0.85).clamp(
        _kMinImageQuality,
        _kMaxImageQuality,
      );
      settingsChanged = true;
    }

    // Reduce image scale for very poor connections
    if (_performanceMetrics.averageNetworkResponseTime > 1500 &&
        _currentImageScale > _kMinImageScale) {
      _currentImageScale = (_currentImageScale * 0.9).clamp(
        _kMinImageScale,
        1.0,
      );
      settingsChanged = true;
    }

    // Note: Always using JPEG format for optimal performance

    if (settingsChanged) {
      // developer.log('Reduced quality for poor connection');
    }
  }

  void _increaseQualityForGoodConnection() {
    bool settingsChanged = false;

    // Decrease detection interval for faster response
    if (_currentDetectionInterval > _kMinDetectionInterval) {
      _currentDetectionInterval = Duration(
        milliseconds: (_currentDetectionInterval.inMilliseconds * 0.9).round(),
      );
      _restartDetectionLoop();
      settingsChanged = true;
    }

    // Increase image quality
    if (_currentImageQuality < _kMaxImageQuality) {
      _currentImageQuality = (_currentImageQuality * 1.1).clamp(
        _kMinImageQuality,
        _kMaxImageQuality,
      );
      settingsChanged = true;
    }

    // Restore full image scale
    if (_currentImageScale < 1.0) {
      _currentImageScale = (_currentImageScale * 1.1).clamp(
        _kMinImageScale,
        1.0,
      );
      settingsChanged = true;
    }

    // Note: Always using JPEG format for optimal performance

    if (settingsChanged) {
      // developer.log('Increased quality for good connection');
    }
  }

  void _restartDetectionLoop() {
    if (_disposed) return;
    _detectionTimer?.cancel();
    _startDetectionLoop();
  }

  void _emitFeedback(DetectionFeedback feedback) {
    if (_disposed) return;

    // Always emit feedback for debugging - no filtering
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!_disposed) {
        _feedbackController.add(feedback);
      }
    });
  }

  /// Performs manual document capture with precise cropping and coordinate transformation
  ///
  /// Executes high-quality document capture for final processing, distinct from
  /// the continuous detection frames. This method ensures optimal image quality
  /// and precise document extraction for verification purposes.
  ///
  /// ## Capture Process
  /// 1. **Flash Management**: Ensures flash is disabled for consistent lighting
  /// 2. **High-Quality Capture**: Takes full resolution image for processing
  /// 3. **Format Conversion**: Converts to PNG for consistent processing
  /// 4. **Coordinate Transformation**: Maps screen target to image coordinates
  /// 5. **Precise Cropping**: Extracts exact document area with padding
  /// 6. **File Generation**: Creates processed XFile for downstream use
  ///
  /// ## Coordinate System Handling
  /// Accurately transforms the target rectangle from screen coordinates through:
  /// - Camera preview scaling calculations
  /// - Portrait/landscape orientation adjustments
  /// - Image dimension scaling factors
  /// - Crop offset calculations for center alignment
  ///
  /// ## Quality Optimization
  /// - Uses high resolution capture (distinct from detection frames)
  /// - Applies minimal padding for edge preservation
  /// - Maintains PNG format for lossless quality (final capture only, detection uses JPEG)
  /// - Handles coordinate clamping to prevent out-of-bounds cropping
  ///
  /// The captured image is emitted through the capture stream for consumption
  /// by the parent widget or application logic.
  Future<void> capture() async {
    if (_disposed) return;

    try {
      // Ensure flash is off before taking picture
      if (cameraController.value.flashMode != FlashMode.off) {
        await cameraController.setFlashMode(FlashMode.off);
      }

      final XFile file = await cameraController.takePicture();
      final originalBytes = await file.readAsBytes();

      // Convert to PNG format for final high-quality capture
      final pngBytes = await ImageCropper.convertToPng(originalBytes);

      // Get actual image dimensions
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final actualImage = frame.image;
      final imageWidth = actualImage.width.toDouble();
      final imageHeight = actualImage.height.toDouble();

      // Get camera preview size (note: in portrait mode, width/height are swapped)
      final previewSize = cameraController.value.previewSize!;
      final cameraWidth = previewSize.height
          .toDouble(); // Actual camera width in portrait
      final cameraHeight = previewSize.width
          .toDouble(); // Actual camera height in portrait

      // Calculate how the camera preview is displayed on screen
      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;

      // Camera preview is typically scaled to fill the screen height and center-cropped for width
      final previewScale = screenHeight / cameraHeight;
      final scaledPreviewWidth = cameraWidth * previewScale;

      // If scaled preview is wider than screen, it gets center-cropped
      final cropOffsetX = (scaledPreviewWidth - screenWidth) / 2;

      // Calculate the actual scaling from screen coordinates to image coordinates
      final scaleX = imageWidth / cameraWidth;
      final scaleY = imageHeight / cameraHeight;

      // developer.log('Manual capture - Image: ${imageWidth}x${imageHeight}');
      // developer.log('Manual capture - Camera: ${cameraWidth}x${cameraHeight}');
      // developer.log('Manual capture - Screen: ${screenWidth}x${screenHeight}');
      // developer.log('Manual capture - Preview scale: $previewScale');
      // developer.log(
      //   'Manual capture - Scaled preview width: $scaledPreviewWidth',
      // );
      // developer.log('Manual capture - Crop offset X: $cropOffsetX');
      // developer.log(
      //   'Manual capture - Image scale factors: scaleX=$scaleX, scaleY=$scaleY',
      // );

      // Transform target rectangle from screen coordinates to camera coordinates
      final cameraTargetRect = Rect.fromLTWH(
        (targetRect.left + cropOffsetX) / previewScale,
        targetRect.top / previewScale,
        targetRect.width / previewScale,
        targetRect.height / previewScale,
      );

      // Then scale from camera coordinates to actual image coordinates
      final imageTargetRect = Rect.fromLTWH(
        cameraTargetRect.left * scaleX,
        cameraTargetRect.top * scaleY,
        cameraTargetRect.width * scaleX,
        cameraTargetRect.height * scaleY,
      );

      // Add padding to the target area for better cropping
      final paddedImageRect = Rect.fromLTRB(
        imageTargetRect.left - _kCropPadding,
        imageTargetRect.top - _kCropPadding,
        imageTargetRect.right + _kCropPadding,
        imageTargetRect.bottom + _kCropPadding,
      );

      // Clamp to image bounds to prevent cropping outside image
      final clampedRect = Rect.fromLTRB(
        paddedImageRect.left.clamp(0.0, imageWidth),
        paddedImageRect.top.clamp(0.0, imageHeight),
        paddedImageRect.right.clamp(0.0, imageWidth),
        paddedImageRect.bottom.clamp(0.0, imageHeight),
      );

      // developer.log('Manual capture - Original target rect: $targetRect');
      // developer.log('Manual capture - Camera target rect: $cameraTargetRect');
      // developer.log('Manual capture - Image target rect: $imageTargetRect');
      // developer.log(
      //   'Manual capture - Padded image rect (10px): $paddedImageRect',
      // );
      // developer.log('Manual capture - Clamped rect: $clampedRect');

      // Convert to bbox format for cropping
      final targetBboxList = [
        clampedRect.left,
        clampedRect.top,
        clampedRect.right,
        clampedRect.bottom,
      ];

      final croppedBytes = await ImageCropper.cropImage(
        pngBytes,
        targetBboxList,
      );
      final croppedPath = await ImageCropper.saveCroppedImage(
        croppedBytes,
        file.path.replaceAll('.jpg', '.png'),
      );

      final croppedFile = XFile(croppedPath);
      // Mark as manual capture (not automatic from ML backend)
      _captureController.add(
        CapturedImage(file: croppedFile, isAutomatic: false),
      );

      // developer.log(
      //   'Manual capture completed with proper coordinate transformation',
      // );
    } catch (e) {
      developer.log('Error during manual capture: $e');
    }
  }

  void disconnect() {
    _detectionTimer?.cancel();
    _steadyTimer?.cancel();
    _debounceTimer?.cancel();
    _stopImageStream(); // Stop image stream

    // Only disconnect if we created the WebSocket service ourselves
    if (!_wsServiceProvided) {
      _wsService.disconnect();
    }
  }

  /// Disposes of all resources and cleans up the camera service
  ///
  /// Performs comprehensive cleanup to prevent memory leaks and ensure
  /// proper resource management. This method should be called when the
  /// service is no longer needed.
  ///
  /// ## Cleanup Operations
  /// - **Timer Cancellation**: Stops all periodic operations
  /// - **Stream Subscriptions**: Cancels WebSocket event listeners
  /// - **Image Stream**: Stops camera frame processing
  /// - **WebSocket Management**: Disconnects and optionally disposes service
  /// - **Stream Controllers**: Closes feedback and capture streams
  ///
  /// ## WebSocket Handling
  /// Only disposes the WebSocket service if it was created internally.
  /// Externally provided services are left intact for the parent to manage.
  ///
  /// ## State Management
  /// Sets the disposed flag to prevent any further operations and ensures
  /// all async operations check this flag before proceeding.
  void dispose() {
    _disposed = true;
    _performanceTimer?.cancel();
    _wsStatusSub?.cancel();
    _wsMessageSub?.cancel();
    _wsErrorSub?.cancel();
    _periodicCaptureTimer?.cancel();
    _stopImageStream(); // Ensure stream is stopped
    disconnect();

    // Only dispose WebSocket service if we created it ourselves
    if (!_wsServiceProvided) {
      _wsService.dispose();
    }

    _feedbackController.close();
    _captureController.close();
  }
}
