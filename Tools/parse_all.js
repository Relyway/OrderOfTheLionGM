const fs=require('fs'), path=require('path'), luaparse=require('luaparse');
const root=process.argv[2];
let files=[];
function walk(p){for(const ent of fs.readdirSync(p,{withFileTypes:true})){const f=path.join(p,ent.name);if(ent.isDirectory())walk(f);else if(f.endsWith('.lua'))files.push(f)}}
walk(root); let ok=0, bad=[];
for(const f of files){try{luaparse.parse(fs.readFileSync(f,'utf8'),{luaVersion:'5.1',locations:true,scope:true});ok++;}catch(e){bad.push({f,e:String(e)})}}
console.log(JSON.stringify({files:files.length,ok,bad},null,2)); process.exit(bad.length?1:0);
