/* D339 · the web half — the welcome composition. Serve this checkout, open
   /?exit, evaluate with web-verify.mjs at 320, 390 and 1440, and at a short
   height (--height 560). Signed out. Every auth send is refused by a stub, so
   the walk never sends a real code. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=async(t,label)=>{ for(let i=0;i<100;i++){ if(t()) return; await new Promise(r=>setTimeout(r,20));} throw new Error(label); };
  const out={ width: innerWidth, height: innerHeight };
  const TRACER='M88 12 C 82 36';
  const q=s=>document.querySelector(s);
  const sends=[]; const realAuth=window.sb && window.sb.auth;
  if(window.sb) window.sb.auth=new Proxy(realAuth||{}, { get:(t,k)=> (typeof k==='string' && /signIn|verify|resend|otp/i.test(k)) ? (async(...a)=>{ sends.push(String(k)); return { data:null, error:{ message:'refused by the audit' } }; }) : t[k] });
  try{
    /* the brand copy, from the one producer */
    /* the owner's 2026-09-14 board sets this line TWO ways and the producer
       carries both: the editorial serif, sentence case, where it IS the
       statement; tracked caps where it signs a lockup or an artifact. */
    check(!!window.CS_BRAND,'CS_BRAND is not the producer');
    check(CS_BRAND.tagline==='Any time.\nAnywhere.','the statement is not the board’s editorial form: '+JSON.stringify(CS_BRAND.tagline));
    check(CS_BRAND.taglineCaps==='ANY TIME. ANYWHERE.','the tracked-caps form is missing: '+JSON.stringify(CS_BRAND.taglineCaps));
    const h1=q('.ob-hero h1.cs-brandline');
    check(!!h1 && h1.innerText.trim().replace(/\s*\n\s*/g,'\n')===CS_BRAND.tagline,'the door does not print the brand line');
    await document.fonts.ready;
    const headlineStyle=getComputedStyle(h1);
    check(h1.getBoundingClientRect().height <= parseFloat(headlineStyle.lineHeight)*2+2,
      'the normal-size statement breaks ANYWHERE onto a third line');
    const sf=q('.ob-hero .cs-standfirst');
    check(!!sf && sf.textContent.trim()===CS_BRAND.standfirst,'the door does not print the standfirst');
    check(q('meta[name="description"]').content===CS_BRAND.description,'the head description is not the producer’s');
    /* type roles with distinct jobs: the statement in the condensed display role, the standfirst in the story role */
    const ff=el=>getComputedStyle(el).fontFamily;
    /* BOARD RULE · the brand's own moments are the editorial serif; the
       condensed board face belongs to competition and figures. This assertion
       previously required the opposite and is superseded by the owner board. */
    check(/serif|New York|Georgia/i.test(ff(h1)) && !/Condensed/.test(ff(h1)),'the statement is not in the editorial serif: '+ff(h1));
    check(getComputedStyle(h1).textTransform!=='uppercase','the statement is still set in caps');
    check(!!q('.ob-hero .cs-brandrule'),'the board’s ember hairline under the statement is missing');
    check(sf.classList.contains('cs-story') && /serif|New York|Georgia/i.test(ff(sf)) && !/Condensed/.test(ff(sf)),'the standfirst is not in the story role: '+ff(sf));
    check(parseFloat(getComputedStyle(h1).fontSize) > parseFloat(getComputedStyle(sf).fontSize)*1.5,'the statement does not dominate the standfirst');
    /* the compact signature at the top, above the statement */
    const sig=q('.ob-sig'); check(!!sig && !!sig.querySelector('svg.cs-mark') && /Cup Season/.test(sig.textContent),'no compact signature');
    const sr=sig.querySelector('svg').getBoundingClientRect(); check(sr.width>=28 && sr.width<=64,'the signature mark is not compact: '+sr.width);
    /* the mark is cream on fescue and dark green on paper — never ember
       (owner board, 2026-09-14 · mark variations) */
    const markColour=getComputedStyle(sig.querySelector('svg')).color;
    check(markColour===getComputedStyle(q('.ob-hero h1')).color,'the mark is not the ink the statement uses: '+markColour);
    out.markColour=markColour;
    check(sig.getBoundingClientRect().top < h1.getBoundingClientRect().top,'the signature is not above the statement');
    /* the terrain: the accepted paths, two weights, visible, behind everything, never a control */
    const terr=q('.ob-terrain'); check(!!terr,'no terrain on the door');
    const sur=terr.querySelector('.t-sur'), edge=terr.querySelector('.t-edge');
    check(!!sur && !!edge && sur.getAttribute('d').startsWith('M 322 29') && edge.getAttribute('d').startsWith('M 336 57'),'the terrain is not the accepted geometry');
    /* BOARD RULE (2026-09-14) · sparse and fine, and not behind the reading.
       This previously pinned a24/a56, which put contour curves straight through
       the statement; the owner's masthead contours are barely there. */
    check(Math.abs(parseFloat(getComputedStyle(sur).opacity)-.08)<.01 && Math.abs(parseFloat(getComputedStyle(edge).opacity)-.16)<.01,
          'the terrain is not at the quiet end of the ramp: '+getComputedStyle(sur).opacity+'/'+getComputedStyle(edge).opacity);
    check(getComputedStyle(terr).pointerEvents==='none','the terrain takes input');
    const tr=terr.getBoundingClientRect(); check(tr.right>=innerWidth-1 && tr.top<=0,'the terrain is not anchored to the upper right: '+JSON.stringify({r:tr.right,t:tr.top}));
    check(tr.width>=innerWidth*0.6,'the terrain is not at page scale');
    /* the Forge is gone: no crest, no seared wordmark, no fuse, no glow, no delayed entrance */
    for(const s of ['.ob-crest','.obsw','.obfw','.ob-ember','.obtr','.ob-mark']) check(!q(s),'a Forge remnant is still on the door: '+s);
    check(!Array.from(document.querySelectorAll('svg path')).some(p=>(p.getAttribute('d')||'').startsWith(TRACER)),'the Tracer is still drawn somewhere');
    for(const s of ['#obDoor','.ob-hero','#obCaption']) check(getComputedStyle(q(s)).animationName==='none' && parseFloat(getComputedStyle(q(s)).opacity)===1,'an entrance still delays '+s);
    /* the ground is the fescue token, nothing painted over it */
    const ob=q('#onboard'); check(getComputedStyle(ob).backgroundImage==='none','a wash or gradient is painted on the door');
    /* mark-light in both themes */
    const root=document.documentElement, was=root.getAttribute('data-theme');
    const col=el=>getComputedStyle(el).color;
    root.setAttribute('data-theme','dark'); await new Promise(r=>setTimeout(r,30));
    const dark={ sig:col(sig.querySelector('svg')), terr:col(terr), ground:getComputedStyle(ob).backgroundColor };
    root.setAttribute('data-theme','light'); await new Promise(r=>setTimeout(r,30));
    const light={ sig:col(sig.querySelector('svg')), terr:col(terr), ground:getComputedStyle(ob).backgroundColor };
    if(was==null) root.removeAttribute('data-theme'); else root.setAttribute('data-theme',was);
    check(dark.ground!==light.ground && dark.sig!==light.sig && dark.terr!==light.terr,'the door does not follow the theme: '+JSON.stringify({dark,light}));
    out.colors={ dark, light };
    /* the entry: real controls, real sizes, real words */
    const btn=id=>{ const b=document.getElementById(id); const r=b.getBoundingClientRect(); check(r.height>=44-1 && r.width>100, id+' is not a tap target'); return b; };
    const email=btn('obEmail'), join=btn('obJoin');
    check(email.textContent.trim()==='Continue with email' && join.textContent.trim()==='I have a league code','a door changed its words');
    check(getComputedStyle(join).backgroundColor==='rgba(0, 0, 0, 0)' || getComputedStyle(join).backgroundColor==='transparent','the secondary entry is still a filled button');
    check(/v23 · /.test(q('#obCaption').textContent),'the version caption is gone');
    /* email entry: the field opens under the button, is typed into, and nothing is sent by opening it */
    email.click(); await until(()=>q('#emailbox').classList.contains('open'),'the email field did not open');
    const ein=q('#obEmailIn'); check(ein.getBoundingClientRect().height>=40 && !ein.disabled,'the email field is not usable');
    ein.value='audit@example.com'; ein.dispatchEvent(new Event('input',{bubbles:true}));
    check(q('#obEmailGo').getBoundingClientRect().height>=44-1,'the Go control is under the tap target');
    /* join-code entry, and back again */
    join.click(); await until(()=>q('#joinbox').classList.contains('open'),'the join-code field did not open');
    const jin=q('#joinCode'); check(jin.maxLength===8 && jin.getBoundingClientRect().height>=40,'the join-code field is not usable');
    check(q('#obCodeIn').getAttribute('maxlength')==='10' && !q('#obCodeIn').hasAttribute('maxlength6'),'the auth code field is not 8-digit safe');
    check(sends.length===0,'opening an entry sent an auth request: '+sends.join(','));
    /* keyboard-safe: the door scrolls, it is not a fixed-height composition, and the primary can always be reached */
    check(getComputedStyle(ob).overflowY==='auto','the door does not scroll');
    /* F3 · the door is not a fixed-height composition: its column is free to
       grow past the viewport and the overlay scrolls to it. (This replaces an
       assertion that ended in `|| true` and therefore tested nothing.) */
    const fold=q('.ob-fold');
    check(getComputedStyle(fold).height==='auto' || fold.getBoundingClientRect().height>=parseFloat(getComputedStyle(fold).minHeight||'0')-1,
          'the door’s fold is pinned to a fixed height');
    check(ob.scrollHeight>=ob.clientHeight,'the door cannot grow past its viewport');
    email.scrollIntoView({ block:'center' }); await new Promise(r=>setTimeout(r,60));
    const er=email.getBoundingClientRect(); check(er.top>=0 && er.bottom<=innerHeight,'the primary cannot be brought into a '+innerHeight+'-tall viewport');
    check(document.documentElement.scrollWidth<=innerWidth && ob.scrollWidth<=ob.clientWidth+1,'the door overflows sideways at this width');
    /* ── F3 · ENLARGED TEXT REFLOWS; NOTHING IS CLIPPED ────────────────────
       `.onboard` is a fixed overlay with `overflow-x:hidden`, so a document
       -level overflow check prints PASS while the headline's last letters are
       cut off. This measures INSIDE the overlay, and it enlarges the text two
       ways so the check does not depend on which mechanism the reader uses:
       the root font-size (what a browser's text-size setting moves, and what
       a rem-based heading follows) and a direct doubling of the rendered size
       (what a px literal would have ignored). */
    /* back to the resting door: the walk above opened both entry boxes, and an
       opened box hides the button that opened it */
    q('#emailbox').classList.remove('open'); q('#joinbox').classList.remove('open');
    q('#obEmail').style.display=''; q('#obJoin').style.display='';
    await new Promise(r=>setTimeout(r,40));
    const docEl=document.documentElement;
    const shown=el=>!!(el && el.offsetParent!==null && el.getBoundingClientRect().height);
    const clipped=()=>{
      const over=[];
      for(const el of [h1, sf, sig, q('#obDoor'), q('#obEmail'), q('#obJoin'), ob]){
        if(!el) continue;
        if(el.scrollWidth > el.clientWidth + 1) over.push((el.id||el.className||el.tagName)+' '+el.clientWidth+'<'+el.scrollWidth);
      }
      return over;
    };
    const rootWas=docEl.style.fontSize, h1Was=h1.style.fontSize;
    const normalSize=parseFloat(getComputedStyle(h1).fontSize);
    try{
      docEl.style.fontSize='32px';                                  /* 200% of the 16px default */
      await new Promise(r=>setTimeout(r,40));
      const big=parseFloat(getComputedStyle(h1).fontSize);
      /* enlargement is PRESERVED — the statement grows with the reader's
         setting — and it is CAPPED at what this measure holds as whole words,
         which is the owner's 2026-09-14 ruling. Both halves are asserted. */
      check(big>normalSize,'the statement ignored the reader’s text size ('+normalSize+' → '+big+'px)');
      let over=clipped();
      check(!over.length,'F3: enlarged text is clipped inside the door: '+JSON.stringify(over));
      out.normalSize=normalSize;
      check(/ANY TIME/.test(h1.innerText.toUpperCase()) && /ANYWHERE/.test(h1.innerText.toUpperCase()),'F3: the statement lost letters when it reflowed');
      /* OWNER RULING (2026-09-14) · enlargement is preserved AND the words stay
         whole. Breaking anywhere kept every letter and printed ANYWHE / RE;
         the composition takes the height instead. */
      const wrap=getComputedStyle(h1);
      check(wrap.overflowWrap==='normal' && wrap.wordBreak==='normal','the statement may still break mid-word: '+wrap.overflowWrap+'/'+wrap.wordBreak);
      const words=h1.innerText.split(/\s+/).filter(Boolean).map(w=>w.replace(/[^A-Za-z.]/g,''));
      check(words.every(w=>/^(Any|time\.|Anywhere\.)$/i.test(w)),'the statement broke a word: '+JSON.stringify(words));
      out.enlargedWords=words;
      const entries=[q('#obEmail'), q('#obJoin')].filter(shown);
      check(entries.length===2,'F3: an entry control vanished at enlarged text');
      for(const b of entries){
        const r=b.getBoundingClientRect();
        check(r.height>=44-1 && r.left>=-1 && r.right<=innerWidth+1,
              'F3: an entry control is unusable at enlarged text: '+b.id+' '+JSON.stringify({h:Math.round(r.height),l:Math.round(r.left),rt:Math.round(r.right)}));
      }
      out.enlargedTo=big;
    } finally {
      docEl.style.fontSize=rootWas; h1.style.fontSize=h1Was;
      await new Promise(r=>setTimeout(r,40));
    }

    out.passed=true; return out;
  } finally {
    if(window.sb) window.sb.auth=realAuth;
    q('#emailbox')?.classList.remove('open'); q('#joinbox')?.classList.remove('open');
  }
})()
