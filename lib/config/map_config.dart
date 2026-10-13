// ============================================================================
// KONFIGURASI PETA & GOOGLE MAPS API KEY (T.H.A.L.I.A)
// ============================================================================
//
// PANDUAN MENGGANTI API KEY GOOGLE MAPS (OPSIONAL):
// ----------------------------------------------------------------------------
// Peta pada aplikasi ini sudah dirancang agar **LANGSUNG MENYALA** menampilkan
// peta jalanan, sungai Ciliwung, dan wilayah DKI Jakarta asli tanpa wajib
// memasukkan API Key berbayar terlebih dahulu.
//
// Namun, jika Anda sudah memiliki **Google Maps API Key** dari Google Cloud
// Console (https://console.cloud.google.com/google/maps-apis/credentials):
//
// 1. Ganti nilai konstanta [MapConfig.googleMapsApiKey] di bawah ini dengan
//    API Key Anda (contoh: `'AIzaSyB1234567890abcdef...'`).
// 2. Buka juga file `android/app/src/main/AndroidManifest.xml`, lalu ganti
//    nilai pada `<meta-data android:name="com.google.android.geo.API_KEY" ...>`
//    dengan API Key yang sama.
// 3. Jalankan ulang aplikasi (`flutter run` atau build APK).
// ============================================================================

/// Pilihan gaya layer peta interaktif yang tersedia di pojok kanan atas peta
enum MapTileStyle {
  /// Peta Jalan Standar Google Maps Asli (Jalan raya, sungai, gedung, nama tempat)
  googleStandard,

  /// Peta Clean Light Minimalist (CartoDB Positron / Nordic Light)
  nordicLight,

  /// Peta Satelit & Medan Terintegrasi (Google Maps Hybrid Satellite/Terrain)
  googleHybrid,
}

class MapConfig {
  MapConfig._();

  // ===========================================================================
  // 1. TEMPAT MENARUH API KEY GOOGLE MAPS ANDA
  // ===========================================================================
  /// Masukkan Google Maps API Key Anda di sini jika ada.
  /// Biarkan `'YOUR_GOOGLE_MAPS_API_KEY_HERE'` atau kosong `''` untuk tetap
  /// menggunakan mode tile peta jalan Jakarta asli secara langsung.
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  /// Mengecek apakah pengguna telah mengisi API Key Google Maps kustom
  static bool get hasCustomApiKey =>
      googleMapsApiKey.trim().isNotEmpty &&
      googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // ===========================================================================
  // 2. TEMPLATE URL TILE PETA ASLI (GOOGLE MAPS & CARTODB LIGHT)
  // ===========================================================================
  /// URL Tile Google Maps Standard Road (Jalan, Sungai Ciliwung, Label Kota)
  static const String googleRoadTileTemplate =
      'https://mt1.google.com/vt/lyrs=m&hl=id&x={x}&y={y}&z={z}';

  /// URL Tile Clean Light Minimalist (CartoDB Positron Light)
  static const String cartoLightTileTemplate =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  /// URL Tile Google Maps Satellite / Terrain Hybrid
  static const String googleHybridTileTemplate =
      'https://mt1.google.com/vt/lyrs=y&hl=id&x={x}&y={y}&z={z}';

  /// Header HTTP standar agar request tile dari Android tidak diblokir CDN
  static const Map<String, String> tileRequestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  };

  /// Menghasilkan URL tile untuk koordinat slippy map (z, x, y) sesuai layer aktif
  static String resolveTileUrl({
    required MapTileStyle style,
    required int z,
    required int x,
    required int y,
  }) {
    String template;
    switch (style) {
      case MapTileStyle.googleStandard:
        template = googleRoadTileTemplate;
        break;
      case MapTileStyle.nordicLight:
        template = cartoLightTileTemplate;
        break;
      case MapTileStyle.googleHybrid:
        template = googleHybridTileTemplate;
        break;
    }

    final maxTile = 1 << z;
    final wrappedX = ((x % maxTile) + maxTile) % maxTile;
    final clampedY = y.clamp(0, maxTile - 1);

    String url = template
        .replaceAll('{z}', z.toString())
        .replaceAll('{x}', wrappedX.toString())
        .replaceAll('{y}', clampedY.toString());

    // Jika pengguna sudah mengisi Google Maps API Key kustom dan memakai layer Google,
    // sertakan parameter key secara otomatis.
    if (hasCustomApiKey && style != MapTileStyle.nordicLight) {
      url = '$url&key=${googleMapsApiKey.trim()}';
    }

    return url;
  }

  /// Nama tampilan untuk tombol switch layer peta
  static String styleLabel(MapTileStyle style) {
    switch (style) {
      case MapTileStyle.googleStandard:
        return 'Google Maps';
      case MapTileStyle.nordicLight:
        return 'Nordic Light';
      case MapTileStyle.googleHybrid:
        return 'Satelit';
    }
  }

  /// Sub-info sumber peta aktif
  static String styleSourceBadge(MapTileStyle style) {
    switch (style) {
      case MapTileStyle.googleStandard:
        return hasCustomApiKey
            ? 'Google Maps API • DKI Jakarta'
            : 'Google Maps Asli • DKI Jakarta';
      case MapTileStyle.nordicLight:
        return 'Nordic Light (CartoDB) • DKI Jakarta';
      case MapTileStyle.googleHybrid:
        return 'Google Satelit • DKI Jakarta';
    }
  }

  // ===========================================================================
  // 3. KOORDINAT GPS NYATA DKI JAKARTA & BANTARAN SUNGAI CILIWUNG
  // ===========================================================================
  /// Titik GPS Pengguna: Bantaran Sungai Ciliwung (Kampung Melayu / Manggarai)
  static const double userGpsLat = -6.2250;
  static const double userGpsLng = 106.8600;

  /// Koordinat Tengah Awal Peta (mencakup seluruh stasiun DKI Jakarta)
  static const double initialCenterLat = -6.1920;
  static const double initialCenterLng = 106.8360;
  static const double initialZoom = 12.0;

  /// Koordinat Nyata Pos Pantau Wilayah Sekitar DKI Jakarta
  static const double jaktimLat = -6.2320; // Kampung Melayu / Cawang (1.8 km)
  static const double jaktimLng = 106.8670;

  static const double jakselLat = -6.2150; // Tebet / Manggarai (3.4 km)
  static const double jakselLng = 106.8480;

  static const double jakpusLat = -6.1950; // Menteng / Tanah Abang (4.2 km)
  static const double jakpusLng = 106.8320;

  static const double jakbarLat = -6.1780; // Tomang / Grogol (7.1 km)
  static const double jakbarLng = 106.7950;

  static const double jakutLat = -6.1280; // Ancol / Penjaringan (10.8 km)
  static const double jakutLng = 106.8350;
}
