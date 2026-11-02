/**
 * MyCricStats — Cloudflare Worker (works on *.workers.dev)
 * Includes: HTML app + /api/proxy (Sportmonks CORS fix)
 */
const INDEX_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"/>
<title>MyCricStats</title>
<meta name="theme-color" content="#01002C"/>
<link rel="manifest" href="/manifest.webmanifest"/>
<meta name="mobile-web-app-capable" content="yes"/>
<meta name="apple-mobile-web-app-capable" content="yes"/>
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>
<meta name="apple-mobile-web-app-title" content="MyCricStats"/>
<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png"/>
<link rel="icon" type="image/png" sizes="192x192" href="/icons/icon-192.png"/>
<link rel="icon" type="image/png" sizes="512x512" href="/icons/icon-512.png"/>
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@500;600;700;800;900&display=swap" rel="stylesheet">
<style>
/* Sportmonks-inspired: Torch Red #FF0F50, Stratos #01002C, pink accent */
:root{
  --bg:#01002C;--bg2:#0a0a3a;--card:#12123f;--line:rgba(255,255,255,.12);
  --text:#f8fafc;--muted:#a8a8c8;--red:#FF0F50;--pink:#F78DA7;--gold:#fbbf24;
  --blue:#7dd3fc;--accent:#FF0F50;--shine:linear-gradient(135deg,#FF0F50,#F78DA7);
}
body.theme-dark{--bg:#01002C;--bg2:#0a0a3a;--card:#12123f;--accent:#FF0F50;--blue:#7dd3fc}
body.theme-light{--bg:#f4f4f8;--bg2:#ffffff;--card:#ffffff;--line:rgba(1,0,44,.12);--text:#01002C;--muted:#5c5c7a;--accent:#FF0F50;--blue:#0284c7;--gold:#b45309}
body.theme-pitch{--bg:#062816;--bg2:#0c3d22;--card:#0f4a2a;--line:rgba(52,211,153,.2);--text:#ecfdf5;--muted:#6ee7b7;--accent:#10b981;--blue:#34d399;--gold:#fde68a}
body.theme-night{--bg:#0b1020;--bg2:#151b2e;--card:#1c2438;--accent:#FF0F50;--blue:#38bdf8}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Montserrat,system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh;-webkit-font-smoothing:antialiased}
.app{max-width:480px;margin:0 auto;padding-bottom:32px;min-height:100vh}
.sport-bar{display:flex;gap:6px;overflow-x:auto;padding:8px 12px;background:var(--bg2);border-bottom:1px solid var(--line)}
.sport-bar button{flex:0 0 auto;border:1px solid var(--line);background:transparent;color:var(--muted);font-family:inherit;font-weight:800;font-size:11px;padding:8px 14px;border-radius:999px;cursor:pointer;text-transform:uppercase;letter-spacing:.04em}
.sport-bar button.on{background:var(--accent);border-color:var(--accent);color:#fff;box-shadow:0 0 16px rgba(255,15,80,.35)}
.broadcast{position:relative;background:#01002C;border-bottom:1px solid var(--line);padding:14px;overflow:hidden;min-height:30vh;display:flex;flex-direction:column;justify-content:center}
.broadcast .bg-layer{position:absolute;inset:0;background-size:cover;background-position:center;z-index:0}
.broadcast .bg-overlay{position:absolute;inset:0;background:#01002C;z-index:1}
.broadcast .bc-content{position:relative;z-index:2}
.bar{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:8px}
.brand-chip{display:inline-flex;align-items:center;gap:6px;font-size:11px;font-weight:900;letter-spacing:.06em;color:#fff}
.brand-chip img{width:22px;height:22px;border-radius:6px}
.live-pill{display:inline-flex;align-items:center;gap:6px;background:rgba(255,15,80,.2);border:1px solid rgba(255,15,80,.5);color:#fecdd3;font-size:11px;font-weight:900;padding:4px 10px;border-radius:999px}
.live-pill i{width:7px;height:7px;border-radius:50%;background:#FF0F50;animation:pulse 1.4s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.35}}
.icon-btn{border:1px solid rgba(255,255,255,.3);background:rgba(255,255,255,.12);color:#fff;border-radius:999px;width:34px;height:34px;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:14px;font-family:inherit}
.view-badge{font-size:10px;font-weight:800;background:rgba(255,15,80,.2);color:#F78DA7;padding:3px 8px;border-radius:999px}
.match-header{text-align:center;padding:2px 4px 6px}
.match-header .title{font-size:15px;font-weight:900;color:var(--gold);line-height:1.25;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.match-header .sub{font-size:11px;font-weight:700;color:#cbd5e1;margin-top:3px}
.match-header .status-line{font-size:12px;font-weight:700;color:#e2e8f0;margin-top:4px}
.score-grid{display:grid;grid-template-columns:1fr 48px 1fr;gap:4px;align-items:center;margin-top:10px}
.side{text-align:center;min-width:0;padding:0 4px}
.tname{font-size:11px;font-weight:800;text-transform:uppercase;color:#f8fafc;display:flex;align-items:center;justify-content:center;gap:5px}
.tname img{width:22px;height:15px;object-fit:cover;border-radius:2px}
.tname span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.side-left .tname{justify-content:flex-start}
.side-right .tname{justify-content:flex-end;flex-direction:row-reverse}
.score-num{font-size:34px;font-weight:900;line-height:1.1;margin:6px 0 0;color:#fff;font-variant-numeric:tabular-nums;text-shadow:0 0 20px rgba(255,15,80,.35)}
.match-center .vs-label{font-size:12px;font-weight:900;letter-spacing:.14em;color:#94a3b8;text-align:center}
.crr{display:flex;justify-content:center;gap:14px;margin-top:10px;font-size:11px;color:#cbd5e1;font-weight:600}
.crr b{color:#fff}
.tabs{display:flex;gap:0;overflow-x:auto;background:var(--bg2);border-bottom:1px solid var(--line);position:sticky;top:0;z-index:10}
.tabs button{flex:0 0 auto;border:0;background:transparent;color:var(--muted);font-family:inherit;font-weight:800;font-size:12px;padding:13px 12px;cursor:pointer;border-bottom:2px solid transparent;white-space:nowrap}
.tabs button.on{color:var(--text);border-bottom-color:var(--accent)}
.panel{padding:12px}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:12px;margin-bottom:10px}
.card h3{margin:0 0 10px;font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:800}
.muted{color:var(--muted);font-size:13px}
.btn{border:1px solid var(--line);background:rgba(127,127,127,.08);color:var(--text);border-radius:999px;padding:8px 14px;font-weight:800;font-size:12px;cursor:pointer;font-family:inherit}
.btn.primary,.btn.on{background:var(--accent);border-color:var(--accent);color:#fff}
.match-list{display:flex;flex-direction:column;gap:8px}
.match-card{padding:12px 14px;border-radius:14px;border:1px solid var(--line);background:rgba(255,255,255,.03);cursor:pointer}
body.theme-light .match-card{background:#fff}
.match-card.is-live{border-color:rgba(255,15,80,.45)}
.match-card.is-sel{border-color:rgba(255,15,80,.6);background:rgba(255,15,80,.08)}
.mc-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:4px}
.mc-live{font-size:10px;font-weight:900;color:#fecdd3;background:rgba(255,15,80,.25);padding:2px 8px;border-radius:999px}
.mc-meta{font-size:11px;color:var(--muted)}
.mc-teams{font-size:14px;font-weight:800;margin:2px 0}
.mc-scores{font-size:18px;font-weight:900;margin:4px 0;color:var(--blue)}
.event-row{display:flex;gap:10px;padding:10px 0;border-bottom:1px solid var(--line);font-size:13px}
.event-row .min{font-weight:900;color:var(--accent);min-width:36px;font-size:12px}
.empty{text-align:center;padding:36px 16px;color:var(--muted);font-size:14px}
.spinner{display:inline-block;width:18px;height:18px;border:2px solid rgba(127,127,127,.3);border-top-color:var(--accent);border-radius:50%;animation:spin .7s linear infinite;vertical-align:middle;margin-right:8px}
@keyframes spin{to{transform:rotate(360deg)}}
.error-bar{background:#3b0715;color:#fecaca;font-size:13px;padding:10px 14px;text-align:center;font-weight:600;line-height:1.4}
body.theme-light .error-bar{background:#fef2f2;color:#991b1b}
.footer{text-align:center;padding:16px;font-size:11px;color:var(--muted)}
.settings-dd{position:fixed;right:12px;top:52px;z-index:9999;background:var(--bg2);border:1px solid var(--line);border-radius:14px;min-width:280px;max-width:92vw;max-height:80vh;overflow:auto;padding:8px;box-shadow:0 16px 40px rgba(0,0,0,.5)}
.settings-dd .dd-title{font-size:10px;font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);padding:6px 12px}
.settings-dd button{display:block;width:100%;text-align:left;border:0;background:transparent;color:var(--text);font-weight:700;font-size:13px;padding:11px 12px;border-radius:10px;cursor:pointer;font-family:inherit}
.settings-dd button:hover,.settings-dd button.on{background:rgba(255,15,80,.15)}
.settings-backdrop{position:fixed;inset:0;z-index:9998}
.modal-scrim{position:fixed;inset:0;z-index:10050;background:rgba(1,0,44,.75);display:flex;align-items:center;justify-content:center;padding:16px}
.modal-card{width:min(420px,94vw);background:var(--bg2);border:1px solid var(--line);border-radius:18px;padding:18px;color:var(--text);box-shadow:0 20px 50px rgba(0,0,0,.45);max-height:90vh;overflow:auto}
.modal-card h2{font-size:16px;font-weight:900;margin:0 0 6px}
.modal-card .hint{font-size:12px;color:var(--muted);line-height:1.45;margin-bottom:12px}
.modal-card .hint a{color:var(--blue)}
.modal-card .field{margin-bottom:12px}
.modal-card .field label{display:block;font-size:11px;font-weight:800;text-transform:uppercase;color:var(--muted);margin-bottom:5px}
.modal-card .field input,.modal-card .field select,.modal-card .field textarea{width:100%;padding:12px;border-radius:12px;border:1px solid var(--line);background:var(--bg);color:var(--text);font-family:inherit;font-size:14px;font-weight:600}
.modal-card .actions{display:flex;gap:8px;margin-top:14px}
.modal-card .actions .btn{flex:1;padding:12px;border-radius:12px}
.opacity-row{display:flex;align-items:center;gap:10px;margin-top:8px}
.opacity-row input[type=range]{flex:1}
.kv{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.kv .item{background:rgba(127,127,127,.06);border:1px solid var(--line);border-radius:12px;padding:10px}
.kv .item .k{font-size:10px;color:var(--muted);font-weight:800;text-transform:uppercase}
.kv .item .v{font-size:13px;font-weight:800;margin-top:4px;word-break:break-word}
.ad-overlay{position:fixed;inset:0;z-index:10000;display:flex;align-items:center;justify-content:center;background:rgba(1,0,44,.6);padding:16px}
.ad-card{background:#0a0a3a;color:#fff;border-radius:16px;padding:14px;max-width:360px;width:100%;position:relative;text-align:center;border:1px solid rgba(255,15,80,.3)}
.ad-card img{max-width:100%;max-height:220px;border-radius:10px;margin:8px auto;display:block}
.ad-close{position:absolute;top:8px;right:10px;border:0;background:rgba(127,127,127,.3);color:inherit;width:28px;height:28px;border-radius:50%;cursor:pointer;font-weight:900}
.toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%);z-index:10001;background:#166534;color:#fff;padding:10px 18px;border-radius:999px;font-size:13px;font-weight:700}
body.theme-light .sport-bar,body.theme-light .tabs,body.theme-light .settings-dd,body.theme-light .modal-card{background:#fff}
body.theme-light .settings-dd button,body.theme-light .sport-bar button{color:#01002C}
body.theme-light .broadcast .icon-btn{border-color:rgba(255,255,255,.4);background:rgba(255,255,255,.15);color:#fff}
body.theme-light .broadcast .title,body.theme-light .broadcast .sub,body.theme-light .broadcast .status-line,
body.theme-light .broadcast .tname,body.theme-light .broadcast .score-num,body.theme-light .broadcast .crr,body.theme-light .broadcast .crr b,body.theme-light .broadcast .vs-label{color:#f8fafc!important}
</style>
</head>
<body class="theme-dark">
<div id="root"></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react/18.2.0/umd/react.production.min.js" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react-dom/18.2.0/umd/react-dom.production.min.js" crossorigin="anonymous"></script>
<script>
(function(){
'use strict';
if('serviceWorker' in navigator){window.addEventListener('load',function(){navigator.serviceWorker.register('/sw.js').catch(function(){});});}
if(!window.React||!window.ReactDOM){document.getElementById('root').innerHTML='<div style="padding:20px;color:#fecaca">React failed to load</div>';return;}
var h=React.createElement,useState=React.useState,useEffect=React.useEffect,useRef=React.useRef,useCallback=React.useCallback;
var THEMES=['dark','light','pitch','night'];
var CACHE_MS=45000;
var memCache={};
/* Default stadium/pitch images (Unsplash) */
var DEFAULT_BG={
  football:'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=1200&q=60',
  cricket:'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=1200&q=60'
};

function qs(){try{return new URLSearchParams(location.search);}catch(e){return new URLSearchParams();}}
function isViewMode(){var q=qs();return q.get('view')==='1';}
function lsGet(k,fb){try{var v=localStorage.getItem(k);return v==null?fb:v;}catch(e){return fb;}}
function lsSet(k,v){try{localStorage.setItem(k,v);}catch(e){}}
function lsJSON(k,fb){try{var v=localStorage.getItem(k);return v?JSON.parse(v):fb;}catch(e){return fb;}}
function lsJSONSet(k,o){try{localStorage.setItem(k,JSON.stringify(o));}catch(e){}}
function cacheGet(key){var m=memCache[key];if(m&&Date.now()-m.t<m.ttl)return m.d;try{var raw=localStorage.getItem('sm_cache_'+key);if(raw){var o=JSON.parse(raw);if(o&&Date.now()-o.t<o.ttl){memCache[key]=o;return o.d;}}}catch(e){}return null;}
function cacheSet(key,data,ttl){var o={t:Date.now(),ttl:ttl||CACHE_MS,d:data};memCache[key]=o;try{localStorage.setItem('sm_cache_'+key,JSON.stringify(o));}catch(e){}}
function cacheClear(){memCache={};try{Object.keys(localStorage).forEach(function(k){if(k.indexOf('sm_cache_')===0)localStorage.removeItem(k);});}catch(e){}}

async function fetchJson(url){
  var res=await fetch(url);
  if(!res.ok){
    var t='';try{t=await res.text();}catch(e){}
    if(res.status===404)throw new Error('HTTP 404 — API proxy missing. Redeploy with functions/api/proxy.js (Pages output dir = public).');
    throw new Error('HTTP '+res.status+(t?': '+String(t).slice(0,100):''));
  }
  return res.json();
}
async function smGet(url){
  var cacheKey=url.replace(/api_token=[^&]+/,'api_token=***');
  var cached=cacheGet(cacheKey);
  if(cached)return{data:cached,fromCache:true};
  var json=await fetchJson(url);
  if(json.message&&json.data==null&&!Array.isArray(json.data))throw new Error(json.message);
  if(json.error)throw new Error(typeof json.error==='string'?json.error:(json.error.message||JSON.stringify(json.error)));
  var data=json.data!=null?json.data:json;
  cacheSet(cacheKey,data,CACHE_MS);
  return{data:data,fromCache:false,meta:json.meta};
}
function fbUrl(path,token,include){
  var u='/api/proxy?sport=football&path='+encodeURIComponent(path.replace(/^\\//,''))+'&api_token='+encodeURIComponent(token);
  if(include)u+='&include='+encodeURIComponent(include);
  return u;
}
function ckUrl(path,token,include){
  var u='/api/proxy?sport=cricket&path='+encodeURIComponent(path.replace(/^\\//,''))+'&api_token='+encodeURIComponent(token);
  if(include)u+='&include='+encodeURIComponent(include);
  return u;
}
function parseFbScores(scores,participants){
  var home=0,away=0;
  (scores||[]).forEach(function(s){
    if(!s||!s.score)return;
    var desc=(s.description||'').toUpperCase();
    if(desc==='CURRENT'||s.type_id===1525){
      if(s.score.participant==='home')home=s.score.goals||0;
      if(s.score.participant==='away')away=s.score.goals||0;
    }
  });
  return{home:home,away:away};
}
function fbTeams(participants){
  var home={name:'Home',image:null},away={name:'Away',image:null};
  (participants||[]).forEach(function(p){
    var loc=p.meta&&p.meta.location;
    var obj={name:p.name||p.short_code||'Team',image:p.image_path||null};
    if(loc==='home')home=obj;else if(loc==='away')away=obj;
  });
  if(home.name==='Home'&&participants&&participants[0])home={name:participants[0].name,image:participants[0].image_path};
  if(away.name==='Away'&&participants&&participants[1])away={name:participants[1].name,image:participants[1].image_path};
  return{home:home,away:away};
}
function eventLabel(ev){
  var map={14:'⚽ Goal',15:'⚽ OG',16:'⚽ Pen',18:'🟨 Yellow',19:'🟨→🟥',20:'🟥 Red',21:'🔄 Sub'};
  return map[ev.type_id]||(ev.info||'Event');
}
function shortName(n){if(!n)return'—';n=String(n);return n.length>14?n.slice(0,13)+'…':n;}

function App(){
  var viewOnly=isViewMode();
  var shareId=qs().get('match')||'';
  var _token=useState(function(){return lsGet('sportmonks_token','');});
  var token=_token[0],setToken=_token[1];
  var _sport=useState(function(){return lsGet('sm_sport','football');});
  var sport=_sport[0],setSport=_sport[1];
  var _matches=useState([]);var matches=_matches[0],setMatches=_matches[1];
  var _selected=useState(null);var selected=_selected[0],setSelected=_selected[1];
  var _detail=useState(null);var detail=_detail[0],setDetail=_detail[1];
  var _tab=useState('matches');var tab=_tab[0],setTab=_tab[1];
  var _loading=useState(false);var loading=_loading[0],setLoading=_loading[1];
  var _error=useState(null);var error=_error[0],setError=_error[1];
  var _settings=useState(false);var settingsOpen=_settings[0],setSettingsOpen=_settings[1];
  var _theme=useState(function(){return lsGet('cric_theme','dark');});
  var theme=_theme[0],setTheme=_theme[1];
  var _bgFb=useState(function(){return lsGet('bg_football',DEFAULT_BG.football);});
  var bgFb=_bgFb[0],setBgFb=_bgFb[1];
  var _bgCk=useState(function(){return lsGet('bg_cricket',DEFAULT_BG.cricket);});
  var bgCk=_bgCk[0],setBgCk=_bgCk[1];
  var _opFb=useState(function(){return parseFloat(lsGet('op_football','0.55'))||0.55;});
  var opFb=_opFb[0],setOpFb=_opFb[1];
  var _opCk=useState(function(){return parseFloat(lsGet('op_cricket','0.55'))||0.55;});
  var opCk=_opCk[0],setOpCk=_opCk[1];
  var _ads=useState(function(){return lsJSON('cric_ads_v1',{enabled:true,items:[
    {event:'goal',image:'',text:'Sponsor · GOAL!',duration:4},
    {event:'card',image:'',text:'Sponsor · Card',duration:3}
  ]});});
  var ads=_ads[0],setAds=_ads[1];
  var _adShow=useState(null);var adShow=_adShow[0],setAdShow=_adShow[1];
  var _toast=useState(null);var toast=_toast[0],setToast=_toast[1];
  var _modal=useState(null);var modal=_modal[0],setModal=_modal[1];
  var _modalVal=useState('');var modalVal=_modalVal[0],setModalVal=_modalVal[1];
  var _adminAds=useState(false);var adminAds=_adminAds[0],setAdminAds=_adminAds[1];
  var prevGoals=useRef(null);

  var bgUrl=sport==='cricket'?bgCk:bgFb;
  var bgOp=sport==='cricket'?opCk:opFb;

  useEffect(function(){document.body.className='theme-'+theme;},[theme]);

  var loadList=useCallback(function(force){
    if(!token){setError('Add Sportmonks token in ⚙ Settings.');return;}
    setLoading(true);setError(null);
    if(force)cacheClear();
    var p;
    if(sport==='cricket'){
      p=smGet(ckUrl('livescores',token,'localteam,visitorteam,runs,league,venue'));
    }else{
      p=smGet(fbUrl('livescores/inplay',token,'participants;scores;state;league;venue;events'))
        .then(function(r){
          if(Array.isArray(r.data)&&r.data.length)return r;
          return smGet(fbUrl('livescores',token,'participants;scores;state;league;venue;events'));
        });
    }
    p.then(function(r){
      var list=Array.isArray(r.data)?r.data:[];
      setMatches(list);
      if(shareId){
        var m=list.find(function(x){return String(x.id)===String(shareId);});
        if(m){setSelected(m);setDetail(m);setTab('live');}
      }
    }).catch(function(e){setError(e.message||'Load failed');})
     .finally(function(){setLoading(false);});
  },[token,sport,shareId]);

  useEffect(function(){if(token)loadList(false);},[token,sport]);

  var selectMatch=function(m){
    setSelected(m);setDetail(m);setTab('live');
    if(sport==='football'){
      var sc=parseFbScores(m.scores,m.participants);
      var prev=prevGoals.current;prevGoals.current=sc;
      if(prev&&(sc.home+sc.away)>(prev.home+prev.away))triggerAd('goal');
    }
  };
  var loadDetail=function(m){
    if(!token||!m)return;
    setLoading(true);setError(null);
    var p=sport==='cricket'
      ?smGet(ckUrl('fixtures/'+m.id,token,'localteam,visitorteam,runs,batting,bowling,league,venue,lineup'))
      :smGet(fbUrl('fixtures/'+m.id,token,'participants;scores;events;state;league;venue;lineups'));
    p.then(function(r){setDetail(r.data||m);setSelected(r.data||m);})
     .catch(function(e){setError(e.message);})
     .finally(function(){setLoading(false);});
  };
  function triggerAd(event){
    if(!ads.enabled||adShow)return;
    var item=(ads.items||[]).find(function(x){return x.event===event;});
    if(!item||(!item.image&&!item.text))return;
    setAdShow(item);
    setTimeout(function(){setAdShow(null);},(item.duration||4)*1000);
  }
  var shareView=function(){
    if(!selected){setToast('Select a match');setTimeout(function(){setToast(null);},2000);return;}
    var u=new URL(location.href);u.searchParams.set('view','1');u.searchParams.set('match',selected.id);
    var link=u.toString();
    if(navigator.clipboard&&navigator.clipboard.writeText){
      navigator.clipboard.writeText(link).then(function(){setToast('Link copied');setTimeout(function(){setToast(null);},2000);})
        .catch(function(){setModalVal(link);setModal('share');});
    }else{setModalVal(link);setModal('share');}
  };

  var d=detail||selected;
  var homeName='—',awayName='—',homeScore='—',awayScore='—',status='',venue='',league='',homeImg=null,awayImg=null,events=[];
  if(d&&sport==='football'){
    var teams=fbTeams(d.participants);homeName=teams.home.name;awayName=teams.away.name;homeImg=teams.home.image;awayImg=teams.away.image;
    var sc=parseFbScores(d.scores,d.participants);homeScore=sc.home;awayScore=sc.away;
    status=(d.state&&d.state.name)||d.result_info||'';venue=(d.venue&&d.venue.name)||'';league=(d.league&&d.league.name)||'';
    events=(d.events||[]).slice().sort(function(a,b){return(a.sort_order||0)-(b.sort_order||0);});
  }else if(d&&sport==='cricket'){
    homeName=(d.localteam&&d.localteam.name)||'Home';awayName=(d.visitorteam&&d.visitorteam.name)||'Away';
    status=d.status||d.note||'';venue=(d.venue&&d.venue.name)||'';league=(d.league&&d.league.name)||d.type||'';
    var runs=d.runs||[];
    if(runs[0])homeScore=runs[0].score+(runs[0].wickets!=null?'/'+runs[0].wickets:'');
    if(runs[1])awayScore=runs[1].score+(runs[1].wickets!=null?'/'+runs[1].wickets:'');
  }

  var tabs=[['matches','Matches'],['live','Live'],['events','Events'],['lineups','Lineups'],['info','Info']];

  return h('div',{className:'app'},
    !viewOnly?h('div',{className:'sport-bar'},
      h('button',{className:sport==='football'?'on':'',onClick:function(){setSport('football');lsSet('sm_sport','football');setSelected(null);setDetail(null);setTab('matches');}},'Football'),
      h('button',{className:sport==='cricket'?'on':'',onClick:function(){setSport('cricket');lsSet('sm_sport','cricket');setSelected(null);setDetail(null);setTab('matches');}},'Cricket')
    ):null,

    error?h('div',{className:'error-bar'},error):null,

    h('div',{className:'broadcast'},
      bgUrl?h('div',{className:'bg-layer',style:{backgroundImage:'url('+bgUrl+')'}}):null,
      h('div',{className:'bg-overlay',style:{opacity:bgUrl?bgOp:0.92}}),
      h('div',{className:'bc-content'},
        h('div',{className:'bar'},
          viewOnly?h('span',{className:'view-badge'},'VIEW ONLY'):
            (selected?h('span',{className:'live-pill'},h('i'),'LIVE'):
              h('span',{className:'brand-chip'},h('img',{src:'/icons/icon-192.png',alt:''}),'MCS')),
          h('div',{style:{display:'flex',gap:8}},
            !viewOnly?h('button',{className:'icon-btn',onClick:shareView},'↗'):null,
            h('button',{className:'icon-btn',onClick:function(){loadList(true);}},loading?'…':'↻'),
            !viewOnly?h('button',{className:'icon-btn',onClick:function(){setSettingsOpen(!settingsOpen);}},'⚙'):null
          )
        ),
        selected?h(React.Fragment,null,
          h('div',{className:'match-header'},
            h('div',{className:'title'},league||d.name||'Match'),
            h('div',{className:'sub'},venue),
            h('div',{className:'status-line'},status)
          ),
          h('div',{className:'score-grid'},
            h('div',{className:'side side-left'},
              h('div',{className:'tname'},homeImg?h('img',{src:homeImg,alt:''}):null,h('span',null,shortName(homeName))),
              h('div',{className:'score-num'},homeScore)
            ),
            h('div',{className:'match-center'},h('div',{className:'vs-label'},'VS')),
            h('div',{className:'side side-right'},
              h('div',{className:'tname'},h('span',null,shortName(awayName)),awayImg?h('img',{src:awayImg,alt:''}):null),
              h('div',{className:'score-num'},awayScore)
            )
          ),
          h('div',{className:'crr'},h('span',null,sport==='football'?'Football':'Cricket'),
            d.starting_at?h('span',null,String(d.starting_at).replace('T',' ').slice(0,16)):null)
        ):h('div',{className:'match-header'},
          h('div',{className:'title'},'MyCricStats'),
          h('div',{className:'sub'},token?'Tap a match':'Add token in Settings ⚙')
        )
      )
    ),

    !viewOnly&&settingsOpen?h(React.Fragment,null,
      h('div',{className:'settings-backdrop',onClick:function(){setSettingsOpen(false);}}),
      h('div',{className:'settings-dd'},
        h('div',{className:'dd-title'},'API'),
        h('button',{onClick:function(){setModalVal(token);setModal('token');setSettingsOpen(false);}},token?'Change token':'Add Sportmonks token'),
        h('div',{className:'dd-title'},'Theme'),
        THEMES.map(function(t){return h('button',{key:t,className:theme===t?'on':'',onClick:function(){setTheme(t);lsSet('cric_theme',t);}},t.charAt(0).toUpperCase()+t.slice(1));}),
        h('div',{className:'dd-title'},'Scoreboard background'),
        h('button',{onClick:function(){setModal('bgpanel');setSettingsOpen(false);}},'Football & Cricket images'),
        h('div',{className:'dd-title'},'Admin'),
        h('button',{onClick:function(){setAdminAds(true);setSettingsOpen(false);}},'Sponsor ads'),
        h('button',{onClick:shareView},'Copy view-only link'),
        h('button',{onClick:function(){cacheClear();setSettingsOpen(false);loadList(true);}},'Clear cache & refresh')
      )
    ):null,

    /* Combined BG + opacity panel for both sports */
    modal==='bgpanel'?h('div',{className:'modal-scrim',onClick:function(){setModal(null);}},
      h('div',{className:'modal-card',onClick:function(e){e.stopPropagation();}},
        h('h2',null,'Scoreboard backgrounds'),
        h('div',{className:'hint'},'Separate images for Football and Cricket. Opacity slider sits under each image URL.'),
        h('div',{className:'field'},
          h('label',null,'Football image URL'),
          h('input',{type:'url',value:bgFb,onChange:function(e){setBgFb(e.target.value);lsSet('bg_football',e.target.value);}}),
          h('div',{className:'opacity-row'},
            h('span',{style:{fontSize:11,fontWeight:700,minWidth:70}},Math.round(opFb*100)+'%'),
            h('input',{type:'range',min:0.2,max:0.95,step:0.05,value:opFb,onChange:function(e){var v=parseFloat(e.target.value);setOpFb(v);lsSet('op_football',String(v));}})
          )
        ),
        h('div',{className:'field'},
          h('label',null,'Cricket image URL'),
          h('input',{type:'url',value:bgCk,onChange:function(e){setBgCk(e.target.value);lsSet('bg_cricket',e.target.value);}}),
          h('div',{className:'opacity-row'},
            h('span',{style:{fontSize:11,fontWeight:700,minWidth:70}},Math.round(opCk*100)+'%'),
            h('input',{type:'range',min:0.2,max:0.95,step:0.05,value:opCk,onChange:function(e){var v=parseFloat(e.target.value);setOpCk(v);lsSet('op_cricket',String(v));}})
          )
        ),
        h('div',{className:'actions'},
          h('button',{className:'btn',onClick:function(){
            setBgFb(DEFAULT_BG.football);setBgCk(DEFAULT_BG.cricket);setOpFb(0.55);setOpCk(0.55);
            lsSet('bg_football',DEFAULT_BG.football);lsSet('bg_cricket',DEFAULT_BG.cricket);
            lsSet('op_football','0.55');lsSet('op_cricket','0.55');
          }},'Reset defaults'),
          h('button',{className:'btn primary',onClick:function(){setModal(null);}},'Done')
        )
      )
    ):null,

    modal&&modal!=='bgpanel'?h('div',{className:'modal-scrim',onClick:function(){setModal(null);}},
      h('div',{className:'modal-card',onClick:function(e){e.stopPropagation();}},
        h('h2',null,modal==='token'?'Sportmonks token':modal==='share'?'Share link':'Settings'),
        h('div',{className:'hint'},
          modal==='token'?h(React.Fragment,null,'Token from ',h('a',{href:'https://my.sportmonks.com',target:'_blank',rel:'noreferrer'},'my.sportmonks.com'),'. Free plan = limited leagues.'):
          modal==='share'?'Viewers do not see Settings.':''
        ),
        h('div',{className:'field'},
          h('label',null,modal==='share'?'Link':'Token'),
          h('input',{type:modal==='token'?'password':'text',value:modalVal,readOnly:modal==='share',
            onChange:function(e){setModalVal(e.target.value);},onFocus:function(e){if(modal==='share')e.target.select();}})
        ),
        h('div',{className:'actions'},
          h('button',{className:'btn',onClick:function(){setModal(null);}},'Cancel'),
          modal==='share'?h('button',{className:'btn primary',onClick:function(){if(navigator.clipboard)navigator.clipboard.writeText(modalVal);setModal(null);}},'Copy'):
          h('button',{className:'btn primary',onClick:function(){
            var v=String(modalVal||'').trim();if(!v)return;
            lsSet('sportmonks_token',v);setToken(v);setModal(null);setToast('Saved');setTimeout(function(){setToast(null);},2000);
          }},'Save')
        )
      )
    ):null,

    !viewOnly&&adminAds?h('div',{className:'modal-scrim',onClick:function(){setAdminAds(false);}},
      h('div',{className:'modal-card',onClick:function(e){e.stopPropagation();}},
        h('h2',null,'Sponsor ads'),
        h('label',{style:{display:'flex',gap:8,fontWeight:700,marginBottom:12}},
          h('input',{type:'checkbox',checked:!!ads.enabled,onChange:function(e){var n=Object.assign({},ads,{enabled:e.target.checked});setAds(n);lsJSONSet('cric_ads_v1',n);}}),' Enabled'
        ),
        (ads.items||[]).map(function(item,idx){
          return h('div',{key:idx,className:'card'},
            h('h3',null,item.event.toUpperCase()),
            h('div',{className:'field'},h('label',null,'Image'),h('input',{value:item.image||'',onChange:function(e){
              var items=ads.items.slice();items[idx]=Object.assign({},item,{image:e.target.value});var n=Object.assign({},ads,{items:items});setAds(n);lsJSONSet('cric_ads_v1',n);
            }})),
            h('div',{className:'field'},h('label',null,'Text'),h('input',{value:item.text||'',onChange:function(e){
              var items=ads.items.slice();items[idx]=Object.assign({},item,{text:e.target.value});var n=Object.assign({},ads,{items:items});setAds(n);lsJSONSet('cric_ads_v1',n);
            }})),
            h('button',{className:'btn',onClick:function(){triggerAd(item.event);}},'Test')
          );
        }),
        h('button',{className:'btn primary',style:{width:'100%'},onClick:function(){setAdminAds(false);}},'Done')
      )
    ):null,

    adShow?h('div',{className:'ad-overlay',onClick:function(){setAdShow(null);}},
      h('div',{className:'ad-card',onClick:function(e){e.stopPropagation();}},
        h('button',{className:'ad-close',onClick:function(){setAdShow(null);}},'×'),
        adShow.image?h('img',{src:adShow.image,alt:''}):null,
        adShow.text?h('div',{style:{fontWeight:800,marginTop:8}},adShow.text):null
      )
    ):null,
    toast?h('div',{className:'toast'},toast):null,

    h('div',{className:'tabs'},
      tabs.map(function(p){
        return h('button',{key:p[0],className:tab===p[0]?'on':'',onClick:function(){
          setTab(p[0]);if((p[0]==='events'||p[0]==='lineups')&&selected)loadDetail(selected);
        }},p[1]);
      })
    ),

    h('div',{className:'panel'},
      tab==='matches'?h(React.Fragment,null,
        !token?h('div',{className:'empty'},'⚙ → Add Sportmonks token'):null,
        loading&&!matches.length?h('div',{className:'empty'},h('span',{className:'spinner'}),' Loading…'):null,
        !loading&&token&&!matches.length?h('div',{className:'empty'},'No live matches on your plan right now.'):null,
        h('div',{className:'match-list'},
          matches.map(function(m){
            var hn,an,hs,as,st,lg;
            if(sport==='football'){
              var t=fbTeams(m.participants);hn=t.home.name;an=t.away.name;
              var s=parseFbScores(m.scores,m.participants);hs=s.home;as=s.away;
              st=(m.state&&m.state.name)||'';lg=(m.league&&m.league.name)||'';
            }else{
              hn=(m.localteam&&m.localteam.name)||'Home';an=(m.visitorteam&&m.visitorteam.name)||'Away';
              var runs=m.runs||[];hs=runs[0]?runs[0].score:'—';as=runs[1]?runs[1].score:'—';
              st=m.status||'';lg=(m.league&&m.league.name)||m.type||'';
            }
            return h('div',{key:m.id,className:'match-card is-live'+(selected&&selected.id===m.id?' is-sel':''),onClick:function(){selectMatch(m);}},
              h('div',{className:'mc-top'},h('span',{className:'mc-live'},'LIVE'),h('span',{className:'mc-meta'},lg)),
              h('div',{className:'mc-teams'},hn+' vs '+an),
              h('div',{className:'mc-scores'},hs+' — '+as),
              h('div',{className:'mc-meta'},st)
            );
          })
        )
      ):null,

      tab==='live'?(!selected?h('div',{className:'empty'},'Select a match'):h(React.Fragment,null,
        h('div',{className:'card'},h('h3',null,'Score'),
          h('div',{style:{fontSize:28,fontWeight:900,textAlign:'center'}},homeScore+'  –  '+awayScore),
          h('div',{className:'muted',style:{textAlign:'center',marginTop:6}},status)),
        h('button',{className:'btn',onClick:function(){loadDetail(selected);}},'Refresh detail')
      )):null,

      tab==='events'?(!selected?h('div',{className:'empty'},'Select a match'):h('div',{className:'card'},
        h('h3',null,'Events'),
        events.length?events.map(function(ev,i){
          return h('div',{key:ev.id||i,className:'event-row'},
            h('span',{className:'min'},(ev.minute!=null?ev.minute+"'":'—')),
            h('span',null,eventLabel(ev)+' '+(ev.player_name||''))
          );
        }):h('div',{className:'muted'},loading?'Loading…':'No events yet')
      )):null,

      tab==='lineups'?(!selected?h('div',{className:'empty'},'Select a match'):h('div',{className:'card'},
        h('h3',null,'Lineups'),
        (d&&d.lineups&&d.lineups.length)?d.lineups.slice(0,30).map(function(p,i){
          return h('div',{key:i,style:{padding:'6px 0',borderBottom:'1px solid var(--line)',fontSize:13,fontWeight:600}},
            p.player_name||(p.player&&p.player.name)||'Player');
        }):h('div',{className:'muted'},'Lineups unavailable or not in plan')
      )):null,

      tab==='info'?(!selected?h('div',{className:'empty'},'Select a match'):h('div',{className:'card'},
        h('h3',null,'Info'),
        h('div',{className:'kv'},
          h('div',{className:'item'},h('div',{className:'k'},'Home'),h('div',{className:'v'},homeName)),
          h('div',{className:'item'},h('div',{className:'k'},'Away'),h('div',{className:'v'},awayName)),
          h('div',{className:'item'},h('div',{className:'k'},'League'),h('div',{className:'v'},league||'—')),
          h('div',{className:'item'},h('div',{className:'k'},'Venue'),h('div',{className:'v'},venue||'—')),
          h('div',{className:'item'},h('div',{className:'k'},'Status'),h('div',{className:'v'},status||'—')),
          h('div',{className:'item'},h('div',{className:'k'},'Sport'),h('div',{className:'v'},sport))
        )
      )):null
    ),

    h('div',{className:'footer'},'MyCricStats')
  );
}

var root=document.getElementById('root');
if(ReactDOM.createRoot)ReactDOM.createRoot(root).render(h(App));
else ReactDOM.render(h(App),root);
})();
</script>
</body>
</html>`;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // API proxy
    if (path === '/api/proxy' || path.startsWith('/api/proxy')) {
      return handleProxy(request, url);
    }

    // PWA / static
    if (path === '/manifest.webmanifest') {
      return new Response(JSON.stringify({
        name: 'MyCricStats', short_name: 'MCS', start_url: '/', display: 'standalone',
        background_color: '#01002C', theme_color: '#01002C',
        icons: [
          { src: 'https://cdn.jsdelivr.net/gh/beinginnovator-dev/MyCricStats@main/public/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'https://cdn.jsdelivr.net/gh/beinginnovator-dev/MyCricStats@main/public/icons/icon-512.png', sizes: '512x512', type: 'image/png' }
        ]
      }), { headers: { 'Content-Type': 'application/manifest+json', 'Access-Control-Allow-Origin': '*' } });
    }

    if (path === '/sw.js') {
      const sw = `const C='mcs-v2';self.addEventListener('install',e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(['/'])).then(()=>self.skipWaiting()))});self.addEventListener('fetch',e=>{if(new URL(e.request.url).pathname.startsWith('/api/'))return;e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request)))});`;
      return new Response(sw, { headers: { 'Content-Type': 'application/javascript', 'Cache-Control': 'no-cache' } });
    }

    // Icons: redirect to GitHub raw / jsdelivr if requested
    if (path.startsWith('/icons/')) {
      const name = path.split('/').pop();
      return Response.redirect('https://cdn.jsdelivr.net/gh/beinginnovator-dev/MyCricStats@main/public/icons/' + name, 302);
    }

    // Default: app
    if (path === '/' || path === '/index.html' || !path.includes('.')) {
      return new Response(INDEX_HTML, {
        headers: {
          'Content-Type': 'text/html;charset=utf-8',
          'Cache-Control': 'no-cache',
          'X-MyCricStats': 'worker-embedded-v2'
        }
      });
    }

    return new Response('Not found: ' + path, { status: 404 });
  }
};

async function handleProxy(request, url) {
  const h = cors(request);
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: h });

  const sport = (url.searchParams.get('sport') || 'football').toLowerCase();
  const path = (url.searchParams.get('path') || '').replace(/^\/+/, '');
  const token = request.headers.get('X-Sportmonks-Token') || url.searchParams.get('api_token') || '';

  if (!path) {
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: 'Missing path. Use ?path=livescores/inplay&api_token=...' }), { status: 400, headers: h });
  }
  if (!token) {
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: 'Missing api_token' }), { status: 401, headers: h });
  }

  const base = sport === 'cricket'
    ? 'https://cricket.sportmonks.com/api/v2.0'
    : 'https://api.sportmonks.com/v3/football';
  const upstream = new URL(base + '/' + path);
  url.searchParams.forEach((v, k) => {
    if (k === 'sport' || k === 'path' || k === 'api_token') return;
    upstream.searchParams.set(k, v);
  });
  upstream.searchParams.set('api_token', token);

  try {
    const res = await fetch(upstream.toString(), {
      headers: { Accept: 'application/json', 'User-Agent': 'MyCricStats-Worker/2.0' }
    });
    const text = await res.text();
    h.set('Content-Type', res.headers.get('Content-Type') || 'application/json');
    h.set('Cache-Control', 'public, max-age=10');
    return new Response(text, { status: res.status, headers: h });
  } catch (e) {
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: 'Upstream: ' + (e.message || String(e)) }), { status: 502, headers: h });
  }
}

function cors(request) {
  return new Headers({
    'Access-Control-Allow-Origin': request.headers.get('Origin') || '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Sportmonks-Token',
    Vary: 'Origin'
  });
}
