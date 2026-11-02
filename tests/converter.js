const assert=require('assert'),fs=require('fs');
const {convert}=require('../tools/factoruide_converter');
const sample={format:'factoruide-guide',version:2,request:{params:{edition:'forever'}},outcome:{route:{format:2,name:'QA route',class_id:5,race_id:1,faction:'Alliance',from_level:1,to_level:60,steps:[{kind:'objective',quest:90001,objective:0,level:10,text:'Literal |cffnot-code % tab\tquote "',map:{ui_map:1429,x:48,y:43},pre:[10],pre_any:[20,30],pre_need:1}]}}};
let n=0;const check=(fn)=>{fn();n++};
check(()=>assert(convert(JSON.stringify(sample)).text.startsWith('RFP1\tQA%20route')));
check(()=>assert(convert(JSON.stringify(sample)).text.includes('\t90001\t0\t1429\t48\t43\t')));
check(()=>{const x=JSON.parse(JSON.stringify(sample));x.outcome.route.steps[0].slot=3;assert(convert(JSON.stringify(x)).text.includes('\t90001\t3\t1429\t'));});
check(()=>{const x=JSON.parse(JSON.stringify(sample));x.outcome.route.steps[0].slot=3;x.outcome.route.steps[0].child=10;assert(convert(JSON.stringify(x)).text.includes('\t90001\t0\t1429\t'));});
check(()=>assert(convert(JSON.stringify(sample)).text.includes('%7Ccffnot-code%20%25%20tab%09quote%20%22')));
for(const mutate of [x=>x.version=99,x=>x.request.params.edition='tbc',x=>x.outcome.route.players=[{},{}],x=>x.outcome.route.steps[0].map.x=101,x=>x.outcome.route.steps[0].quest=-1,x=>x.outcome.route.steps[0].pre_need=3,x=>x.outcome.route.steps=[],x=>x.outcome.route.class_id=99])check(()=>{const x=JSON.parse(JSON.stringify(sample));mutate(x);assert.throws(()=>convert(JSON.stringify(x)));});
check(()=>assert.throws(()=>convert('FGG1:compressed')));
check(()=>assert.throws(()=>convert('return os.execute("never run")')));
check(()=>assert.throws(()=>convert('x'.repeat(8000001))));
if(fs.existsSync('research/factoruide/example.fgguide')){
 const text=fs.readFileSync('research/factoruide/example.fgguide','utf8'),result=convert(text);
 check(()=>assert.equal(result.steps,JSON.parse(text).outcome.route.steps.length));
 fs.mkdirSync('tmp',{recursive:true});fs.writeFileSync('tmp/factoruide-real.rfp',result.text);
 console.log('PASS: actual upstream Factoruide sample converted ('+result.steps+' steps); not bundled as a player route');
}
console.log('PASS: '+n+' data-only route converter assertions');
