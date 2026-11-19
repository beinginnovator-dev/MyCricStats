import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'tournament_engine.dart';

void main()=>runApp(const SportzFlutterApp());

class SportzFlutterApp extends StatefulWidget { const SportzFlutterApp({super.key}); @override State<SportzFlutterApp> createState()=>_SportzFlutterAppState(); }
class _SportzFlutterAppState extends State<SportzFlutterApp>{
  ThemeMode mode=ThemeMode.dark;
  @override void initState(){super.initState();SharedPreferences.getInstance().then((p){if(mounted)setState(()=>mode=p.getBool('light_theme')??false?ThemeMode.light:ThemeMode.dark);});}
  void setMode(ThemeMode m)async{final p=await SharedPreferences.getInstance();await p.setBool('light_theme',m==ThemeMode.light);if(mounted)setState(()=>mode=m);}
  @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'MyCricStats',themeMode:mode,theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff087f68),brightness:Brightness.light),scaffoldBackgroundColor:const Color(0xfff3f6fa),cardTheme:CardThemeData(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))),darkTheme:ThemeData(useMaterial3:true,brightness:Brightness.dark,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xffff304f),brightness:Brightness.dark),scaffoldBackgroundColor:const Color(0xff080b12),cardTheme:CardThemeData(color:const Color(0xff141b29),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))),home:SportzHome(mode:mode,onMode:setMode));
}

class SportzHome extends StatefulWidget{const SportzHome({super.key,required this.mode,required this.onMode});final ThemeMode mode;final ValueChanged<ThemeMode> onMode;@override State<SportzHome> createState()=>_SportzHomeState();}
class _SportzHomeState extends State<SportzHome>{
  int tab=0,homeSubtab=0,statsSubtab=0;bool loading=true;
  final teams=<TeamRecord>[];final history=<Map<String,dynamic>>[];
  MatchSettings settings=MatchSettings();
  MatchRecord? match;TournamentEngine? engine;
  String tossWinner='',tossDecision='Bat';
  final sponsors=<Map<String,String>>[];
  final popupAds=<Map<String,String>>[];
  final titleC=TextEditingController(),venueC=TextEditingController(),adTextC=TextEditingController(),adImageC=TextEditingController(),adLinkC=TextEditingController();
  final teamNameC=TextEditingController(),playerNameC=TextEditingController();
  String teamCountry='India',teamFlag='🇮🇳',playerRole='All-rounder';
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{final p=await SharedPreferences.getInstance();try{final t=jsonDecode(p.getString('sportz_teams')??'[]') as List;teams..clear()..addAll(t.map((e)=>TeamRecord.fromJson(Map<String,dynamic>.from(e))));history..clear()..addAll((jsonDecode(p.getString('sportz_history')??'[]') as List).map((e)=>Map<String,dynamic>.from(e)));settings=MatchSettings.fromJson(Map<String,dynamic>.from(jsonDecode(p.getString('sportz_settings')??'{}')));sponsors..clear()..addAll((jsonDecode(p.getString('sportz_sponsors')??'[]') as List).map((x)=>Map<String,String>.from(x)));popupAds..clear()..addAll((jsonDecode(p.getString('sportz_popup_ads')??'[]') as List).map((x)=>Map<String,String>.from(x)));}catch(_){}if(mounted)setState(()=>loading=false);}
  Future<void> _save()async{final p=await SharedPreferences.getInstance();await p.setString('sportz_teams',jsonEncode(teams.map((e)=>e.toJson()).toList()));await p.setString('sportz_history',jsonEncode(history));await p.setString('sportz_settings',jsonEncode(settings.toJson()));await p.setString('sportz_sponsors',jsonEncode(sponsors));await p.setString('sportz_popup_ads',jsonEncode(popupAds));}
  TeamRecord? get a=>teams.isNotEmpty?teams[0]:null;TeamRecord? get b=>teams.length>1?teams[1]:null;
  List<PlayerRecord> get allPlayers=>teams.expand((t)=>t.players).toList();
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Future<String?> textDialog(String title,String initial)async{final c=TextEditingController(text:initial);return showDialog<String>(context:context,builder:(d)=>AlertDialog(title:Text(title),content:TextField(controller:c,autofocus:true),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('Save'))]));}
  Future<void> addTeam()async{final n=await textDialog('Create team name','');if(n==null||n.isEmpty)return;final country=await textDialog('Country / team region',teamCountry);if(country==null)return;teamCountry=country.isEmpty?'India':country;teamFlag=teamCountry.toLowerCase().contains('new zealand')?'🇳🇿':teamCountry.toLowerCase().contains('australia')?'🇦🇺':teamCountry.toLowerCase().contains('england')?'🏴':teamCountry.toLowerCase().contains('pakistan')?'🇵🇰':teamCountry.toLowerCase().contains('india')?'🇮🇳':'🏏';setState(()=>teams.add(TeamRecord(id:'t${DateTime.now().microsecondsSinceEpoch}',name:n,country:teamCountry,flag:teamFlag)));await _save();}
  Future<void> addPlayer(TeamRecord team)async{final n=await textDialog('Player name','');if(n==null||n.isEmpty)return;final role=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('Player role'),content:Column(mainAxisSize:MainAxisSize.min,children:['Batter','Bowler','All-rounder','Wicketkeeper'].map((r)=>ListTile(title:Text(r),onTap:()=>Navigator.pop(d,r))).toList())));if(role==null)return;setState(()=>team.players.add(PlayerRecord(id:'p${DateTime.now().microsecondsSinceEpoch}',name:n,role:role,teamId:team.id)));await _save();}
  Future<void> configureMatch()async{titleC.text=settings.title;venueC.text=settings.venue;adTextC.text=settings.adText;adImageC.text=settings.adImageUrl;adLinkC.text=settings.adLink;await showDialog<void>(context:context,builder:(d)=>StatefulBuilder(builder:(d,setD)=>AlertDialog(title:const Text('Match & advertisement settings'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:titleC,decoration:const InputDecoration(labelText:'Match title')),TextField(controller:venueC,decoration:const InputDecoration(labelText:'Venue')),TextFormField(initialValue:settings.overs.toString(),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Overs per innings',helperText:'Enter any positive whole number'),onChanged:(v){final n=int.tryParse(v.trim());if(n!=null&&n>0&&n<=300)setD(()=>settings.overs=n);}),DropdownButtonFormField<int>(value:settings.playersPerSide,decoration:const InputDecoration(labelText:'Players per side'),items:[5,6,7,8,9,10,11].map((x)=>DropdownMenuItem(value:x,child:Text('$x players'))).toList(),onChanged:(v)=>setD(()=>settings.playersPerSide=v??11)),DropdownButtonFormField<String>(value:settings.matchType,decoration:const InputDecoration(labelText:'Match format'),items:['Limited Overs','T10','T20','ODI','Custom'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setD(()=>settings.matchType=v??'Limited Overs')),SwitchListTile(title:const Text('Enable super-over option'),value:settings.superOvers,onChanged:(v)=>setD(()=>settings.superOvers=v)),SwitchListTile(title:const Text('Dual batting mode'),subtitle:const Text('Track striker and non-striker'),value:settings.dualBatting,onChanged:(v)=>setD(()=>settings.dualBatting=v)),const Divider(),SwitchListTile(title:const Text('Enable advertisement'),value:settings.adEnabled,onChanged:(v)=>setD(()=>settings.adEnabled=v)),SwitchListTile(title:const Text('Popup advertisement'),value:settings.adPopup,onChanged:(v)=>setD(()=>settings.adPopup=v)),DropdownButtonFormField<String>(value:settings.adPosition,decoration:const InputDecoration(labelText:'Advertisement position'),items:['Below scoreboard','Above scoreboard','Between innings','Match result'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setD(()=>settings.adPosition=v??'Below scoreboard')),TextField(controller:adTextC,decoration:const InputDecoration(labelText:'Ad text / sponsor')),TextField(controller:adImageC,decoration:const InputDecoration(labelText:'Image URL')),TextField(controller:adLinkC,decoration:const InputDecoration(labelText:'Click-through URL'))])),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:(){settings.title=titleC.text;settings.venue=venueC.text;settings.adText=adTextC.text;settings.adImageUrl=adImageC.text;settings.adLink=adLinkC.text;setState((){});_save();Navigator.pop(d);},child:const Text('Save settings'))])));}
  void createMatch(){if(a==null||b==null){msg('Create at least two teams first');return;}if(a!.players.length<2||b!.players.length<1){msg('Add at least two players to batting team and one bowler to opposition');return;}for(final p in allPlayers){p.isOut=false;p.runs=0;p.balls=0;p.fours=0;p.sixes=0;p.bowlRuns=0;p.bowlBalls=0;p.wickets=0;p.dots=0;p.wides=0;p.noBalls=0;}settings.title=settings.title.trim().isEmpty?'MATCH DAY':settings.title;match=MatchRecord(id:'m${DateTime.now().millisecondsSinceEpoch}',teamAId:a!.id,teamBId:b!.id,teamA:a!.name,teamB:b!.name,settings:settings,firstBattingTeamId:a!.id);engine=TournamentEngine(match!,allPlayers);tossWinner='';tossDecision='Bat';setState(()=>{tab=0;homeSubtab=2;});}
  Future<void> completeToss()async{
    if(match==null||engine==null)return;
    final caller=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('Which team calls the toss?'),content:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(title:Text(match!.teamA),onTap:()=>Navigator.pop(d,match!.teamAId)),ListTile(title:Text(match!.teamB),onTap:()=>Navigator.pop(d,match!.teamBId))])));
    if(caller==null)return;
    final call=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('Call the coin'),content:Wrap(spacing:12,children:['Heads','Tails'].map((x)=>FilledButton(onPressed:()=>Navigator.pop(d,x),child:Text(x))).toList())));
    if(call==null)return;
    final result=DateTime.now().microsecondsSinceEpoch.isEven?'Heads':'Tails';
    final winner=call==result?caller:(caller==match!.teamAId?match!.teamBId:match!.teamAId);
    final decision=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:Text('${result.toUpperCase()} — ${_team(winner)?.name??'Winner'} won the toss'),content:const Text('Toss-winning team elects:'),actions:[TextButton(onPressed:()=>Navigator.pop(d,'Bat'),child:const Text('BAT')),FilledButton(onPressed:()=>Navigator.pop(d,'Bowl'),child:const Text('BOWL'))]));
    if(decision==null)return;
    try{engine!.startToss(winnerTeamId:winner,decision:decision);tossWinner=winner;tossDecision=decision;setState(()=>homeSubtab=2);await _save();msg('${_team(winner)?.name??'Team'} won the toss and elected to ${decision.toLowerCase()}.');}catch(e){msg(e.toString());}
  }
  Future<String?> choosePlayer(String title,List<PlayerRecord> options)async=>showDialog<String>(context:context,builder:(d)=>AlertDialog(title:Text(title),content:SizedBox(width:320,child:ListView(shrinkWrap:true,children:options.map((p)=>ListTile(title:Text(p.name),subtitle:Text(p.role),onTap:()=>Navigator.pop(d,p.id))).toList()))));
  Future<void> pickOpeners()async{final e=engine!;final bat=e.battingSquad,bowl=e.bowlingSquad;if(bat.length<2||bowl.isEmpty){msg('Squad players are missing');return;}final st=await choosePlayer('Select striker',bat.where((p)=>!p.isOut).toList());if(st==null)return;final ns=await choosePlayer('Select non-striker',bat.where((p)=>!p.isOut&&p.id!=st).toList());if(ns==null)return;final bw=await choosePlayer('Select opening bowler',bowl);if(bw==null)return;try{if(match!.innings==1)e.selectOpeners(strikerId:st,nonStrikerId:ns,bowlerId:bw);else e.startSecondInnings(strikerId:st,nonStrikerId:ns,bowlerId:bw);setState((){});await publishLive();}catch(x){msg(x.toString());}}
  Future<void> nextBatter()async{final e=engine!,inn=e.match.current;final p=await choosePlayer('Select next batter',e.battingSquad.where((x)=>!x.isOut&&x.id!=inn.striker&&x.id!=inn.nonStriker).toList());if(p==null)return;try{e.selectNextBatter(p);setState((){});await publishLive();}catch(x){msg(x.toString());}}
  Future<void> nextBowler()async{final e=engine!;final p=await choosePlayer('Select next bowler',e.bowlingSquad.where((x)=>x.id!=e.match.current.bowler&&x.id!=e.lastOverBowler).toList());if(p==null)return;try{e.selectNextBowler(p);setState((){});await publishLive();}catch(x){msg(x.toString());}}
  TeamRecord? _team(String id){for(final t in teams){if(t.id==id)return t;}return null;}
  Future<void> publishLive()async{final m=match;if(m==null)return;try{final payload={'match':m.toJson(),'players':allPlayers.map((p)=>p.toJson()).toList(),'teamA':{'flag':_team(m.teamAId)?.flag??'🏏'},'teamB':{'flag':_team(m.teamBId)?.flag??'🏏'}};final url=Uri.parse('${Uri.base.origin}/api/live/${m.id}');final r=await http.put(url,headers:{'Content-Type':'application/json'},body:jsonEncode(payload));if(r.statusCode<200||r.statusCode>=300)throw Exception('Live sync HTTP ${r.statusCode}');}catch(e){debugPrint('Live sync failed: $e');}}
  Future<void> shareLive()async{final m=match;if(m==null){msg('Create a match first');return;}await publishLive();final url='${Uri.base.origin}/live.html?id=${Uri.encodeComponent(m.id)}';await Share.share(url,subject:'${m.teamA} vs ${m.teamB} - Live Score');}
  Future<void> reselectBatter(bool striker)async{final e=engine!;final options=e.battingSquad.where((p)=>!p.isOut&&p.id!=(striker?e.match.current.nonStriker:e.match.current.striker)).toList();final id=await choosePlayer(striker?'Select striker':'Select non-striker',options);if(id==null)return;try{e.changeBatter(playerId:id,striker:striker);setState((){});await publishLive();}catch(x){msg(x.toString());}}
  Future<void> reselectBowler()async{final e=engine!;final options=e.bowlingSquad.where((p)=>p.id!=e.match.current.bowler).toList();final id=await choosePlayer('Select bowler',options);if(id==null)return;try{e.changeBowler(id);setState((){});await publishLive();}catch(x){msg(x.toString());}}
  Future<void> selectBatterCategory()async{
    final choice=await showModalBottomSheet<String>(context:context,builder:(d)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
      const ListTile(title:Text('BATTING PLAYERS',style:TextStyle(fontWeight:FontWeight.w900))),
      ListTile(leading:const Icon(Icons.star),title:const Text('Select striker'),onTap:()=>Navigator.pop(d,'striker')),
      ListTile(leading:const Icon(Icons.person_outline),title:const Text('Select non-striker'),onTap:()=>Navigator.pop(d,'non')),
      if(engine?.requireBatterChange==true)ListTile(leading:const Icon(Icons.person_add),title:const Text('Select next batter'),onTap:()=>Navigator.pop(d,'next')),
      ListTile(leading:const Icon(Icons.swap_horiz),title:const Text('Swap striker / non-striker ends'),onTap:()=>Navigator.pop(d,'swap')),
    ])));
    if(choice==null)return;
    if(choice=='striker')await reselectBatter(true);
    if(choice=='non')await reselectBatter(false);
    if(choice=='next')await nextBatter();
    if(choice=='swap'){try{engine!.swapBatters();setState((){});await publishLive();}catch(e){msg(e.toString());}}
  }
  Future<void> changePlayerUnified()async{
    final role=await showModalBottomSheet<String>(context:context,builder:(d)=>SafeArea(child:Wrap(children:[
      ListTile(leading:const Icon(Icons.sports_cricket),title:const Text('Change striker'),onTap:()=>Navigator.pop(d,'striker')),
      ListTile(leading:const Icon(Icons.swap_horiz),title:const Text('Change non-striker'),onTap:()=>Navigator.pop(d,'non')),
      ListTile(leading:const Icon(Icons.sports_baseball),title:const Text('Change bowler'),onTap:()=>Navigator.pop(d,'bowler')),
      if(engine?.requireBatterChange==true)ListTile(leading:const Icon(Icons.person_add),title:const Text('Select next batter'),onTap:()=>Navigator.pop(d,'next')),
      if(engine?.requireBowlerChange==true)ListTile(leading:const Icon(Icons.sports),title:const Text('Select next-over bowler'),onTap:()=>Navigator.pop(d,'nextBowler')),
    ])));
    if(role==null)return;
    if(role=='striker'){await reselectBatter(true);}
    else if(role=='non'){await reselectBatter(false);}
    else if(role=='bowler'){await reselectBowler();}
    else if(role=='next'){await nextBatter();}
    else if(role=='nextBowler'){await nextBowler();}
  }
  Future<void> extraDelivery(DeliveryType type)async{final choices=type==DeliveryType.noBall?[0,1,2,3,4,6]:type==DeliveryType.wide?[1,2,3,4,5]:[1,2,3,4];final n=await showDialog<int>(context:context,builder:(d)=>AlertDialog(title:Text(type==DeliveryType.wide?'Wide runs (total) ':type==DeliveryType.noBall?'Runs off the bat on no-ball':'Leg-bye runs'),content:Wrap(spacing:8,children:choices.map((v)=>FilledButton(onPressed:()=>Navigator.pop(d,v),child:Text('$v'))).toList()),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel'))]));if(n!=null)await score(n,type:type);}
  Future<void> score(int runs,{DeliveryType type=DeliveryType.legal})async{final e=engine!;try{e.record(runs:runs,type:type);setState((){});await publishLive();if(e.match.status=='Innings Break'){msg('Innings complete. Select openers for the chase.');}if(e.match.status=='Completed'){msg('Match completed. Review the scorecard, then save it to history.');}}catch(x){msg(x.toString());}}
  Future<void> wicket()async{final e=engine!;final d=await showDialog<DismissalType>(context:context,builder:(c)=>AlertDialog(title:const Text('Dismissal type'),content:Column(mainAxisSize:MainAxisSize.min,children:DismissalType.values.map((v)=>ListTile(title:Text(v.name),onTap:()=>Navigator.pop(c,v))).toList())));if(d==null)return;String? fielder;if(d==DismissalType.caught||d==DismissalType.runOut){final f=await choosePlayer('Select fielder',e.bowlingSquad);if(f==null)return;fielder=e.players[f]!.name;}String? out;if(d==DismissalType.runOut){final inn=e.match.current;out=await showDialog<String>(context:context,builder:(c)=>AlertDialog(title:const Text('Who was run out?'),content:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(title:Text(e.players[inn.striker]?.name??'Striker'),onTap:()=>Navigator.pop(c,inn.striker)),ListTile(title:Text(e.players[inn.nonStriker]?.name??'Non-striker'),onTap:()=>Navigator.pop(c,inn.nonStriker))])));if(out==null)return;}try{e.record(runs:0,wicket:true,dismissal:d,fielder:fielder,runOutBatterId:out);setState((){});await publishLive();if(e.match.status=='Completed'){msg('Match completed. Review the scorecard, then save it to history.');}else if(e.requireBatterChange){await nextBatter();}}catch(x){msg(x.toString());}}
  Future<void> saveCompletedMatch()async{final m=match!,e=engine!;final playerRows=allPlayers.map((p)=>p.toJson()).toList();final first=m.inningsList.first;final second=m.inningsList.length>1?m.inningsList[1]:null;history.add({'id':m.id,'title':m.settings.title,'teamA':m.teamA,'teamB':m.teamB,'result':m.result,'firstRuns':first.runs,'firstWickets':first.wickets,'firstOvers':first.overs,'secondRuns':second?.runs??0,'secondWickets':second?.wickets??0,'secondOvers':second?.overs??'0.0','players':playerRows,'completedAt':DateTime.now().toIso8601String(),'deliveries':m.allDeliveries.map((d)=>d.toJson()).toList()});await _save();match=null;engine=null;setState(()=>tab=4);}
  Widget teamCard(TeamRecord t)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text(t.flag,style:const TextStyle(fontSize:26)),const SizedBox(width:10),Expanded(child:Text(t.name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16))),IconButton(tooltip:'Edit team',onPressed:()async{final n=await textDialog('Edit team name',t.name);if(n!=null&&n.trim().isNotEmpty){setState(()=>t.name=n.trim());await _save();}},icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()=>addPlayer(t),icon:const Icon(Icons.person_add_alt_1)),IconButton(tooltip:'Delete team',onPressed:()async{final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('Delete team?'),content:Text('Delete '+t.name+' and its squad?'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Delete'))]));if(ok==true){setState(()=>teams.remove(t));await _save();}},icon:const Icon(Icons.delete_outline))]),Text('${t.country} · ${t.players.length} players',style:TextStyle(color:Theme.of(context).colorScheme.secondary)),const Divider(),...t.players.map((p)=>ListTile(dense:true,title:Text(p.name),subtitle:Text(p.role),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit'){final n=await textDialog('Edit player name',p.name);if(n!=null&&n.trim().isNotEmpty){setState(()=>p.name=n.trim());await _save();}}else if(v=='delete'){setState(()=>t.players.remove(p));await _save();}},itemBuilder:(c)=>const [PopupMenuItem(value:'edit',child:Text('Edit player')),PopupMenuItem(value:'delete',child:Text('Delete player'))]))) ])));
  Widget home()=>ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xff101d2b),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xff26394c))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('MYCRICSTATS',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,letterSpacing:1.5,fontSize:20)),
      const SizedBox(height:5),const Text('CRICKET TOURNAMENT CENTRE',style:TextStyle(color:Color(0xffb9cad9),fontSize:12)),
      const SizedBox(height:12),Text('${history.length}',style:const TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w900)),
      const Text('Completed matches saved',style:TextStyle(color:Color(0xffb9cad9))),
    ])),
    const SizedBox(height:16),
    SegmentedButton<int>(segments:const [
      ButtonSegment(value:0,label:Text('Teams & Squads'),icon:Icon(Icons.groups)),
      ButtonSegment(value:1,label:Text('Match Settings'),icon:Icon(Icons.tune)),
      ButtonSegment(value:2,label:Text('Toss'),icon:Icon(Icons.monetization_on)),
    ],selected:{homeSubtab},onSelectionChanged:(v)=>setState(()=>homeSubtab=v.first)),
    const SizedBox(height:14),
    if(homeSubtab==0)...[
      section('TEAM SETUP','TEAMS & SQUADS'),
      OutlinedButton.icon(onPressed:addTeam,icon:const Icon(Icons.add),label:const Text('Create team')),
      ...teams.map(teamCard),
      if(teams.length<2)const Padding(padding:EdgeInsets.all(12),child:Text('Create two teams and add their players before creating a match.'))
    ] else if(homeSubtab==1)...[
      section('MATCH SETTINGS','CONFIGURATION'),
      Card(child:ListTile(leading:const Icon(Icons.sports_cricket),title:const Text('Match configuration'),subtitle:Text('${settings.title} · ${settings.overs} overs · ${settings.playersPerSide} players · ${settings.matchType}'),trailing:const Icon(Icons.edit),onTap:configureMatch)),
      Card(child:ListTile(title:const Text('Dual batting'),subtitle:Text(settings.dualBatting?'Enabled — select striker and non-striker':'Disabled — one batter selection only'),trailing:Switch(value:settings.dualBatting,onChanged:(v)async{setState(()=>settings.dualBatting=v);await _save();}))),
      if(match==null)FilledButton.icon(onPressed:createMatch,icon:const Icon(Icons.add_circle),label:const Text('CREATE MATCH'))
      else ListTile(title:Text('${match!.teamA} vs ${match!.teamB}'),subtitle:Text('Status: ${match!.status}'),trailing:const Icon(Icons.edit),onTap:configureMatch),
    ] else ...[
      section('TOSS CENTRE','CALL · FLIP · ELECT'),
      if(match==null)Card(child:ListTile(title:const Text('Create a match first'),subtitle:const Text('Complete match settings, then return here for the toss.'),trailing:const Icon(Icons.arrow_forward),onTap:()=>setState(()=>homeSubtab=1)))
      else ...[
        Card(child:ListTile(title:Text('${match!.teamA}  vs  ${match!.teamB}'),subtitle:Text(match!.status),leading:const Icon(Icons.sports_cricket))),
        if(match!.tossWinner.isEmpty)FilledButton.icon(onPressed:completeToss,icon:const Icon(Icons.casino),label:const Text('CALL THE TOSS'))
        else ...[
          Card(child:ListTile(title:Text('Toss won by ${_team(match!.tossWinner)?.name??'Team'}'),subtitle:Text('Elected to ${tossDecision.toUpperCase()}'))),
          if(match!.status=='Ready')FilledButton.icon(onPressed:pickOpeners,icon:const Icon(Icons.people),label:const Text('SELECT OPENERS & START INNINGS')),
          if(match!.status=='Innings Break')FilledButton.icon(onPressed:pickOpeners,icon:const Icon(Icons.swap_horiz),label:const Text('SELECT CHASE OPENERS')),
          if(match!.status=='Live')FilledButton.icon(onPressed:()=>setState(()=>tab=2),icon:const Icon(Icons.scoreboard),label:const Text('OPEN SCOREBOARD')),
        ]
      ],
      if(match==null&&teams.length>=2)Padding(padding:const EdgeInsets.only(top:10),child:FilledButton.icon(onPressed:createMatch,icon:const Icon(Icons.add),label:const Text('CREATE MATCH')))
    ]
  ]);
  Future<void> _addAdEntry(List<Map<String,String>> list,String title)async{
    if(list.length>=10){msg('Maximum 10 entries allowed');return;}
    final name=TextEditingController(),logo=TextEditingController(),link=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:Text('Add $title'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Sponsor / advertisement name')),TextField(controller:logo,decoration:const InputDecoration(labelText:'Logo / image URL')),TextField(controller:link,decoration:const InputDecoration(labelText:'Click-through URL'))])),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Save'))]));
    if(ok==true&&name.text.trim().isNotEmpty){setState(()=>list.add({'name':name.text.trim(),'image':logo.text.trim(),'link':link.text.trim()}));await _save();}
  }
  Widget _adList(String title,List<Map<String,String>> list){
    return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('$title (${list.length}/10)',style:const TextStyle(fontWeight:FontWeight.w900))),IconButton(onPressed:()=>_addAdEntry(list,title),icon:const Icon(Icons.add_circle))]),
      if(list.isEmpty)const Text('No entries added yet.'),
      ...list.asMap().entries.map((entry)=>ListTile(leading:entry.value['image']?.isNotEmpty==true?const Icon(Icons.image):const Icon(Icons.campaign),title:Text(entry.value['name']??''),subtitle:Text(entry.value['image']??'No logo/image URL'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{setState(()=>list.removeAt(entry.key));await _save();})))
    ])));
  }
  Widget sponsorPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    section('SPONSOR CENTRE','LIVE VIEWER PAGE'),
    Card(child:SwitchListTile(title:const Text('Show sponsors and advertisements to viewers'),value:settings.adEnabled,onChanged:(v)async{setState(()=>settings.adEnabled=v);await _save();})),
    _adList('Scoreboard sponsors',sponsors),
    _adList('Popup advertisements',popupAds),
    Card(child:ListTile(title:const Text('Viewer delivery'),subtitle:const Text('Sponsors and pop-up ads are included in the live match payload. The viewer page must load the matching live record from the Live DB.'),trailing:const Icon(Icons.info_outline))),
    if(match!=null)FilledButton.icon(onPressed:shareLive,icon:const Icon(Icons.share),label:const Text('SHARE LIVE VIEWER PAGE'))
  ]);
  Widget section(String title,String sub)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[Expanded(child:Text(title,style:const TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.1))),Text(sub,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800,color:Colors.grey))]));
  Widget matchFlow()=>sponsorPage();
  Widget scoreboard()=>engine==null?const Center(child:Text('Create a match and complete the toss first.')):Builder(builder:(c){
    final e=engine!,m=e.match,inn=m.current;
    final ta=_team(m.teamAId),tb=_team(m.teamBId);
    final batting=e.battingSquad,bowling=e.bowlingSquad;
    final striker=e.players[inn.striker],non=e.players[inn.nonStriker],bowler=e.players[inn.bowler];
    final first=m.inningsList.first;
    final inningsBreak=m.status=='Innings Break';
    final displayInn=inningsBreak?first:inn;
    final firstTeamIsA=e.actualFirstBattingTeamId==m.teamAId;
    final liveUrl='${Uri.base.origin}/live.html?id=${Uri.encodeComponent(m.id)}';
    Widget teamPanel(TeamRecord? t,bool isTeamA){
      final isFirstBattingTeam=isTeamA==firstTeamIsA;
      final showScore=m.innings==1?isFirstBattingTeam:(inningsBreak?isFirstBattingTeam:true);
      final scoreInn=isFirstBattingTeam?first:inn;
      final runs=scoreInn.runs;
      final wkts=scoreInn.wickets;
      final overs=scoreInn.overs;
      return Expanded(child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:const Color(0xff101d2b),border:Border.all(color:const Color(0xff26394c)),borderRadius:BorderRadius.circular(14)),child:Column(children:[
        Text('${t?.flag??'🏏'}  ${t?.name??'TEAM'}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xffd9e5ef),fontWeight:FontWeight.w900,fontSize:13)),
        const SizedBox(height:10),Text(showScore?'$runs/$wkts':'Yet to bat',style:TextStyle(color:showScore?const Color(0xff38d5a0):const Color(0xff9eb2c5),fontSize:24,fontWeight:FontWeight.w900)),
        Text(showScore?'($overs)':(inningsBreak?'Batting next':'Bowling'),style:const TextStyle(color:Color(0xffa9bac9),fontSize:12,fontWeight:FontWeight.w700)),
        if(showScore)Text('CRR ${scoreInn.crr.toStringAsFixed(2)}',style:const TextStyle(color:Color(0xffa9bac9),fontSize:11))
      ])));
    }
    Widget playerPanel(String heading,PlayerRecord? p,String detail){
      return Expanded(child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:const Color(0xff0c1724),border:Border.all(color:const Color(0xff26394c)),borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(heading,style:const TextStyle(color:Color(0xffb9cad9),fontWeight:FontWeight.w900,fontSize:12)),
        const SizedBox(height:9),Text(p?.name??'Not selected',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),
        const SizedBox(height:10),Text(detail,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:19)),
        if(heading.contains('STRIKER'))Text('4s ${p?.fours??0} · 6s ${p?.sixes??0} · SR ${p==null||p.balls==0?'0.0':(p.runs*100/p.balls).toStringAsFixed(1)}',style:const TextStyle(color:Color(0xffc4d1dd),fontSize:11)),
        if(heading.contains('BOWLER'))Text('Runs ${p?.bowlRuns??0} · Dots ${p?.dots??0} · Econ ${p==null||p.bowlBalls==0?'0.00':(p.bowlRuns/(p.bowlBalls/6)).toStringAsFixed(2)}',style:const TextStyle(color:Color(0xffc4d1dd),fontSize:11))
      ])));
    }
    Widget actionButton(String label,VoidCallback? fn,{IconData? icon})=>OutlinedButton.icon(onPressed:fn,icon:Icon(icon??Icons.tune,size:17),label:Text(label,maxLines:1));
    Widget tableHeader(List<String> cols)=>Container(color:const Color(0xffdce6f0),padding:const EdgeInsets.symmetric(vertical:9,horizontal:6),child:Row(children:cols.map((x)=>Expanded(child:Text(x,style:const TextStyle(color:Color(0xff26384a),fontSize:10,fontWeight:FontWeight.w900)))).toList()));
    return ListView(padding:const EdgeInsets.fromLTRB(12,12,12,24),children:[
      Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xff14283a),Color(0xff07111e)]),borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xff26394c))),child:DefaultTextStyle.merge(style:const TextStyle(color:Colors.white),child:Column(children:[
        Row(children:[const Text('MYCRICSTATS  •  MATCH CENTRE',style:TextStyle(color:Color(0xffb6c6d4),fontWeight:FontWeight.w900,fontSize:11,letterSpacing:1)),const Spacer(),Text(m.status.toUpperCase(),style:const TextStyle(color:Color(0xffffc857),fontWeight:FontWeight.w900,fontSize:10))]),
        const SizedBox(height:16),Row(children:[teamPanel(ta,true),const SizedBox(width:10),teamPanel(tb,false)]),
        const SizedBox(height:14),Text('${displayInn.runs}/${displayInn.wickets}',style:const TextStyle(fontSize:56,fontWeight:FontWeight.w900,height:1.05,letterSpacing:-2)),Text('${displayInn.overs} OV   •   CRR ${displayInn.crr.toStringAsFixed(2)}   •   EXTRAS ${displayInn.extras}',style:const TextStyle(color:Color(0xffc1ced9),fontWeight:FontWeight.w800,fontSize:12)),
        if(m.innings==2)Padding(padding:const EdgeInsets.only(top:8),child:Text('TARGET ${inn.target??first.runs+1}  •  NEED ${((inn.target??first.runs+1)-inn.runs).clamp(0,99999)} RUNS',style:const TextStyle(color:Color(0xffffc857),fontWeight:FontWeight.w900))),
        const Divider(color:Color(0xff304253),height:26),
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[playerPanel(inningsBreak?'NEXT BATTER / STRIKER':'ON STRIKE',striker,'${striker?.runs??0} (${striker?.balls??0})'),const SizedBox(width:10),playerPanel(inningsBreak?'OPENING BOWLER':'BOWLER',bowler,'${bowler?.bowlRuns??0} (${bowler?.bowlBalls??0})/${bowler?.wickets??0}')]),
        const SizedBox(height:14),Row(children:[Expanded(child:Text('NON-STRIKER  ${non?.name??'—'}   ${non?.runs??0} (${non?.balls??0})',style:const TextStyle(color:Color(0xffd8e3ec),fontWeight:FontWeight.w700))),Text('THIS OVER',style:TextStyle(color:Color(0xff9db0c1),fontWeight:FontWeight.w900,fontSize:11))]),
        const SizedBox(height:7),Align(alignment:Alignment.centerLeft,child:Wrap(spacing:5,children:inn.overBalls.map((b)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:8),decoration:BoxDecoration(color:b=='W'?const Color(0xffd8323e):const Color(0xff13a980),shape:BoxShape.circle),child:Text(b,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:12)))).toList()))
      ]))),
      const SizedBox(height:12),
      if(m.status=='Live'||m.status=='Ready'||m.status=='Innings Break')
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          OutlinedButton.icon(onPressed:pickOpeners,icon:const Icon(Icons.groups),label:Text(inningsBreak?'SELECT CHASE OPENERS':'OPENERS')),
          const SizedBox(width:8),
          OutlinedButton.icon(onPressed:selectBatterCategory,icon:const Icon(Icons.sports_cricket),label:const Text('BATSMAN')),
          const SizedBox(width:8),
          OutlinedButton.icon(onPressed:reselectBowler,icon:const Icon(Icons.sports_baseball),label:const Text('BOWLER')),
        ])),
      const SizedBox(height:10),section('MATCH CONTROL','LIVE VIEWER & CORRECTIONS'),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
        OutlinedButton.icon(onPressed:shareLive,icon:const Icon(Icons.share),label:const Text('SHARE LIVE PAGE')),
        const SizedBox(width:8),
        OutlinedButton.icon(onPressed:()async{await publishLive();await Clipboard.setData(ClipboardData(text:liveUrl));if(context.mounted)msg('Viewer link copied');},icon:const Icon(Icons.link),label:const Text('COPY LINK')),
        const SizedBox(width:8),
        OutlinedButton.icon(onPressed:()async{await publishLive();await Share.share(liveUrl,subject:'Live score: ${m.teamA} vs ${m.teamB}');},icon:const Icon(Icons.tv),label:const Text('VIEWER')),
      ])),
      const SizedBox(height:8),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
        FilledButton.tonalIcon(onPressed:(){setState((){e.undo();});publishLive();},icon:const Icon(Icons.undo),label:const Text('UNDO')),
        const SizedBox(width:8),
        FilledButton.tonalIcon(onPressed:(){setState((){e.redo();});publishLive();},icon:const Icon(Icons.redo),label:const Text('REDO')),
        if(m.status=='Completed')Padding(padding:const EdgeInsets.only(left:8),child:FilledButton(onPressed:saveCompletedMatch,child:const Text('SAVE MATCH TO HISTORY')))
      ])),
      if(m.status=='Live')...[const SizedBox(height:12),section('SCORING PAD','BALL BY BALL'),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,childAspectRatio:2.2,children:[for(final n in [0,1,2,3,4,6])Padding(padding:const EdgeInsets.all(4),child:FilledButton(onPressed:()=>score(n),child:Text('$n')))]),Wrap(spacing:8,runSpacing:8,children:[OutlinedButton(onPressed:()=>extraDelivery(DeliveryType.wide),child:const Text('WIDE')),OutlinedButton(onPressed:()=>extraDelivery(DeliveryType.noBall),child:const Text('NO BALL')),OutlinedButton(onPressed:()=>extraDelivery(DeliveryType.legBye),child:const Text('LEG BYE')),FilledButton.tonal(onPressed:wicket,child:const Text('WICKET'))])],
      if(settings.adEnabled&&settings.adPosition=='Below scoreboard')Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[const Text('ADVERTISEMENT',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900)),Text(settings.adText.isEmpty?'Sponsor placement':settings.adText),if(settings.adImageUrl.isNotEmpty)Text(settings.adImageUrl,style:const TextStyle(fontSize:10))])))
    ]);
  });
  Widget stats()=>ListView(padding:const EdgeInsets.all(14),children:[
    SegmentedButton<int>(segments:const [ButtonSegment(value:0,label:Text('Current Match')),ButtonSegment(value:1,label:Text('Cumulative'))],selected:{statsSubtab},onSelectionChanged:(v)=>setState(()=>statsSubtab=v.first)),
    if(statsSubtab==0&&engine!=null)...[
      section('LIVE MATCH SCORECARD','DETAILED INNINGS STATISTICS'),
      Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${match!.teamA} vs ${match!.teamB} · Innings ${match!.innings}',style:const TextStyle(fontWeight:FontWeight.w900)),
        const SizedBox(height:5),Text('${match!.current.runs}/${match!.current.wickets}  (${match!.current.overs} ov) · CRR ${match!.current.crr.toStringAsFixed(2)} · Extras ${match!.current.extras}',style:const TextStyle(fontWeight:FontWeight.w800)),
        const SizedBox(height:12),const Text('BATTING',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12)),
        _statsTable(['BATSMAN','R','B','4s','6s','SR','STATUS'],engine!.battingSquad.where((p)=>p.balls>0||p.isOut||p.id==match!.current.striker||p.id==match!.current.nonStriker).map((p)=>[p.name+(p.id==match!.current.striker?' *':''),p.runs,p.balls,p.fours,p.sixes,p.balls==0?'0.00':(p.runs*100/p.balls).toStringAsFixed(2),p.isOut?'OUT':'NOT OUT']).toList()),
        const SizedBox(height:12),const Text('BOWLING',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12)),
        _statsTable(['BOWLER','O','R','W','DOTS','WD','NB','ECON'],engine!.bowlingSquad.where((p)=>p.bowlBalls>0||p.wickets>0||p.id==match!.current.bowler).map((p)=>[p.name,'${p.bowlBalls~/6}.${p.bowlBalls%6}',p.bowlRuns,p.wickets,p.dots,p.wides,p.noBalls,p.bowlBalls==0?'0.00':(p.bowlRuns/(p.bowlBalls/6)).toStringAsFixed(2)]).toList()),
        const SizedBox(height:12),const Text('EXTRAS BREAKDOWN',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12)),
        Text('Wides ${match!.current.wides}  ·  No-balls ${match!.current.noBalls}  ·  Leg-byes ${match!.current.legByes}  ·  Total ${match!.current.extras}'),
        const SizedBox(height:12),const Text('FALL OF WICKETS',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12)),
        if(match!.current.fallOfWickets.isEmpty)const Text('No wickets yet') else ...match!.current.fallOfWickets.asMap().entries.map((x)=>Text('${x.key+1}) ${x.value['score']} runs · ${x.value['batter']} · ${x.value['dismissal']} · ${x.value['over']} ov')),
        const SizedBox(height:12),const Text('BALL-BY-BALL / OVER SUMMARY',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12)),
        ..._overSummary(match!.current.deliveries).map((x)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Text('Over ${x['over']}: ${x['balls']}   ·   ${x['runs']} runs'))),
      ]))),
      const SizedBox(height:14),
    ],
    if(statsSubtab==1)...[section('TOURNAMENT CENTRE','DETAILED PLAYER STATISTICS'),
    Wrap(spacing:8,runSpacing:8,children:[
      SizedBox(width:155,child:metric('Matches',history.length.toString())),
      SizedBox(width:155,child:metric('Total runs',history.fold<int>(0,(s,m)=>s+(m['firstRuns'] as int? ??0)+(m['secondRuns'] as int? ??0)).toString())),
      SizedBox(width:155,child:metric('Wickets',history.fold<int>(0,(s,m)=>s+((m['players'] as List? ??[]).fold<int>(0,(v,p)=>v+(p['wickets'] as int? ??0)))) .toString()))
    ]),
    const SizedBox(height:14),section('ORANGE CAP','MOST TOURNAMENT RUNS'),
    _statsTable(['RANK','PLAYER','RUNS','BALLS','4s','6s','SR'],_rankedPlayers('runs').asMap().entries.map((e)=><dynamic>[e.key+1,e.value['name'],e.value['runs'],e.value['balls'],e.value['fours'],e.value['sixes'],e.value['sr']]).toList()),
    const SizedBox(height:14),section('PURPLE CAP','MOST WICKETS'),
    _statsTable(['RANK','PLAYER','WKTS','OVERS','RUNS','DOTS','ECON'],_rankedPlayers('wickets').asMap().entries.map((e)=><dynamic>[e.key+1,e.value['name'],e.value['wickets'],e.value['overs'],e.value['bowlRuns'],e.value['dots'],e.value['economy']]).toList()),
    const SizedBox(height:14),section('BATTING LEADERS','BOUNDARIES & STRIKE RATE'),
    _statsTable(['PLAYER','RUNS','4s','6s','SR','AVG'],_rankedPlayers('runs').map((p)=><dynamic>[p['name'],p['runs'],p['fours'],p['sixes'],p['sr'],p['average']]).toList()),
    const SizedBox(height:14),section('BOWLING LEADERS','ECONOMY & DOT BALLS'),
    _statsTable(['PLAYER','WKTS','OVERS','RUNS','DOTS','ECON'],_rankedPlayers('wickets').map((p)=><dynamic>[p['name'],p['wickets'],p['overs'],p['bowlRuns'],p['dots'],p['economy']]).toList()),
    const SizedBox(height:14),section('EXTRAS & MATCH SUMMARY','SAVED MATCHES'),
    _statsTable(['MATCH','SCORE A','SCORE B','RESULT'],history.reversed.map((m)=>['${m['teamA']} v ${m['teamB']}','${m['firstRuns']}/${m['firstWickets']}','${m['secondRuns']}/${m['secondWickets']}',m['result']??'']).toList())]
  ]);
  List<Map<String,dynamic>> _overSummary(List<BallRecord> deliveries){
    final result=<Map<String,dynamic>>[];var legal=0;var runs=0;var balls=<String>[];
    for(final d in deliveries){runs+=d.type==DeliveryType.wide?(d.runs<=0?1:d.runs):d.type==DeliveryType.noBall?d.runs+1:d.runs;balls.add(d.label);if(d.legal)legal++;if(d.legal&&legal%6==0){result.add({'over':legal~/6,'balls':balls.join('  '),'runs':runs});balls=[];runs=0;}}
    if(balls.isNotEmpty)result.add({'over':'${legal~/6}.${legal%6}','balls':balls.join('  '),'runs':runs});
    return result;
  }
  List<Map<String,dynamic>> _rankedPlayers(String sort){
    final map=<String,Map<String,dynamic>>{};
    for(final m in history){for(final raw in (m['players'] as List? ??[])){
      final p=Map<String,dynamic>.from(raw);final id=(p['id']??p['name']??'').toString();if(id.isEmpty)continue;
      final x=map.putIfAbsent(id,()=>{'name':p['name']??'','runs':0,'balls':0,'fours':0,'sixes':0,'wickets':0,'bowlRuns':0,'bowlBalls':0,'dots':0,'wides':0,'noBalls':0});
      for(final k in ['runs','balls','fours','sixes','wickets','bowlRuns','bowlBalls','dots','wides','noBalls']){x[k]=(x[k] as int)+(p[k] as int? ??0);}
    }}
    final list=map.values.toList();
    for(final p in list){final balls=p['balls'] as int,bb=p['bowlBalls'] as int;p['sr']=balls==0?'0.00':((p['runs'] as int)*100/balls).toStringAsFixed(2);p['average']=(p['wickets'] as int)==0?'—':((p['runs'] as int)/(p['wickets'] as int)).toStringAsFixed(2);p['overs']='${bb~/6}.${bb%6}';p['economy']=bb==0?'0.00':((p['bowlRuns'] as int)/(bb/6)).toStringAsFixed(2);}
    list.sort((a,b)=>(b[sort] as int).compareTo(a[sort] as int));return list;
  }
  Widget _statsTable(List<String> headers,List<List<dynamic>> rows){
    final columns=headers.map((h)=>DataColumn(label:Text(h,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w900)))).toList();
    final dataRows=rows.isEmpty
      ? <DataRow>[DataRow(cells:headers.map((h)=>DataCell(Text(h==headers.first?'No data':'—'))).toList())]
      : rows.map((r)=>DataRow(cells:List.generate(headers.length,(i)=>DataCell(Text(i<r.length?(r[i]??'—').toString():'—',style:const TextStyle(fontSize:11)))))).toList();
    return Card(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(columnSpacing:18,horizontalMargin:10,headingRowHeight:38,dataRowMinHeight:38,dataRowMaxHeight:48,columns:columns,rows:dataRows)));
  }
  Widget metric(String a,String b)=>Card(child:ListTile(title:Text(a),trailing:Text(b,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))));
  Widget historyPage()=>ListView(padding:const EdgeInsets.all(16),children:[section('MATCH HISTORY','LOCAL ARCHIVE'),if(history.isEmpty)const Text('No completed matches yet.'),...history.reversed.map((m)=>Card(child:ListTile(title:Text('${m['teamA']} vs ${m['teamB']}'),subtitle:Text('${m['firstRuns']}/${m['firstWickets']} (${m['firstOvers']}) · ${m['secondRuns']}/${m['secondWickets']} (${m['secondOvers']})'),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit'){final n=await textDialog('Edit match title',m['title']??'Match');if(n!=null&&n.trim().isNotEmpty){m['title']=n.trim();await _save();setState((){});}}else if(v=='delete'){history.remove(m);await _save();setState((){});}},itemBuilder:(c)=>const [PopupMenuItem(value:'edit',child:Text('Edit match entry')),PopupMenuItem(value:'delete',child:Text('Delete match'))]),onTap:()=>showDialog(context:context,builder:(d)=>AlertDialog(title:Text(m['title']??'Match'),content:Text('${m['result']}\n${(m['deliveries'] as List? ??[]).length} deliveries'),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Close'))])))))]);
  Widget more()=>ListView(padding:const EdgeInsets.all(16),children:[section('APP SETTINGS','PREFERENCES'),SwitchListTile(title:const Text('Light theme'),value:widget.mode==ThemeMode.light,onChanged:(v)=>widget.onMode(v?ThemeMode.light:ThemeMode.dark)),ListTile(title:const Text('Match & advertisement settings'),subtitle:const Text('Overs, players, venue, popup and ad slot'),trailing:const Icon(Icons.chevron_right),onTap:configureMatch),ListTile(title:const Text('Super overs'),subtitle:Text(settings.superOvers?'Enabled':'Disabled')),ListTile(title:const Text('Original scorer features checklist'),subtitle:const Text('Toss gating · legal ball rules · wicket flow · bowler rotation · undo/redo · full analytics · cloud sync and live viewer integration are being completed in phases.'))]);
  @override Widget build(BuildContext c){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));final pages=[home(),matchFlow(),scoreboard(),stats(),historyPage(),more()];return Scaffold(appBar:AppBar(title:const Text('MYCRICSTATS',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.1)),actions:[IconButton(onPressed:()=>widget.onMode(widget.mode==ThemeMode.dark?ThemeMode.light:ThemeMode.dark),icon:Icon(widget.mode==ThemeMode.dark?Icons.light_mode:Icons.dark_mode)),IconButton(onPressed:configureMatch,icon:const Icon(Icons.tune))]),body:SafeArea(child:IndexedStack(index:tab,children:pages)),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),NavigationDestination(icon:Icon(Icons.event_note),label:'Sponsors'),NavigationDestination(icon:Icon(Icons.scoreboard),label:'Scorer'),NavigationDestination(icon:Icon(Icons.query_stats),label:'Stats'),NavigationDestination(icon:Icon(Icons.history),label:'History'),NavigationDestination(icon:Icon(Icons.settings),label:'More')]));}
}
