import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders={
 'Access-Control-Allow-Origin':'*',
 'Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type',
 'Access-Control-Allow-Methods':'POST, OPTIONS',
 'Content-Type':'application/json'
};

Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:corsHeaders});
 if(req.method!=='POST')return new Response(JSON.stringify({error:'Method not allowed'}),{status:405,headers:corsHeaders});
 try{
  const body=await req.json();
  const slug=String(body.slug||'').trim();
  const fingerprint=String(body.fingerprint||'').trim();
  const phone=body.phone?String(body.phone).trim():null;
  const answers=body.answers&&typeof body.answers==='object'?body.answers:{};
  const consent=body.consent===true;
  if(!slug||fingerprint.length<16)return new Response(JSON.stringify({error:'Invalid game session.'}),{status:400,headers:corsHeaders});
  const url=Deno.env.get('SUPABASE_URL');
  const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if(!url||!serviceKey)return new Response(JSON.stringify({error:'Game service is not configured.'}),{status:503,headers:corsHeaders});
  const admin=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data,error}=await admin.rpc('smollan_play_digital_game',{p_slug:slug,p_fingerprint:fingerprint,p_phone:phone,p_answers:answers,p_consent:consent});
  if(error)return new Response(JSON.stringify({error:error.message}),{status:400,headers:corsHeaders});
  return new Response(JSON.stringify(data),{status:200,headers:corsHeaders});
 }catch(error){
  return new Response(JSON.stringify({error:error?.message||'Could not process this play.'}),{status:500,headers:corsHeaders});
 }
});
