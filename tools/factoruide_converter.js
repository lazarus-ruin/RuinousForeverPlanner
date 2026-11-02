/* Data-only bridge for Factoruide .fgguide JSON format 1/2. No Lua/eval execution. */
(function(root){
  'use strict';
  const classes={1:'WARRIOR',2:'PALADIN',3:'HUNTER',4:'ROGUE',5:'PRIEST',7:'SHAMAN',8:'MAGE',9:'WARLOCK',11:'DRUID'};
  const integer=(v,lo,hi,label)=>{if(!Number.isInteger(v)||v<lo||v>hi)throw Error('Invalid '+label);return v;};
  const str=(v,max,label)=>{if(typeof v!=='string'||v.length>max||/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(v))throw Error('Invalid '+label);return encodeURIComponent(v);};
  function list(v,label){if(v===undefined)return '';if(!Array.isArray(v)||v.length>50)throw Error('Invalid '+label);return v.map(x=>integer(x,1,10000000,label)).join(',');}
  function convert(text){
    if(typeof text!=='string'||text.length>8000000)throw Error('Select a .fgguide JSON file smaller than 8 MB.');
    if(text.trim().startsWith('FGG1:'))throw Error('Use Factoruide Share / .fgguide file, not its compressed in-game import text.');
    const data=JSON.parse(text);
    if(data.format!=='factoruide-guide'||![1,2].includes(data.version))throw Error('Unsupported Factoruide file version.');
    const r=data.outcome&&data.outcome.route;
    if(!r||![1,2].includes(r.format??1)||!Array.isArray(r.steps)||r.steps.length<1||r.steps.length>5000)throw Error('Unsupported or oversized route.');
    if(data.request?.params?.edition!=='forever')throw Error('Only explicitly identified WoW Forever routes are accepted.');
    if((r.players&&r.players.length>1)||(data.request?.mates?.length>0)||(data.meta?.group?.length>0))throw Error('Group-member step ownership is not supported. Export a single-character route.');
    const cls=classes[r.class_id];if(!cls)throw Error('Unsupported class.');
    if(!['Alliance','Horde'].includes(r.faction))throw Error('Unsupported faction.');
    const from=integer(r.from_level,1,60,'starting level'),to=integer(r.to_level,from,60,'target level');
    const lines=[['RFP1',str(r.name,160,'route name'),cls,integer(r.race_id,1,200,'race'),r.faction,from,to,str('Factoruide .fgguide v'+data.version+' / route format '+(r.format??1),180,'source')].join('\t')];
    for(const [i,s] of r.steps.entries()){
      if(typeof s.kind!=='string'||!/^[a-z_]{1,30}$/.test(s.kind))throw Error('Invalid step kind at '+(i+1));
      const m=s.map;
      if(m&&(!Number.isFinite(m.x)||!Number.isFinite(m.y)||m.x<0||m.x>100||m.y<0||m.y>100))throw Error('Invalid map coordinates.');
      const any=s.pre_any||[];const need=s.pre_need??(any.length?1:0);
      // `slot` is the client's one-based objective order; `objective` is an internal planner index.
      // Missing/zero slots and child/item-buy conditions must remain manual, never guessed as index+1.
      const objective=(s.held||s.child||s.try_buy||s.buy)?0:integer(s.slot??0,0,100,'client objective slot');
      lines.push([s.kind,integer(s.quest??0,0,10000000,'quest'),objective,m?integer(m.ui_map,1,100000,'map'):0,m?m.x:0,m?m.y:0,integer(s.min_level??0,0,60,'minimum level'),integer(s.level,1,60,'step level'),s.bg?1:0,str(s.text,1200,'step text'),list(s.pre,'prerequisites'),list(any,'alternative prerequisites'),integer(need,0,any.length,'required alternative count'),list(s.alt,'exclusions')].join('\t'));
    }
    const result=lines.join('\n');if(new TextEncoder().encode(result).length>1000000)throw Error('Converted route exceeds 1 MB. Split the guide in Factoruide.');
    return {text:result,name:r.name,steps:r.steps.length,warnings:['Imported as ordered advice only. Travel paths, group ownership, item-buy conditions, simulation and automation are not reproduced.','Background objectives remain ordered steps; pass them manually when continuing in parallel.','Imported coordinates are destinations, not safe walking paths.']};
  }
  if(typeof module!=='undefined'&&module.exports)module.exports={convert};else root.RFPConverter={convert};
})(typeof globalThis!=='undefined'?globalThis:this);
