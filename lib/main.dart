import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Deine Brand-Dateien (lib/brand/...)
import 'brand/subscription_brand.dart';
import 'brand/brand_logo.dart';
import 'brand/brand_registry.dart';

void main() {
  runApp(const SubscriptionApp());
}

// --- HELPER ---
SubscriptionBrand findBrandByName(String name) {
  final n = name.toLowerCase().trim();
  if (n.contains("canva")) return SubscriptionBrand.canva;
  if (n.contains("spusu")) return SubscriptionBrand.spusu;
  if (n.contains("wattpad")) return SubscriptionBrand.wattpad;
  if (n.contains("netflix")) return SubscriptionBrand.netflix;
  if (n.contains("spotify")) return SubscriptionBrand.spotify;
  if (n.contains("amazon") || n.contains("prime")) return SubscriptionBrand.amazon;
  if (n.contains("apple") || n.contains("icloud")) return SubscriptionBrand.apple;
  if (n.contains("youtube")) return SubscriptionBrand.youtube;
  return SubscriptionBrand.other;
}

Widget buildBrandLogo(String name, double size, int colorValue) {
  SubscriptionBrand brand = findBrandByName(name);
  BrandInfo? info = brandRegistry[brand];
  Color fallbackColor = Color(colorValue);

  if (info?.assetPath != null) {
    return SvgPicture.asset(info!.assetPath!, width: size, height: size, fit: BoxFit.contain);
  } else if (info?.webUrl != null) {
    return Image.network(info!.webUrl!, width: size, height: size, fit: BoxFit.contain, errorBuilder: (c,o,e) => Icon(Icons.subscriptions, size: size, color: info.color));
  } else {
    return Icon(Icons.subscriptions, size: size, color: fallbackColor);
  }
}

// --- 1. CONFIG ---
class AppColors {
  static const Color accent = Color(0xFFFF9F0A);
  static const Color accentLight = Color(0xFFFFE5B4);
  static const Color success = Color(0xFF34C759);
  static const Color textDark = Color(0xFF1C1C1E);
}

class SubscriptionApp extends StatelessWidget {
  const SubscriptionApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, fontFamily: 'San Francisco', scaffoldBackgroundColor: const Color(0xFFF2F2F7), primaryColor: AppColors.accent, useMaterial3: true, cardColor: Colors.white),
      darkTheme: ThemeData(brightness: Brightness.dark, fontFamily: 'San Francisco', scaffoldBackgroundColor: Colors.black, primaryColor: AppColors.accent, cardColor: const Color(0xFF1C1C1E), useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}

// --- 2. MODEL ---
class Subscription {
  final String id;
  final String name;
  final String category;
  final double price;
  final DateTime nextPayment;
  final int colorValue;
  final bool isYearly;

  Subscription({required this.id, required this.name, required this.category, required this.price, required this.nextPayment, required this.colorValue, this.isYearly = false});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'price': price, 'nextPayment': nextPayment.toIso8601String(), 'colorValue': colorValue, 'isYearly': isYearly};
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(id: json['id'], name: json['name'], category: json['category'], price: json['price'], nextPayment: DateTime.parse(json['nextPayment']), colorValue: json['colorValue'], isYearly: json['isYearly']);
  }
}

// --- 3. MAIN SCAFFOLD ---
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  List<Subscription> mySubs = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subsString = prefs.getString('subs_data');
    if (subsString != null) {
      List<dynamic> jsonList = jsonDecode(subsString);
      setState(() { mySubs = jsonList.map((json) => Subscription.fromJson(json)).toList(); isLoading = false; });
    } else { setState(() { mySubs = []; isLoading = false; }); }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(mySubs.map((s) => s.toJson()).toList());
    await prefs.setString('subs_data', jsonString);
  }

  void _saveSubscription(Subscription sub) {
    setState(() {
      int index = mySubs.indexWhere((s) => s.id == sub.id);
      if (index != -1) { mySubs[index] = sub; } else { mySubs.add(sub); }
    });
    _saveData();
  }

  void _deleteSubscription(String id) { setState(() => mySubs.removeWhere((s) => s.id == id)); _saveData(); }

  void _openModal({Subscription? subToEdit}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AddSubscriptionModal(onSave: _saveSubscription, existingSub: subToEdit));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, systemOverlayStyle: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark, backgroundColor: Colors.transparent),
      body: SafeArea(child: DashboardScreen(subs: mySubs, onDelete: _deleteSubscription, onEdit: (s) => _openModal(subToEdit: s))),
      floatingActionButton: FloatingActionButton(onPressed: () => _openModal(), backgroundColor: Theme.of(context).cardColor, elevation: 4, shape: const CircleBorder(), child: Icon(Icons.add, color: AppColors.accent)),
    );
  }
}

// --- 4. DASHBOARD ---
class DashboardScreen extends StatelessWidget {
  final List<Subscription> subs;
  final Function(String) onDelete;
  final Function(Subscription) onEdit;
  const DashboardScreen({super.key, required this.subs, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1C1C1E);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Meine Abos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)), IconButton(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => YearOverviewScreen(subs: subs))); }, icon: Icon(Icons.bar_chart_rounded, color: textColor, size: 28))])),
          Container(margin: const EdgeInsets.symmetric(horizontal: 20), height: 36, decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)), child: TabBar(labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, unselectedLabelColor: Colors.grey, indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent, indicator: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]), tabs: const [Tab(text: "Monatlich"), Tab(text: "Jährlich")])),
          const SizedBox(height: 12),
          Expanded(child: TabBarView(children: [MonthlyView(subs: subs, onDelete: onDelete, onEdit: onEdit), YearlyView(subs: subs, onDelete: onDelete, onEdit: onEdit)])),
        ],
      ),
    );
  }
}

// --- 5. MONATSANSICHT (MIT MARKIERUNG FÜR HEUTE) ---
class MonthlyView extends StatelessWidget {
  final List<Subscription> subs;
  final Function(String) onDelete;
  final Function(Subscription) onEdit;
  const MonthlyView({super.key, required this.subs, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final relevantSubs = subs.where((s) => !s.isYearly || (s.isYearly && s.nextPayment.month == now.month)).toList();
    relevantSubs.sort((a, b) => a.nextPayment.day.compareTo(b.nextPayment.day));
    final paidSubs = relevantSubs.where((s) => s.nextPayment.day < now.day).toList();
    double totalCost = relevantSubs.fold(0, (sum, s) => sum + s.price);
    double progressPercent = relevantSubs.isEmpty ? 0 : paidSubs.length / relevantSubs.length;
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    int weekdayOffset = firstDayOfMonth.weekday - 1; 
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    String monthName = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"][now.month - 1];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF9F0A), Color(0xFFFFB340)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFFFF9F0A).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Ausgaben aktuell", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)), Text("€${totalCost.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progressPercent, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))), const SizedBox(height: 6), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${paidSubs.length}/${relevantSubs.length} bezahlt", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)), Text("${(progressPercent*100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))])])),
          const SizedBox(height: 20), Text("$monthName ${now.year}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
          
          // KALENDER
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ["M", "D", "M", "D", "F", "S", "S"].map((e) => SizedBox(width: 30, child: Center(child: Text(e, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))))).toList()), const SizedBox(height: 8), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: weekdayOffset + daysInMonth, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4), itemBuilder: (context, index) { if (index < weekdayOffset) return const SizedBox(); int day = index - weekdayOffset + 1; Subscription? subOnDay; try { subOnDay = relevantSubs.firstWhere((s) => s.nextPayment.day == day); } catch(e) { subOnDay = null; } bool isToday = day == now.day; 
            
            // HIER IST DIE ÄNDERUNG: Container um den Tag
            return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 24, height: 24,
                decoration: isToday ? BoxDecoration(color: AppColors.accent, shape: BoxShape.circle) : null,
                alignment: Alignment.center,
                child: Text("$day", style: TextStyle(color: isToday ? Colors.white : (day < now.day ? Colors.grey.withValues(alpha: 0.5) : null), fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 12))
              ), 
              const SizedBox(height: 2), 
              if (subOnDay != null) SizedBox(width: 14, height: 14, child: buildBrandLogo(subOnDay.name, 14, subOnDay.colorValue)) else const SizedBox(height: 14)
            ]); })])),
          
          const SizedBox(height: 20), Text("Übersicht", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10),
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: relevantSubs.length, itemBuilder: (context, index) { return SubscriptionCardSwipeable(sub: relevantSubs[index], onDelete: onDelete, onEdit: onEdit); }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// --- 6. JÄHRLICHE ANSICHT ---
class YearlyView extends StatelessWidget {
  final List<Subscription> subs;
  final Function(String) onDelete;
  final Function(Subscription) onEdit;
  const YearlyView({super.key, required this.subs, required this.onDelete, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final yearlySubs = subs.where((s) => s.isYearly).toList();
    yearlySubs.sort((a, b) => a.nextPayment.compareTo(b.nextPayment));
    double totalYearly = yearlySubs.fold(0, (sum, s) => sum + s.price);
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.savings_outlined, color: AppColors.accent, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Jährliche Fixkosten", style: TextStyle(fontSize: 12, color: Colors.grey)), Text("€${totalYearly.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]))])), const SizedBox(height: 20), if (yearlySubs.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("Keine jährlichen Zahlungen"))) else ...yearlySubs.map((sub) => SubscriptionCardSwipeable(sub: sub, onDelete: onDelete, onEdit: onEdit))]);
  }
}

// --- 7. SWIPE & CARD ---
class SubscriptionCardSwipeable extends StatelessWidget {
  final Subscription sub;
  final Function(String) onDelete;
  final Function(Subscription) onEdit;
  const SubscriptionCardSwipeable({super.key, required this.sub, required this.onDelete, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 8), child: Dismissible(key: Key(sub.id), background: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit, color: Colors.white)), secondaryBackground: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.white)), confirmDismiss: (direction) async { if (direction == DismissDirection.startToEnd) { onEdit(sub); return false; } else { return true; } }, onDismissed: (direction) { if (direction == DismissDirection.endToStart) onDelete(sub.id); }, child: SubscriptionCard(sub: sub)));
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  const SubscriptionCard({super.key, required this.sub});
  String _getMonthName(int month) => ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"][month - 1];
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool isPaid = false;
    if (sub.isYearly) { if (now.month > sub.nextPayment.month) { isPaid = true; } else if (now.month == sub.nextPayment.month && now.day > sub.nextPayment.day) { isPaid = true; } } else { if (now.day > sub.nextPayment.day) { isPaid = true; } }
    Widget logoWidget = buildBrandLogo(sub.name, 20, sub.colorValue);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: Offset(0, 2))]), child: Row(children: [Container(width: 36, height: 36, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (Color(sub.colorValue)).withValues(alpha: 0.1), shape: BoxShape.circle), child: logoWidget), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sub.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text("${sub.category} • ${sub.nextPayment.day}. ${_getMonthName(sub.nextPayment.month)}", style: TextStyle(fontSize: 11, color: Colors.grey))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("€${sub.price.toStringAsFixed(2)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isPaid ? AppColors.success : null)), if (isPaid) Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle, size: 12, color: AppColors.success))])]));
  }
}

// --- 8. JAHRESÜBERSICHT SCREEN ---
class YearOverviewScreen extends StatelessWidget {
  final List<Subscription> subs;
  const YearOverviewScreen({super.key, required this.subs});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double baseMonthlyCost = subs.where((s) => !s.isYearly).fold(0, (sum, s) => sum + s.price);
    return Scaffold(
      appBar: AppBar(title: Text("Jahresplaner ${now.year}", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: ListView.separated(padding: const EdgeInsets.all(20), itemCount: 12, separatorBuilder: (c, i) => const SizedBox(height: 8), itemBuilder: (context, index) { int monthIndex = index + 1; List<Subscription> yearlyInThisMonth = subs.where((s) => s.isYearly && s.nextPayment.month == monthIndex).toList(); double extraCost = yearlyInThisMonth.fold(0, (sum, s) => sum + s.price); double totalMonthCost = baseMonthlyCost + extraCost; bool isCurrentMonth = monthIndex == now.month; bool hasYearly = extraCost > 0; double progress = totalMonthCost > 0 ? (totalMonthCost / 500).clamp(0.0, 1.0) : 0.0; return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: hasYearly ? AppColors.accent.withValues(alpha: 0.05) : Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: isCurrentMonth ? Border.all(color: AppColors.accent, width: 2) : Border.all(color: Colors.transparent)), child: Row(children: [SizedBox(width: 40, child: Text(_getMonthName(monthIndex), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCurrentMonth ? AppColors.accent : null))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(hasYearly ? AppColors.accent : Colors.grey))), if (yearlyInThisMonth.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text("+ ${yearlyInThisMonth.map((e)=>e.name).join(", ")}", style: TextStyle(fontSize: 10, color: Colors.grey)))])) ,const SizedBox(width: 12), Text("€${totalMonthCost.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))])); }),
    );
  }
  String _getMonthName(int i) => ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"][i-1];
}

// --- 9. ADD MODAL ---
class AddSubscriptionModal extends StatefulWidget {
  final Function(Subscription) onSave;
  final Subscription? existingSub; 
  const AddSubscriptionModal({super.key, required this.onSave, this.existingSub});
  @override
  State<AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<AddSubscriptionModal> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _dayController = TextEditingController();
  bool _isYearly = false;
  int _selectedYearlyMonth = 1; 
  Color _selectedColor = Colors.orange;
  String _selectedCategory = "Sonstiges";
  
  final List<String> _categories = ["Streaming", "Music", "Software", "Health", "Shopping", "Insurance", "Unterhaltung", "Telekommunikation", "Sonstiges"];
  final List<String> _monthNames = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];

  @override
  void initState() {
    super.initState();
    _selectedYearlyMonth = DateTime.now().month;
    if (widget.existingSub != null) {
      final s = widget.existingSub!;
      _nameController.text = s.name;
      _priceController.text = s.price.toString();
      _dayController.text = s.nextPayment.day.toString();
      _selectedCategory = _categories.contains(s.category) ? s.category : "Sonstiges";
      _selectedColor = Color(s.colorValue);
      _isYearly = s.isYearly;
      if (s.isYearly) { _selectedYearlyMonth = s.nextPayment.month; }
    }
  }

  void _checkAutoPreset(String val) {
    String n = val.toLowerCase();
    SubscriptionBrand brand = findBrandByName(val);
    if (brand != SubscriptionBrand.other && brandRegistry.containsKey(brand)) { setState(() { _selectedColor = brandRegistry[brand]!.color; }); }
    if (n.contains("wattpad")) { setState(() => _selectedCategory = "Unterhaltung"); }
    else if (n.contains("spusu")) { setState(() => _selectedCategory = "Telekommunikation"); }
    else if (n.contains("canva")) { setState(() => _selectedCategory = "Software"); }
    else if (n.contains("netflix") || n.contains("disney")) { setState(() => _selectedCategory = "Streaming"); }
    else if (n.contains("spotify") || n.contains("music")) { setState(() => _selectedCategory = "Music"); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existingSub != null ? "Bearbeiten" : "Neues Abo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, onChanged: _checkAutoPreset, decoration: InputDecoration(hintText: "Name (z.B. Wattpad)", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: "Preis", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _dayController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Tag", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCategory),
              initialValue: _selectedCategory, 
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), 
              onChanged: (v) => setState(() => _selectedCategory = v!), 
              decoration: InputDecoration(filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Jährliche Zahlung?"), 
                  Switch(value: _isYearly, activeTrackColor: AppColors.accent, activeThumbColor: Colors.white, onChanged: (v) => setState(() => _isYearly = v))
                ]),
                if (_isYearly) 
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(_selectedYearlyMonth),
                      initialValue: _selectedYearlyMonth,
                      decoration: InputDecoration(labelText: "Fällig im Monat", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_monthNames[index]))),
                      onChanged: (val) => setState(() => _selectedYearlyMonth = val!)
                    ),
                  )
              ],
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((c) => GestureDetector(onTap: () => setState(() => _selectedColor = c), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: _selectedColor == c ? Border.all(width: 2) : null)))).toList()),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final now = DateTime.now();
                  int day = int.tryParse(_dayController.text) ?? 1;
                  int month = _isYearly ? _selectedYearlyMonth : now.month;
                  final newSub = Subscription(id: widget.existingSub?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), name: _nameController.text, category: _selectedCategory, price: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0, nextPayment: DateTime(now.year, month, day), colorValue: _selectedColor.toARGB32(), isYearly: _isYearly);
                  widget.onSave(newSub);
                  Navigator.pop(context);
                }
              }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)), child: Text("Speichern")))
          ],
        ),
      ),
    );
  }
}