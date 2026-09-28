const {chromium}=require('/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const OUT='/Users/fischbeck3/cup-season-ten-gallery/approved';fs.mkdirSync(OUT,{recursive:true});
const profiles={door:{root:'/Users/fischbeck3/cup-season-ten-door',base:'http://127.0.0.1:8794'},home:{root:'/Users/fischbeck3/cup-season-ten-home',base:'http://127.0.0.1:8795'}};
const rows=[],tests=[],failure=[],logs=[];let browser;
const check=(v,m)=>{if(!v)throw Error(m)};
async function open(kind,width,height,theme){const cfg=profiles[kind],read=p=>fs.readFileSync(path.join(cfg.root,p),'utf8');const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:1,timezoneId:'America/Phoenix',colorScheme:theme,serviceWorkers:'block'});const page=await context.newPage();const messages=[];page.on('pageerror',e=>messages.push({kind:'exception',text:e.message}));page.on('console',m=>{if(['error','warning'].includes(m.type()))messages.push({kind:m.type(),text:m.text()})});await page.route('**/*',r=>{const u=r.request().url();if(u===cfg.base+'/')return r.fulfill({contentType:'text/html',body:read('index.html').replace('window._csShareRender = renderShareView;','window.__captureShowWelcome = showWelcome; window._csShareRender = renderShareView;')});if(/supabase\.co/.test(u))return r.abort();return r.continue()});await page.goto(cfg.base+'/',{waitUntil:'networkidle'});await page.waitForFunction(()=>window.sb&&window._csShareRender);await page.evaluate(async t=>{document.documentElement.dataset.theme=t;localStorage.setItem('cs_theme',t);await Promise.all((await navigator.serviceWorker.getRegistrations()).map(r=>r.unregister()));await Promise.all((await caches.keys()).map(k=>caches.delete(k)));await document.fonts.ready},theme);return{page,context,messages,cfg};}
async function fixture(page,cfg,id='event_live'){const data=JSON.parse(fs.readFileSync(path.join(cfg.root,'tests/fixtures/home-states.json'))).states.find(s=>s.id===id).payload;await page.evaluate(({payload,id})=>{window.qaEvent=()=>{};const chain=new Proxy(function(){},{get:(t,k)=>k==='then'?(res=>res({data:[],error:null})):chain,apply:()=>chain});window.sb.rpc=async n=>({data:null,error:{message:'No fixture for '+n}});window.sb.from=()=>chain;window.sb.channel=()=>chain;state.demo=false;window.CS.user={id:payload.me.profile.id};window.CS.profile=payload.me.profile;window.CS.memberships=[];window.CS.league=null;window.CS.members=[];window.CS.squads=[];window.homeFeedRows=[];window.homePosts=[];window.career=null;resetToBlank();window.__captureShowWelcome();window.csHomeState=id;},{payload:data,id});await page.waitForTimeout(650);await page.evaluate(async()=>{await loadHomeDispatch();renderHomeDispatch();renderHomeFeed();window.refreshWhoChip?.();renderMeStrip();renderOccasion();});}
async function capture(page,name,meta){const file=name+'.png';await page.screenshot({path:path.join(OUT,file),fullPage:true});rows.push({file,...meta,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(OUT,file))).digest('hex')});}
const metrics=()=>{const lum=s=>{const a=s.match(/[\d.]+/g).slice(0,3).map(Number).map(c=>{c/=255;return c<=.04045?c/12.92:((c+.055)/1.055)**2.4});return .2126*a[0]+.7152*a[1]+.0722*a[2]};const ratio=(a,b)=>{const x=lum(a),y=lum(b);return(Math.max(x,y)+.05)/(Math.min(x,y)+.05)};const box=document.querySelector('.hocc'),bg=getComputedStyle(box).backgroundColor;return{bg,heading:ratio(getComputedStyle(box.querySelector('h4')).color,bg),body:ratio(getComputedStyle(box.querySelector('p')).color,bg),action:ratio(getComputedStyle(box.querySelector('.ho-act')).color,bg),actionColor:getComputedStyle(box.querySelector('.ho-act')).color,act:getComputedStyle(document.documentElement).getPropertyValue('--act').trim(),overflow:Math.max(0,document.documentElement.scrollWidth-innerWidth)}};
(async()=>{
 browser=await chromium.launch({headless:true,executablePath:'/Users/fischbeck3/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell'});
 for(const stateId of ['brand_new','between_seasons','preseason','ceremony_night'])for(const width of[375,402,1280,1600])for(const theme of['dark','light']){
  const{page,context,cfg,messages}=await open('home',width,width<500?(width===375?667:874):1000,theme);
  try{
   await fixture(page,cfg,stateId);
   const evidence=await page.evaluate(metrics);
   check(evidence.heading>=4.5&&evidence.body>=4.5&&evidence.action>=4.5,'contrast');
   check(evidence.overflow===0,'horizontal overflow');
   await page.locator('.hocc .ho-act').scrollIntoViewIfNeeded();
   const reach=await page.locator('.hocc .ho-act').evaluate(e=>{const r=e.getBoundingClientRect();return{top:r.top,bottom:r.bottom,viewport:innerHeight,hit:e.contains(document.elementFromPoint(r.x+r.width/2,r.y+r.height/2))}});
   await capture(page,`home-state-${stateId}--${width}--${theme}`,{kind:'home',stateId,width,theme,evidence,reach,scope:'Existing safe dispatch/profile fixture; remaining read models empty. Native/authenticated path not exercised.'});
   logs.push({stateId,width,theme,messages});
  }catch(e){failure.push({stateId,width,theme,message:e.message})}finally{await context.close()}
 }
 await browser.close();
 fs.writeFileSync(path.join(OUT,'home-additional-states.json'),JSON.stringify({sourceSHA256:crypto.createHash('sha256').update(fs.readFileSync(path.join(profiles.home.root,'index.html'))).digest('hex'),rows,failure,logs},null,2));
 console.log(JSON.stringify({captures:rows.length,failures:failure,actionCovered:rows.filter(r=>!r.reach.hit).map(({stateId,width,theme})=>({stateId,width,theme}))}));
 process.exitCode=failure.length?1:0;
})().catch(async e=>{console.error(e);await browser?.close();process.exitCode=1});
