import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const FoodVisionApp());
}

class FoodVisionApp extends StatelessWidget {
  const FoodVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodVision',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FoodHomePage(),
    );
  }
}

class FoodHomePage extends StatefulWidget {
  const FoodHomePage({super.key});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  bool _loading = false;
  String? _error;
  FoodAnalysisResponse? _result;

  static const String _endpoint = 'https://flask-app-23004343283.us-central1.run.app/analyze';

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final XFile? x = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (x == null) return;
      setState(() {
        _image = x;
        _result = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not pick image: $e');
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final bytes = await File(_image!.path).readAsBytes();
      final b64 = base64Encode(bytes);
      final mime = _detectMimeFromPath(_image!.path);

      final res = await http.post(
        Uri.parse(_endpoint),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "image": {
            "inlineData": {"data": b64, "mimeType": mime}
          }
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _result = FoodAnalysisResponse.fromJson(decoded));
      } else {
        setState(() {
          _error = 'Server responded with ${res.statusCode}: ${res.body.take(200)}';
        });
      }
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  cs.primaryContainer.withOpacity(0.55),
                  cs.secondaryContainer.withOpacity(0.45),
                  cs.tertiaryContainer.withOpacity(0.35),
                ],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: cs.primary.withOpacity(0.15), size: 280),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(color: cs.secondary.withOpacity(0.12), size: 320),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Glass(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                        child: Row(
                          children: [
                            const Icon(Icons.bubble_chart, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('FoodVision',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Snap or upload a food photo for instant nutrition insights.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ImageFrame(
                        image: _image,
                        onClear: () => setState(() {
                          _image = null;
                          _result = null;
                          _error = null;
                        }),
                      ),

                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Camera'),
                            onPressed: _loading ? null : () => _pick(ImageSource.camera),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Analyze'),
                            onPressed: (_image == null || _loading) ? null : _analyze,
                          ),
                        ],
                      ),

                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const _LoadingCard(),
                      ],

                      if (_error != null && _result == null) ...[
                        const SizedBox(height: 16),
                        _ErrorCard(message: _error!),
                      ],

                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _result == null
                              ? const SizedBox.shrink()
                              : _ResultScroller(
                                  child: _ResultCard(result: _result!),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.6,
              spreadRadius: size * 0.25,
            ),
          ],
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.image, required this.onClear});

  final XFile? image;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    return Glass(
      radius: 24,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: hasImage ? 230 : 170,
        width: double.infinity,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      File(image!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Tooltip(
                      message: 'Remove image',
                      child: IconButton.filledTonal(
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox.expand(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fastfood_outlined, size: 44),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick from camera or gallery',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3)),
          SizedBox(width: 12),
          Text('Analyzing your food…'),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Glass(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultScroller extends StatelessWidget {
  const _ResultScroller({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: child,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final FoodAnalysisResponse result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = result.foodAnalysis;

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.identifiedFood ?? 'Unknown food',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if ((r.portionSize ?? '').trim().isNotEmpty)
                _ChipLabel(icon: Icons.scale, label: r.portionSize!),
              if ((r.recognizedServingSize ?? '').trim().isNotEmpty)
                _ChipLabel(icon: Icons.local_dining, label: r.recognizedServingSize!),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outlineVariant),
          const SizedBox(height: 12),

          // per portion
          Row(
            children: [
              const Icon(Icons.local_fire_department, size: 20),
              const SizedBox(width: 6),
              Text('Nutrition per portion',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          _NutritionGrid(map: r.nutritionFactsPerPortion),
          const SizedBox(height: 12),

          // per 100g
          Row(
            children: [
              const Icon(Icons.scale_outlined, size: 20),
              const SizedBox(width: 6),
              Text('Nutrition per 100g',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          _NutritionGrid(map: r.nutritionFactsPer100g),

          if ((r.additionalNotes ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.notes_outlined, size: 20),
                const SizedBox(width: 6),
                Text('Notes',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: r.additionalNotes!
                  .map((n) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Icon(Icons.check_circle_outline, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(n)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.55),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.map});
  final Map<String, dynamic>? map;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (map == null || map!.isEmpty) {
      return Text(
        'No data available',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    const order = [
      'calories',
      'protein',
      'carbs',
      'fat',
      'fiber',
      'sugar',
      'sodium',
      'cholesterol',
    ];

    final entries = <MapEntry<String, String>>[];
    for (final key in order) {
      if (map!.containsKey(key)) {
        entries.add(MapEntry(key, '${map![key]}'));
      }
    }
    for (final e in map!.entries) {
      if (!order.contains(e.key)) {
        entries.add(MapEntry(e.key, '${e.value}'));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final columns = isWide ? 4 : 2;

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 60,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final e = entries[i];
            return Glass(
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titleize(e.key),
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(
                    e.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _titleize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Models

class FoodAnalysisResponse {
  final FoodAnalysis foodAnalysis;
  FoodAnalysisResponse({required this.foodAnalysis});

  factory FoodAnalysisResponse.fromJson(Map<String, dynamic> json) {
    // Flask route wraps as {"success": true, "data": {...}}
    final inner = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final fa = inner['foodAnalysis'] is Map<String, dynamic>
        ? inner['foodAnalysis'] as Map<String, dynamic>
        : inner; 

    return FoodAnalysisResponse(foodAnalysis: FoodAnalysis.fromJson(fa));
  }
}

class FoodAnalysis {
  final String? identifiedFood;
  final String? portionSize;
  final String? recognizedServingSize;
  final Map<String, dynamic>? nutritionFactsPerPortion;
  final Map<String, dynamic>? nutritionFactsPer100g;
  final List<String>? additionalNotes;

  FoodAnalysis({
    this.identifiedFood,
    this.portionSize,
    this.recognizedServingSize,
    this.nutritionFactsPerPortion,
    this.nutritionFactsPer100g,
    this.additionalNotes,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    List<String>? notes;
    final rawNotes = json['additionalNotes'];
    if (rawNotes is List) {
      notes = rawNotes.map((e) => '$e').toList();
    }

    Map<String, dynamic>? mapOrNull(dynamic v) =>
        v is Map<String, dynamic> ? v : null;

    return FoodAnalysis(
      identifiedFood: json['identifiedFood'] as String?,
      portionSize: json['portionSize'] as String?,
      recognizedServingSize: json['recognizedServingSize'] as String?,
      nutritionFactsPerPortion: mapOrNull(json['nutritionFactsPerPortion']),
      nutritionFactsPer100g: mapOrNull(json['nutritionFactsPer100g']),
      additionalNotes: notes,
    );
  }
}

// helpers

String _detectMimeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

extension _Take on String {
  String take(int n) => length <= n ? this : substring(0, n) + '…';
}