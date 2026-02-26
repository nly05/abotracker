import 'package:flutter/material.dart';

class BrandInfo {
  final String name;
  final Color color;
  final String? assetPath; // Pfad zum lokalen SVG (z.B. assets/logos/spusu.svg)
  final String? webUrl;    // Fallback URL (für Netflix etc.)

  const BrandInfo({
    required this.name,
    required this.color,
    this.assetPath,
    this.webUrl,
  });
}