/* D339 I-2 · every shared artifact carries the same signature. Serve this
   checkout, open /?exit, evaluate with web-verify.mjs. Labelled fixtures
   only — no account data, nothing uploaded, nothing shared. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};
  const fixture={ name:'FIXTURE · Sam Ridley', course:'FIXTURE GC', gross:84, points:7, pvi:0.2,
                  date:new Date(2026,8,11), marker:'saguaro', league:'FIXTURE LEAGUE', squad:'FIXTURE',
                  band:'Played to it', jug:'the fixture jug', when:'SEP 11', pot:'$0',
                  holes:Array.from({length:18},(_,i)=>({par:4,score:4,si:i+1})), rows:[], lines:[],
                  /* the round card draws a SCORECARD: it needs a card, not a list of holes */
                  mine:true,
                  card:{ parTotal:72, holes:Array.from({length:18},(_,i)=>({ n:i+1, par:4, si:i+1 })),
                         players:[{ name:'FIXTURE · Sam Ridley', you:true, scores:Array.from({length:18},()=>4) }] } };
  /* one canvas the signature is drawn on alone, so its geometry can be read */
  const probe=()=>{
    const cv=document.createElement('canvas'); cv.width=1080; cv.height=1350;
    const x=cv.getContext('2d');
    const bottom=csArtifactSignature(x, 1080, 1180, {});
    return { cv, x, bottom };
  };
  const p=probe();
  check(typeof csArtifactSignature==='function','I-2: there is no shared signature');
  check(p.bottom>1180 && p.bottom<=1322,'I-2: the signature does not fit the artifact: '+p.bottom);
  /* it actually PUT INK on the canvas in the mark's own box, which is what
     separates "the mark is drawn" from "the name is drawn where the mark was" */
  const box=p.x.getImageData(1080/2-250, 1180, 150, 56).data;
  let lit=0; for(let i=3;i<box.length;i+=4) if(box[i]>8) lit++;
  check(lit>200,'I-2: the mark did not draw on the artifact (lit '+lit+')');
  out.markPixels=lit;

  /* every generator ends on the same signature, at the same size */
  const gens=[['recap',()=>drawRecapCard(fixture)],
              ['round',()=>drawRoundCardArtifact(fixture)],
              ['settlement',()=>drawSettlementCard(fixture)],
              ['major',()=>drawMajorCard(fixture)]];
  const sig={};
  for(const [name,make] of gens){
    let cv=null;
    try{ cv=make(); }catch(e){ throw new Error('I-2: '+name+' stopped drawing: '+e.message); }
    check(cv && cv.width===1080 && cv.height===1350,'I-2: '+name+' is not the artifact canvas');
    const cx=cv.getContext('2d');
    /* the signature's band, read as a fingerprint: the same mark and the same
       two lines land in the same place on all four */
    /* the card paints an opaque ground, so alpha says nothing — count the
       pixels that are LIGHTER than that ground, which is the drawn signature */
    const band=cx.getImageData(0, 1176, 1080, 150).data;
    let ink=0; for(let i=0;i<band.length;i+=4) if(band[i]>60 || band[i+1]>60 || band[i+2]>60) ink++;
    check(ink>3000,'I-2: '+name+' has no signature band (ink '+ink+')');
    sig[name]=ink;
  }
  /* the four are within a hair of one another — one producer, not four */
  const vals=Object.values(sig), lo=Math.min(...vals), hi=Math.max(...vals);
  check(hi-lo < hi*0.35,'I-2: the four artifacts do not share one signature: '+JSON.stringify(sig));
  out.signatureInk=sig;

  /* the old per-card sign-offs are gone from the DRAWING code (the comment
     that records what they were is not a sign-off) */
  check(!/START YOURS AT/.test(String(drawMajorCard)),'I-2: the Major card still signs itself its own way');
  for(const [name,fn] of [['recap',drawRecapCard],['round',drawRoundCardArtifact],['settlement',drawSettlementCard],['major',drawMajorCard]])
    check(/csArtifactSignature/.test(String(fn)),'I-2: '+name+' does not use the shared signature');
  out.passed=true; return out;
})()
