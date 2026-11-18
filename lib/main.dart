import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
void main() => runApp(const MyCricStatsApp());
const navy = Color(0xFFF4F6FA), panel = Color(0xFFFFFFFF), red = Color(0xFFE11D48), gold = Color(0xFFB7791F), muted = Color(0xFF667085), blue = Color(0xFF2563EB);
final ValueNotifier<int> mcsTheme = ValueNotifier<int>(0);
const List<Color> mcsThemeSeeds = [Color(0xFFE11D48), Color(0xFF2563EB), Color(0xFF0F9D78), Color(0xFF334155)];
const List<String> mcsThemeNames = ['Crimson','Blue','Emerald','Night'];
const List<List<double>> mcsThemeFilters = [
 [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0],
 [0.82,0,0.08,0,0, 0,0.9,0.08,0,0, 0.08,0.12,1,0,0, 0,0,0,1,0],
 [0.78,0.12,0,0,0, 0.08,0.95,0.05,0,0, 0.02,0.18,0.82,0,0, 0,0,0,1,0],
 [0.42,0,0,0,12, 0,0.48,0,0,12, 0,0,0.62,0,18, 0,0,0,1,0],
];
const apiBase = String.fromEnvironment('MCS_API_BASE', defaultValue: 'https://mycricstats.pages.dev');
class MyCricStatsApp extends StatelessWidget {
 const MyCricStatsApp({super.key});
 @override Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable:mcsTheme,builder:(context,index,_) { final seed=mcsThemeSeeds[index.clamp(0,2)]; return MaterialApp(title:'MyCricStats',debugShowCheckedModeBanner:false,
  theme:ThemeData(useMaterial3:true,brightness:Brightness.light,scaffoldBackgroundColor:navy,colorScheme:ColorScheme.fromSeed(seedColor:seed,brightness:Brightness.light,surface:panel),appBarTheme:const AppBarTheme(backgroundColor:Colors.white,foregroundColor:Color(0xFF101828),elevation:0)),home:const MCSHome()); });
}
class MCSMatch {
 final String id,name,teamA,teamB,status,venue,type;
 final int? scoreA,wicketsA,scoreB,wicketsB; final String oversA,oversB;
 const MCSMatch({required this.id,required this.name,required this.teamA,required this.teamB,required this.status,this.venue='',this.type='Cricket',this.scoreA,this.wicketsA,this.scoreB,this.wicketsB,this.oversA='',this.oversB=''});
 factory MCSMatch.fromJson(Map<String,dynamic> j){
  final runs=(j['runs'] is List)?List<Map>.from(j['runs']):<Map>[];
  final a=runs.isNotEmpty?runs[0]:null, b=runs.length>1?runs[1]:null;
  final local=j['localteam'], visitor=j['visitorteam'];
  return MCSMatch(
   id:(j['id']??j['fixture_id']??'').toString(),
   name:(j['name']??j['round']??j['type']??'Cricket match').toString(),
   teamA:(j['teamA']??(local is Map?local['name']:null)??j['localteam_name']??'Team A').toString(),
   teamB:(j['teamB']??(visitor is Map?visitor['name']:null)??j['visitorteam_name']??'Team B').toString(),
   status:(j['status']??j['note']??(j['live']==1?'LIVE':'Upcoming')).toString(),
   venue:(j['venue'] is Map?j['venue']['name']:j['venue']??'').toString(),
   type:(j['type']??'Cricket').toString(),
   scoreA:_toInt(j['scoreA']??a?['score']),wicketsA:_toInt(j['wicketsA']??a?['wickets']),
   scoreB:_toInt(j['scoreB']??b?['score']),wicketsB:_toInt(j['wicketsB']??b?['wickets']),
   oversA:(j['oversA']??a?['overs']??'').toString(),oversB:(j['oversB']??b?['overs']??'').toString());
 }
 bool get isLive=>status.toLowerCase().contains('live')||status.toLowerCase().contains('innings');
}
int? _toInt(dynamic v)=>v==null?null:int.tryParse(v.toString());
String _score(int? r,int? w)=>r==null?'—':r.toString()+'/'+(w??0).toString();
class MCSApi {
 static Future<List<MCSMatch>> domestic() async {
  final r=await http.get(Uri.parse('$apiBase/api/domestic')).timeout(const Duration(seconds:12));
  if(r.statusCode!=200) throw Exception('Domestic feed returned '+r.statusCode.toString());
  final body=jsonDecode(r.body); final list=body is List?body:(body is Map?body['matches']:null);
  if(list is! List)return []; return list.whereType<Map>().map((e)=>MCSMatch.fromJson(Map<String,dynamic>.from(e))).toList();
 }
 static Future<List<MCSMatch>> liveScores() async {
  final body=await cricket('livescores',query:{'include':'localteam,visitorteam,runs,venue,league'});
  final list=body['data'];
  if(list is! List)return [];
  return list.whereType<Map>().map((e)=>MCSMatch.fromJson(Map<String,dynamic>.from(e))).toList();
 }
 static Future<Map<String,dynamic>> fixture(String id) async {
  return cricket('fixtures/$id',query:{'include':'localteam,visitorteam,runs,batting,bowling,lineup,balls.batsman,balls.bowler,balls.score,venue,league'});
 }
 static Future<Map<String,dynamic>> cricket(String path,{Map<String,String> query=const {}}) async {
  final uri=Uri.parse('$apiBase/api/proxy').replace(queryParameters:{'path':path,'guest':'1',...query});
  final r=await http.get(uri).timeout(const Duration(seconds:14)); final data=jsonDecode(r.body);
  if(r.statusCode!=200)throw Exception(data is Map?data['message']??'Cricket API error':'Cricket API error');
  return Map<String,dynamic>.from(data as Map);
 }
}
class MCSHome extends StatefulWidget { const MCSHome({super.key}); @override State<MCSHome> createState()=>_MCSHomeState(); }
class _MCSHomeState extends State<MCSHome> {
 int tab=0; bool loading=true; String? error; List<MCSMatch> matches=[]; MCSMatch? selected; Timer? timer; Timer? playbackTimer; List<Map<String,dynamic>> demoEvents=[]; int playbackIndex=-1; bool playbackRunning=false; String? demoMatchId;
 Map<String,dynamic>? fixtureData; bool fixtureLoading=false; String? fixtureError; String eventKey=''; int eventVersion=0;
 List<Map<String,dynamic>> get _batting => _records(fixtureData?['batting'] ?? fixtureData?['scoreboards']);
 List<Map<String,dynamic>> get _bowling => _records(fixtureData?['bowling']);
 List<Map<String,dynamic>> get _deliveries => _records(fixtureData?['balls']).reversed.take(24).toList();
 // Historical India–New Zealand results used only as local UI test fixtures.
 // These are not live Sportmonks records.
 static const List<MCSMatch> _demoMatches = [
  MCSMatch(id:'demo-ind-nz-2026-01-11',name:'1st ODI • 11 Jan 2026',teamA:'India',teamB:'New Zealand',status:'DEMO • INDIA WON BY 4 WICKETS',venue:'BCA Stadium, Vadodara',type:'ODI',scoreA:306,wicketsA:6,scoreB:300,wicketsB:8,oversA:'49.0',oversB:'50.0'),
  MCSMatch(id:'demo-ind-nz-2026-01-14',name:'2nd ODI • 14 Jan 2026',teamA:'India',teamB:'New Zealand',status:'DEMO • NZ WON BY 7 WICKETS',venue:'Niranjan Shah Stadium, Rajkot',type:'ODI',scoreA:284,wicketsA:7,scoreB:286,wicketsB:3,oversA:'50.0',oversB:'47.3'),
  MCSMatch(id:'demo-ind-nz-2026-01-18',name:'3rd ODI • 18 Jan 2026',teamA:'India',teamB:'New Zealand',status:'DEMO • NZ WON BY 41 RUNS',venue:'Holkar Cricket Stadium, Indore',type:'ODI',scoreA:296,wicketsA:10,scoreB:337,wicketsB:8,oversA:'46.0',oversB:'50.0'),
  MCSMatch(id:'demo-ind-nz-2026-11-15',name:'5th ODI • 15 Nov 2026',teamA:'India',teamB:'New Zealand',status:'DEMO • INDIA WON BY 22 RUNS',venue:'Bay Oval, Mount Maunganui',type:'ODI',scoreA:209,wicketsA:10,scoreB:187,wicketsB:10,oversA:'42.1',oversB:'48.1'),
 ];

 @override void initState(){super.initState();_loadTheme();refresh();timer=Timer.periodic(const Duration(seconds:12),(_)=>refresh(silent:true));}
 Future<void> _loadTheme() async { final p=await SharedPreferences.getInstance(); mcsTheme.value=(p.getInt('mcs_theme')??0).clamp(0,3); }
 Future<void> _saveTheme(int v) async { mcsTheme.value=v; final p=await SharedPreferences.getInstance(); await p.setInt('mcs_theme',v); }
 @override void dispose(){timer?.cancel();playbackTimer?.cancel();super.dispose();}
 static List<Map<String,dynamic>> _records(dynamic value){if(value is Map&&value['data'] is List)value=value['data'];if(value is! List)return <Map<String,dynamic>>[];return value.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
 String _player(dynamic value){if(value is Map)return (value['fullname']??value['name']??value['display_name']??'Player').toString();return value?.toString()??'—';}
 String _deliveryText(Map<String,dynamic> ball){final score=ball['score'] is Map?Map<String,dynamic>.from(ball['score']):<String,dynamic>{};final runs=_toInt(score['runs']??ball['score'])??0;final wicket=score['is_wicket']==true||ball['is_wicket']==true||ball['wicket']!=null;final name=(score['name']??ball['name']??'').toString().toLowerCase();if(wicket||name.contains('wicket'))return 'WICKET';if(runs==6||name.contains('six'))return 'SIX';if(runs==4||name.contains('four'))return 'FOUR';if(name.isNotEmpty)return name.toUpperCase();return runs.toString()+' RUN'+(runs==1?'':'S');}
 Future<void> loadFixture({bool silent=false}) async {final match=selected;if(match==null||match.id.isEmpty)return;if(match.id.startsWith('demo-')){_stopPlayback();_prepareDemoPlayback(match);if(mounted)setState((){fixtureData=null;fixtureError=null;fixtureLoading=false;});return;}if(!silent&&mounted)setState(()=>fixtureLoading=true);try{final body=await MCSApi.fixture(match.id);final raw=body['data'];if(!mounted||selected?.id!=match.id)return;final data=raw is Map?Map<String,dynamic>.from(raw):body;final balls=_records(data['balls']);final latest=balls.isEmpty?null:balls.last;final key=latest==null?'':(latest['id']??latest['ball']??latest['overs']??jsonEncode(latest)).toString();setState((){fixtureData=data;fixtureError=null;fixtureLoading=false;if(key.isNotEmpty&&key!=eventKey){eventKey=key;eventVersion++;}});}catch(e){if(!mounted)return;setState((){fixtureLoading=false;fixtureError=e.toString().replaceFirst('Exception: ','');});}}
 Future<void> refresh({bool silent=false}) async {
  if(!silent&&mounted)setState(()=>loading=true);
  try{
   List<MCSMatch> live=[];
   try{live=await MCSApi.liveScores();}catch(_){}
   List<MCSMatch> domestic=[];
   try{domestic=await MCSApi.domestic();}catch(_){}
   final byId=<String,MCSMatch>{};
   for(final m in _demoMatches) { byId[m.id]=m; }
   for(final m in domestic) { byId[m.id]=m; }
   for(final m in live) { byId[m.id]=m; }
   final rows=byId.values.toList();
   if(!mounted)return;setState((){
    matches=rows;
    if(selected==null&&rows.isNotEmpty)selected=rows.firstWhere((m)=>m.isLive,orElse:()=>rows.first);
    else if(selected!=null){final fresh=rows.where((m)=>m.id==selected!.id);if(fresh.isNotEmpty)selected=fresh.first;}
    loading=false;error=null;});
   if(selected!=null){if(selected!.id.startsWith('demo-'))_prepareDemoPlayback(selected!);await loadFixture(silent:true);}
  }
  catch(e){if(!mounted)return;setState(() { loading=false; error=e.toString().replaceFirst('Exception: ',''); });}
 }
 @override Widget build(BuildContext context){
  final pages=[_home(),_matches(),_scorecard(),_commentary(),_more()];
  return ValueListenableBuilder<int>(valueListenable:mcsTheme,builder:(context,themeIndex,_)=>ColorFiltered(colorFilter:ColorFilter.matrix(mcsThemeFilters[themeIndex.clamp(0,3)]),child:Scaffold(appBar:AppBar(toolbarHeight:64,titleSpacing:14,title:Row(children:[
   Container(width:38,height:38,decoration:BoxDecoration(color:red,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.sports_cricket,color:Colors.white)),
   const SizedBox(width:10),const Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
    Text('MYCRICSTATS',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900,letterSpacing:1)),
    Text('CRICKET MATCH CENTRE',style:TextStyle(fontSize:9,color:muted,letterSpacing:1.2,fontWeight:FontWeight.w700))])]),
   actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),const SizedBox(width:5)]),
   body:SafeArea(top:false,child:IndexedStack(index:tab,children:pages)),
   bottomNavigationBar:NavigationBar(backgroundColor:Colors.white,indicatorColor:red.withOpacity(.18),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
    destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
     NavigationDestination(icon:Icon(Icons.sports_cricket_outlined),label:'Matches'),NavigationDestination(icon:Icon(Icons.scoreboard_outlined),label:'Scorecard'),
     NavigationDestination(icon:Icon(Icons.mic_none),label:'Commentary'),NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'More')]))));
 }
 Widget _home()=>RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(14),children:[
  _heading('MATCH CENTRE','CRICKET ONLY'),if(selected!=null)_featured(selected!)else _empty(),
  const SizedBox(height:17),_heading('MATCHES',matches.length.toString()+' LISTED'),
  if(loading&&matches.isEmpty)const _Loading() else if(matches.isEmpty)_empty() else ...matches.take(5).map(_matchTile),
  const SizedBox(height:16),_heading('QUICK ACCESS',null),
  Row(children:[Expanded(child:_quick(Icons.table_chart_outlined,'Scorecard',()=>setState(()=>tab=2))),const SizedBox(width:8),
   Expanded(child:_quick(Icons.forum_outlined,'Commentary',()=>setState(()=>tab=3))),const SizedBox(width:8),
   Expanded(child:_quick(Icons.leaderboard_outlined,'Stats',()=>setState(()=>tab=4)))])
 ]));
 Widget _matches()=>RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(14),children:[
  _title('MATCHES','Historical IND vs NZ demo results + connected feeds'),if(error!=null)_error(error!),
  if(loading&&matches.isEmpty)const _Loading(),if(matches.isEmpty&&!loading)_empty(),...matches.map(_matchTile)]));

 void _stopPlayback(){playbackTimer?.cancel();playbackTimer=null;playbackRunning=false;}
 int _ballsFor(String overs){final p=overs.split('.');final o=int.tryParse(p.first)??0;final b=p.length>1?(int.tryParse(p[1])??0):0;return o*6+b;}
 void _prepareDemoPlayback(MCSMatch m){
  if(!m.id.startsWith('demo-'))return;
  if(demoMatchId==m.id&&demoEvents.isNotEmpty)return;
  demoMatchId=m.id;_stopPlayback();final out=<Map<String,dynamic>>[];
  void innings(int n,String team,int runs,int wickets,String overs){
   final count=_ballsFor(overs);if(count<=0)return;
   final values=List<int>.filled(count,0);var remaining=runs;
   const pattern=[1,2,0,4,1,0,3,1,6,0,2,1];
   for(var i=0;i<count&&remaining>0;i++){final cap=pattern[i%pattern.length];final take=remaining<cap?remaining:cap;values[i]=take;remaining-=take;}
   for(var i=0;i<count&&remaining>0;i++){final take=remaining>6?6:remaining;values[i]=take;remaining-=take;}
   final wicketAt=<int>{};for(var w=0;w<wickets;w++){final pos=((w+1)*count/(wickets+1)).floor().clamp(0,count-1);wicketAt.add(pos);}
   for(var i=0;i<count;i++){final label=wicketAt.contains(i)?'WICKET':values[i]==6?'SIX':values[i]==4?'FOUR':values[i]==0?'DOT BALL':values[i].toString()+' RUNS';out.add({'innings':n,'team':team,'runs':values[i],'wicket':wicketAt.contains(i),'over':i~/6+1,'ball':i%6+1,'text':label});}
  }
  innings(1,m.teamA,m.scoreA??0,m.wicketsA??0,m.oversA);
  innings(2,m.teamB,m.scoreB??0,m.wicketsB??0,m.oversB);
  if(mounted)setState(() { demoEvents=out; playbackIndex=-1; playbackRunning=false; });
 }
 void _startPlayback(){
  if(demoEvents.isEmpty||playbackRunning)return;
  if(playbackIndex>=demoEvents.length-1)playbackIndex=-1;
  setState(()=>playbackRunning=true);
  playbackTimer=Timer.periodic(const Duration(milliseconds:650),(t){
   if(!mounted){t.cancel();return;}
   if(playbackIndex>=demoEvents.length-1){t.cancel();setState(()=>playbackRunning=false);return;}
   setState(()=>playbackIndex++);
   if(playbackIndex>=demoEvents.length-1){t.cancel();setState(()=>playbackRunning=false);}
  });
 }
 void _restartPlayback(){_stopPlayback();setState(()=>playbackIndex=-1);_startPlayback();}
 Widget _demoPlaybackPanel(){
  final m=selected!;final current=playbackIndex>=0&&playbackIndex<demoEvents.length?demoEvents[playbackIndex]:null;
  final inning=current==null?1:current['innings'] as int;
  var runs=0,wkts=0,balls=0;
  for(var i=0;i<=playbackIndex&&i<demoEvents.length;i++){final e=demoEvents[i];if(e['innings']==inning){runs+=e['runs'] as int;if(e['wicket']==true)wkts++;balls++;}}
  final team=inning==1?m.teamA:m.teamB;final targetRuns=inning==1?(m.scoreA??0):(m.scoreB??0);final targetWkts=inning==1?(m.wicketsA??0):(m.wicketsB??0);
  final totalBalls=_ballsFor(inning==1?m.oversA:m.oversB);
  final overText='\${balls~/6}.\${balls%6}';
  return _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[_pill('DEMO PLAYBACK',gold),const Spacer(),Text(m.type,style:const TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w800))]),
   const SizedBox(height:12),Text(m.name,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900)),
   const SizedBox(height:12),Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF101044),borderRadius:BorderRadius.circular(14)),child:Column(children:[
    Text('INNINGS $inning • $team',style:const TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),
    const SizedBox(height:7),Text('$runs/$wkts',style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w900)),
    Text('OVER $overText  •  '+(current==null?'READY':current["text"].toString()),style:const TextStyle(color:Color(0xFFF3C66A),fontSize:11,fontWeight:FontWeight.w800)),
    const SizedBox(height:10),LinearProgressIndicator(value:totalBalls==0?0:balls/totalBalls,backgroundColor:Colors.white24,color:const Color(0xFFF3C66A),minHeight:5),
    const SizedBox(height:5),Align(alignment:Alignment.centerRight,child:Text('$balls / $totalBalls balls',style:const TextStyle(color:Colors.white60,fontSize:9)))
   ])),
   const SizedBox(height:12),Row(children:[
    Expanded(child:ElevatedButton.icon(onPressed:playbackRunning?(){_stopPlayback();setState((){});}:_startPlayback,icon:Icon(playbackRunning?Icons.pause:Icons.play_arrow),label:Text(playbackRunning?'PAUSE':'START'),style:ElevatedButton.styleFrom(backgroundColor:red,foregroundColor:Colors.white))),
    const SizedBox(width:8),OutlinedButton.icon(onPressed:_restartPlayback,icon:const Icon(Icons.restart_alt),label:const Text('RESTART'))
   ]),
   const SizedBox(height:8),Text('Final target: $targetRuns/$targetWkts • '+(inning==1?m.oversA:m.oversB)+' overs',style:const TextStyle(color:muted,fontSize:10)),
   const SizedBox(height:6),const Text('Simulated delivery sequence for UI testing — not official historical ball-by-ball data.',style:TextStyle(color:gold,fontSize:9,height:1.4))
  ]));
 }

 Widget _demoScorecard(){
  final m=selected!;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[_pill(m.status,gold),const Spacer(),Text(m.type,style:const TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w900))]),const SizedBox(height:12),_scoreRow(m.teamA,_score(m.scoreA,m.wicketsA),m.oversA),const Divider(height:22),_scoreRow(m.teamB,_score(m.scoreB,m.wicketsB),m.oversB),const SizedBox(height:10),Row(children:[const Icon(Icons.stadium_outlined,color:gold,size:15),const SizedBox(width:6),Expanded(child:Text(m.venue,style:const TextStyle(color:muted,fontSize:10)))])])),
   _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('INNINGS SUMMARY',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12,letterSpacing:1)),const SizedBox(height:12),_inningsSummary(m.teamA,m.scoreA??0,m.wicketsA??0,m.oversA),const Divider(height:22),_inningsSummary(m.teamB,m.scoreB??0,m.wicketsB??0,m.oversB)])),
   _demoPlaybackPanel(),_note('Demo scorecard: final totals are shown for visual testing. Playback deliveries are simulated and are not verified historical ball-by-ball records.')
  ]);
 }
 Widget _inningsSummary(String team,int runs,int wickets,String overs)=>Row(children:[Expanded(child:Text(team,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900))),Text('$runs/$wickets',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:Color(0xFF101828))),const SizedBox(width:8),Text('$overs overs',style:const TextStyle(color:muted,fontSize:10))]);
 Widget _scorecard()=>ListView(padding:const EdgeInsets.all(14),children:[
  _title('SCORECARD',selected?.name??'Select a cricket match'),
  if(selected==null)_empty()else if(selected!.id.startsWith('demo-'))_demoScorecard()else _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[_pill(selected!.status.toUpperCase(),selected!.isLive?red:gold),const Spacer(),Text(selected!.type,style:const TextStyle(color:muted,fontSize:10))]),
   const SizedBox(height:14),_scoreRow(selected!.teamA,_score(selected!.scoreA,selected!.wicketsA),selected!.oversA),
   const Divider(color:Color(0x33444466),height:22),_scoreRow(selected!.teamB,_score(selected!.scoreB,selected!.wicketsB),selected!.oversB),
   const SizedBox(height:14),if(fixtureLoading)const LinearProgressIndicator(minHeight:2),if(fixtureError!=null)Text('Fixture detail: '+fixtureError!,style:const TextStyle(color:red,fontSize:10)),
   _dataSection('BATTING',_batting,['score','runs','ball','overs','four_x','six_x','strike_rate']),_dataSection('BOWLING',_bowling,['overs','medals','runs','wickets','wide','noball','rate']),
   if(_batting.isEmpty&&_bowling.isEmpty&&!fixtureLoading)const Text('Detailed innings figures are not present in this fixture response yet.',style:TextStyle(color:muted,fontSize:11))])),
  _note(selected?.id.startsWith('demo-')==true?'Historical final scores are demo fixtures for layout testing. Detailed batting, bowling and ball-by-ball data are not included.':'Scorecard figures are shown only when returned by the selected Sportmonks fixture.')]);
 Widget _commentary()=>ListView(padding:const EdgeInsets.all(14),children:[_title('BALL-BY-BALL',selected?.name??'Match commentary'),if(selected!=null)_card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.graphic_eq,color:gold),const SizedBox(width:8),const Text('LATEST CONFIRMED EVENTS',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1)),const Spacer(),IconButton(onPressed:()=>loadFixture(),icon:const Icon(Icons.refresh,size:18))]),if(fixtureLoading)const LinearProgressIndicator(minHeight:2),if(fixtureError!=null)Text(fixtureError!,style:const TextStyle(color:red,fontSize:10)),if(_deliveries.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('No ball-by-ball records returned for this fixture yet.',style:TextStyle(color:muted,fontSize:11))),..._deliveries.map((ball){final label=_deliveryText(ball);final special=['FOUR','SIX','WICKET'].contains(label);final over=(ball['ball']??ball['overs']??ball['over']??'').toString();final batter=_player(ball['batsman']);final bowler=_player(ball['bowler']);return Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:const Color(0xFFF8FAFC),borderRadius:BorderRadius.circular(11)),child:Row(children:[Container(width:54,height:38,alignment:Alignment.center,decoration:BoxDecoration(color:special?red.withOpacity(.12):Colors.white,borderRadius:BorderRadius.circular(9)),child:Text(label,style:TextStyle(color:special?red:blue,fontSize:9,fontWeight:FontWeight.w900))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(over.isEmpty?'Delivery':'Ball '+over,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w900)),Text(batter+' vs '+bowler,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:9))]))]));})]))else _empty()]);
 Widget _more()=>ListView(padding:const EdgeInsets.all(14),children:[
  _title('APP THEMES','Choose a theme applied across every screen'),
  _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SELECT A THEME',style:TextStyle(fontSize:11,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[for(var i=0;i<4;i++)_themeChoice(i,mcsThemeNames[i],mcsThemeSeeds[i])])])),
  _title('TOURNAMENT & TOOLS','MyCricStats cricket features'),
  _feature(Icons.groups_2_outlined,'Squads','Playing XI and player list'),
  _feature(Icons.casino_outlined,'Toss setup','Toss winner and bat / bowl decision'),
  _feature(Icons.leaderboard_outlined,'Tournament stats','Orange Cap, Purple Cap and leaderboards'),
  _feature(Icons.chat_bubble_outline,'Match room','Viewer chat and room activity'),
  _feature(Icons.history,'Match history','Completed matches and saved scorecards'),
  _feature(Icons.campaign_outlined,'Sponsor placements','Advertisement areas in match centre'),
  _note('These are MCS cricket destinations. Full migration of each module is staged separately; they are not marked as integrated.')]);
 Widget _featured(MCSMatch m)=>Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(16),
  decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF17174F),Color(0xFF09092E)]),border:Border.all(color:Colors.white.withOpacity(.13))),
  child:Column(children:[
   Row(children:[_pill(m.isLive?'LIVE':m.status.toUpperCase(),m.isLive?red:gold),const Spacer(),Text(m.type.toUpperCase(),style:const TextStyle(color:muted,fontSize:9,fontWeight:FontWeight.w800))]),
   const SizedBox(height:17),Row(children:[Expanded(child:_team(m.teamA,_score(m.scoreA,m.wicketsA),m.oversA)),
    const Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Text('VS',style:TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w900))),
    Expanded(child:_team(m.teamB,_score(m.scoreB,m.wicketsB),m.oversB))]),
   const SizedBox(height:14),Divider(color:Colors.white.withOpacity(.1),height:1),
   Row(children:[const Icon(Icons.stadium_outlined,color:gold,size:14),const SizedBox(width:6),
    Expanded(child:Text(m.venue.isEmpty?m.name:m.venue,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:10))),
    TextButton(onPressed:()=>setState(()=>tab=2),child:const Text('SCORECARD',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900)))])]));
 Widget _team(String name,String score,String overs)=>Column(children:[
  const Icon(Icons.shield_outlined,color:blue,size:29),const SizedBox(height:6),
  Text(name.toUpperCase(),textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)),
  const SizedBox(height:4),Text(score,style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)),
  if(overs.isNotEmpty)Text('OV '+overs,style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w800))]);
 Widget _matchTile(MCSMatch m)=>InkWell(onTap:(){setState(() { selected=m; tab=m.id.startsWith('demo-')?2:0; fixtureData=null; fixtureError=null; });if(m.id.startsWith('demo-'))loadFixture(silent:true);},borderRadius:BorderRadius.circular(14),
  child:Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),
   decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(.09))),
   child:Column(children:[Row(children:[_pill(m.isLive?'LIVE':m.status.toUpperCase(),m.isLive?red:gold),const Spacer(),Text(m.type,style:const TextStyle(color:muted,fontSize:9))]),
    const SizedBox(height:10),_scoreRow(m.teamA,_score(m.scoreA,m.wicketsA),m.oversA),const SizedBox(height:7),
    _scoreRow(m.teamB,_score(m.scoreB,m.wicketsB),m.oversB),
    if(m.venue.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Align(alignment:Alignment.centerLeft,child:Text(m.venue,style:const TextStyle(color:muted,fontSize:9))))])));
 Widget _dataSection(String heading,List<Map<String,dynamic>> rows,List<String> fields){if(rows.isEmpty)return const SizedBox.shrink();return Padding(padding:const EdgeInsets.only(top:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(heading,style:const TextStyle(color:gold,fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1)),const SizedBox(height:6),...rows.map((r){final player=_player(r['batsman']??r['bowler']??r['player']??r['player_name']??r['name']);final vals=fields.where((k)=>r[k]!=null).map((k)=>k+': '+r[k].toString()).join(' • ');return Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(player,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800))),Flexible(child:Text(vals,overflow:TextOverflow.ellipsis,textAlign:TextAlign.right,style:const TextStyle(color:muted,fontSize:9)))]));})]));}
 Widget _scoreRow(String n,String s,String o)=>Row(children:[Expanded(child:Text(n,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))),
  Text(s,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),if(o.isNotEmpty)Padding(padding:const EdgeInsets.only(left:7),child:Text('('+o+' ov)',style:const TextStyle(color:muted,fontSize:10)))]);
 Widget _empty()=>_card(Column(children:[const Icon(Icons.sports_cricket,color:gold,size:30),const SizedBox(height:8),
  const Text('No matches available yet',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),const SizedBox(height:5),
  const Text('Demo IND vs NZ results and matches published to the MyCricStats feeds will appear here.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:11,height:1.45)),
  const SizedBox(height:9),OutlinedButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh,size:16),label:const Text('Refresh'))]));
 Widget _error(String s)=>_card(Row(children:[const Icon(Icons.cloud_off,color:red),const SizedBox(width:9),Expanded(child:Text(s,style:const TextStyle(color:muted,fontSize:11)))]));
 Widget _title(String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Text(a,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(b,style:const TextStyle(color:muted,fontSize:11))]));
 Widget _heading(String a,String? b)=>Row(children:[Text(a,style:const TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.2)),const Spacer(),if(b!=null)Text(b,style:const TextStyle(color:gold,fontSize:9,fontWeight:FontWeight.w800))]);
 Widget _card(Widget child)=>Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(15),border:Border.all(color:Colors.white.withOpacity(.09))),child:child);
 Widget _pill(String t,Color c)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:c.withOpacity(.14),borderRadius:BorderRadius.circular(30),border:Border.all(color:c.withOpacity(.45))),child:Text(t.isEmpty?'MATCH':t,style:TextStyle(color:c,fontSize:8,fontWeight:FontWeight.w900,letterSpacing:.7)));
 Widget _quick(IconData i,String s,VoidCallback f)=>InkWell(onTap:f,borderRadius:BorderRadius.circular(12),child:Container(padding:const EdgeInsets.symmetric(vertical:14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(12)),child:Column(children:[Icon(i,color:gold),const SizedBox(height:6),Text(s,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800))])));
 Widget _themeChoice(int value,String label,Color color)=>ChoiceChip(label:Text(label),selected:mcsTheme.value==value,avatar:CircleAvatar(radius:7,backgroundColor:color),onSelected:(_)=>_saveTheme(value));
 Widget _feature(IconData i,String a,String b)=>_card(Row(children:[Icon(i,color:gold,size:21),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(b,style:const TextStyle(color:muted,fontSize:10))])),const Icon(Icons.chevron_right,color:muted)]));
 Widget _note(String s)=>Padding(padding:const EdgeInsets.only(top:12),child:Text(s,style:const TextStyle(color:muted,fontSize:10,height:1.5)));
}
class _Loading extends StatelessWidget { const _Loading(); @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14)),child:const Row(children:[SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:12),Text('Loading MyCricStats matches…',style:TextStyle(color:muted,fontSize:11))])); }
