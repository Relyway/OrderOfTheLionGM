const fs=require('fs'),path=require('path'),luaparse=require('luaparse');
const root=process.argv[2]; let files=[]; function walk(p){for(const e of fs.readdirSync(p,{withFileTypes:true})){const f=path.join(p,e.name);if(e.isDirectory())walk(f);else if(f.endsWith('.lua'))files.push(f)}} walk(root);
let defs=new Map(), calls=new Map(), globals=new Map(), methods=new Map();
function add(map,k,v){if(!map.has(k))map.set(k,[]);map.get(k).push(v)}
function memberName(node){if(!node)return null;if(node.type==='MemberExpression'){const base=memberName(node.base)|| (node.base.type==='Identifier'?node.base.name:null); const id=node.identifier&&node.identifier.name; return base&&id?base+node.indexer+id:null;}return node.type==='Identifier'?node.name:null}
function visit(n,file){if(!n||typeof n!=='object')return;
 if(n.type==='FunctionDeclaration'){
   let name=memberName(n.identifier); if(name)add(defs,name,{file,loc:n.loc&&n.loc.start.line});
 }
 if(n.type==='CallExpression'||n.type==='TableCallExpression'||n.type==='StringCallExpression'){
   let name=memberName(n.base); if(name)add(calls,name,{file,loc:n.loc&&n.loc.start.line});
 }
 if(n.type==='CallExpression'&&n.base&&n.base.type==='MemberExpression'&&n.base.indexer===':') add(methods,n.base.identifier.name,{file,loc:n.loc&&n.loc.start.line});
 for(const [k,v] of Object.entries(n)){if(k==='loc'||k==='range')continue;if(Array.isArray(v))for(const x of v)visit(x,file);else if(v&&typeof v==='object')visit(v,file)}
}
for(const f of files){const ast=luaparse.parse(fs.readFileSync(f,'utf8'),{luaVersion:'5.1',locations:true,scope:true});visit(ast,path.relative(root,f));}
let dup=[...defs].filter(([k,v])=>v.length>1).sort((a,b)=>a[0].localeCompare(b[0]));
console.log('DUPLICATE DEFINITIONS',dup.length);for(const [k,v] of dup)console.log(k, v.map(x=>x.file+':'+x.loc).join(', '));
let otlDefs=new Set([...defs.keys()].filter(k=>k.startsWith('OTLGM:')||k.startsWith('OTLGM.')).map(k=>k.replace('OTLGM:','OTLGM.')));
let otlCalls=[];for(const [k,v] of calls){if(k.startsWith('OTLGM:')||k.startsWith('OTLGM.')){let norm=k.replace('OTLGM:','OTLGM.');if(!otlDefs.has(norm))otlCalls.push([k,v]);}}
console.log('\nUNRESOLVED OTLGM CALLS',otlCalls.length);for(const [k,v] of otlCalls.sort((a,b)=>a[0].localeCompare(b[0])))console.log(k,v.slice(0,5).map(x=>x.file+':'+x.loc).join(', '));
console.log('\nTOP FRAME METHODS');for(const [k,v] of [...methods].sort((a,b)=>b[1].length-a[1].length).slice(0,100))console.log(k,v.length);
