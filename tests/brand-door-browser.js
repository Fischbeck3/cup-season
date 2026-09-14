/* D339 · the web half, I-1 — the door and both mastheads say what the phone
   says. Serve this checkout, open /?exit, evaluate with web-verify.mjs at 390,
   320 and 1440. Signed out; nothing is written. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={ width: innerWidth };
  const TRACER='M88 12 C 82 36';
  /* the brand copy, from the one producer */
  check(window.CS_BRAND && CS_BRAND.tagline==='ANY TIME.\nANYWHERE.','CS_BRAND is not the producer');
  const h1=document.querySelector('.ob-hero h1.cs-brandline');
  check(!!h1 && h1.innerText.trim().replace(/\s*\n\s*/g,'\n')===CS_BRAND.tagline,'the door does not print the brand line: '+JSON.stringify(h1&&h1.innerText));
  const sf=document.querySelector('.ob-hero .cs-standfirst');
  check(!!sf && sf.textContent.trim()===CS_BRAND.standfirst,'the door does not print the standfirst');
  check(document.querySelector('meta[name="description"]').content===CS_BRAND.description,'the head description is not the producer’s');
  /* the mark: the generated pennant, and the Tracer nowhere in the document */
  const door=document.querySelector('.ob-crest svg.cs-mark-door');
  check(!!door && door.getAttribute('viewBox')==='0 0 1000 570','the door has no pennant');
  const dr=door.getBoundingClientRect(); check(dr.width>80 && dr.height>40,'the door mark has no size');
  check(!document.querySelector('.ob-crest .obtr, .ob-crest .ob-mark'),'the forge is still on the door');
  check(!Array.from(document.querySelectorAll('svg path')).some(p=>(p.getAttribute('d')||'').startsWith(TRACER)),'the Tracer is still drawn somewhere in the document');
  check(!!document.querySelector('.brand .mk svg.cs-mark') && !!document.querySelector('#hdrLogo svg.hdrmark.cs-mark'),'a masthead lost the mark');
  /* the same paths in all three places — one generated source */
  const d=el=>Array.from(el.querySelectorAll('path')).map(p=>p.getAttribute('d')).join('|');
  check(d(door)===d(document.querySelector('.brand .mk svg')) && d(door)===d(document.querySelector('#hdrLogo svg')),'the three marks are not the same geometry');
  /* mark-light: ember on charcoal, ink on light, in every placement */
  const color=el=>getComputedStyle(el).color;
  const root=document.documentElement; const was=root.getAttribute('data-theme');
  root.setAttribute('data-theme','dark'); await new Promise(r=>setTimeout(r,30));
  const dark={ door:color(door), hdr:color(document.querySelector('#hdrLogo svg')), side:color(document.querySelector('.brand .mk')) };
  root.setAttribute('data-theme','light'); await new Promise(r=>setTimeout(r,30));
  const light={ door:color(door), hdr:color(document.querySelector('#hdrLogo svg')), side:color(document.querySelector('.brand .mk')) };
  if(was==null) root.removeAttribute('data-theme'); else root.setAttribute('data-theme',was);
  check(dark.door!==light.door && dark.hdr!==light.hdr,'the mark does not follow the mark-light rule: '+JSON.stringify({dark,light}));
  check(!/rgba\(0, 0, 0, 0\)|transparent/.test(dark.door+light.door),'the door mark has no colour');
  out.colors={ dark, light };
  /* the door's controls are untouched and reachable */
  for(const id of ['obEmail','obJoin']){ const b=document.getElementById(id); const r=b.getBoundingClientRect(); check(r.height>=44-1 && r.width>100,id+' is not a tap target'); }
  check(document.getElementById('obEmail').textContent.trim()==='Continue with email','the email door changed its words');
  check(document.getElementById('obJoin').textContent.trim()==='I have a league code','the code door changed its words');
  check(/v23 · /.test(document.getElementById('obCaption').textContent),'the version caption is gone');
  check(document.documentElement.scrollWidth<=innerWidth,'the door overflows at this width');
  out.passed=true; return out;
})()
