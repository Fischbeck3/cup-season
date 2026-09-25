import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';

// Run the actual Edge handler against controlled Storage and RPC responses.
// No network calls: webhook payloads must never override the server's due queue.
const source=stripTypeScriptTypes(readFileSync(new URL('../supabase/functions/share-cleanup/index.ts',import.meta.url),'utf8')
  .replace("import { createClient } from 'npm:@supabase/supabase-js@2';",''));
function worker({due=[],expiryError=false,storageError=false,remaining=false,expireToken=null}={}){
  const calls=[],removed=[],reported=[];let handler;
  const sb={storage:{from:()=>({remove:async paths=>{removed.push(...paths);return {error:storageError?{message:'offline'}:null};}})},
    rpc:async(name,args)=>{
      calls.push(name);
      if(name==='_expire_share_attempts'){
        if(expireToken)due.push(expireToken);
        return {error:expiryError?{message:'unavailable'}:null};
      }
      if(name==='_share_cleanup_due')return {data:due};
      if(name==='_share_cleanup_report'){reported.push(args);return {data:remaining?'error':'completed'};}
      if(name==='_media_cleanup_due')return {data:[]};   // D395's queue: empty here, walked in edge-security-share-cleanup
      throw Error(name);
    }};
  vm.runInNewContext(source,{createClient:()=>sb,Response,console:{log:()=>{}},Deno:{env:{get:name=>name==='SHARE_CLEANUP_SECRET'?'test-secret':'local'},serve:fn=>{handler=fn;}}});
  return {calls,removed,reported,run:(body={},authorized=true)=>handler(new Request('http://localhost/cleanup',{
    method:'POST',headers:authorized?{'x-cleanup-secret':'test-secret'}:{},body:JSON.stringify(body)}))};
}
test('an error webhook cannot bypass backoff or recursively retry itself',async()=>{
  const w=worker();const r=await w.run({record:{token:'not-due',status:'error',next_attempt_at:'2099-01-01'}});
  assert.equal(r.status,200);assert.equal((await r.json()).processed,0);assert.deepEqual(w.removed,[]);
});
test('a stale completed webhook never deletes or reports that token again',async()=>{
  const w=worker();await w.run({record:{token:'done',status:'pending'}});assert.deepEqual(w.reported,[]);
});
test('a scheduled empty request expires abandoned shares and removes both copies',async()=>{
  const w=worker({expireToken:'expired'});const r=await w.run();
  assert.deepEqual(w.calls,['_expire_share_attempts','_share_cleanup_due','_share_cleanup_report','_media_cleanup_due']);
  assert.deepEqual(w.removed,['expired.jpg','expired.png']);assert.equal((await r.json()).completed,1);
});
test('Storage success cannot override the database finding a remaining copy',async()=>{
  const w=worker({due:['token'],remaining:true});const r=await w.run();assert.equal((await r.json()).failed,1);
});
test('Storage failure is reported for durable retry',async()=>{
  const w=worker({due:['token'],storageError:true,remaining:true});const r=await w.run();
  assert.equal((await r.json()).failed,1);assert.match(w.reported[0].p_error,/Storage API: offline/);
});
test('failed expiry cannot be reported as a healthy sweep',async()=>{
  const w=worker({expiryError:true});assert.equal((await w.run()).status,500);assert.deepEqual(w.removed,[]);
});
test('an unauthorized invocation never touches Storage or the database',async()=>{
  const w=worker();assert.equal((await w.run({},false)).status,401);assert.deepEqual(w.calls,[]);
});
