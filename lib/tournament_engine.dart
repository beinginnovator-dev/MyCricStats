import 'dart:convert';

enum DeliveryType { legal, wide, noBall, legBye }
enum DismissalType { bowled, caught, lbw, stumped, runOut, hitWicket, hitOutOfBox, notPlaying }

class PlayerRecord {
  PlayerRecord({required this.id, required this.name, this.role = 'All-rounder', this.batting = 'Right', this.bowling = 'Right-arm', this.teamId = '', this.isOut = false, this.runs = 0, this.balls = 0, this.fours = 0, this.sixes = 0, this.bowlRuns = 0, this.bowlBalls = 0, this.wickets = 0, this.dots = 0, this.wides = 0, this.noBalls = 0});
  final String id;
  String name, role, batting, bowling, teamId;
  bool isOut;
  int runs, balls, fours, sixes, bowlRuns, bowlBalls, wickets, dots, wides, noBalls;
  Map<String, dynamic> toJson() => {'id':id,'name':name,'role':role,'batting':batting,'bowling':bowling,'teamId':teamId,'isOut':isOut,'runs':runs,'balls':balls,'fours':fours,'sixes':sixes,'bowlRuns':bowlRuns,'bowlBalls':bowlBalls,'wickets':wickets,'dots':dots,'wides':wides,'noBalls':noBalls};
  factory PlayerRecord.fromJson(Map<String,dynamic> j) => PlayerRecord(id:j['id']??'',name:j['name']??'',role:j['role']??'All-rounder',batting:j['batting']??'Right',bowling:j['bowling']??'Right-arm',teamId:j['teamId']??'',isOut:j['isOut']??false,runs:j['runs']??0,balls:j['balls']??0,fours:j['fours']??0,sixes:j['sixes']??0,bowlRuns:j['bowlRuns']??0,bowlBalls:j['bowlBalls']??0,wickets:j['wickets']??0,dots:j['dots']??0,wides:j['wides']??0,noBalls:j['noBalls']??0);
}

class TeamRecord {
  TeamRecord({required this.id, required this.name, this.country = 'India', this.flag = '🇮🇳', List<PlayerRecord>? players}) : players = players ?? [];
  final String id;
  String name, country, flag;
  List<PlayerRecord> players;
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'country':country,'flag':flag,'players':players.map((p)=>p.toJson()).toList()};
  factory TeamRecord.fromJson(Map<String,dynamic> j)=>TeamRecord(id:j['id']??'',name:j['name']??'',country:j['country']??'India',flag:j['flag']??'🏏',players:((j['players'] as List?)??[]).map((x)=>PlayerRecord.fromJson(Map<String,dynamic>.from(x))).toList());
}

class MatchSettings {
  MatchSettings({this.title='MATCH DAY',this.overs=8,this.playersPerSide=11,this.venue='',this.matchType='Limited Overs',this.superOvers=false,this.dualBatting=false,this.adEnabled=true,this.adPosition='Below scoreboard',this.adText='',this.adImageUrl='',this.adLink='',this.adPopup=false});
  String title, venue, matchType, adPosition, adText, adImageUrl, adLink;
  int overs, playersPerSide;
  bool superOvers, dualBatting, adEnabled, adPopup;
  Map<String,dynamic> toJson()=>{'title':title,'overs':overs,'playersPerSide':playersPerSide,'venue':venue,'matchType':matchType,'superOvers':superOvers,'dualBatting':dualBatting,'adEnabled':adEnabled,'adPosition':adPosition,'adText':adText,'adImageUrl':adImageUrl,'adLink':adLink,'adPopup':adPopup};
  factory MatchSettings.fromJson(Map<String,dynamic> j)=>MatchSettings(title:j['title']??'MATCH DAY',overs:j['overs']??8,playersPerSide:j['playersPerSide']??11,venue:j['venue']??'',matchType:j['matchType']??'Limited Overs',superOvers:j['superOvers']??false,dualBatting:j['dualBatting']??false,adEnabled:j['adEnabled']??true,adPosition:j['adPosition']??'Below scoreboard',adText:j['adText']??'',adImageUrl:j['adImageUrl']??'',adLink:j['adLink']??'',adPopup:j['adPopup']??false);
}

class BallRecord {
  BallRecord({required this.innings,required this.label,required this.type,required this.runs,required this.legal,required this.batter,required this.bowler,this.dismissal,this.fielder});
  final int innings, runs;
  final String label, batter, bowler;
  final DeliveryType type;
  final bool legal;
  final DismissalType? dismissal;
  final String? fielder;
  Map<String,dynamic> toJson()=>{'innings':innings,'label':label,'type':type.name,'runs':runs,'legal':legal,'batter':batter,'bowler':bowler,'dismissal':dismissal?.name,'fielder':fielder};
}

class InningsRecord {
  int runs=0,wickets=0,legalBalls=0,extras=0,wides=0,noBalls=0,legByes=0;
  String striker='',nonStriker='',bowler='';
  int? target;
  List<String> overBalls=[];
  List<BallRecord> deliveries=[];
  List<Map<String,dynamic>> fallOfWickets=[];
  bool complete=false;
  String get overs => '${legalBalls~/6}.${legalBalls%6}';
  double get crr => legalBalls==0?0:runs/(legalBalls/6);
  Map<String,dynamic> toJson()=>{'runs':runs,'wickets':wickets,'legalBalls':legalBalls,'extras':extras,'wides':wides,'noBalls':noBalls,'legByes':legByes,'striker':striker,'nonStriker':nonStriker,'bowler':bowler,'target':target,'overBalls':overBalls,'deliveries':deliveries.map((d)=>d.toJson()).toList(),'fallOfWickets':fallOfWickets,'complete':complete};
}

class MatchRecord {
  MatchRecord({required this.id,required this.teamAId,required this.teamBId,required this.teamA,required this.teamB,required this.settings,required this.firstBattingTeamId});
  final String id,teamAId,teamBId,teamA,teamB,firstBattingTeamId;
  final MatchSettings settings;
  String tossWinner='',tossDecision='',status='Setup',result='',manOfMatch='';
  int innings=1;
  List<InningsRecord> inningsList=[InningsRecord()];
  List<BallRecord> allDeliveries=[];
  DateTime createdAt=DateTime.now();
  DateTime? completedAt;
  InningsRecord get current => inningsList.last;
  Map<String,dynamic> toJson()=>{'id':id,'teamAId':teamAId,'teamBId':teamBId,'teamA':teamA,'teamB':teamB,'settings':settings.toJson(),'firstBattingTeamId':firstBattingTeamId,'tossWinner':tossWinner,'tossDecision':tossDecision,'status':status,'result':result,'manOfMatch':manOfMatch,'innings':innings,'inningsList':inningsList.map((x)=>x.toJson()).toList(),'createdAt':createdAt.toIso8601String(),'completedAt':completedAt?.toIso8601String()};
}

class TournamentEngine {
  static const dismissals = ['Bowled','Catch out','LBW','Stumped','Run out','Hit wicket','Hit out of box','Not playing'];
  final Map<String,PlayerRecord> players;
  final MatchRecord match;
  final List<Map<String,dynamic>> undoStack=[];
  bool requireBatterChange=false, requireBowlerChange=false;
  String lastDismissedBatter='',lastOverBowler='';
  bool lastDismissedAtStriker=true;
  TournamentEngine(this.match, List<PlayerRecord> allPlayers):players={for(final p in allPlayers)p.id:p};

  String get battingTeamId => match.innings==1?actualFirstBattingTeamId:(actualFirstBattingTeamId==match.teamAId?match.teamBId:match.teamAId);
  String get bowlingTeamId => battingTeamId==match.teamAId?match.teamBId:match.teamAId;
  List<PlayerRecord> get battingSquad=>players.values.where((p)=>p.teamId==battingTeamId).toList();
  List<PlayerRecord> get bowlingSquad=>players.values.where((p)=>p.teamId==bowlingTeamId).toList();

  void startToss({required String winnerTeamId,required String decision}) {
    if(winnerTeamId!=match.teamAId&&winnerTeamId!=match.teamBId) throw StateError('Select a valid toss winner');
    if(decision!='Bat'&&decision!='Bowl') throw StateError('Select Bat or Bowl');
    match.tossWinner=winnerTeamId;match.tossDecision=decision;
    match.status='Ready';
    // The toss decision determines first batting side, not the team ordering.
    final batFirst=decision=='Bat'?winnerTeamId:(winnerTeamId==match.teamAId?match.teamBId:match.teamAId);
    // MatchRecord is immutable for this identifier; use a dedicated mutable first batting override in match data.
    _firstBattingOverride=batFirst;
    match.status='Ready';
  }
  String? _firstBattingOverride;
  String get actualFirstBattingTeamId=>_firstBattingOverride??match.firstBattingTeamId;

  void selectOpeners({required String strikerId,required String nonStrikerId,required String bowlerId}) {
    if(match.tossWinner.isEmpty) throw StateError('Complete toss before selecting players');
    if(strikerId==nonStrikerId) throw StateError('Striker and non-striker must be different');
    final st=players[strikerId], ns=players[nonStrikerId], bw=players[bowlerId];
    if(st==null||ns==null||bw==null||st.teamId!=battingTeamId||ns.teamId!=battingTeamId||bw.teamId!=bowlingTeamId) throw StateError('Select players from the correct teams');
    match.current.striker=strikerId;match.current.nonStriker=nonStrikerId;match.current.bowler=bowlerId;match.status='Live';
  }

  void record({required int runs,DeliveryType type=DeliveryType.legal,bool wicket=false,DismissalType? dismissal,String? fielder,String? runOutBatterId,String? runsCreditedTo}) {
    final inn=match.current;
    if(match.status!='Live'||inn.complete) throw StateError('Match is not accepting deliveries');
    if(inn.striker.isEmpty||inn.nonStriker.isEmpty||inn.bowler.isEmpty) throw StateError('Select striker, non-striker and bowler');
    if(requireBatterChange&&inn.striker==lastDismissedBatter) throw StateError('Select a new batter before the next ball');
    if(requireBowlerChange&&inn.bowler==lastOverBowler) throw StateError('Select a different bowler for the new over');
    if(inn.overBalls.isNotEmpty&&inn.overBalls.length>0){
      final previous=inn.deliveries.isEmpty?'':inn.deliveries.last.bowler;
      final activeBowlerName=players[inn.bowler]?.name??'';
      if(previous.isNotEmpty&&previous!=activeBowlerName) throw StateError('The same bowler must complete this over');
    }
    if(wicket&&dismissal==null) throw StateError('Select dismissal type');
    if((dismissal==DismissalType.caught||dismissal==DismissalType.runOut)&&(fielder==null||fielder.trim().isEmpty)) throw StateError('Select fielder');
    if(dismissal==DismissalType.runOut&&(runOutBatterId==null||!{inn.striker,inn.nonStriker}.contains(runOutBatterId))) throw StateError('Select which batter was run out');
    final before=match.toJson();
    undoStack.add(before);
    final legal=type==DeliveryType.legal||type==DeliveryType.legBye;
    final label=wicket?'W':type==DeliveryType.wide?'WD':type==DeliveryType.noBall?'NB':type==DeliveryType.legBye?'LB$runs':'$runs';
    final batter=players[inn.striker]!,bowler=players[inn.bowler]!;
    if(type==DeliveryType.noBall){
      inn.runs+=runs+1;inn.extras+=1;inn.noBalls++;
      bowler.bowlRuns+=runs+1;bowler.noBalls++;
      final batRuns=runs;
      batter.runs+=batRuns;batter.balls++;
      if(batRuns==4)batter.fours++;if(batRuns==6)batter.sixes++;
    } else if(type==DeliveryType.wide){
      final conceded=runs<=0?1:runs;
      inn.runs+=conceded;inn.extras+=conceded;inn.wides++;
      bowler.bowlRuns+=conceded;bowler.wides++;
    } else if(type==DeliveryType.legBye){
      inn.runs+=runs;inn.extras+=runs;inn.legByes+=runs;inn.legalBalls++;
      batter.balls++;bowler.bowlBalls++;
    } else {
      inn.runs+=runs;inn.legalBalls++;batter.runs+=runs;batter.balls++;
      if(runs==4)batter.fours++;if(runs==6)batter.sixes++;
      bowler.bowlBalls++;bowler.bowlRuns+=runs;if(runs==0)bowler.dots++;
    }
    if(wicket){
      inn.wickets++;
      final outId=runOutBatterId??inn.striker;
      final outPlayer=players[outId]!;
      outPlayer.isOut=true;
      final bowlerCredited= dismissal!=DismissalType.runOut&&dismissal!=DismissalType.notPlaying;
      if(bowlerCredited)bowler.wickets++;
      inn.fallOfWickets.add({'score':inn.runs,'over':inn.overs,'batter':outPlayer.name,'dismissal':dismissal!.name,'bowler':bowlerCredited?bowler.name:'—','fielder':fielder??''});
      requireBatterChange=true;lastDismissedBatter=outId;
      if(outId==inn.striker){inn.striker='';lastDismissedAtStriker=true;}
      else {inn.nonStriker='';lastDismissedAtStriker=false;}
    }
    final d=BallRecord(innings:match.innings,label:label,type:type,runs:runs,legal:legal,batter:batter.name,bowler:bowler.name,dismissal:dismissal,fielder:fielder);
    inn.deliveries.add(d);match.allDeliveries.add(d);inn.overBalls.add(label);
    if(legal){
      if((type==DeliveryType.legal||type==DeliveryType.legBye)&&runs.isOdd&&!wicket){final x=inn.striker;inn.striker=inn.nonStriker;inn.nonStriker=x;}
      if(inn.legalBalls>0&&inn.legalBalls%6==0){final x=inn.striker;inn.striker=inn.nonStriker;inn.nonStriker=x;requireBowlerChange=true;lastOverBowler=inn.bowler;inn.overBalls=[];}
    }
    final maxWickets=(match.settings.playersPerSide<battingSquad.length?match.settings.playersPerSide:battingSquad.length)-1;
    final chaseDone=match.innings==2&&inn.target!=null&&inn.runs>=inn.target!;
    if(inn.wickets>=maxWickets||inn.legalBalls>=match.settings.overs*6||chaseDone){inn.complete=true;_finishInnings();}
  }

  void changeBatter({required String playerId, required bool striker}) {
    final inn=match.current;final p=players[playerId];
    if(match.status!='Live'||p==null||p.teamId!=battingTeamId||p.isOut) throw StateError('Choose an available batter from the batting team');
    final current=striker?inn.striker:inn.nonStriker;
    if(playerId==current) return;
    if(playerId==(striker?inn.nonStriker:inn.striker)) throw StateError('A batter cannot occupy both positions');
    if(striker&&inn.striker.isEmpty||!striker&&inn.nonStriker.isEmpty) throw StateError('Select the dismissed batter first');
    inn.striker=striker?playerId:inn.striker;inn.nonStriker=striker?inn.nonStriker:playerId;
  }

  void changeBowler(String playerId) {
    final p=players[playerId];
    if(match.status!='Live'||p==null||p.teamId!=bowlingTeamId) throw StateError('Choose a bowler from the fielding team');
    if(requireBowlerChange){if(playerId==lastOverBowler) throw StateError('The previous over bowler cannot bowl consecutive overs');match.current.bowler=playerId;requireBowlerChange=false;lastOverBowler='';return;}
    if(match.current.legalBalls%6!=0&&match.current.bowler.isNotEmpty&&playerId!=match.current.bowler) throw StateError('The same bowler must complete the current over');
    match.current.bowler=playerId;
  }

  void selectNextBatter(String playerId) {
    final inn=match.current;final p=players[playerId];
    if(match.status!='Live'||!requireBatterChange||p==null||p.teamId!=battingTeamId||p.isOut) throw StateError('Select an available batter from the batting team');
    if(playerId==inn.striker||playerId==inn.nonStriker) throw StateError('Player is already at the crease');
    if(lastDismissedAtStriker||inn.striker.isEmpty)inn.striker=playerId;else inn.nonStriker=playerId;
    requireBatterChange=false;lastDismissedBatter='';
  }
  void selectNextBowler(String playerId) {
    final inn=match.current;final p=players[playerId];
    if(match.status!='Live'||!requireBowlerChange||p==null||p.teamId!=bowlingTeamId||playerId==lastOverBowler) throw StateError('Choose a different bowler from the fielding team');
    inn.bowler=playerId;requireBowlerChange=false;lastOverBowler='';
  }
  void _finishInnings(){
    final inn=match.current;
    if(match.innings==1){
      inn.complete=true;match.innings=2;
      final next=InningsRecord();next.target=inn.runs+1;match.inningsList.add(next);
      requireBatterChange=false;requireBowlerChange=false;lastDismissedBatter='';lastOverBowler='';
      match.status='Innings Break';
    } else {
      match.status='Completed';match.completedAt=DateTime.now();
      final first=match.inningsList[0].runs,second=inn.runs;
      match.result=second>=first+1?'Chasing team won':second==first?'Match tied':'Defending team won';
    }
  }

  void startSecondInnings({required String strikerId,required String nonStrikerId,required String bowlerId}){
    if(match.status!='Innings Break')throw StateError('First innings is not complete');
    match.status='Ready';selectOpeners(strikerId:strikerId,nonStrikerId:nonStrikerId,bowlerId:bowlerId);
    match.status='Live';
  }
}
