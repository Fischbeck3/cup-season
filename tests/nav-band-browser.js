/* The five-position band, as the phone builds it (`CSTabBand`) and as the
   owner's 2026-09-14 board requires. Serve this checkout, open /?exit,
   evaluate with web-verify.mjs at 390, 320 and a short viewport. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const q=s=>document.querySelector(s);
  const out={ width: innerWidth };
  const bar=q('nav.tabbar');
  check(!!bar,'there is no band');
  const tabs=Array.from(bar.querySelectorAll('.tab'));

  /* FIVE POSITIONS, in the phone's order */
  const order=tabs.map(t=>t.getAttribute('data-v'));
  check(order.join(',')==='home,compete,record,golfers,stats','the band is not the phone’s five: '+order.join(','));
  const cols=getComputedStyle(bar).gridTemplateColumns.split(' ').length;
  check(cols===5,'the band does not lay out five equal slots: '+cols);
  out.slots=order.length;

  /* every slot is LABELLED — including Play */
  const labels=tabs.map(t=>t.textContent.trim());
  check(labels.every(l=>l.length>0),'a slot has no label: '+JSON.stringify(labels));
  const play=tabs.find(t=>t.getAttribute('data-v')==='record');
  check(/play/i.test(play.textContent),'Play has no label');
  check(parseFloat(getComputedStyle(play).fontSize)>=10,'Play’s label is suppressed to nothing');
  out.labels=labels;

  /* Play is IN the band — not floating above it, not a filled disc */
  check(getComputedStyle(play).position!=='fixed','Play still floats out of the band');
  const pr=play.getBoundingClientRect(), br=bar.getBoundingClientRect();
  check(pr.top>=br.top-1 && pr.bottom<=br.bottom+1,'Play is not inside the band’s own box');
  const circ=play.querySelector('.circ');
  if(circ){
    const cs=getComputedStyle(circ);
    check(cs.backgroundColor==='rgba(0, 0, 0, 0)' || cs.display==='contents','Play is still a filled disc');
    check(cs.boxShadow==='none' || cs.display==='contents','Play still carries the disc’s glow');
  }
  /* and it draws the phone's own outlined glyph: a circle with a plus in it */
  const d=play.querySelector('svg path').getAttribute('d');
  check(d.startsWith('M12 3.5a8.5 8.5 0 100 17'),'Play is not the phone’s outlined glyph: '+d.slice(0,26));
  check(getComputedStyle(play.querySelector('svg')).fill==='none','the glyph is filled, not outlined');

  /* the selected slot is marked the phone's way: a 26×2 rule in ink */
  const on=tabs.find(t=>t.classList.contains('active'));
  check(!!on,'no slot is selected');
  const rule=getComputedStyle(on,'::after');
  check(rule.width==='26px' && rule.height==='2px','the selected rule is not the phone’s 26×2: '+rule.width+'×'+rule.height);
  const ink=getComputedStyle(document.documentElement).getPropertyValue('--ink').trim();
  const toRgb=h=>{ const n=parseInt(h.slice(1),16); return `rgb(${n>>16&255}, ${n>>8&255}, ${n&255})`; };
  check(rule.backgroundColor===toRgb(ink),'the selected rule is not ink: '+rule.backgroundColor+' vs '+toRgb(ink));
  check(getComputedStyle(on).color===toRgb(ink),'the selected slot is not ink: '+getComputedStyle(on).color);
  out.selected=on.getAttribute('data-v');

  /* ORANGE IS NOT THE COLOUR OF ORDINARY NAVIGATION (owner board) */
  const ember=getComputedStyle(document.documentElement).getPropertyValue('--brand').trim();
  for(const t of tabs){
    const c=getComputedStyle(t).color;
    check(c!==toRgb(ember),'a slot is painted ember: '+t.getAttribute('data-v'));
  }
  /* Play carries the ACTION colour, flat */
  const act=getComputedStyle(document.documentElement).getPropertyValue('--act').trim();
  check(getComputedStyle(play).color===toRgb(act),'Play is not the action colour: '+getComputedStyle(play).color);
  out.playColour=getComputedStyle(play).color;

  /* every slot is a real target and the band does not overflow */
  for(const t of tabs){
    const r=t.getBoundingClientRect();
    check(r.height>=44-1,'a slot is under the tap target: '+t.getAttribute('data-v')+' '+Math.round(r.height));
    check(r.left>=-1 && r.right<=innerWidth+1,'a slot is off screen: '+t.getAttribute('data-v'));
  }
  check(bar.scrollWidth<=bar.clientWidth+1,'the band overflows sideways');
  /* and tapping one moves the selection */
  const compete=tabs.find(t=>t.getAttribute('data-v')==='compete');
  const realView=switchView; let went=null; switchView=v=>{ went=v; };
  try{ compete.click(); } finally { switchView=realView; }
  check(went==='compete','a slot did not route: '+went);
  out.passed=true; return out;
})()
