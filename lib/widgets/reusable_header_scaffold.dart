import 'package:flutter/material.dart';

class ReusableHeaderScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? headerColor;
  final double headerHeight;
  final double borderRadius;
  final double overlappingOffset;
  final Widget? trailing;
  final bool centerTitle;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? contentPadding;
  final List<BoxShadow>? contentShadow;

  const ReusableHeaderScaffold({
    Key? key,
    required this.title,
    required this.child,
    this.onBackPressed,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.headerColor = const Color(0xFF10295C),
    this.headerHeight = 120,
    this.borderRadius = 24,
    this.overlappingOffset = -18,
    this.trailing,
    this.centerTitle = true,
    this.headerPadding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
    this.contentPadding,
    this.contentShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header Container
          Container(
            decoration: BoxDecoration(
              color: headerColor,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: headerPadding!,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: onBackPressed ?? () => Navigator.pop(context),
                        ),
                        if (centerTitle)
                          Expanded(
                            child: Center(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        if (trailing != null)
                          trailing!
                        else if (centerTitle)
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Content area with rounded corners overlapping header
          Expanded(
            child: Transform.translate(
              offset: Offset(0, overlappingOffset),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                  boxShadow: contentShadow ?? [
                    const BoxShadow(
                      color: Color(0x1A000000),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: contentPadding != null
                    ? Padding(
                        padding: contentPadding!,
                        child: child,
                      )
                    : child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified version for full-screen dialogs like MapSelectorDialog
class ReusableHeaderDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? headerColor;
  final double borderRadius;
  final double overlappingOffset;
  final Widget? trailing;
  final bool centerTitle;

  const ReusableHeaderDialog({
    Key? key,
    required this.title,
    required this.child,
    this.onBackPressed,
    this.backgroundColor = const Color(0xFF1E3A8A),
    this.headerColor = const Color(0xFF1E3A8A),
    this.borderRadius = 20,
    this.overlappingOffset = -20,
    this.trailing,
    this.centerTitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Header with back button and title
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                color: headerColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 8), // Adjusted left padding to match address screen
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios, // Changed to match address screen
                            color: Colors.white,
                            size: 18, // Changed size to match address screen
                          ),
                          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                        ),
                        if (centerTitle)
                          Expanded(
                            child: Center(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28, // Changed to match address screen
                                  fontWeight: FontWeight.w700, // Changed to match address screen
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28, // Changed to match address screen
                                fontWeight: FontWeight.w700, // Changed to match address screen
                              ),
                            ),
                          ),
                        if (trailing != null) 
                          trailing!
                        else if (centerTitle)
                          const SizedBox(width: 40), // Add balance for centering
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content container with rounded corners that overlaps header
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}