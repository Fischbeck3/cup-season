/* D339 I-3 · the interior pages carry the identity, quietly. Serve this
   checkout, open /?exit, evaluate with web-verify.mjs at 390, 320 and 1440. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={ width: innerWidth };
  window.csPaintTopoHeads();
  const heads=Array.from(document.querySelectorAll('.cmphead, .seasonhead'));
  check(heads.length>=2,'I-3: the interior heads are gone: '+heads.length);
  const withTopo=heads.filter(h=>h.querySelector(':scope > .cs-topohead'));
  check(withTopo.length===heads.length,'I-3: '+(heads.length-withTopo.length)+' of '+heads.length+' page heads carry no terrain');
  out.heads=heads.length;

  /* the same accepted geometry as the door — one source, not a second drawing */
  const door=document.querySelector('.ob-terrain .t-sur'), head=withTopo[0].querySelector('.t-sur');
  check(!!door && head.getAttribute('d')===door.getAttribute('d'),'I-3: the head draws different terrain from the door');
  const edge=withTopo[0].querySelector('.t-edge');
  check(!!edge && edge.getAttribute('d')===document.querySelector('.ob-terrain .t-edge').getAttribute('d'),'I-3: the head’s edges are not the accepted ones');

  /* restrained: quieter than the door, behind the type, and inert */
  const s=getComputedStyle(head), se=getComputedStyle(edge), box=getComputedStyle(withTopo[0].querySelector('.cs-topohead'));
  check(parseFloat(s.opacity)<=0.10 && parseFloat(se.opacity)<=0.20,'I-3: the interior terrain is not restrained: '+s.opacity+'/'+se.opacity);
  /* the door came DOWN to this same quiet end under the owner's 2026-09-14
     board, so the rule is no longer "quieter than the door" but "both at the
     quiet end" — sparse and fine everywhere, never behind reading. */
  check(parseFloat(s.opacity)<=parseFloat(getComputedStyle(document.querySelector('.ob-terrain .t-sur')).opacity)+.001,'I-3: the interior terrain is louder than the door’s');
  check(box.pointerEvents==='none','I-3: the terrain takes input');
  check(Number(box.zIndex)<0,'I-3: the terrain is not behind the page’s own name');
  out.alpha=[s.opacity, se.opacity];

  /* it is a HEAD treatment: never behind a table or a row of facts */
  for(const sel of ['#standings','#indTable','#cmpList','.peerrow','.tbl'])
    for(const el of document.querySelectorAll(sel))
      check(!el.querySelector('.cs-topohead'),'I-3: terrain was drawn inside '+sel+' — a contour over data');

  /* and painting twice does not draw twice */
  window.csPaintTopoHeads(); window.csPaintTopoHeads();
  check(withTopo[0].querySelectorAll(':scope > .cs-topohead').length===1,'I-3: a repaint stacked a second terrain');

  /* the name it sits behind is still the brightest thing in the head */
  const h2=document.querySelector('.cmphead h2');
  if(h2) check(getComputedStyle(h2).color!==s.color,'I-3: the head’s name took the terrain’s colour');
  check(document.documentElement.scrollWidth<=innerWidth,'the head overflows at this width');
  out.passed=true; return out;
})()
