import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
void main() => runApp(const MyCricStatsApp());
const navy = Color(0xFFF4F6FA), panel = Color(0xFFFFFFFF), red = Color(0xFFE11D48), gold = Color(0xFFB7791F), muted = Color(0xFF667085), blue = Color(0xFF2563EB);
const apiBase = String.fromEnvironment('MCS_API_BASE', defaultValue: 'https://mycricstats.pages.dev');
class MyCricStatsApp extends StatelessWidget {
 const MyCricStatsApp({super.key});
 @override Widget build(BuildContext context) => MaterialApp(title:'MyCricStats',debugShowCheckedModeBanner:false,
  theme:ThemeData(useMaterial3:true,brightness:Brightness.light,scaffoldBackgroundColor:navy,colorScheme:const ColorScheme.light(primary:red,secondary:gold,surface:panel),appBarTheme:const AppBarTheme(backgroundColor:Colors.white,foregroundColor:Color(0xFF101828),elevation:0)),home:const MCSHome());
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
   scoreA:_toInt(j['scoreA']??a?['score']),wicketsA:_toInt(j['wicketsA']??a?[' wickets']??a?['wickets']),
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
  return cricket('fixtures/$id',query:{'include':'localteam,visitorteam,runs,batting,bowling,lineup,balls,venue,league'});
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
 int tab=0; bool loading=true; String? error; List<MCSMatch> matches=[]; MCSMatch? selected; Timer? timer;
 @override void initState(){super.initState();refresh();timer=Timer.periodic(const Duration(seconds:12),(_)=>refresh(silent:true));}
 @override void dispose(){timer?.cancel();super.dispose();}
 Future<void> refresh({bool silent=false}) async {
  if(!silent&&mounted)setState(()=>loading=true);
  try{
   List<MCSMatch> live=[];
   try{live=await MCSApi.liveScores();}catch(_){}
   final domestic=await MCSApi.domestic();
   final byId=<String,MCSMatch>{};
   for(final m in domestic) { byId[m.id]=m; }
   for(final m in live) { byId[m.id]=m; }
   final rows=byId.values.toList();
   if(!mounted)return;setState((){
    matches=rows;
    if(selected==null&&rows.isNotEmpty)selected=rows.firstWhere((m)=>m.isLive,orElse:()=>rows.first);
    else if(selected!=null){final fresh=rows.where((m)=>m.id==selected!.id);if(fresh.isNotEmpty)selected=fresh.first;}
    loading=false;error=null;});
  }
  catch(e){if(!mounted)return;setState(() { loading=false; error=e.toString().replaceFirst('Exception: ',''); });}
 }
 @override Widget build(BuildContext context){
  final pages=[_home(),_matches(),_scorecard(),_commentary(),_more()];
  return Scaffold(appBar:AppBar(toolbarHeight:64,titleSpacing:14,title:Row(children:[
   Container(width:38,height:38,decoration:BoxDecoration(color:red,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.sports_cricket,color:Colors.white)),
   const SizedBox(width:10),const Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
    Text('MYCRICSTATS',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900,letterSpacing:1)),
    Text('CRICKET MATCH CENTRE',style:TextStyle(fontSize:9,color:muted,letterSpacing:1.2,fontWeight:FontWeight.w700))])]),
   actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),const SizedBox(width:5)]),
   body:SafeArea(top:false,child:IndexedStack(index:tab,children:pages)),
   bottomNavigationBar:NavigationBar(backgroundColor:const Color(0xFF08083A),indicatorColor:red.withOpacity(.18),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
    destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
     NavigationDestination(icon:Icon(Icons.sports_cricket_outlined),label:'Matches'),NavigationDestination(icon:Icon(Icons.scoreboard_outlined),label:'Scorecard'),
     NavigationDestination(icon:Icon(Icons.mic_none),label:'Commentary'),NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'More')]));
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
  _title('MATCHES','MyCricStats domestic match feed'),if(error!=null)_error(error!),
  if(loading&&matches.isEmpty)const _Loading(),if(matches.isEmpty&&!loading)_empty(),...matches.map(_matchTile)]));
 Widget _scorecard()=>ListView(padding:const EdgeInsets.all(14),children:[
  _title('SCORECARD',selected?.name??'Select a cricket match'),
  if(selected==null)_empty()else _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[_pill(selected!.status.toUpperCase(),selected!.isLive?red:gold),const Spacer(),Text(selected!.type,style:const TextStyle(color:muted,fontSize:10))]),
   const SizedBox(height:14),_scoreRow(selected!.teamA,_score(selected!.scoreA,selected!.wicketsA),selected!.oversA),
   const Divider(color:Color(0x33444466),height:22),_scoreRow(selected!.teamB,_score(selected!.scoreB,selected!.wicketsB),selected!.oversB),
   const SizedBox(height:14),const Text('BATTING & BOWLING',style:TextStyle(color:gold,fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1)),
   const SizedBox(height:7),const Text('Live innings totals are synced from Sportmonks Cricket. Detailed batting, bowling and ball-by-ball panels are being connected next.',style:TextStyle(color:muted,fontSize:11,height:1.5))])),
  _note('This view is connected to the MCS domestic match list. Full fixture scorecard mapping is the next integration step.')]);
 Widget _commentary()=>ListView(padding:const EdgeInsets.all(14),children:[
  _title('BALL-BY-BALL',selected?.name??'Match commentary'),
  _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Row(children:[Icon(Icons.graphic_eq,color:gold),SizedBox(width:8),Text('LIVE COMMENTARY',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1))]),
   const SizedBox(height:12),const Text('Commentary and ball-by-ball data will be loaded from the selected Sportmonks fixture when available. Event animations will only play for confirmed deliveries.',style:TextStyle(color:muted,fontSize:12,height:1.55)),
   if(selected!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(selected!.teamA+' vs '+selected!.teamB,style:const TextStyle(color:blue,fontSize:11,fontWeight:FontWeight.w800))) ]))]);
 Widget _more()=>ListView(padding:const EdgeInsets.all(14),children:[
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
  Text(name.toUpperCase(),textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w900)),
  const SizedBox(height:4),Text(score,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
  if(overs.isNotEmpty)Text('OV '+overs,style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w800))]);
 Widget _matchTile(MCSMatch m)=>InkWell(onTap:()=>setState(() { selected=m; tab=0; }),borderRadius:BorderRadius.circular(14),
  child:Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),
   decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(.09))),
   child:Column(children:[Row(children:[_pill(m.isLive?'LIVE':m.status.toUpperCase(),m.isLive?red:gold),const Spacer(),Text(m.type,style:const TextStyle(color:muted,fontSize:9))]),
    const SizedBox(height:10),_scoreRow(m.teamA,_score(m.scoreA,m.wicketsA),m.oversA),const SizedBox(height:7),
    _scoreRow(m.teamB,_score(m.scoreB,m.wicketsB),m.oversB),
    if(m.venue.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Align(alignment:Alignment.centerLeft,child:Text(m.venue,style:const TextStyle(color:muted,fontSize:9))))])));
 Widget _scoreRow(String n,String s,String o)=>Row(children:[Expanded(child:Text(n,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))),
  Text(s,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),if(o.isNotEmpty)Padding(padding:const EdgeInsets.only(left:7),child:Text('('+o+' ov)',style:const TextStyle(color:muted,fontSize:10)))]);
 Widget _empty()=>_card(Column(children:[const Icon(Icons.sports_cricket,color:gold,size:30),const SizedBox(height:8),
  const Text('No MCS matches available yet',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),const SizedBox(height:5),
  const Text('Matches published to the MyCricStats domestic feed will appear here.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:11,height:1.45)),
  const SizedBox(height:9),OutlinedButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh,size:16),label:const Text('Refresh'))]));
 Widget _error(String s)=>_card(Row(children:[const Icon(Icons.cloud_off,color:red),const SizedBox(width:9),Expanded(child:Text(s,style:const TextStyle(color:muted,fontSize:11)))]));
 Widget _title(String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Text(a,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(b,style:const TextStyle(color:muted,fontSize:11))]));
 Widget _heading(String a,String? b)=>Row(children:[Text(a,style:const TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.2)),const Spacer(),if(b!=null)Text(b,style:const TextStyle(color:gold,fontSize:9,fontWeight:FontWeight.w800))]);
 Widget _card(Widget child)=>Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(15),border:Border.all(color:Colors.white.withOpacity(.09))),child:child);
 Widget _pill(String t,Color c)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:c.withOpacity(.14),borderRadius:BorderRadius.circular(30),border:Border.all(color:c.withOpacity(.45))),child:Text(t.isEmpty?'MATCH':t,style:TextStyle(color:c,fontSize:8,fontWeight:FontWeight.w900,letterSpacing:.7)));
 Widget _quick(IconData i,String s,VoidCallback f)=>InkWell(onTap:f,borderRadius:BorderRadius.circular(12),child:Container(padding:const EdgeInsets.symmetric(vertical:14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(12)),child:Column(children:[Icon(i,color:gold),const SizedBox(height:6),Text(s,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800))])));
 Widget _feature(IconData i,String a,String b)=>_card(Row(children:[Icon(i,color:gold,size:21),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(b,style:const TextStyle(color:muted,fontSize:10))])),const Icon(Icons.chevron_right,color:muted)]));
 Widget _note(String s)=>Padding(padding:const EdgeInsets.only(top:12),child:Text(s,style:const TextStyle(color:muted,fontSize:10,height:1.5)));
}
class _Loading extends StatelessWidget { const _Loading(); @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14)),child:const Row(children:[SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:12),Text('Loading MyCricStats matches…',style:TextStyle(color:muted,fontSize:11))])); }
