import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MyCricStatsApp());

const ink = Color(0xFF080D1B), panel = Color(0xFF121B2D), panel2 = Color(0xFF1A263B);
const accent = Color(0xFFFF3158), lime = Color(0xFFB9F36A), muted = Color(0xFF93A0B5);

class MyCricStatsApp extends StatelessWidget {
  const MyCricStatsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MyCricStats', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(primary: accent, secondary: lime, surface: panel),
      useMaterial3: true),
    home: const MatchCentre(),
  );
}

class MatchCentre extends StatefulWidget {
  const MatchCentre({super.key});
  @override
  State<MatchCentre> createState() => _MatchCentreState();
}

class _MatchCentreState extends State<MatchCentre> {
  int tab = 0;
  String tossWinner = 'Team Blue', decision = 'Bat';
  String? tossResult;
  final teams = const ['Team Blue', 'Team Orange'];
  final players = const ['Sarang', 'Mehul', 'Homesh', 'Subash', 'Ashu', 'Keith'];

  void runToss() => setState(() {
    tossWinner = teams[Random().nextInt(teams.length)];
    tossResult = '$tossWinner won the toss and elected to $decision first.';
  });

  @override
  Widget build(BuildContext context) {
    final pages = [_matchPage(), _tossPage(), _squadsPage(), _statsPage()];
    return Scaffold(
      body: SafeArea(child: Column(children: [_header(), Expanded(child: IndexedStack(index: tab, children: pages))])),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0D1525), indicatorColor: accent.withOpacity(.18),
        selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_cricket_outlined), selectedIcon: Icon(Icons.sports_cricket), label: 'Match'),
          NavigationDestination(icon: Icon(Icons.currency_exchange), label: 'Toss'),
          NavigationDestination(icon: Icon(Icons.groups_2_outlined), label: 'Squads'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Stats'),
        ],
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
    decoration: const BoxDecoration(color: ink, border: Border(bottom: BorderSide(color: Color(0xFF243047)))),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(13)),
        child: const Icon(Icons.sports_cricket, color: Colors.white, size: 25)),
      const SizedBox(width: 11),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MYCRICSTATS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
        SizedBox(height: 2),
        Text('CRICKET MATCH CENTRE', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
      ])),
      _tag('FLUTTER TEST', lime),
    ]),
  );

  Widget _matchPage() => ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [const Text('MATCH CENTRE', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const Spacer(), _tag('PREVIEW', lime)]),
    const SizedBox(height: 13), _scoreCard(), const SizedBox(height: 14),
    Row(children: [Expanded(child: _metric('RUN RATE', '—')), const SizedBox(width: 9), Expanded(child: _metric('TARGET', '—')), const SizedBox(width: 9), Expanded(child: _metric('REMAINING', '—'))]),
    const SizedBox(height: 14), _sectionTitle('MATCH OVERVIEW', '01'),
    _card(child: Column(children: [
      _infoRow(Icons.stadium_outlined, 'Venue', 'Tournament ground'), _line(),
      _infoRow(Icons.timer_outlined, 'Format', 'T20 · 20 overs'), _line(),
      _infoRow(Icons.sports, 'Status', 'Waiting for live match feed'),
    ])),
    const SizedBox(height: 14), _sectionTitle('RECENT BALLS', 'LAST OVER'),
    _card(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('No live delivery data yet', style: TextStyle(color: muted, fontSize: 13)),
      SizedBox(height: 9), Text('Connect the match feed to show ball-by-ball updates here.', style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
    ])),
    const SizedBox(height: 8),
    const Text('Flutter migration preview · Live data integration is not connected in this milestone.', style: TextStyle(color: muted, fontSize: 10), textAlign: TextAlign.center),
  ]);

  Widget _scoreCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF202D45), Color(0xFF10192A)]),
      border: Border.all(color: const Color(0xFF35435B))),
    child: Column(children: [
      Row(children: [_tag('MATCH PREVIEW', accent), const Spacer(), const Icon(Icons.more_horiz, color: muted)]),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: _teamScore('BLUE', '🔵', '—', 'Yet to bat')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('VS', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2))),
        Expanded(child: _teamScore('ORANGE', '🟠', '—', 'Yet to bat')),
      ]),
      const SizedBox(height: 20), Container(height: 1, color: Colors.white.withOpacity(.09)),
      const SizedBox(height: 13),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.info_outline, size: 13, color: lime), SizedBox(width: 6), Text('Waiting for match selection', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600))]),
    ]),
  );

  Widget _teamScore(String name, String flag, String score, String sub) => Column(children: [
    Text(flag, style: const TextStyle(fontSize: 28)), const SizedBox(height: 5),
    Text(name, style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
    const SizedBox(height: 5), Text(score, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
    Text(sub, style: const TextStyle(color: muted, fontSize: 10)),
  ]);

  Widget _tossPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageIntro('TOSS SETUP', 'Set the toss details before the match begins.'), const SizedBox(height: 18),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('TOSS WINNER'), const SizedBox(height: 8),
      _choice(teams, tossWinner, (v) => setState(() { tossWinner = v; tossResult = null; })),
      const SizedBox(height: 20), _fieldLabel('DECISION'), const SizedBox(height: 8),
      Row(children: ['Bat', 'Bowl'].map((v) => Expanded(child: Padding(
        padding: EdgeInsets.only(right: v == 'Bat' ? 8 : 0),
        child: _selectTile(v, decision == v, () => setState(() { decision = v; tossResult = null; })),
      ))).toList()),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: runToss,
        icon: const Icon(Icons.casino_outlined), label: const Text('CONFIRM TOSS'),
        style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))))),
      if (tossResult != null) ...[
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: lime.withOpacity(.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: lime.withOpacity(.3))),
          child: Text(tossResult!, style: const TextStyle(color: lime, fontWeight: FontWeight.w700, height: 1.4))),
      ],
    ])),
    const SizedBox(height: 14),
    _card(child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.tips_and_updates_outlined, color: lime, size: 19), SizedBox(width: 10),
      Expanded(child: Text('This is the first Flutter UI milestone. Match persistence and scorer-side toss synchronisation will be connected during the integration phase.', style: TextStyle(color: muted, fontSize: 11, height: 1.5))),
    ])),
  ]);

  Widget _squadsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageIntro('SQUADS', 'Player roster layout for the tournament.'), const SizedBox(height: 14),
    _squadCard('TEAM BLUE', '🔵', players.take(3).toList()), const SizedBox(height: 12),
    _squadCard('TEAM ORANGE', '🟠', players.skip(3).toList()),
  ]);

  Widget _squadCard(String title, String icon, List<String> names) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 9), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))]),
    const SizedBox(height: 12),
    ...names.asMap().entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      CircleAvatar(radius: 15, backgroundColor: panel2, child: Text(e.value.substring(0, 1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
      const SizedBox(width: 10), Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      Text('PLAYER 0\${e.key + 1}', style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1)),
    ]))),
  ]));

  Widget _statsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageIntro('TOURNAMENT STATS', 'Performance tables and match leaders.'), const SizedBox(height: 14),
    Row(children: [Expanded(child: _metric('ORANGE CAP', '—')), const SizedBox(width: 9), Expanded(child: _metric('PURPLE CAP', '—'))]),
    const SizedBox(height: 12),
    _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('LEADERBOARDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
      const SizedBox(height: 13),
      ...['Most Runs', 'Most Wickets', 'Most Fours', 'Most Sixes', 'Best Economy', 'Player of the Tournament'].map((v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [const Icon(Icons.emoji_events_outlined, color: lime, size: 17), const SizedBox(width: 10), Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), const Text('Awaiting data', style: TextStyle(color: muted, fontSize: 10))]),
      )),
    ])),
    const SizedBox(height: 8),
    const Text('Leaderboards populate after tournament history and scorecard data are connected.', style: TextStyle(color: muted, fontSize: 10), textAlign: TextAlign.center),
  ]);

  Widget _pageIntro(String title, String subtitle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: .5)),
    const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
  ]);
  Widget _sectionTitle(String title, String tag) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [
    Text(title, style: const TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
    const Spacer(), Text(tag, style: const TextStyle(fontSize: 9, color: lime, fontWeight: FontWeight.w900)),
  ]));
  Widget _metric(String label, String value) => Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF26334A))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    ]));
  Widget _card({required Widget child}) => Container(padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFF26334A))), child: child);
  Widget _tag(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(.35))),
    child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)));
  Widget _line() => Container(height: 1, color: Colors.white.withOpacity(.07), margin: const EdgeInsets.symmetric(vertical: 9));
  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 17, color: lime), const SizedBox(width: 10),
    Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 11))),
    Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
  ]);
  Widget _fieldLabel(String label) => Text(label, style: const TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2));
  Widget _choice(List<String> options, String selected, ValueChanged<String> onTap) => Row(children: options.map((v) => Expanded(child: Padding(
    padding: EdgeInsets.only(right: v == options.first ? 8 : 0),
    child: _selectTile(v, selected == v, () => onTap(v)),
  ))).toList());
  Widget _selectTile(String label, bool active, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: active ? accent.withOpacity(.13) : panel2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? accent : const Color(0xFF344159), width: active ? 1.4 : 1)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (active) const Icon(Icons.check_circle, color: accent, size: 15),
        if (active) const SizedBox(width: 7),
        Text(label, style: TextStyle(color: active ? Colors.white : muted, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    ),
  );
}