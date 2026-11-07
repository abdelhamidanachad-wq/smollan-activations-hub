import { createClient } from '@supabase/supabase-js';

const definitions=[
 {type:'function',function:{name:'list_projects',description:'List current projects the signed-in user is allowed to see.',parameters:{type:'object',properties:{query:{type:'string',description:'Optional name or client filter'}},additionalProperties:false}}},
 {type:'function',function:{name:'create_task',description:'Create an operational task assigned to the signed-in user.',parameters:{type:'object',properties:{project_id:{type:'string'},title:{type:'string'},description:{type:'string'},due_at:{type:'string',description:'ISO 8601 date/time, optional'},priority:{type:'integer',enum:[1,2,3,4]}},required:['project_id','title'],additionalProperties:false}}},
 {type:'function',function:{name:'update_project',description:'Update an existing project status, dates or budget. Only change fields explicitly requested by the user.',parameters:{type:'object',properties:{project_id:{type:'string'},status:{type:'string',enum:['lead','brief_received','planning','in_progress','on_hold','completed','archived']},start_date:{type:'string'},end_date:{type:'string'},budget:{type:'number'}},required:['project_id'],additionalProperties:false}}},
 {type:'function',function:{name:'create_quotation',description:'Create a supplier or client quotation with line items for an existing project.',parameters:{type:'object',properties:{project_id:{type:'string'},quotation_scope:{type:'string',enum:['Supplier quotation received','Client quotation sent']},supplier_name:{type:'string'},quotation_number:{type:'string'},status:{type:'string',enum:['Draft','Requested','Received','Under comparison','Submitted','Sent to client','Approved','Rejected','Expired']},lines:{type:'array',items:{type:'object',properties:{description:{type:'string'},quantity:{type:'number'},unit_price:{type:'number'}},required:['description','quantity','unit_price'],additionalProperties:false}}},required:['project_id','quotation_scope','supplier_name','lines'],additionalProperties:false}}},
 {type:'function',function:{name:'get_project_report',description:'Fetch a grounded operational snapshot for one project including setup, tasks, attendance and quotations.',parameters:{type:'object',properties:{project_id:{type:'string'}},required:['project_id'],additionalProperties:false}}}
];
export default async function handler(req,res){
 if(req.method!=='POST'){res.setHeader('Allow','POST');return res.status(405).json({error:'Method not allowed'})}
 const openaiKey=process.env.OPENAI_API_KEY;
 const supabaseUrl=process.env.SUPABASE_URL||process.env.VITE_SUPABASE_URL;
 const anonKey=process.env.SUPABASE_ANON_KEY||process.env.VITE_SUPABASE_ANON_KEY;
 if(!openaiKey||!supabaseUrl||!anonKey)return res.status(503).json({error:'Assistant service is not configured. Set OPENAI_API_KEY, SUPABASE_URL and SUPABASE_ANON_KEY as server environment variables.'});
 const authorization=req.headers.authorization;
 if(!authorization?.startsWith('Bearer '))return res.status(401).json({error:'Sign in to use the operations assistant.'});
 const db=createClient(supabaseUrl,anonKey,{global:{headers:{Authorization:authorization}}});
 const {data:userData,error:userError}=await db.auth.getUser();
 if(userError||!userData?.user)return res.status(401).json({error:'Your session is invalid or expired.'});
 const {data:membership,error:memberError}=await db.from('smollan_memberships').select('role,is_active,display_name').eq('user_id',userData.user.id).maybeSingle();
 if(memberError||!membership?.is_active)return res.status(403).json({error:'An active SMOLLAN workspace membership is required.'});
 const message=String(req.body?.message||'').trim();
 if(!message)return res.status(400).json({error:'Message is required.'});
 const context=req.body?.context||{};
 const messages=[
  {role:'system',content:'You are the SMOLLAN Operations Copilot. Help the signed-in team member run the activation agency workspace. You may call tools to list projects, create tasks, update project status/dates/budget, create quotations, and prepare grounded project reports. Use the tools for live facts; never invent records, totals, suppliers, store coverage or approvals. Before a consequential change, confirm the user clearly asked for it in the current message. Do not change a project status to approved or completed unless explicitly requested. Do not expose personal promoter data, CIN, RIB, passwords, tokens or private HR records. Summarize every action taken and any action that failed. User role: '+membership.role+'. Signed-in user ID: '+userData.user.id+'. Current section: '+String(context.section||'Unknown')+'.'} ,
  {role:'user',content:message}
 ];
 const runTool=async(name,args)=>{
  if(name==='list_projects'){
   let q=db.from('smollan_projects').select('id,code,name,status,start_date,end_date,budget,currency,client_id').order('created_at',{ascending:false}).limit(100);
   if(args.query)q=q.ilike('name','%'+args.query+'%');
   const r=await q;if(r.error)throw r.error;return r.data;
  }
  if(name==='create_task'){
   const r=await db.from('smollan_tasks').insert({project_id:args.project_id,title:args.title,description:args.description||null,due_at:args.due_at||null,priority:args.priority||2,status:'todo',assigned_to:userData.user.id,created_by:userData.user.id}).select('id,title,project_id,status,due_at,priority').single();
   if(r.error)throw r.error;return r.data;
  }
  if(name==='update_project'){
   const patch={};for(const k of ['status','start_date','end_date','budget'])if(args[k]!==undefined)patch[k]=args[k];
   if(!Object.keys(patch).length)throw new Error('No project fields were supplied to update.');
   const r=await db.from('smollan_projects').update(patch).eq('id',args.project_id).select('id,code,name,status,start_date,end_date,budget').single();
   if(r.error)throw r.error;return r.data;
  }
  if(name==='create_quotation'){
   const project=await db.from('smollan_projects').select('id,client_id').eq('id',args.project_id).single();if(project.error)throw project.error;
   const lines=args.lines||[];if(!lines.length||lines.some(x=>!x.description||Number(x.quantity)<=0||Number(x.unit_price)<0))throw new Error('Quotation lines need a description, positive quantity and non-negative unit price.');
   const total=lines.reduce((s,x)=>s+Number(x.quantity)*Number(x.unit_price),0);
   const head=await db.from('smollan_quotations').insert({project_id:args.project_id,client_id:project.data.client_id,quotation_scope:args.quotation_scope,supplier_name:args.supplier_name,quotation_number:args.quotation_number||'AI-'+Date.now().toString().slice(-8),quotation_date:new Date().toISOString().slice(0,10),status:args.status||'Draft',total_amount:total,currency:'MAD',created_by:userData.user.id}).select('id,quotation_number,total_amount,status').single();
   if(head.error)throw head.error;
   const detail=await db.from('smollan_quotation_lines').insert(lines.map(x=>({quotation_id:head.data.id,description:x.description,quantity:Number(x.quantity),unit_price:Number(x.unit_price)})));
   if(detail.error)return {quotation:head.data,warning:'Header saved but line items failed: '+detail.error.message};
   return {quotation:head.data,line_count:lines.length};
  }
  if(name==='get_project_report'){
   const [p,t,a,q,c]=await Promise.all([
    db.from('smollan_projects').select('id,code,name,status,start_date,end_date,budget,currency,client_id').eq('id',args.project_id).single(),
    db.from('smollan_tasks').select('id,title,status,due_at,priority').eq('project_id',args.project_id).limit(200),
    db.from('smollan_attendance').select('id,status,attendance_date').eq('project_id',args.project_id).limit(500),
    db.from('smollan_quotations').select('quotation_number,supplier_name,status,total_amount,quotation_scope').eq('project_id',args.project_id).limit(100),
    db.from('smollan_activation_configs').select('activation_type,promoters_required,promoter_count,tasting_required,plv_required,goodies_required,digital_game_enabled,survey_enabled,bat_status').eq('project_id',args.project_id).maybeSingle()
   ]);
   for(const x of [p,t,a,q,c])if(x.error)throw x.error;
   return {project:p.data,activation_setup:c.data,tasks:{total:t.data.length,open:t.data.filter(x=>!['done','cancelled'].includes(x.status)).length,items:t.data},attendance:{records:a.data.length,items:a.data.slice(0,30)},quotations:q.data};
  }
  throw new Error('Unsupported assistant action.');
 };
 try{
  for(let step=0;step<5;step++){
   const response=await fetch('https://api.openai.com/v1/chat/completions',{method:'POST',headers:{Authorization:'Bearer '+openaiKey,'Content-Type':'application/json'},body:JSON.stringify({model:'gpt-4.1-mini',messages,tools:definitions,tool_choice:'auto',temperature:0.2})});
   const data=await response.json();if(!response.ok)throw new Error(data.error?.message||'OpenAI request failed');
   const choice=data.choices?.[0];if(!choice)throw new Error('The assistant returned no response.');
   messages.push(choice.message);
   if(choice.finish_reason!=='tool_calls')return res.status(200).json({reply:choice.message.content||'Done.',actions:messages.filter(m=>m.role==='tool').length});
   for(const call of choice.message.tool_calls||[]){
    let args={};try{args=JSON.parse(call.function.arguments||'{}')}catch{throw new Error('The assistant produced invalid action arguments.')}
    let result;try{result=await runTool(call.function.name,args)}catch(e){result={error:e.message||'Action failed'};}
    messages.push({role:'tool',tool_call_id:call.id,content:JSON.stringify(result)});
   }
  }
  return res.status(200).json({reply:'I completed the available actions, but the request needs another step. Please ask me to continue.'});
 }catch(e){return res.status(500).json({error:e.message||'Assistant service failed.'})}
}
