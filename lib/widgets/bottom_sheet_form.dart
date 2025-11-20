// Bottom Sheet Form Widget
// Related: T055, US2, FR-002, FR-003
// Reusable widget for forms in bottom sheet with dynamic height and scroll support

import 'package:flutter/material.dart';

class BottomSheetForm extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final String saveButtonText;
  final String cancelButtonText;
  final bool isLoading;
  final GlobalKey<FormState>? formKey;

  const BottomSheetForm({
    super.key,
    required this.title,
    required this.children,
    this.onSave,
    this.onCancel,
    this.saveButtonText = 'Guardar',
    this.cancelButtonText = 'Cancelar',
    this.isLoading = false,
    this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    // Dynamic height: max 80% of screen, adjusts for keyboard
    final maxHeight = screenHeight * 0.8;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel ?? () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: keyboardHeight + 16,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : (onCancel ?? () => Navigator.pop(context)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        side: const BorderSide(color: Color(0xFFB3D9F2)),
                        backgroundColor: const Color(0xFFE3F2FD),
                      ),
                      child: Text(cancelButtonText),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(saveButtonText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to show bottom sheet with form
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required VoidCallback onSave,
    String saveButtonText = 'Guardar',
    String cancelButtonText = 'Cancelar',
    bool isLoading = false,
    GlobalKey<FormState>? formKey,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetForm(
        title: title,
        children: children,
        onSave: onSave,
        saveButtonText: saveButtonText,
        cancelButtonText: cancelButtonText,
        isLoading: isLoading,
        formKey: formKey,
      ),
    );
  }
}
