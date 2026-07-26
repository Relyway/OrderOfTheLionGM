const {spawnSync}=require('child_process');
const path=require('path');
const root=path.resolve(process.argv[2]||'.');
const validator=path.join(root,'Tools','validate.py');
const run=spawnSync('python3',[validator,root],{encoding:'utf8',stdio:'pipe'});
if(run.stdout) process.stdout.write(run.stdout);
if(run.stderr) process.stderr.write(run.stderr);
if(run.status!==0) process.exit(run.status||1);
console.log('RUNTIME_RELEASE_GATE_OK');
