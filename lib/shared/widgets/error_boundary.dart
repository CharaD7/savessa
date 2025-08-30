import 'package:flutter/material.dart';

/// A widget that catches errors and displays a fallback UI instead of crashing
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    
    // Set a custom error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details;
        });
      }
      
      // Call the optional error callback
      widget.onError?.call(details);
      
      // Still report to Flutter's default error handler
      FlutterError.presentError(details);
    };
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget(context);
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The app encountered an unexpected error. You can try restarting or report this issue.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      // Show error details in debug mode
                      if (_errorDetails != null) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error Details'),
                            content: SingleChildScrollView(
                              child: Text(
                                _errorDetails!.exception.toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simplified error boundary that just shows a message
class SimpleErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;

  const SimpleErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorWidget: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      child: child,
    );
  }
}
