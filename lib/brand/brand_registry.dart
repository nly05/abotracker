import 'package:flutter/material.dart';
import 'subscription_brand.dart';
import 'brand_logo.dart';

// Mapping: Welches Enum gehört zu welchem Logo/Farbe?
const Map<SubscriptionBrand, BrandInfo> brandRegistry = {
  
  // --- DEINE LOKALEN SVGS ---
  SubscriptionBrand.canva: BrandInfo(
    name: "Canva",
    color: Color(0xFF00C4CC),
    assetPath: "assets/logos/canva.svg", // Das File aus deinem Screenshot
  ),
  SubscriptionBrand.spusu: BrandInfo(
    name: "Spusu",
    color: Color(0xFF5DB82D),
    assetPath: "assets/logos/spusu.svg",
  ),
  SubscriptionBrand.wattpad: BrandInfo(
    name: "Wattpad",
    color: Color(0xFFFF5000),
    assetPath: "assets/logos/wattpad.svg",
  ),

  // --- DIE ONLINE BILDER ---
  SubscriptionBrand.netflix: BrandInfo(
    name: "Netflix",
    color: Color(0xFFE50914),
    webUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Netflix_icon.svg/2048px-Netflix_icon.svg.png",
  ),
  SubscriptionBrand.spotify: BrandInfo(
    name: "Spotify",
    color: Color(0xFF1DB954),
    webUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Spotify_icon.svg/2048px-Spotify_icon.svg.png",
  ),
  SubscriptionBrand.amazon: BrandInfo(
    name: "Amazon Prime",
    color: Color(0xFF00A8E1),
    webUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Amazon_icon.svg/2500px-Amazon_icon.svg.png",
  ),
  SubscriptionBrand.apple: BrandInfo(
    name: "iCloud+",
    color: Color(0xFF007AFF),
    webUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/ICloud_logo.svg/2560px-ICloud_logo.svg.png",
  ),
  SubscriptionBrand.youtube: BrandInfo(
    name: "YouTube",
    color: Color(0xFFFF0000),
    webUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/2560px-YouTube_full-color_icon_%282017%29.svg.png",
  ),
  
  // Fallback
  SubscriptionBrand.other: BrandInfo(
    name: "Sonstiges",
    color: Colors.grey,
  ),
};