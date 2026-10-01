#!/usr/bin/env node
// Recipient doors: real public link -> email -> explicit consent; an existing
// season opens without another join. Every record is synthetic; no live writes.
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { join } from 'node:path'
import { homedir } from 'node:os'
const require=createRequire(import.meta.url)
const arg=(k,d)=>{const i=process.argv.indexOf('--'+k);return i<0?d:process.argv[i+1]}
const BASE=arg('base','http://127.0.0.1:8821'), OUT=arg('out',null), REF=arg('source-ref',null)
if(OUT)mkdirSync(OUT,{recursive:true})
const source=REF?execFileSync('git',['show',REF+':index.html'],{encoding:'utf8',maxBuffer:10*1024*1024}):null
const {chromium}=require(process.env.CS_PLAYWRIGHT||join(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright'))
const cache=join(homedir(),'Library/Caches/ms-playwright')
const executablePath=readdirSync(cache).filter(d=>d.startsWith('chromium_headless_shell')).sort().reverse().map(d=>join(cache,d,'chrome-headless-shell-mac-arm64/chrome-headless-shell')).find(existsSync)
const browser=await chromium.launch({headless:true,executablePath})
let passed=0,failed=0
const check=(name,ok,got)=>{console.log((ok?'PASS ':'FAIL ')+name+(ok?'':' '+JSON.stringify(got)));ok?passed++:failed++}
const TOKEN='fd400000-0000-4000-8000-000000000020'
for(const width of [375,402,1280])for(const theme of ['dark','light']){
  const ctx=await browser.newContext({viewport:{width,height:width<500?740:900},serviceWorkers:'block',reducedMotion:'reduce'})
  await ctx.addInitScript(t=>{if(!sessionStorage.getItem('recipient-test-init')){localStorage.clear();sessionStorage.setItem('recipient-test-init','1')}localStorage.setItem('cs_theme',t)},theme)
  // Clear only once per context: link storage must genuinely survive navigation.
  await ctx.clearCookies()
  const page=await ctx.newPage(), errors=[], writes=[]
  page.on('pageerror',e=>errors.push(e.message))
  let payload
  await page.route('**/*',async r=>{
    const url=new URL(r.request().url())
    if(source && url.origin===BASE && r.request().resourceType()==='document')return r.fulfill({contentType:'text/html',body:source})
    if(/supabase\.co$/.test(url.hostname)){
      const fn=url.pathname.split('/').at(-1)
      if(fn==='share_info')return r.fulfill({contentType:'application/json',body:JSON.stringify(payload)})
      if(url.pathname.includes('/rpc/'))writes.push(fn)
      return r.fulfill({contentType:'application/json',body:'null'})
    }
    return r.continue()
  })
  for(const kind of ['person','plan']){
    payload=kind==='person'?{kind,name:'Blake Fixture',marker:'weebridge',rounds_n:4}:
      {kind,host:'Blake Fixture',course:'Saguaro Flats',play_on:'2099-10-02',tee:'07:10',who_in:['Blake Fixture']}
    const q=kind==='person'?'p':'plan', key='cs_'+kind
    await page.goto(BASE+'/?'+q+'='+TOKEN)
    await page.waitForSelector('#shareView .sv-action')
    const primary=page.locator('#shareView .sv-action').first()
    const href=await primary.getAttribute('href'), text=await primary.innerText(), box=await primary.boundingBox()
    check(`${width} ${theme} ${kind}: direct sign-in with the same token`,href?.includes(q+'='+TOKEN)&&href.includes('signin=1')&&/Sign in/i.test(text),{href,text})
    check(`${width} ${theme} ${kind}: target is at least 44pt`,box?.height>=44,box)
    check(`${width} ${theme} ${kind}: installation remains available`,await page.locator('.sv-install[href="/get"]').count()===1)
    if(!href?.includes('signin=1'))continue // parent control: don't run its wrong journey.
    if(OUT)await page.screenshot({path:join(OUT,`${kind}-${width}-${theme}.png`)})
    await primary.click()
    await page.waitForSelector('#emailbox.open')
    check(`${width} ${theme} ${kind}: token survives email arrival`,await page.evaluate(k=>localStorage.getItem(k),key)===TOKEN)
    await page.reload(); await page.waitForSelector('#emailbox.open')
    check(`${width} ${theme} ${kind}: refresh keeps intent and the email door`,await page.evaluate(k=>localStorage.getItem(k),key)===TOKEN && await page.locator('#shareView').count()===0)
    const consent=await page.evaluate(async({key,TOKEN,kind})=>{
      localStorage.setItem(key,TOKEN); state.demo=false; CS.user={id:'c5000000-0000-4000-8000-000000000001'};
      CS.profile={display_name:'Casey Placeholder',marker:'weebridge'};
      const original=sb.rpc; window.__redeemed=0;
      sb.rpc=async(name)=> name==='redeem_share'?(window.__redeemed++,{data:{kind,result:'requested',seat:'in'},error:null}):original.call(sb,name,{p_token:TOKEN});
      window.__draining=window.redeemPendingShares(); return true;
    },{key,TOKEN,kind})
    await page.waitForSelector('#lnkYes')
    check(`${width} ${theme} ${kind}: no write before the deciding yes`,await page.evaluate(()=>window.__redeemed)===0)
    await page.locator('#lnkYes').click(); await page.evaluate(()=>window.__draining)
    check(`${width} ${theme} ${kind}: one confirmed redeem consumes the token`,await page.evaluate(k=>window.__redeemed===1&&!localStorage.getItem(k),key))
    // Reload before another kind so each journey starts with a real signed-out session.
  }
  await page.goto(BASE+'/?exit'); await page.waitForFunction(()=>window.CS&&window.sb)
  await page.waitForTimeout(500)
  await page.evaluate(()=>{
    state.demo=false;CS.user={id:'c5000000-0000-4000-8000-000000000001'};window.__open=[];window.__joins=0;
    window.__members=[{id:'m',role:'member',league:{id:'c5000000-0000-4000-8000-000000000100',code:'NGFX26',name:'North Grove (fixture)'}}];
    window.__failOpen=false;window.__failRead=false;
    sb.rpc=async(name)=>name==='join_covenant_info'?{data:{agreed:true,season_number:2},error:null}:(window.__joins++,{data:null,error:null});
    sb.from=()=>{const chain={select:()=>chain,eq:async()=>({data:window.__members,error:window.__failRead?{message:'No signal'}:null})};return chain};
    window.csOpenSeason=async id=>{window.__open.push(id);return !window.__failOpen};
  })
  for(const entry of ['door','welcome','sheet']){
    await page.evaluate(entry=>{
      localStorage.setItem('cs_code','NGFX26');localStorage.setItem('cs_code_name','North Grove (fixture)');window.__open=[];
      if(entry==='door'){document.getElementById('joinCode').value='ngfx26';document.getElementById('joinGo').click()}
      if(entry==='welcome'){document.getElementById('wCode').value='NGFX26';document.getElementById('wCodeGo').click()}
      if(entry==='sheet'){window.openJoinSheet();document.getElementById('jCode').value='NGFX26';document.getElementById('jGo').click()}
    },entry)
    await page.waitForTimeout(150)
    const got=await page.evaluate(()=>({open:window.__open,joins:window.__joins,code:localStorage.getItem('cs_code'),name:localStorage.getItem('cs_code_name')}))
    check(`${width} ${theme} ${entry}: already agreed opens the correct season and retires pending code`,got.open[0]==='c5000000-0000-4000-8000-000000000100'&&got.open.length===1&&got.joins===0&&got.code===null&&got.name===null,got)
  }
  for(const fail of ['read','open','missing']){
    await page.evaluate(fail=>{
      window.__failRead=fail==='read';window.__failOpen=fail==='open';if(fail==='missing')window.__members=[];
      localStorage.setItem('cs_code','NGFX26');document.getElementById('joinCode').value='NGFX26';document.getElementById('joinGo').click();
    },fail)
    await page.waitForTimeout(150)
    check(`${width} ${theme} ${fail}: failed navigation keeps the invitation; no join`,await page.evaluate(()=>localStorage.getItem('cs_code')==='NGFX26'&&window.__joins===0))
  }
  await page.evaluate(()=>{
    window.__failRead=false;window.__failOpen=false;
    window.__members=[{id:'m',role:'member',league:{id:'c5000000-0000-4000-8000-000000000100',code:'NGFX26',name:'North Grove (fixture)'}}];
    document.getElementById('joinGo').click();
  })
  await page.waitForTimeout(150)
  check(`${width} ${theme}: retry opens and consumes the kept invitation`,await page.evaluate(()=>!localStorage.getItem('cs_code')&&window.__joins===0))
  await page.evaluate(()=>{
    window.csOpenSeason=async id=>{window.__open.push(id);localStorage.setItem('cs_code','NEWONE');return true};
    localStorage.setItem('cs_code','NGFX26');document.getElementById('joinGo').click();
  })
  await page.waitForTimeout(150)
  check(`${width} ${theme}: a newer invitation is never consumed by an older read`,await page.evaluate(()=>localStorage.getItem('cs_code')==='NEWONE'))
  await page.evaluate(()=>{
    sb.rpc=async()=>({data:null,error:{message:'No signal'}});
    window.openJoinSheet();document.getElementById('jCode').value='NGFX26';document.getElementById('jGo').click();
  })
  await page.waitForTimeout(150)
  check(`${width} ${theme}: failed terms read leaves the sheet retry enabled`,await page.locator('#jGo').isEnabled())
  check(`${width} ${theme}: no unhandled exceptions`,errors.length===0,errors)
  check(`${width} ${theme}: no unconfirmed request, seat or join RPC`,writes.every(fn=>['door_flags','log_growth_event','my_schedule'].includes(fn)),writes)
  await ctx.close()
}
await browser.close()
console.log(`${passed} passed; ${failed} failed`);process.exitCode=failed?1:0
