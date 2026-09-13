"""Release wrapper only: fake build executables; no signing/archive/network."""
from pathlib import Path
import tempfile, subprocess, shutil, os
source=Path(__file__).resolve().parents[1]/'tools/ios-archive.sh'
with tempfile.TemporaryDirectory() as temp:
 r=Path(temp); (r/'tools').mkdir(); (r/'apps/ios').mkdir(parents=True); (r/'bin').mkdir()
 shutil.copy(source,r/'tools/ios-archive.sh')
 def run(*args): return subprocess.run(args,cwd=r,capture_output=True,text=True)
 run('git','init'); run('git','add','.'); run('git','-c','user.name=QA','-c','user.email=qa@example.invalid','commit','-m','fixture')
 (r/'bin/security').write_text('#!/bin/bash\nexit 1\n')
 (r/'bin/xcodegen').write_text('#!/bin/bash\nexit 0\n')
 (r/'bin/xcodebuild').write_text('''#!/bin/bash
if [[ "$EXPECT_API_AUTH" == yes && " $* " != *" -authenticationKeyPath "* ]]; then exit 43; fi
if [[ " $* " == *" -exportArchive "* ]]; then
  [[ "$FAIL_PHASE" == export ]] && exit 42
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == -exportPath ]]; then mkdir -p "$2"; touch "$2/CupSeason.ipa"; fi
    shift
  done
else
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == -archivePath ]]; then mkdir -p "$2"; fi
    shift
  done
  [[ "$FAIL_PHASE" == archive ]] && exit 41
fi
exit 0
''')
 for f in (r/'bin').iterdir(): f.chmod(0o755)
 # Fixtures are intentionally ignored by the fake checkout.
 (r/'.git/info/exclude').write_text('bin/\napps/ios/build/\n')
 env=dict(os.environ,PATH=str(r/'bin')+':'+os.environ['PATH'],ASC_KEY_ID='',ASC_ISSUER_ID='',ASC_KEY_PATH='')
 for phase,success in [('archive',False),('export',False),('',True)]:
  result=subprocess.run(['bash','tools/ios-archive.sh'],cwd=r,env=dict(env,FAIL_PHASE=phase),capture_output=True,text=True)
  assert (result.returncode==0)==success,(phase,result.stdout,result.stderr)
 # Existing credentials are passed to BOTH archive and export, with fake tools only.
 key=r/'bin/fixture.p8'; key.write_text('fixture, not a credential')
 result=subprocess.run(['bash','tools/ios-archive.sh'],cwd=r,
   env=dict(env,ASC_KEY_ID='fixture',ASC_ISSUER_ID='fixture',ASC_KEY_PATH=str(key),EXPECT_API_AUTH='yes'),
   capture_output=True,text=True)
 assert result.returncode==0,(result.stdout,result.stderr)
 (r/'unreviewed').write_text('dirty')
 result=subprocess.run(['bash','tools/ios-archive.sh'],cwd=r,env=env,capture_output=True,text=True)
 assert result.returncode!=0 and 'commit the working tree' in result.stdout
 print('PASS: failed archive, failed export, fresh output, dirty tree, authenticated archive/export; fake tools only')
