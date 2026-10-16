import 'package:flutter/material.dart';

void main() => runApp(const CoinEduApp());

enum Rol { admin, ustoz, talaba }
enum DavomatHolati { keldi, kelmadi, kechikdi }

class Foydalanuvchi {
  final String id, ism, foydalanuvchiNomi;
  final Rol rol;
  String parol;
  bool faol;
  int tangalar;
  Foydalanuvchi(this.id, this.ism, this.foydalanuvchiNomi, this.parol, this.rol, {this.faol = true, this.tangalar = 0});
}

class Kurs {
  final String id;
  String nomi, tavsif;
  Kurs(this.id, this.nomi, this.tavsif);
}

class Guruh {
  final String id, kursId, nomi;
  String? ustozId;
  final List<String> talabalarIdlari = [];
  Guruh(this.id, this.kursId, this.nomi, this.ustozId);
}

class Tranzaksiya {
  final String talabaId, turi, sababi, kimTomonidan;
  final int miqdor;
  final DateTime vaqt = DateTime.now();
  Tranzaksiya(this.talabaId, this.miqdor, this.turi, this.sababi, this.kimTomonidan);
}

class Ombor extends ChangeNotifier {
  static final Ombor i = Ombor._();
  final foydalanuvchilar = <Foydalanuvchi>[];
  final kurslar = <Kurs>[];
  final guruhlar = <Guruh>[];
  final davomatlar = <String, DavomatHolati>{};
  final mukofotlanganlar = <String, int>{};
  final tranzaksiyalar = <Tranzaksiya>[];
  int kelganlikTangasi = 10, kechikkanlikTangasi = 5;
  bool kechikishgaTangaBerish = false, manfiyBalansgaRuxsat = false;
  Foydalanuvchi? joriyFoydalanuvchi;
  int _n = 0;
  String yangiId() => '${++_n}';

  Ombor._() {
    foydalanuvchilar.add(Foydalanuvchi(yangiId(), 'Bosh Admin', 'admin', 'admin123', Rol.admin));
    final ustoz = Foydalanuvchi(yangiId(), 'Aziz Ustoz', 'teacher', 'teacher123', Rol.ustoz);
    final talaba1 = Foydalanuvchi(yangiId(), 'Madina Karimova', 'student', 'student123', Rol.talaba, tangalar: 45);
    final talaba2 = Foydalanuvchi(yangiId(), 'Jasur Aliyev', 'jasur', '123456', Rol.talaba, tangalar: 20);
    foydalanuvchilar.addAll([ustoz, talaba1, talaba2]);

    final kurs = Kurs(yangiId(), 'Flutter Dasturlash', 'Mobil ilovalar yaratish kursi');
    kurslar.add(kurs);

    final guruh = Guruh(yangiId(), kurs.id, 'Flutter 1', ustoz.id);
    guruh.talabalarIdlari.addAll([talaba1.id, talaba2.id]);
    guruhlar.add(guruh);
  }

  Foydalanuvchi? foydalanuvchi(String id) => foydalanuvchilar.where((u) => u.id == id).firstOrNull;
  List<Foydalanuvchi> rolBoyicha(Rol r) => foydalanuvchilar.where((u) => u.rol == r).toList();

  String? kirish(Rol r, String u, String p) {
    final moslar = foydalanuvchilar.where((x) => x.rol == r && x.foydalanuvchiNomi == u.trim() && x.parol == p);
    if (moslar.isEmpty) return 'Login yoki parol noto\'g\'ri!';
    if (!moslar.first.faol) return 'Hisob faolsizlantirilgan!';
    joriyFoydalanuvchi = moslar.first;
    notifyListeners();
    return null;
  }

  void chiqish() {
    joriyFoydalanuvchi = null;
    notifyListeners();
  }

  String? foydalanuvchiQoshish(Rol r, String ism, String foydalanuvchiNomi, String parol) {
    if (foydalanuvchilar.any((u) => u.foydalanuvchiNomi == foydalanuvchiNomi)) return 'Bu foydalanuvchi nomi band!';
    if (parol.length < 6) return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
    foydalanuvchilar.add(Foydalanuvchi(yangiId(), ism, foydalanuvchiNomi, parol, r));
    notifyListeners();
    return null;
  }

  void yangilash() => notifyListeners();

  String? tangaBerish(Foydalanuvchi talaba, int miqdor, String turi, String sabab) {
    final bajaruvchi = joriyFoydalanuvchi;
    if (bajaruvchi == null || talaba.rol != Rol.talaba) return 'Ruxsat etilmagan!';
    if (sabab.trim().isEmpty) return 'Sababini kiriting';
    if (bajaruvchi.rol == Rol.talaba) return 'Ruxsat etilmagan!';
    if (bajaruvchi.rol == Rol.ustoz) {
      final ozGuruhimi = guruhlar.any((g) => g.ustozId == bajaruvchi.id && g.talabalarIdlari.contains(talaba.id));
      if (!ozGuruhimi || miqdor <= 0 || miqdor > 50) return 'O\'qituvchi faqat o\'z o\'quvchisiga 1 dan 50 gacha tanga bera oladi';
    }
    if (talaba.tangalar + miqdor < 0 && !manfiyBalansgaRuxsat) return 'Balans manfiy bo\'lishi mumkin emas!';
    talaba.tangalar += miqdor;
    tranzaksiyalar.insert(0, Tranzaksiya(talaba.id, miqdor, turi, sabab.trim(), bajaruvchi.ism));
    notifyListeners();
    return null;
  }

  String sanaMatni(DateTime d) => d.toIso8601String().substring(0, 10);

  void davomatniSaqlash(Guruh guruh, DateTime sana, Map<String, DavomatHolati> yangiDavomat) {
    for (final entry in yangiDavomat.entries) {
      final kalit = '${guruh.id}|${sanaMatni(sana)}|${entry.key}';
      davomatlar[kalit] = entry.value;
      final kerakliTanga = entry.value == DavomatHolati.keldi
          ? kelganlikTangasi
          : (entry.value == DavomatHolati.kechikdi && kechikishgaTangaBerish ? kechikkanlikTangasi : 0);
      final oldingiTanga = mukofotlanganlar[kalit] ?? 0;
      if (kerakliTanga != oldingiTanga) {
        final talaba = foydalanuvchi(entry.key)!;
        final farq = kerakliTanga - oldingiTanga;
        if (talaba.tangalar + farq >= 0 || manfiyBalansgaRuxsat) {
          talaba.tangalar += farq;
          tranzaksiyalar.insert(0, Tranzaksiya(talaba.id, farq, 'davomat', 'Davomat ${sanaMatni(sana)} (${guruh.nomi})', joriyFoydalanuvchi?.ism ?? '-'));
          mukofotlanganlar[kalit] = kerakliTanga;
        }
      }
    }
    notifyListeners();
  }
}

final baza = Ombor.i;

void xabarKorsat(BuildContext c, String xabar) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Text(xabar, style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

Future<bool> tasdiqlashSohibi(BuildContext c, String xabar) async =>
    await showDialog<bool>(
        context: c,
        builder: (_) => AlertDialog(
          title: const Text('Tasdiqlash'),
          content: Text(xabar),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Yo\'q')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ha')),
          ],
        )) ??
        false;

Future<List<String>?> malumotSorash(BuildContext c, String sarlavha, List<String> yorliqlar, {Set<int> raqamli = const {}}) {
  final kontrollerlar = yorliqlar.map((_) => TextEditingController()).toList();
  return showDialog<List<String>>(
      context: c,
      builder: (_) => AlertDialog(
        title: Text(sarlavha, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < yorliqlar.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                      controller: kontrollerlar[i],
                      decoration: InputDecoration(labelText: yorliqlar[i], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      keyboardType: raqamli.contains(i) ? const TextInputType.numberWithOptions(signed: true) : null),
                ),
            ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () {
                if (kontrollerlar.any((e) => e.text.trim().isEmpty)) return;
                Navigator.pop(c, kontrollerlar.map((e) => e.text.trim()).toList());
              },
              child: const Text('Saqlash')),
        ],
      ));
}

Widget boshKorinish(String matn) => Center(
    child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_rounded, size: 60, color: Colors.indigo.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(matn, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
        ])));

class CoinEduApp extends StatelessWidget {
  const CoinEduApp({super.key});

  ThemeData tema(Brightness b) {
    final qorongu = b == Brightness.dark;
    const asosiyRang = Color(0xFF6366F1);
    const ikkilamchiRang = Color(0xFFF59E0B);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: asosiyRang, secondary: ikkilamchiRang, brightness: b),
      scaffoldBackgroundColor: qorongu ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: qorongu ? Colors.white : const Color(0xFF1E293B)),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        color: qorongu ? const Color(0xFF1E293B) : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: qorongu ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: qorongu ? Colors.white10 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: asosiyRang, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: qorongu ? const Color(0xFF1E293B) : Colors.white,
        indicatorColor: asosiyRang.withOpacity(0.18),
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: asosiyRang,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: baza,
    builder: (_, __) => MaterialApp(
      title: 'CoinEdu',
      debugShowCheckedModeBanner: false,
      theme: tema(Brightness.light),
      darkTheme: tema(Brightness.dark),
      home: baza.joriyFoydalanuvchi == null
          ? const XushKelibsizOynasi()
          : switch (baza.joriyFoydalanuvchi!.rol) {
        Rol.admin => const AdminBoshSahifa(),
        Rol.ustoz => const UstozBoshSahifa(),
        Rol.talaba => const TalabaBoshSahifa(),
      },
    ),
  );
}

const rolMalumotlari = {
  Rol.admin: ('Admin', 'Markazni to\'liq boshqarish', Icons.admin_panel_settings_rounded, Color(0xFF7C4DFF)),
  Rol.ustoz: ('O\'qituvchi', 'Davomat va tanga mukofotlari', Icons.school_rounded, Color(0xFF00BFA5)),
  Rol.talaba: ('O\'quvchi', 'Mening tangalarim va davomatim', Icons.person_rounded, Color(0xFFFF7043)),
};

class XushKelibsizOynasi extends StatelessWidget {
  const XushKelibsizOynasi({super.key});
  Widget doira(double s, int a) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(a)));

  Widget rolKarti(BuildContext context, Rol r) {
    final (sarlavha, tavsif, ikonka, rang) = rolMalumotlari[r]!;
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
            color: Colors.white,
            elevation: 6,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KirishOynasi(r))),
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 54, height: 54, decoration: BoxDecoration(color: rang.withAlpha(30), borderRadius: BorderRadius.circular(16)), child: Icon(ikonka, color: rang, size: 30)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$sarlavha sifatida kirish', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A237E))),
                            const SizedBox(height: 2),
                            Text(tavsif, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ])),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: rang),
                    ])))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF7986CB)])),
      child: Stack(children: [
        Positioned(top: -60, right: -40, child: doira(230, 22)),
        Positioned(bottom: -90, left: -60, child: doira(280, 18)),
        Positioned(top: 180, left: -50, child: doira(110, 14)),
        SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(children: [
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)]), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 26, offset: Offset(0, 12))]),
                              child: const Icon(Icons.monetization_on_rounded, size: 66, color: Colors.white)),
                          const SizedBox(height: 18),
                          const Text('CoinEdu', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          const Text('O\'qing, qatnashing, tanga yig\'ing', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 38),
                          for (final r in Rol.values) rolKarti(context, r),
                        ])))))
      ]),
    ),
  );
}

class KirishOynasi extends StatefulWidget {
  final Rol rol;
  const KirishOynasi(this.rol, {super.key});
  @override
  State<KirishOynasi> createState() => _KirishOynasiState();
}

class _KirishOynasiState extends State<KirishOynasi> {
  final shaklKaliti = GlobalKey<FormState>();
  final loginKontrolleri = TextEditingController(), parolKontrolleri = TextEditingController();
  bool yuklanmoqda = false, parolniYashirish = true;
  String? xatoMatni;

  Future<void> kirishHarakat() async {
    if (!shaklKaliti.currentState!.validate()) return;
    setState(() {
      yuklanmoqda = true;
      xatoMatni = null;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    final xato = baza.kirish(widget.rol, loginKontrolleri.text, parolKontrolleri.text);
    if (!mounted) return;
    if (xato != null) {
      setState(() {
        yuklanmoqda = false;
        xatoMatni = xato;
      });
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (ism, _, ikonka, rang) = rolMalumotlari[widget.rol]!;
    final demoHisob = {Rol.admin: 'admin / admin123', Rol.ustoz: 'teacher / teacher123', Rol.talaba: 'student / student123'}[widget.rol]!;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 36),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF1A237E), rang]), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40))),
            child: Column(children: [
              Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context))),
              CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(ikonka, size: 42, color: rang)),
              const SizedBox(height: 14),
              Text('$ism sahifasiga kirish', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Hisobingizga kiring', style: TextStyle(color: Colors.white70)),
            ]),
          ),
          Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                      key: shaklKaliti,
                      child: Column(children: [
                        TextFormField(controller: loginKontrolleri, decoration: const InputDecoration(labelText: 'Foydalanuvchi nomi', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => (v ?? '').trim().isEmpty ? 'Loginni kiriting' : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: parolKontrolleri,
                            obscureText: parolniYashirish,
                            decoration: InputDecoration(labelText: 'Parol', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(icon: Icon(parolniYashirish ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: () => setState(() => parolniYashirish = !parolniYashirish))),
                            validator: (v) => (v ?? '').length < 6 ? 'Kamida 6 ta belgi bo\'lishi kerak' : null),
                        if (xatoMatni != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(xatoMatni!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                        const SizedBox(height: 22),
                        SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(style: FilledButton.styleFrom(backgroundColor: rang), onPressed: yuklanmoqda ? null : kirishHarakat, child: yuklanmoqda ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
                        const SizedBox(height: 18),
                        Text('Demo hisob: $demoHisob', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ])))),
        ]),
      ),
    );
  }
}

Widget avatarRasm(String ism, {double radius = 24}) {
  const ranglar = [Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF06B6D4)];
  final rang = ranglar[(ism.isEmpty ? 0 : ism.codeUnitAt(0)) % ranglar.length];
  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [rang, rang.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [BoxShadow(color: rang.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Center(child: Text(ism.isNotEmpty ? ism[0].toUpperCase() : '?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.9))),
  );
}

Widget asosiyBanner(String sarlavha, String qiymat, String tavsif, IconData ikonka, {List<Color> ranglar = const [Color(0xFF6366F1), Color(0xFF4F46E5)]}) => Container(
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: ranglar),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: ranglar.first.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.22)), child: Icon(ikonka, size: 36, color: Colors.white)),
      const SizedBox(width: 18),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sarlavha, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(qiymat, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(tavsif, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500)),
          ])),
    ]));

Widget statistikaKarti(BuildContext c, IconData ikonka, String sarlavha, String qiymat, {Color? rang}) {
  final col = rang ?? Theme.of(c).colorScheme.primary;
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(c).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      border: Border.all(color: col.withOpacity(0.15), width: 1.5),
    ),
    padding: const EdgeInsets.all(10),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: col.withOpacity(0.12), shape: BoxShape.circle), child: Icon(ikonka, size: 22, color: col)),
      const SizedBox(height: 8),
      Text(qiymat, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: col)),
      const SizedBox(height: 2),
      Text(sarlavha, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    ]),
  );
}

Widget tranzaksiyaRoyxati(List<Tranzaksiya> royxat) => royxat.isEmpty
    ? boshKorinish('Tranzaksiyalar mavjud emas')
    : ListView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  itemCount: royxat.length,
  itemBuilder: (context, index) {
    final t = royxat[index];
    final musbat = t.miqdor >= 0;
    final rang = musbat ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Card(
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: rang.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(musbat ? Icons.add_circle_rounded : Icons.remove_circle_rounded, color: rang),
          ),
          title: Text(baza.foydalanuvchi(t.talabaId)?.ism ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text('${t.sababi}\n${t.kimTomonidan} • ${t.vaqt.toString().substring(0, 16)}', style: const TextStyle(fontSize: 12)),
          isThreeLine: true,
          trailing: Text('${musbat ? '+' : ''}${t.miqdor} 💰', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: rang)),
        ));
  },
);

List<Widget> chiqishTugmasi() => [
  Padding(
    padding: const EdgeInsets.only(right: 8),
    child: IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)), tooltip: 'Chiqish', onPressed: baza.chiqish),
  )
];

// ---------------- ADMIN ----------------
class AdminBoshSahifa extends StatefulWidget {
  const AdminBoshSahifa({super.key});
  @override
  State<AdminBoshSahifa> createState() => _AdminBoshSahifaState();
}

class _AdminBoshSahifaState extends State<AdminBoshSahifa> {
  int sahifaIndex = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: baza,
    builder: (_, __) {
      final sahifalar = [const AdminUmumiy(), const FoydalanuvchilarSahifasi(), const KurslarSahifasi(), const TangalarSahifasi()];
      return Scaffold(
        appBar: AppBar(
          title: Text(['Boshqaruv Paneli', 'Foydalanuvchilar', 'Kurs va Guruhlar', 'Tanga Sozlamalari'][sahifaIndex]),
          actions: chiqishTugmasi(),
        ),
        body: sahifalar[sahifaIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: sahifaIndex,
          onDestinationSelected: (i) => setState(() => sahifaIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Umumiy'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'Odamlar'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Kurslar'),
            NavigationDestination(icon: Icon(Icons.monetization_on_outlined), selectedIcon: Icon(Icons.monetization_on_rounded), label: 'Tangalar'),
          ],
        ),
      );
    },
  );
}

class AdminUmumiy extends StatelessWidget {
  const AdminUmumiy({super.key});
  @override
  Widget build(BuildContext context) {
    final bugun = baza.sanaMatni(DateTime.now());
    final bugungiDavomat = baza.davomatlar.keys.where((k) => k.split('|')[1] == bugun).length;
    final jamiTangalar = baza.foydalanuvchilar.where((u) => u.rol == Rol.talaba).fold<int>(0, (a, u) => a + u.tangalar);

    return ListView(padding: const EdgeInsets.only(top: 4, bottom: 20), children: [
      asosiyBanner('Tarqatilgan tangalar', '$jamiTangalar 💰', 'Bugungi davomat yozuvlari: $bugungiDavomat', Icons.stars_rounded, ranglar: const [Color(0xFFF59E0B), Color(0xFFD97706)]),
      Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .95, children: [
            statistikaKarti(context, Icons.school_rounded, 'Talabalar', '${baza.rolBoyicha(Rol.talaba).length}', rang: const Color(0xFFEC4899)),
            statistikaKarti(context, Icons.person_pin_rounded, 'O\'qituvchilar', '${baza.rolBoyicha(Rol.ustoz).length}', rang: const Color(0xFF10B981)),
            statistikaKarti(context, Icons.menu_book_rounded, 'Kurslar', '${baza.kurslar.length}', rang: const Color(0xFF8B5CF6)),
            statistikaKarti(context, Icons.groups_rounded, 'Guruhlar', '${baza.guruhlar.length}', rang: const Color(0xFF3B82F6)),
            statistikaKarti(context, Icons.fact_check_rounded, 'Bugun', '$bugungiDavomat', rang: const Color(0xFF06B6D4)),
            statistikaKarti(context, Icons.receipt_long_rounded, 'Tranzaksiyalar', '${baza.tranzaksiyalar.length}', rang: const Color(0xFFF43F5E)),
          ])),
      const Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, 8), child: Text('So\'nggi Amallar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
      SizedBox(height: 380, child: tranzaksiyaRoyxati(baza.tranzaksiyalar.take(8).toList())),
    ]);
  }
}

class FoydalanuvchilarSahifasi extends StatefulWidget {
  const FoydalanuvchilarSahifasi({super.key});
  @override
  State<FoydalanuvchilarSahifasi> createState() => _FoydalanuvchilarSahifasiState();
}

class _FoydalanuvchilarSahifasiState extends State<FoydalanuvchilarSahifasi> {
  String qidiruv = '';
  Widget royxat(Rol r) {
    final list = baza.rolBoyicha(r).where((u) => u.ism.toLowerCase().contains(qidiruv) || u.foydalanuvchiNomi.contains(qidiruv)).toList()..sort((a, b) => a.ism.compareTo(b.ism));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final natija = await malumotSorash(context, r == Rol.ustoz ? 'Yangi o\'qituvchi qo\'shish' : 'Yangi o\'quvchi qo\'shish', ['To\'liq ism', 'Foydalanuvchi nomi', 'Parol (min 6)']);
            if (natija == null) return;
            final xato = baza.foydalanuvchiQoshish(r, natija[0], natija[1], natija[2]);
            if (!context.mounted) return;
            xabarKorsat(context, xato ?? 'Qo\'shildi: ${natija[1]}');
          },
          child: const Icon(Icons.add_rounded)),
      body: list.isEmpty
          ? boshKorinish('Ro\'yxat bo\'sh')
          : ListView(padding: const EdgeInsets.only(top: 8, bottom: 80), children: [
        for (final u in list)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: avatarRasm(u.ism),
              title: Text(u.ism, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${u.foydalanuvchiNomi}${r == Rol.talaba ? ' • ${u.tangalar} 💰 • ${_davomatFoizi(u)}' : ''}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(value: u.faol, activeColor: const Color(0xFF10B981), onChanged: (val) { u.faol = val; baza.yangilash(); }),
                IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                    onPressed: () async {
                      final natija = await malumotSorash(context, 'Yangi parol o\'rnatish', ['Parol (min 6)']);
                      if (natija != null && natija[0].length >= 6) { u.parol = natija[0]; if (context.mounted) xabarKorsat(context, 'Parol yangilandi'); }
                    }),
                IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                    onPressed: () async {
                      if (await tasdiqlashSohibi(context, '${u.ism} o\'chirilsinmi?')) {
                        baza.foydalanuvchilar.remove(u);
                        for (final g in baza.guruhlar) { g.talabalarIdlari.remove(u.id); if (g.ustozId == u.id) g.ustozId = null; }
                        baza.yangilash();
                      }
                    }),
              ]),
            ),
          )
      ]),
    );
  }

  String _davomatFoizi(Foydalanuvchi u) {
    final elementlar = baza.davomatlar.entries.where((e) => e.key.endsWith('|${u.id}')).toList();
    if (elementlar.isEmpty) return 'davomat yo\'q';
    return 'davomat ${((elementlar.where((x) => x.value != DavomatHolati.kelmadi).length * 100) / elementlar.length).round()}%';
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Qidirish...'), onChanged: (val) => setState(() => qidiruv = val.toLowerCase()))),
        TabBar(
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: 'O\'qituvchilar'), Tab(text: 'O\'quvchilar')],
        ),
        Expanded(child: TabBarView(children: [royxat(Rol.ustoz), royxat(Rol.talaba)])),
      ]));
}

class KurslarSahifasi extends StatelessWidget {
  const KurslarSahifasi({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kurs Qo\'shish', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final natija = await malumotSorash(context, 'Yangi kurs', ['Kurs nomi', 'Tavsif / jadval']);
          if (natija != null) { baza.kurslar.add(Kurs(baza.yangiId(), natija[0], natija[1])); baza.yangilash(); }
        }),
    body: baza.kurslar.isEmpty
        ? boshKorinish('Kurslar mavjud emas')
        : ListView(padding: const EdgeInsets.only(top: 8, bottom: 80), children: [
      for (final kurs in baza.kurslar)
        Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(kurs.nomi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    FilledButton.tonal(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        onPressed: () async {
                          final natija = await malumotSorash(context, 'Yangi guruh', ['Guruh nomi (masalan: Flutter 2)']);
                          if (natija != null) { baza.guruhlar.add(Guruh(baza.yangiId(), kurs.id, natija[0], null)); baza.yangilash(); }
                        },
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, size: 18), Text(' Guruh')])),
                    IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                        onPressed: () async {
                          if (await tasdiqlashSohibi(context, '${kurs.nomi} va uning barcha guruhlari o\'chirilsinmi?')) {
                            baza.guruhlar.removeWhere((g) => g.kursId == kurs.id);
                            baza.kurslar.remove(kurs);
                            baza.yangilash();
                          }
                        }),
                  ]),
                  const SizedBox(height: 8),
                  Text(kurs.tavsif, style: TextStyle(color: Colors.grey.shade600)),
                  const Divider(height: 24),
                  if (baza.guruhlar.where((g) => g.kursId == kurs.id).isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Guruhlar mavjud emas', style: TextStyle(color: Colors.grey))),
                  for (final guruh in baza.guruhlar.where((g) => g.kursId == kurs.id)) GuruhKartochkasi(guruh),
                ]))),
    ]),
  );
}

class GuruhKartochkasi extends StatelessWidget {
  final Guruh guruh;
  const GuruhKartochkasi(this.guruh, {super.key});
  @override
  Widget build(BuildContext context) {
    final ustozlar = baza.rolBoyicha(Rol.ustoz);
    // Tuzatish: biriktirilgan ustoz ro'yxatda bo'lmasa, qiymatni null qilamiz (dropdown xatosi chiqmasligi uchun)
    final tanlanganUstoz = ustozlar.any((t) => t.id == guruh.ustozId) ? guruh.ustozId : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(guruh.nomi, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${baza.foydalanuvchi(guruh.ustozId ?? '')?.ism ?? 'O\'qituvchi belgilanmagan'}\n${guruh.talabalarIdlari.length} ta o\'quvchi', style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                  key: ValueKey('${guruh.id}-$tanlanganUstoz-${ustozlar.length}'),
                  value: tanlanganUstoz,
                  decoration: const InputDecoration(labelText: 'Biriktirilgan o\'qituvchi'),
                  items: [for (final t in ustozlar) DropdownMenuItem(value: t.id, child: Text(t.faol ? t.ism : '${t.ism} (faolsiz)'))],
                  onChanged: (val) { guruh.ustozId = val; baza.yangilash(); })),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(spacing: 6, children: [
              for (final talabaId in guruh.talabalarIdlari)
                Chip(
                  avatar: avatarRasm(baza.foydalanuvchi(talabaId)?.ism ?? '?', radius: 12),
                  label: Text(baza.foydalanuvchi(talabaId)?.ism ?? '?'),
                  onDeleted: () { guruh.talabalarIdlari.remove(talabaId); baza.yangilash(); },
                  deleteIconColor: Colors.redAccent,
                ),
            ]),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('O\'quvchi qo\'shish'),
                onPressed: () async {
                  final boshlar = baza.rolBoyicha(Rol.talaba).where((s) => !guruh.talabalarIdlari.contains(s.id)).toList();
                  final tanlangan = await showDialog<Foydalanuvchi>(
                      context: context,
                      builder: (_) => SimpleDialog(title: const Text('O\'quvchi tanlang'), children: [
                        if (boshlar.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Bo\'sh o\'quvchilar yo\'q')),
                        for (final s in boshlar) SimpleDialogOption(onPressed: () => Navigator.pop(context, s), child: Text(s.ism)),
                      ]));
                  if (tanlangan != null) { guruh.talabalarIdlari.add(tanlangan.id); baza.yangilash(); }
                }),
            TextButton.icon(icon: const Icon(Icons.fact_check_rounded), label: const Text('Davomat'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DavomatSahifasi(guruh)))),
            IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () async { if (await tasdiqlashSohibi(context, '${guruh.nomi} o\'chirilsinmi?')) { baza.guruhlar.remove(guruh); baza.yangilash(); } }),
          ]),
        ],
      ),
    );
  }
}

class TangalarSahifasi extends StatelessWidget {
  const TangalarSahifasi({super.key});
  @override
  Widget build(BuildContext context) => ListView(children: [
    Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              ListTile(
                  leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                  title: const Text('Qatnashganlik uchun'),
                  trailing: Text('+${baza.kelganlikTangasi} 💰', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () async { final natija = await malumotSorash(context, 'Qatnashish tangasi', ['Miqdor'], raqamli: {0}); final n = int.tryParse(natija?[0] ?? ''); if (n != null && n >= 0) { baza.kelganlikTangasi = n; baza.yangilash(); } }),
              ListTile(
                  leading: const Icon(Icons.access_time_filled_rounded, color: Colors.orange),
                  title: const Text('Kechikkanlik uchun'),
                  trailing: Text('+${baza.kechikkanlikTangasi} 💰', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () async { final natija = await malumotSorash(context, 'Kechikish tangasi', ['Miqdor'], raqamli: {0}); final n = int.tryParse(natija?[0] ?? ''); if (n != null && n >= 0) { baza.kechikkanlikTangasi = n; baza.yangilash(); } }),
              SwitchListTile(title: const Text('Kechikish uchun tanga berish'), value: baza.kechikishgaTangaBerish, onChanged: (val) { baza.kechikishgaTangaBerish = val; baza.yangilash(); }),
              SwitchListTile(title: const Text('Manfiy balansga ruxsat berish'), value: baza.manfiyBalansgaRuxsat, onChanged: (val) { baza.manfiyBalansgaRuxsat = val; baza.yangilash(); }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                    icon: const Icon(Icons.add_card_rounded),
                    label: const Text('Qo\'lda Qo\'shish / Ayirish', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final talabalar = baza.rolBoyicha(Rol.talaba);
                      final tanlangan = await showDialog<Foydalanuvchi>(context: context, builder: (_) => SimpleDialog(title: const Text('O\'quvchini tanlang'), children: [for (final x in talabalar) SimpleDialogOption(onPressed: () => Navigator.pop(context, x), child: Text('${x.ism} (${x.tangalar} 💰)'))]));
                      if (tanlangan == null || !context.mounted) return;
                      final natija = await malumotSorash(context, tanlangan.ism, ['Miqdor (+/- masalan: 10 yoki -5)', 'Sabab'], raqamli: {0});
                      final n = int.tryParse(natija?[0] ?? '');
                      if (natija == null || n == null || n == 0) return;
                      final xato = baza.tangaBerish(tanlangan, n, n > 0 ? 'manual_add' : 'manual_deduct', natija[1]);
                      if (context.mounted) xabarKorsat(context, xato ?? 'Muvaffaqiyatli bajarildi');
                    }),
              ),
            ]))),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Barcha Tranzaksiyalar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
    SizedBox(height: 500, child: tranzaksiyaRoyxati(baza.tranzaksiyalar)),
  ]);
}

// ---------------- DAVOMAT ----------------
class DavomatSahifasi extends StatefulWidget {
  final Guruh guruh;
  const DavomatSahifasi(this.guruh, {super.key});
  @override
  State<DavomatSahifasi> createState() => _DavomatSahifasiState();
}

class _DavomatSahifasiState extends State<DavomatSahifasi> {
  DateTime sana = DateTime.now();
  late Map<String, DavomatHolati> xarita;
  @override
  void initState() {
    super.initState();
    yuklash();
  }

  void yuklash() => xarita = {for (final talabaId in widget.guruh.talabalarIdlari) talabaId: baza.davomatlar['${widget.guruh.id}|${baza.sanaMatni(sana)}|$talabaId'] ?? DavomatHolati.keldi};

  @override
  Widget build(BuildContext context) {
    final saqlangan = widget.guruh.talabalarIdlari.any((talabaId) => baza.davomatlar.containsKey('${widget.guruh.id}|${baza.sanaMatni(sana)}|$talabaId'));
    return Scaffold(
      appBar: AppBar(title: Text(widget.guruh.nomi), actions: [
        IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1)),
            onPressed: () async {
              final tanlanganSana = await showDatePicker(context: context, initialDate: sana, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (tanlanganSana != null) setState(() { sana = tanlanganSana; yuklash(); });
            })
      ]),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.event_note_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sana: ${baza.sanaMatni(sana)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(saqlangan ? 'Saqlangan (tahrirlashingiz mumkin)' : 'Yangi davomat kiritish', style: TextStyle(fontSize: 12, color: saqlangan ? Colors.green : Colors.orange)),
            ]),
          ]),
        ),
        Expanded(
            child: widget.guruh.talabalarIdlari.isEmpty
                ? boshKorinish('Guruhda o\'quvchilar mavjud emas')
                : ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
              for (final talabaId in widget.guruh.talabalarIdlari)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Row(children: [
                            avatarRasm(baza.foydalanuvchi(talabaId)?.ism ?? '?', radius: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(baza.foydalanuvchi(talabaId)?.ism ?? '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text('${baza.foydalanuvchi(talabaId)?.tangalar ?? 0} 💰', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            ),
                            IconButton(
                                icon: const Icon(Icons.card_giftcard_rounded, color: Colors.amber),
                                onPressed: () async {
                                  final natija = await malumotSorash(context, 'Tanga mukofoti berish', ['Miqdor', 'Sabab'], raqamli: {0});
                                  final n = int.tryParse(natija?[0] ?? '');
                                  if (natija == null || n == null) return;
                                  final xato = baza.tangaBerish(baza.foydalanuvchi(talabaId)!, n, 'reward', natija[1]);
                                  if (context.mounted) xabarKorsat(context, xato ?? 'Tanga berildi');
                                  setState(() {});
                                }),
                          ]),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<DavomatHolati>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(value: DavomatHolati.keldi, label: Text('Keldi')),
                                  ButtonSegment(value: DavomatHolati.kechikdi, label: Text('Kechikdi')),
                                  ButtonSegment(value: DavomatHolati.kelmadi, label: Text('Kelmadi')),
                                ],
                                selected: {xarita[talabaId]!},
                                onSelectionChanged: (sec) => setState(() => xarita[talabaId] = sec.first)),
                          ),
                        ]))),
            ])),
        Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Davomatni Saqlash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: widget.guruh.talabalarIdlari.isEmpty ? null : () { baza.davomatniSaqlash(widget.guruh, sana, xarita); xabarKorsat(context, 'Davomat saqlandi!'); setState(() {}); }))),
      ]),
    );
  }
}

// ---------------- O'QITUVCHI ---------------
class UstozBoshSahifa extends StatelessWidget {
  const UstozBoshSahifa({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: baza,
      builder: (_, __) {
        final guruhlarim = baza.guruhlar.where((g) => g.ustozId == baza.joriyFoydalanuvchi!.id).toList();
        return Scaffold(
          appBar: AppBar(title: Text('Salom, ${baza.joriyFoydalanuvchi!.ism} 👋'), actions: chiqishTugmasi()),
          body: guruhlarim.isEmpty
              ? boshKorinish('Sizga biriktirilgan guruhlar yo\'q')
              : ListView(padding: const EdgeInsets.all(12), children: [
            const Padding(padding: EdgeInsets.all(8), child: Text('Mening Guruhlarim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            for (final guruh in guruhlarim)
              Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.groups_rounded, color: Color(0xFF10B981))),
                      title: Text(guruh.nomi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      subtitle: Text('${baza.kurslar.where((c) => c.id == guruh.kursId).firstOrNull?.nomi ?? ''}\n${guruh.talabalarIdlari.length} ta o\'quvchi'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 28),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DavomatSahifasi(guruh))))),
          ]),
        );
      });
}

// ---------------- O'QUVCHI ----------------
class TalabaBoshSahifa extends StatefulWidget {
  const TalabaBoshSahifa({super.key});
  @override
  State<TalabaBoshSahifa> createState() => _TalabaBoshSahifaState();
}

class _TalabaBoshSahifaState extends State<TalabaBoshSahifa> {
  int sahifaIndex = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: baza,
      builder: (_, __) {
        final talaba = baza.joriyFoydalanuvchi!;
        final meningTranzaksiyalarim = baza.tranzaksiyalar.where((t) => t.talabaId == talaba.id).toList();
        final yozuvlar = baza.davomatlar.entries.where((e) => e.key.endsWith('|${talaba.id}')).toList()..sort((a, b) => b.key.compareTo(a.key));
        final foiz = yozuvlar.isEmpty ? 0 : ((yozuvlar.where((e) => e.value != DavomatHolati.kelmadi).length * 100) / yozuvlar.length).round();
        final ishlangan = meningTranzaksiyalarim.where((t) => t.miqdor > 0).fold<int>(0, (a, t) => a + t.miqdor);
        final sarflangan = meningTranzaksiyalarim.where((t) => t.miqdor < 0).fold<int>(0, (a, t) => a + t.miqdor);

        final sahifalar = <Widget>[
          Column(children: [
            asosiyBanner('Mening Balansim', '${talaba.tangalar} 💰', 'Jami toplangan: +$ishlangan  |  Ishlatilgan: $sarflangan', Icons.stars_rounded, ranglar: const [Color(0xFFF59E0B), Color(0xFFD97706)]),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Tanga Tarixi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
            Expanded(child: tranzaksiyaRoyxati(meningTranzaksiyalarim)),
          ]),
          Column(children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Davomat Foizi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('$foiz%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF6366F1))),
                ]),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: foiz / 100, minHeight: 10, color: const Color(0xFF6366F1), backgroundColor: Colors.grey.shade200)),
              ]),
            ),
            Expanded(
                child: yozuvlar.isEmpty
                    ? boshKorinish('Davomat yozuvlari mavjud emas')
                    : ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
                  for (final entry in yozuvlar)
                    Card(
                        child: ListTile(
                            leading: Icon(
                              entry.value == DavomatHolati.keldi ? Icons.check_circle_rounded : entry.value == DavomatHolati.kechikdi ? Icons.schedule_rounded : Icons.cancel_rounded,
                              color: entry.value == DavomatHolati.keldi ? Colors.green : entry.value == DavomatHolati.kechikdi ? Colors.orange : Colors.red,
                              size: 28,
                            ),
                            title: Text({DavomatHolati.keldi: 'Keldi (+${baza.kelganlikTangasi} 💰)', DavomatHolati.kechikdi: 'Kechikdi (${baza.kechikishgaTangaBerish ? "+${baza.kechikkanlikTangasi}" : "0"} 💰)', DavomatHolati.kelmadi: 'Kelmadi'}[entry.value]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${entry.key.split('|')[1]}\n${baza.guruhlar.where((g) => g.id == entry.key.split('|')[0]).firstOrNull?.nomi ?? ''}'))),
                ])),
          ]),
          ListView(padding: const EdgeInsets.all(12), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  avatarRasm(talaba.ism, radius: 28),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(talaba.ism, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('@${talaba.foydalanuvchiNomi} • ID: ${talaba.id}', style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ]),
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(8, 16, 8, 8), child: Text('A\'zo Bo\'lingan Kurslar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            for (final guruh in baza.guruhlar.where((g) => g.talabalarIdlari.contains(talaba.id)))
              Card(
                  child: ListTile(
                      leading: const KichikIkonkaKutisi(ikonka: Icons.school_rounded),
                      title: Text('${baza.kurslar.where((c) => c.id == guruh.kursId).firstOrNull?.nomi ?? ''} — ${guruh.nomi}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('O\'qituvchi: ${baza.foydalanuvchi(guruh.ustozId ?? '')?.ism ?? 'Belgilanmagan'}'))),
          ]),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(['Mening Tangalarim', 'Davomatim', 'Profil va Kurslar'][sahifaIndex]), actions: chiqishTugmasi()),
          body: sahifalar[sahifaIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: sahifaIndex,
            onDestinationSelected: (i) => setState(() => sahifaIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.monetization_on_outlined), selectedIcon: Icon(Icons.monetization_on_rounded), label: 'Tangalar'),
              NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check_rounded), label: 'Davomat'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
          ),
        );
      });
}

class KichikIkonkaKutisi extends StatelessWidget {
  final IconData ikonka;
  const KichikIkonkaKutisi({super.key, required this.ikonka});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
    child: Icon(ikonka, color: Theme.of(context).colorScheme.primary),
  );
}
