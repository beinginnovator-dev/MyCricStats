import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SportzFlutterApp());

const bg = Color(0xFF080B12);
const surface = Color(0xFF111827);
const surface2 = Color(0xFF192235);
const accent = Color(0xFFFF304F);
const gold = Color(0xFFFFC857);
const muted = Color(0xFF91A0B7);

class SportzFlutterApp extends StatefulWidget {
  const SportzFlutterApp({super.key});
  @override State<SportzFlutterApp> createState() => _SportzFlutterAppState();
}
class _SportzFlutterAppState extends State<SportzFlutterApp> {
  int themeIndex = 0;
  @override void initState() { super.initState(); _loadTheme(); }
  Future<void> _loadTheme() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() => themeIndex = p.getInt('sportz_theme') ?? 0); }
  Future<void> _setTheme(int value) async { final p = await SharedPreferences.getInstance(); await p.setInt('sportz_theme', value); if (mounted) setState(() => themeIndex = value); }
  @override Widget build(BuildContext context) {
    final colors = [accent, const Color(0xFFE11D48), const Color(0xFFFF653D)];
    final primary = colors[themeIndex.clamp(0, 2)];
    return MaterialApp(
      title: 'MySportzStats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, brightness: Brightness.dark,
        scaffoldBackgroundColor: bg, colorScheme: ColorScheme.dark(primary: primary, secondary: gold, surface: surface),
        appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: Colors.white, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: surface, indicatorColor: primary.withOpacity(.18)),
        cardTheme: CardThemeData(color: surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: SportzShell(primary: primary, themeIndex: themeIndex, onThemeChanged: _setTheme),
    );
  }
}

class SportzShell extends StatefulWidget {
  final Color primary; final int themeIndex; final ValueChanged<int> onThemeChanged;
  const SportzShell({super.key, required this.primary, required this.themeIndex, required this.onThemeChanged});
  @override State<SportzShell> createState() => _SportzShellState();
}
class _SportzShellState extends State<SportzShell> {
  int tab = 0;
  int runs = 0, wickets = 0, legalBalls = 0, extras = 0, innings = 1;
  int maxOvers = 8;
  String teamA = 'TEAM RED', teamB = 'TEAM BLUE';
  String striker = 'Batter 01', nonStriker = 'Batter 02', bowler = 'Bowler 01';
  final List<String> thisOver = [];
  final List<Map<String, dynamic>> history = [];
  bool matchLive = false, matchEnded = false;
  String matchTitle = 'MATCH DAY 01';
  double get overs => legalBalls / 6;
  String get overText => '${legalBalls ~/ 6}.${legalBalls % 6}';
  double get crr => legalBalls == 0 ? 0 : runs / (legalBalls / 6);
  String get battingTeam => innings == 1 ? teamA : teamB;
  String get bowlingTeam => innings == 1 ? teamB : teamA;

  void score(String label, {int add = 0, bool legal = true, bool wicket = false, bool extra = false}) {
    if (!matchLive || matchEnded) return;
    setState(() {
      final before = {'runs': runs, 'wickets': wickets, 'balls': legalBalls, 'extras': extras, 'over': List<String>.from(thisOver), 'striker': striker, 'nonStriker': nonStriker};
      history.add(before);
      runs += add; if (wicket) wickets++; if (extra) extras += add;
      if (legal) { legalBalls++; thisOver.add(label); }
      else { thisOver.add(label); }
      if (legalBalls > 0 && legalBalls % 6 == 0) { final old = striker; striker = nonStriker; nonStriker = old; }
      if (wickets >= 10 || legalBalls >= maxOvers * 6) matchEnded = true;
    });
  }
  void undo() { if (history.isEmpty) return; final s = history.removeLast(); setState(() { runs=s['runs']; wickets=s['wickets']; legalBalls=s['balls']; extras=s['extras']; thisOver..clear()..addAll((s['over'] as List).cast<String>()); striker=s['striker']; nonStriker=s['nonStriker']; matchEnded=false; }); }
  void startMatch() { setState(() { matchLive=true; matchEnded=false; runs=0; wickets=0; legalBalls=0; extras=0; innings=1; history.clear(); thisOver.clear(); tab=2; }); }
  void resetMatch() { setState(() { matchLive=false; matchEnded=false; runs=0; wickets=0; legalBalls=0; extras=0; innings=1; history.clear(); thisOver.clear(); }); }
  void swapStrike() { setState(() { final s=striker; striker=nonStriker; nonStriker=s; }); }

  @override Widget build(BuildContext context) {
    final pages = [_dashboard(), _matches(), _scorer(), _stats(), _more()];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: widget.primary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.sports_cricket, color: Colors.white)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MYSPORTZSTATS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('LIVE SPORTS SCORING', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
          ]),
        ]),
        actions: [IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh)), const SizedBox(width: 4)],
      ),
      body: SafeArea(top: false, child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab=v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.sports_score), label: 'Matches'),
          NavigationDestination(icon: Icon(Icons.scoreboard_outlined), selectedIcon: Icon(Icons.scoreboard), label: 'Scorer'),
          NavigationDestination(icon: Icon(Icons.query_stats), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'More'),
        ],
      ),
    );
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [const Expanded(child: Text('MATCH CENTRE', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w900, letterSpacing: 1.5))), _chip(matchLive ? 'LIVE' : 'READY', matchLive ? accent : muted)]),
    const SizedBox(height: 14),
    _heroMatch(),
    const SizedBox(height: 20),
    _section('QUICK ACCESS', 'MATCH OPERATIONS'),
    Row(children: [
      Expanded(child: _quick(Icons.sports_cricket, 'Start scoring', () => setState(() => tab=2))),
      const SizedBox(width: 10),
      Expanded(child: _quick(Icons.groups_2_outlined, 'Squads', () => setState(() => tab=1))),
      const SizedBox(width: 10),
      Expanded(child: _quick(Icons.leaderboard_outlined, 'Statistics', () => setState(() => tab=3))),
    ]),
    const SizedBox(height: 20),
    _section('MATCH SERVICES', 'LIVE CONTROL'),
    _serviceTile(Icons.cast_connected, 'Live viewer & sharing', 'Publish a synchronized match feed', () => _info('Live viewer connection will be wired to the original MySportzStats live service.')),
    _serviceTile(Icons.forum_outlined, 'Live chat & reactions', 'Match-room interaction', () => _info('Chat interface is planned for the next integration stage.')),
    _serviceTile(Icons.history, 'Match history', 'Saved scorecards and results', () => setState(() => tab=3)),
  ]);

  Widget _heroMatch() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF202D46), Color(0xFF111827), Color(0xFF251722)]),
      borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.07)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [_chip('CRICKET', gold), const Spacer(), Text(matchTitle, style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: _teamBlock('🇮🇳', teamA)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('VS', style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 13))),
        Expanded(child: _teamBlock('🇳🇿', teamB)),
      ]),
      const SizedBox(height: 20),
      if (matchLive) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$runs/$wickets', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(width: 12), Text('($overText ov)', style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
      ]) else const Center(child: Text('READY FOR THE NEXT MATCH', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: matchLive ? () => setState(() => tab=2) : startMatch,
        icon: Icon(matchLive ? Icons.open_in_new : Icons.play_arrow),
        label: Text(matchLive ? 'OPEN LIVE SCORER' : 'START MATCH'),
        style: FilledButton.styleFrom(backgroundColor: widget.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
      )),
    ]),
  );

  Widget _teamBlock(String flag, String name) => Column(children: [
    Text(flag, style: const TextStyle(fontSize: 34)),
    const SizedBox(height: 7),
    Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: .7)),
  ]);

  Widget _matches() => ListView(padding: const EdgeInsets.all(16), children: [
    _section('MATCHES', 'FIXTURES • SQUADS • TOSS'),
    _serviceTile(Icons.add_circle_outline, 'Create a match', 'Set teams, match title and overs', _createMatch),
    _serviceTile(Icons.groups_outlined, 'Team squads', 'Manage playing XI and substitutes', () => _info('Squad management screen is in the build plan.')),
    _serviceTile(Icons.toll, 'Toss setup', 'Choose toss winner and decision', () => _info('Toss setup will be connected to match creation.')),
    _serviceTile(Icons.event_available, 'Upcoming matches', 'Your scheduled fixtures', () => _info('No scheduled fixtures have been added yet.')),
    _serviceTile(Icons.history, 'Completed matches', 'Open past scorecards', () => setState(() => tab=3)),
  ]);

  Widget _scorer() => ListView(padding: const EdgeInsets.all(14), children: [
    Row(children: [const Expanded(child: Text('LIVE SCORER', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w900, letterSpacing: 1.4))), _chip(matchLive ? (matchEnded ? 'COMPLETED' : 'LIVE') : 'NOT STARTED', matchLive ? accent : muted)]),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF202D46), Color(0xFF111827)]), borderRadius: BorderRadius.circular(20)), child: Column(children: [
      Text('$teamA  vs  $teamB', style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('$runs/$wickets', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
      Text('$overText OV  •  CRR ${crr.toStringAsFixed(2)}  •  EXTRAS $extras', style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('STRIKER  $striker', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(width: 14), Text('NON-STRIKER  $nonStriker', style: const TextStyle(fontSize: 10, color: muted))]),
      const SizedBox(height: 12),
      Wrap(spacing: 6, children: thisOver.map((e) => _chip(e, e=='W' ? accent : (e=='4'||e=='6' ? gold : muted))).toList()),
    ])),
    const SizedBox(height: 14),
    if (!matchLive) SizedBox(width: double.infinity, child: FilledButton(onPressed: startMatch, child: const Text('START MATCH'))),
    if (matchLive && !matchEnded) ...[
      _section('RUNS', 'LEGAL DELIVERIES'),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0, children: [
        _runButton('0', () => score('0')), _runButton('1', () { score('1', add:1); swapStrike(); }), _runButton('2', () { score('2', add:2); if (legalBalls.isOdd) swapStrike(); }),
        _runButton('3', () { score('3', add:3); swapStrike(); }), _runButton('4', () => score('4', add:4)), _runButton('6', () => score('6', add:6)),
      ]),
      const SizedBox(height: 12),
      _section('EXTRAS & WICKETS', 'MATCH EVENTS'),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0, children: [
        _runButton('WIDE', () => score('Wd', add:1, legal:false, extra:true)),
        _runButton('NO BALL', () => score('Nb', add:1, legal:false, extra:true)),
        _runButton('WICKET', () => score('W', wicket:true)),
      ]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: undo, icon: const Icon(Icons.undo), label: const Text('UNDO'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: swapStrike, icon: const Icon(Icons.swap_horiz), label: const Text('SWAP STRIKE')))]),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _changeBowler, icon: const Icon(Icons.sports), label: Text('BOWLER: $bowler'))),
    ],
    if (matchEnded) _serviceTile(Icons.flag, 'Innings complete', 'Start the second innings from match controls', () => _info('Second-innings workflow will be added with toss and innings management.')),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: TextButton.icon(onPressed: resetMatch, icon: const Icon(Icons.restart_alt), label: const Text('RESET LOCAL TEST MATCH'))),
    const Text('Local scoring prototype. Live server sync, persistent history and tournament aggregation are integration tasks.', style: TextStyle(color: muted, fontSize: 10, height: 1.5)),
  ]);

  Widget _stats() => ListView(padding: const EdgeInsets.all(16), children: [
    _section('MATCH STATISTICS', 'SCORE SUMMARY'),
    Row(children: [Expanded(child: _metric('RUNS', '$runs')), const SizedBox(width: 8), Expanded(child: _metric('WICKETS', '$wickets')), const SizedBox(width: 8), Expanded(child: _metric('OVERS', overText))]),
    const SizedBox(height: 14),
    _serviceTile(Icons.scoreboard, 'Full scorecard', 'Batting, bowling and fall of wickets', () => _info('Full scorecard will be linked to saved match data.')),
    _serviceTile(Icons.emoji_events_outlined, 'Tournament standings', 'Points table and net run rate', () => _info('Standings and NRR aggregation are planned.')),
    _serviceTile(Icons.military_tech_outlined, 'Player leaderboards', 'Orange Cap, Purple Cap and awards', () => _info('Player award tables will be populated from match history.')),
    _serviceTile(Icons.bar_chart, 'Match analytics', 'Run rate, partnerships and over summary', () => _info('Advanced analytics will follow persistent scorecard integration.')),
  ]);

  Widget _more() => ListView(padding: const EdgeInsets.all(16), children: [
    _section('MORE', 'APP SETTINGS & SERVICES'),
    _serviceTile(Icons.palette_outlined, 'App themes', 'Choose a professional scoreboard palette', _chooseTheme),
    _serviceTile(Icons.share_outlined, 'Share live match', 'Viewer link and match room', () => _info('Live sharing will use the existing MySportzStats live room service.')),
    _serviceTile(Icons.campaign_outlined, 'Advertisement placement', 'Dedicated match-page ad area', () => _info('Advertisement slot layout will be added to the match viewer and scorer.')),
    _serviceTile(Icons.settings_outlined, 'Match settings', 'Overs, match title and team names', _createMatch),
    _serviceTile(Icons.info_outline, 'About', 'Flutter rebuild of MySportzStats', () => _info('This is the separate Flutter rebuild. The original scorer app is not modified.')),
  ]);

  Widget _section(String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2))), Text(subtitle, style: const TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w800))]));
  Widget _chip(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(.3))), child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .6)));
  Widget _quick(IconData icon, String label, VoidCallback action) => InkWell(onTap: action, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(icon, color: widget.primary, size: 22), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))])));
  Widget _serviceTile(IconData icon, String title, String subtitle, VoidCallback action) => Card(child: ListTile(onTap: action, leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: widget.primary.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: widget.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)), trailing: const Icon(Icons.chevron_right, color: muted)));
  Widget _metric(String label, String value) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(label, style: const TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))]));
  Widget _runButton(String text, VoidCallback action) => FilledButton(onPressed: action, style: FilledButton.styleFrom(backgroundColor: surface2, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)));
  Future<void> _info(String message) async { if (!mounted) return; showDialog<void>(context: context, builder: (c) => AlertDialog(backgroundColor: surface, content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))])); }
  Future<void> _changeBowler() async { final c=TextEditingController(text:bowler); await showDialog<void>(context:context,builder:(d)=>AlertDialog(backgroundColor:surface,title:const Text('Change bowler'),content:TextField(controller:c,decoration:const InputDecoration(labelText:'Bowler name')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('CANCEL')),FilledButton(onPressed:(){setState(()=>bowler=c.text.trim().isEmpty?'Bowler':c.text.trim());Navigator.pop(d);},child:const Text('SAVE'))])); }
  Future<void> _createMatch() async {
    final a=TextEditingController(text:teamA), b=TextEditingController(text:teamB), title=TextEditingController(text:matchTitle), oversC=TextEditingController(text:maxOvers.toString());
    await showDialog<void>(context:context,builder:(d)=>AlertDialog(backgroundColor:surface,title:const Text('Match setup'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Match title')),TextField(controller:a,decoration:const InputDecoration(labelText:'Team A')),TextField(controller:b,decoration:const InputDecoration(labelText:'Team B')),TextField(controller:oversC,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Overs'))])),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('CANCEL')),FilledButton(onPressed:(){setState((){matchTitle=title.text;teamA=a.text;teamB=b.text;maxOvers=(int.tryParse(oversC.text)??8).clamp(1,50);resetMatch();});Navigator.pop(d);},child:const Text('SAVE'))]));
  }
  Future<void> _chooseTheme() async { await showModalBottomSheet<void>(context:context,backgroundColor:surface,builder:(c)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[const Padding(padding:EdgeInsets.all(16),child:Text('CHOOSE THEME',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1))),...['Pro Black / Red','Midnight Red','Graphite Red'].asMap().entries.map((e)=>ListTile(title:Text(e.value),trailing:widget.themeIndex==e.key?const Icon(Icons.check_circle,color:accent):null,onTap:(){widget.onThemeChanged(e.key);Navigator.pop(c);})),const SizedBox(height:12)]))); }
}
