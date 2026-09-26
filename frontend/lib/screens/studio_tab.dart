import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math' show max;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../theme.dart';

// ─── Canvas constants ─────────────────────────────────────────────────────────
const _kLogW = 540.0; // logical canvas width (invariant)

// ─── Size presets ─────────────────────────────────────────────────────────────
const _kSizes = [
  (label: 'Square', h: 540.0),
  (label: 'Portrait', h: 675.0),
  (label: 'Story', h: 960.0),
  (label: 'Landscape', h: 304.0),
];

// ─── Color palette ────────────────────────────────────────────────────────────
const _kPalette = <Color>[
  Color(0xFFFFFFFF), Color(0xFF080F0B), Color(0xFF004423), Color(0xFF006B3A),
  Color(0xFF38524A), Color(0xFF7A9487), Color(0xFFDBEAE1), Color(0xFFF5F9F6),
  Color(0xFFE53935), Color(0xFFE67E22), Color(0xFFF1C40F), Color(0xFF43A047),
  Color(0xFF1E88E5), Color(0xFF8E24AA), Color(0xFFE91E63), Color(0xFF00ACC1),
  Color(0xFFFF5722), Color(0xFF6D4C41), Color(0xFF546E7A), Color(0xFF212121),
];

// ─── Font options ─────────────────────────────────────────────────────────────
const _kFonts = ['DM Sans', 'Playfair Display', 'Space Mono'];

// ─── Element type ─────────────────────────────────────────────────────────────
enum ElType { text, rect, ellipse }

// ─── Canvas element model ─────────────────────────────────────────────────────
class _El {
  final String id;
  ElType type;
  double x, y, w, h;
  int z;

  // text
  String text;
  double fontSize;
  Color textColor;
  bool bold;
  bool italic;
  TextAlign textAlign;
  String fontFamily;

  // shape fill
  Color fill;
  Color fill2;
  bool useGradient;
  double radius; // corner radius for rect
  Color strokeColor;
  double strokeWidth;

  // common
  double opacity;

  _El({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.z = 0,
    this.text = 'Your text',
    this.fontSize = 48,
    this.textColor = Colors.white,
    this.bold = true,
    this.italic = false,
    this.textAlign = TextAlign.center,
    this.fontFamily = 'DM Sans',
    this.fill = const Color(0x33FFFFFF),
    this.fill2 = const Color(0x11FFFFFF),
    this.useGradient = false,
    this.radius = 0,
    this.strokeColor = Colors.transparent,
    this.strokeWidth = 0,
    this.opacity = 1.0,
  });
}

// ─── Gallery item ─────────────────────────────────────────────────────────────
class _GItem {
  final String id;
  final String dataUrl;
  final String sizeLabel;
  final DateTime createdAt;
  bool isPinned;

  _GItem({
    required this.id,
    required this.dataUrl,
    required this.sizeLabel,
    required this.createdAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataUrl': dataUrl,
    'sizeLabel': sizeLabel,
    'createdAt': createdAt.toIso8601String(),
    'isPinned': isPinned,
  };

  static _GItem fromJson(Map<String, dynamic> j) => _GItem(
    id: j['id'] as String,
    dataUrl: j['dataUrl'] as String,
    sizeLabel: j['sizeLabel'] as String? ?? 'Square',
    createdAt: DateTime.parse(j['createdAt'] as String),
    isPinned: j['isPinned'] as bool? ?? false,
  );
}

// ─── Unique ID helper ─────────────────────────────────────────────────────────
int _idCounter = 0;
String _newId() => 'el_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

// ─── StudioPage ───────────────────────────────────────────────────────────────
class StudioPage extends StatefulWidget {
  final String creatorSlug;
  final String creatorName;
  const StudioPage({super.key, required this.creatorSlug, required this.creatorName});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  // ── Canvas ──────────────────────────────────────────────────────────────────
  int _sizeIdx = 0;
  Color _bgColor1 = const Color(0xFF004423);
  Color _bgColor2 = const Color(0xFF006B3A);
  bool _bgGradient = true;

  final List<_El> _elements = [];
  String? _selectedId;
  bool _exporting = false;

  // Text sync controller (properties panel → selected text element)
  final _textCtrl = TextEditingController();

  // Export
  final _repaintKey = GlobalKey();

  // Gallery
  final _gallery = <_GItem>[];
  bool _showGallery = true;
  static const _lsKey = 'studio_canva_v1';

  // ── Computed ─────────────────────────────────────────────────────────────────
  double get _logH => _kSizes[_sizeIdx].h;
  static const double _displayW = 440.0;
  double get _displayH => _displayW * _logH / _kLogW;
  double get _scale => _displayW / _kLogW;

  _El? get _selected =>
      _selectedId == null ? null : _elements.where((e) => e.id == _selectedId).firstOrNull;

  List<_El> get _sortedEls => [..._elements]..sort((a, b) => a.z.compareTo(b.z));

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadGallery();
    _seedDefaultElements();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _seedDefaultElements() {
    _elements.addAll([
      _El(
        id: _newId(), type: ElType.text,
        x: 40, y: 190, w: 460, h: 90, z: 1,
        text: widget.creatorName,
        fontSize: 54, textColor: Colors.white, bold: true,
        textAlign: TextAlign.center,
      ),
      _El(
        id: _newId(), type: ElType.text,
        x: 80, y: 300, w: 380, h: 60, z: 2,
        text: 'Support my work ✨',
        fontSize: 26, textColor: const Color(0xCCFFFFFF), bold: false,
        textAlign: TextAlign.center,
      ),
    ]);
  }

  // ── Gallery persistence ───────────────────────────────────────────────────────
  void _loadGallery() {
    try {
      final raw = html.window.localStorage[_lsKey];
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _gallery.addAll(list.map((j) => _GItem.fromJson(j as Map<String, dynamic>)));
      _gallery.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (_) {}
  }

  void _persistGallery() {
    html.window.localStorage[_lsKey] =
        jsonEncode(_gallery.map((g) => g.toJson()).toList());
  }

  // ── Export ────────────────────────────────────────────────────────────────────
  Future<void> _export() async {
    setState(() { _selectedId = null; _exporting = true; });
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final b64 = base64Encode(bytes.buffer.asUint8List());
      final dataUrl = 'data:image/png;base64,$b64';

      // Download
      html.AnchorElement(href: dataUrl)
        ..setAttribute('download', 'tippingjar-${DateTime.now().millisecondsSinceEpoch}.png')
        ..click();

      // Save to gallery
      final item = _GItem(
        id: _newId(),
        dataUrl: dataUrl,
        sizeLabel: _kSizes[_sizeIdx].label,
        createdAt: DateTime.now(),
      );
      setState(() {
        _gallery.insert(0, item);
        if (_gallery.length > 60) _gallery.removeLast();
      });
      _persistGallery();
    } finally {
      setState(() => _exporting = false);
    }
  }

  // ── Element operations ────────────────────────────────────────────────────────
  void _select(_El el) {
    setState(() {
      _selectedId = el.id;
      if (el.type == ElType.text) {
        _textCtrl.text = el.text;
        _textCtrl.selection = TextSelection.collapsed(offset: el.text.length);
      }
    });
  }

  void _deselect() => setState(() => _selectedId = null);

  void _addText() {
    final el = _El(
      id: _newId(), type: ElType.text,
      x: 100, y: 200, w: 340, h: 70, z: _elements.length,
      text: 'New text', fontSize: 36, textColor: Colors.white, bold: false,
    );
    _elements.add(el);
    _select(el);
  }

  void _addRect() {
    final el = _El(
      id: _newId(), type: ElType.rect,
      x: 110, y: 150, w: 320, h: 200, z: _elements.length,
      fill: Colors.white.withOpacity(0.15), radius: 16,
    );
    setState(() { _elements.add(el); _selectedId = el.id; });
  }

  void _addEllipse() {
    final el = _El(
      id: _newId(), type: ElType.ellipse,
      x: 170, y: 150, w: 200, h: 200, z: _elements.length,
      fill: Colors.white.withOpacity(0.15),
    );
    setState(() { _elements.add(el); _selectedId = el.id; });
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _elements.removeWhere((e) => e.id == _selectedId);
      _selectedId = null;
    });
  }

  void _duplicate() {
    final el = _selected;
    if (el == null) return;
    final copy = _El(
      id: _newId(), type: el.type,
      x: el.x + 20, y: el.y + 20, w: el.w, h: el.h, z: el.z + 1,
      text: el.text, fontSize: el.fontSize, textColor: el.textColor,
      bold: el.bold, italic: el.italic, textAlign: el.textAlign,
      fontFamily: el.fontFamily, fill: el.fill, fill2: el.fill2,
      useGradient: el.useGradient, radius: el.radius,
      strokeColor: el.strokeColor, strokeWidth: el.strokeWidth,
      opacity: el.opacity,
    );
    setState(() { _elements.add(copy); _selectedId = copy.id; });
    if (copy.type == ElType.text) _textCtrl.text = copy.text;
  }

  void _bringForward() { final el = _selected; if (el != null) setState(() => el.z++); }
  void _sendBackward() { final el = _selected; if (el != null) setState(() { if (el.z > 0) el.z--; }); }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _toolbar(),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _canvasArea()),
          _propertiesPanel(),
        ]),
      ),
      if (_showGallery) _galleryPanel(),
    ]);
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────────
  Widget _toolbar() {
    final hasSel = _selected != null;
    return Container(
      height: 52,
      decoration: BoxDecoration(color: kDarker, border: Border(bottom: BorderSide(color: kBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        // Size selector
        for (var i = 0; i < _kSizes.length; i++)
          _TBtn(
            label: _kSizes[i].label,
            active: _sizeIdx == i,
            onTap: () => setState(() { _sizeIdx = i; _selectedId = null; }),
          ),
        _Sep(),

        // Add elements
        _TBtn(label: '+ Text', icon: Iconsax.text, onTap: _addText),
        _TBtn(label: '+ Rect', icon: Icons.crop_square_rounded, onTap: _addRect),
        _TBtn(label: '+ Circle', icon: Icons.circle_outlined, onTap: _addEllipse),
        _Sep(),

        // Element actions (visible only when selected)
        if (hasSel) ...[
          _TBtn(icon: Iconsax.copy, tip: 'Duplicate', onTap: _duplicate),
          _TBtn(icon: Iconsax.arrow_up_2, tip: 'Bring forward', onTap: _bringForward),
          _TBtn(icon: Iconsax.arrow_down_2, tip: 'Send backward', onTap: _sendBackward),
          _TBtn(icon: Iconsax.trash, tip: 'Delete', danger: true, onTap: _deleteSelected),
          _Sep(),
        ],

        const Spacer(),

        // Gallery toggle
        _TBtn(
          icon: _showGallery ? Iconsax.gallery_tick : Iconsax.gallery,
          tip: 'Toggle gallery',
          active: _showGallery,
          onTap: () => setState(() => _showGallery = !_showGallery),
        ),
        const SizedBox(width: 10),

        // Export
        GestureDetector(
          onTap: _export,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Iconsax.import, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text('Export & Save',
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Canvas area ───────────────────────────────────────────────────────────────
  Widget _canvasArea() {
    return Container(
      color: kDark,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Canvas label
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _kSizes[_sizeIdx].label,
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 11, letterSpacing: 1),
              ),
            ),
            // Canvas
            RepaintBoundary(
              key: _repaintKey,
              child: SizedBox(
                width: _displayW,
                height: _displayH,
                child: GestureDetector(
                  onTap: _deselect,
                  child: ClipRect(child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Background
                      Positioned.fill(child: _renderBg()),
                      // Elements (z-sorted)
                      ..._sortedEls.map(_elementWidget),
                      // Selection handles (hidden during export)
                      if (!_exporting && _selected != null)
                        ..._selectionHandles(_selected!),
                    ],
                  )),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to select • Drag to move • Drag corners to resize',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _renderBg() {
    if (_bgGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor1, _bgColor2],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      );
    }
    return Container(color: _bgColor1);
  }

  Widget _elementWidget(_El el) {
    final s = _scale;
    final isSelected = el.id == _selectedId && !_exporting;

    Widget content;
    switch (el.type) {
      case ElType.text:   content = _textWidget(el, s);    break;
      case ElType.rect:   content = _rectWidget(el, s);    break;
      case ElType.ellipse: content = _ellipseWidget(el, s); break;
    }

    return Positioned(
      left: el.x * s,
      top: el.y * s,
      width: max(el.w * s, 20),
      height: max(el.h * s, 20),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(el),
        onPanUpdate: (d) {
          setState(() {
            el.x = (el.x + d.delta.dx / s).clamp(-el.w + 24, _kLogW - 24);
            el.y = (el.y + d.delta.dy / s).clamp(-el.h + 24, _logH - 24);
          });
        },
        child: Opacity(
          opacity: el.opacity.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  )
                : const BoxDecoration(),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _textWidget(_El el, double s) {
    TextStyle style;
    final sz = el.fontSize * s;
    final fw = el.bold ? FontWeight.w700 : FontWeight.w400;
    final fi = el.italic ? FontStyle.italic : FontStyle.normal;

    switch (el.fontFamily) {
      case 'Playfair Display':
        style = GoogleFonts.playfairDisplay(color: el.textColor, fontSize: sz, fontWeight: fw, fontStyle: fi, height: 1.2);
        break;
      case 'Space Mono':
        style = GoogleFonts.spaceMono(color: el.textColor, fontSize: sz, fontWeight: fw, fontStyle: fi, height: 1.2);
        break;
      default:
        style = GoogleFonts.dmSans(color: el.textColor, fontSize: sz, fontWeight: fw, fontStyle: fi, height: 1.2);
    }

    return Align(
      alignment: el.textAlign == TextAlign.center
          ? Alignment.center
          : el.textAlign == TextAlign.left
              ? Alignment.centerLeft
              : Alignment.centerRight,
      child: Text(el.text, style: style, textAlign: el.textAlign, softWrap: true),
    );
  }

  Widget _rectWidget(_El el, double s) {
    final r = el.radius * s / 10; // radius is 0-100, scale down
    BoxDecoration deco;
    if (el.useGradient) {
      deco = BoxDecoration(
        gradient: LinearGradient(colors: [el.fill, el.fill2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(r),
        border: el.strokeWidth > 0 ? Border.all(color: el.strokeColor, width: el.strokeWidth) : null,
      );
    } else {
      deco = BoxDecoration(
        color: el.fill,
        borderRadius: BorderRadius.circular(r),
        border: el.strokeWidth > 0 ? Border.all(color: el.strokeColor, width: el.strokeWidth) : null,
      );
    }
    return Container(decoration: deco);
  }

  Widget _ellipseWidget(_El el, double s) {
    BoxDecoration deco;
    if (el.useGradient) {
      deco = BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [el.fill, el.fill2]),
        border: el.strokeWidth > 0 ? Border.all(color: el.strokeColor, width: el.strokeWidth) : null,
      );
    } else {
      deco = BoxDecoration(
        shape: BoxShape.circle,
        color: el.fill,
        border: el.strokeWidth > 0 ? Border.all(color: el.strokeColor, width: el.strokeWidth) : null,
      );
    }
    return Container(decoration: deco);
  }

  // ── Selection handles ─────────────────────────────────────────────────────────
  List<Widget> _selectionHandles(_El el) {
    final s = _scale;
    final x = el.x * s;
    final y = el.y * s;
    final w = max(el.w * s, 20.0);
    final h = max(el.h * s, 20.0);
    const hs = 10.0;
    const hh = hs / 2;

    void resize(double dx, double dy, {bool left = false, bool top = false}) {
      setState(() {
        if (left) { el.x += dx / s; el.w -= dx / s; }
        else { el.w += dx / s; }
        if (top) { el.y += dy / s; el.h -= dy / s; }
        else { el.h += dy / s; }
        if (el.w < 20 / s) el.w = 20 / s;
        if (el.h < 20 / s) el.h = 20 / s;
      });
    }

    Widget handle(double l, double t, void Function(double, double) fn,
        {MouseCursor cursor = SystemMouseCursors.resizeUpLeftDownRight}) {
      return Positioned(
        left: l, top: t,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => fn(d.delta.dx, d.delta.dy),
            child: Container(
              width: hs, height: hs,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return [
      // Selection border
      Positioned(
        left: x, top: y, width: w, height: h,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
            ),
          ),
        ),
      ),
      // 4 corners
      handle(x - hh, y - hh, (dx, dy) => resize(dx, dy, left: true, top: true)),
      handle(x + w - hh, y - hh, (dx, dy) => resize(dx, dy, top: true)),
      handle(x - hh, y + h - hh, (dx, dy) => resize(dx, dy, left: true)),
      handle(x + w - hh, y + h - hh, (dx, dy) => resize(dx, dy)),
      // 4 edge midpoints
      handle(x + w / 2 - hh, y - hh, (dx, dy) => resize(0, dy, top: true),
          cursor: SystemMouseCursors.resizeRow),
      handle(x + w / 2 - hh, y + h - hh, (dx, dy) => resize(0, dy),
          cursor: SystemMouseCursors.resizeRow),
      handle(x - hh, y + h / 2 - hh, (dx, dy) => resize(dx, 0, left: true),
          cursor: SystemMouseCursors.resizeColumn),
      handle(x + w - hh, y + h / 2 - hh, (dx, dy) => resize(dx, 0),
          cursor: SystemMouseCursors.resizeColumn),
    ];
  }

  // ── Properties panel ──────────────────────────────────────────────────────────
  Widget _propertiesPanel() {
    final el = _selected;
    return Container(
      width: 272,
      color: kDarker,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Panel header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
          child: Row(children: [
            Icon(
              el == null ? Iconsax.brush_2 : el.type == ElType.text ? Iconsax.text : Iconsax.element_equal,
              size: 14, color: kPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              el == null ? 'Canvas' : el.type == ElType.text ? 'Text' : 'Shape',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (el != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: _deselect,
                child: Icon(Icons.close_rounded, size: 14, color: kMuted),
              ),
            ],
          ]),
        ),
        // Panel body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: el == null ? _canvasProps() : _elementProps(el),
          ),
        ),
      ]),
    );
  }

  Widget _canvasProps() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _PLabel('Background'),
    const SizedBox(height: 10),
    Row(children: [
      Text('Use gradient', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      const Spacer(),
      Switch(
        value: _bgGradient,
        onChanged: (v) => setState(() => _bgGradient = v),
        activeColor: kPrimary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ]),
    const SizedBox(height: 12),
    _PLabel(_bgGradient ? 'Color 1' : 'Color'),
    const SizedBox(height: 8),
    _ColorPicker(selected: _bgColor1, onPick: (c) => setState(() => _bgColor1 = c)),
    if (_bgGradient) ...[
      const SizedBox(height: 12),
      _PLabel('Color 2'),
      const SizedBox(height: 8),
      _ColorPicker(selected: _bgColor2, onPick: (c) => setState(() => _bgColor2 = c)),
    ],
    const SizedBox(height: 20),
    _PLabel('Canvas Size'),
    const SizedBox(height: 10),
    for (var i = 0; i < _kSizes.length; i++)
      GestureDetector(
        onTap: () => setState(() { _sizeIdx = i; _selectedId = null; }),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _sizeIdx == i ? kPrimary.withOpacity(0.15) : kCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _sizeIdx == i ? kPrimary : kBorder),
          ),
          child: Text(_kSizes[i].label,
              style: GoogleFonts.dmSans(
                  color: _sizeIdx == i ? kPrimary : Colors.white70, fontSize: 13)),
        ),
      ),
  ]);

  Widget _elementProps(_El el) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (el.type == ElType.text) ...[
      _PLabel('Content'),
      const SizedBox(height: 8),
      TextField(
        controller: _textCtrl,
        maxLines: 4,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          filled: true, fillColor: kCardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPrimary)),
          contentPadding: const EdgeInsets.all(10),
        ),
        onChanged: (v) => setState(() => el.text = v),
      ),
      const SizedBox(height: 14),

      _PLabel('Font'),
      const SizedBox(height: 8),
      _FontPicker(selected: el.fontFamily, onPick: (f) => setState(() => el.fontFamily = f)),
      const SizedBox(height: 14),

      _PLabel('Size  ${el.fontSize.round()}px'),
      Slider(
        value: el.fontSize.clamp(10.0, 120.0),
        min: 10, max: 120, divisions: 110,
        activeColor: kPrimary,
        onChanged: (v) => setState(() => el.fontSize = v),
      ),

      Row(children: [
        _TglBtn('B', el.bold, () => setState(() => el.bold = !el.bold), bold: true),
        const SizedBox(width: 6),
        _TglBtn('I', el.italic, () => setState(() => el.italic = !el.italic), italic: true),
        const SizedBox(width: 10),
        _AlignBtn(TextAlign.left, el.textAlign, (a) => setState(() => el.textAlign = a)),
        _AlignBtn(TextAlign.center, el.textAlign, (a) => setState(() => el.textAlign = a)),
        _AlignBtn(TextAlign.right, el.textAlign, (a) => setState(() => el.textAlign = a)),
      ]),
      const SizedBox(height: 14),

      _PLabel('Text Color'),
      const SizedBox(height: 8),
      _ColorPicker(selected: el.textColor, onPick: (c) => setState(() => el.textColor = c)),
    ] else ...[
      _PLabel('Fill Color'),
      const SizedBox(height: 8),
      _ColorPicker(selected: el.fill, onPick: (c) => setState(() => el.fill = c)),
      const SizedBox(height: 12),
      Row(children: [
        Text('Gradient', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        const Spacer(),
        Switch(
          value: el.useGradient,
          onChanged: (v) => setState(() => el.useGradient = v),
          activeColor: kPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
      if (el.useGradient) ...[
        const SizedBox(height: 8),
        _PLabel('Color 2'),
        const SizedBox(height: 8),
        _ColorPicker(selected: el.fill2, onPick: (c) => setState(() => el.fill2 = c)),
      ],
      if (el.type == ElType.rect) ...[
        const SizedBox(height: 12),
        _PLabel('Corner Radius  ${el.radius.round()}'),
        Slider(
          value: el.radius.clamp(0.0, 100.0), min: 0, max: 100,
          activeColor: kPrimary,
          onChanged: (v) => setState(() => el.radius = v),
        ),
      ],
      const SizedBox(height: 6),
      _PLabel('Border Width  ${el.strokeWidth.round()}'),
      Slider(
        value: el.strokeWidth.clamp(0.0, 12.0), min: 0, max: 12,
        activeColor: kPrimary,
        onChanged: (v) => setState(() => el.strokeWidth = v),
      ),
      if (el.strokeWidth > 0) ...[
        _PLabel('Border Color'),
        const SizedBox(height: 8),
        _ColorPicker(selected: el.strokeColor, onPick: (c) => setState(() => el.strokeColor = c)),
      ],
    ],

    // Common: opacity
    const SizedBox(height: 14),
    _PLabel('Opacity  ${(el.opacity * 100).round()}%'),
    Slider(
      value: el.opacity.clamp(0.0, 1.0), min: 0, max: 1,
      activeColor: kPrimary,
      onChanged: (v) => setState(() => el.opacity = v),
    ),

    // Position & size (editable)
    const SizedBox(height: 6),
    _PLabel('Position & Size'),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _NumField('X', el.x.round(), (v) => setState(() => el.x = v.toDouble()))),
      const SizedBox(width: 8),
      Expanded(child: _NumField('Y', el.y.round(), (v) => setState(() => el.y = v.toDouble()))),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: _NumField('W', el.w.round(), (v) => setState(() => el.w = max(20, v.toDouble())))),
      const SizedBox(width: 8),
      Expanded(child: _NumField('H', el.h.round(), (v) => setState(() => el.h = max(20, v.toDouble())))),
    ]),
  ]);

  // ── Gallery panel ─────────────────────────────────────────────────────────────
  Widget _galleryPanel() {
    return Container(
      height: 168,
      decoration: BoxDecoration(color: kDarker, border: Border(top: BorderSide(color: kBorder))),
      child: _gallery.isEmpty
          ? Center(child: Text('Saved assets appear here', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: _gallery.length,
              itemBuilder: (_, i) {
                final item = _gallery[i];
                return _GalleryCard(
                  item: item,
                  onDelete: () { setState(() { _gallery.removeAt(i); }); _persistGallery(); },
                  onPin: () { setState(() { item.isPinned = !item.isPinned; }); _persistGallery(); },
                  onDownload: () {
                    html.AnchorElement(href: item.dataUrl)
                      ..setAttribute('download', 'tippingjar-${item.id}.png')
                      ..click();
                  },
                );
              },
            ),
    );
  }
}

// ─── Small helper widgets ─────────────────────────────────────────────────────

class _TBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? tip;
  final bool active, danger;
  final VoidCallback? onTap;
  const _TBtn({this.label, this.icon, this.tip, this.active = false, this.danger = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red[300]! : active ? kPrimary : Colors.white70;
    return Tooltip(
      message: tip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: active && !danger
              ? BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(6))
              : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) Icon(icon!, size: 14, color: color),
            if (icon != null && label != null) const SizedBox(width: 4),
            if (label != null)
              Text(label!, style: GoogleFonts.dmSans(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 24, width: 1, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _PLabel extends StatelessWidget {
  final String text;
  const _PLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4));
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final void Function(Color) onPick;
  const _ColorPicker({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6, runSpacing: 6,
    children: _kPalette.map((c) {
      final isSel = c.value == selected.value;
      return GestureDetector(
        onTap: () => onPick(c),
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: c, shape: BoxShape.circle,
            border: isSel ? Border.all(color: Colors.white, width: 2.5) : Border.all(color: Colors.white12),
            boxShadow: isSel ? [const BoxShadow(color: Color(0xFF2196F3), blurRadius: 4, spreadRadius: 1)] : null,
          ),
        ),
      );
    }).toList(),
  );
}

class _FontPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onPick;
  const _FontPicker({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) => Column(
    children: _kFonts.map((f) {
      final isSel = f == selected;
      return GestureDetector(
        onTap: () => onPick(f),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? kPrimary.withOpacity(0.15) : kCardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSel ? kPrimary : kBorder),
          ),
          child: Text(f, style: GoogleFonts.dmSans(color: isSel ? kPrimary : Colors.white70, fontSize: 12)),
        ),
      );
    }).toList(),
  );
}

class _TglBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool bold, italic;
  const _TglBtn(this.label, this.active, this.onTap, {this.bold = false, this.italic = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: active ? kPrimary.withOpacity(0.15) : kCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? kPrimary : kBorder),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: GoogleFonts.dmSans(
              color: active ? kPrimary : Colors.white70,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontSize: 13)),
    ),
  );
}

class _AlignBtn extends StatelessWidget {
  final TextAlign align;
  final TextAlign selected;
  final void Function(TextAlign) onPick;
  const _AlignBtn(this.align, this.selected, this.onPick);

  @override
  Widget build(BuildContext context) {
    final active = align == selected;
    final icon = align == TextAlign.left
        ? Icons.format_align_left
        : align == TextAlign.center
            ? Icons.format_align_center
            : Icons.format_align_right;
    return GestureDetector(
      onTap: () => onPick(align),
      child: Container(
        width: 30, height: 30,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: active ? kPrimary.withOpacity(0.15) : kCardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? kPrimary : kBorder),
        ),
        child: Icon(icon, size: 15, color: active ? kPrimary : Colors.white70),
      ),
    );
  }
}

class _NumField extends StatefulWidget {
  final String label;
  final int value;
  final void Function(int) onSubmit;
  const _NumField(this.label, this.value, this.onSubmit);

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _ctrl;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumField old) {
    super.didUpdateWidget(old);
    if (!_focused && old.value != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (f) => setState(() => _focused = f),
    child: TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
        filled: true, fillColor: kCardBg,
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kPrimary)),
      ),
      onSubmitted: (v) {
        final n = int.tryParse(v);
        if (n != null) widget.onSubmit(n);
      },
    ),
  );
}

class _GalleryCard extends StatelessWidget {
  final _GItem item;
  final VoidCallback onDelete, onPin, onDownload;
  const _GalleryCard({required this.item, required this.onDelete, required this.onPin, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(item.dataUrl.substring(item.dataUrl.indexOf(',') + 1));
    return Container(
      width: 116,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        Expanded(child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item.sizeLabel, style: GoogleFonts.dmSans(color: kMuted, fontSize: 9)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _Ic(item.isPinned ? Icons.star_rounded : Icons.star_border_rounded,
                  item.isPinned ? Colors.amber : kMuted, onPin),
              const SizedBox(width: 6),
              _Ic(Iconsax.import, kMuted, onDownload),
              const SizedBox(width: 6),
              _Ic(Iconsax.trash, Colors.red.shade300, onDelete),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Ic extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Ic(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, size: 14, color: color),
  );
}
