const { chromium } = require('/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const assert=require('node:assert/strict'),fs=require('fs');
const out=require('node:path').join(__dirname,'captures');
(async()=>{const browser=await chromium.launch({headless:true,executablePath:'/Users/fischbeck3/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell'});const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:2});const errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.route('**/*',r=> r.request().url().includes('/shared/photo-fixture.jpg') ? r.fulfill({contentType:'image/png',body:fs.readFileSync(out+'/fixture-photo.png')}) : /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue());
await page.goto('http://127.0.0.1:8793',{waitUntil:'networkidle'});
await page.evaluate(async()=>{await Promise.all((await navigator.serviceWorker.getRegistrations()).map(r=>r.unregister()));await Promise.all((await caches.keys()).map(k=>caches.delete(k)));});
const base={kind:'round',name:'Alex Morgan',gross:84,pvi:2.4,course:'Encanto Golf Course',played_on:'2026-09-24',marker:'lonetree',holes:18,photo:false,points:9};
for(const [name,width,height,theme,patch] of [
 ['public-mobile-dark',390,844,'dark',{}],['public-mobile-light',390,844,'light',{}],
 ['public-desktop-dark',1440,1000,'dark',{}],['public-small-long',320,812,'light',{name:'Alexandra Montgomery-Williams',course:'The Championship Course at Whispering Pines',holes:9}],
 ['public-photo-mobile',390,844,'dark',{photo:true,token:'photo-fixture'}],['public-escaped-name',390,844,'light',{name:'<img src=x onerror=window.reviewInjected=true>',course:'Pines & Dunes <North>'}],['public-no-band',390,844,'dark',{pvi:null}],['public-broken-photo',390,844,'dark',{photo:true}]]){
 await page.setViewportSize({width,height});
 await page.evaluate(async({info,theme})=>{document.querySelector('#shareView')?.remove();document.documentElement.dataset.theme=theme;await window._csShareRender(info.token || 'fixture',info);await document.fonts.ready;},{info:{...base,...patch},theme});
 await page.waitForTimeout(150);
 const state=await page.locator('#shareView').evaluate(e=>({text:e.innerText,overflow:e.scrollWidth>e.clientWidth,photos:e.querySelectorAll('img.sv-photo').length,background:getComputedStyle(e).backgroundColor,mark:e.querySelector('svg')?.getAttribute('viewBox')}));
 assert.equal(state.overflow,false,name+' fits');assert.ok(!state.text.includes('PTS'),name+' no private points');assert.equal(state.mark,'0 0 1000 570');assert.equal(state.photos,patch.token ? 1 : 0,'photo follows consent and availability');assert.equal(await page.evaluate(()=>window.reviewInjected),undefined,'untrusted copy is text');
 assert.ok(await page.getByRole('link',{name:'Play with your people'}).isVisible());
 await page.screenshot({path:out+'/'+name+'.png'});console.log(name,state.background);
}
assert.deepEqual(errors,[]);await browser.close();console.log('Public page: 8 variants passed, no JavaScript errors.');})();
