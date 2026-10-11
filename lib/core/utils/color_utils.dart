import 'package:flutter/material.dart';

/// Returns true when [color] is too light to stay a reliably scannable QR
/// foreground: modules this light lose contrast against a white background
/// and many scanners fail to read them.
///
/// Used by the Create screen to show the contrast warning; the threshold
/// (relative luminance > 0.55) errs on the side of warning.
bool qrColorWarns(Color color) => color.computeLuminance() > 0.55;
