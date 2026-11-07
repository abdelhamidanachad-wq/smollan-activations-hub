import React from 'react';
export default function ProjectSetupFields({value,setValue}){
 const set=(k,v)=>setValue(x=>({...x,[k]:v}));
 const select=(k,label,values)=><label className="field">{label}<select value={value[k]??''} onChange={e=>set(k,e.target.value)}>{values.map(v=><option key={v} value={v}>{v}</option>)}</select></label>;
 const text=(k,label,type='text')=><label className="field">{label}<input type={type} value={value[k]??''} onChange={e=>set(k,e.target.value)}/></label>;
 const area=(k,label)=><label className="field full">{label}<textarea rows={3} value={value[k]??''} onChange={e=>set(k,e.target.value)}/></label>;
 return <div className="project-setup-form">
 <section className="setup-section"><h3>01 · Project basics</h3><div className="form-grid">
 <label className="field full">Project name<input required value={value.name} onChange={e=>set('name',e.target.value)}/></label>
 <label className="field full">Client<input required value={value.client} onChange={e=>set('client',e.target.value)}/></label>
 {select('service_type','Service type',['activation','permanent_promoters','production_only','in_store_animation','merchandising'])}
 {select('cadence','Promoter workday pattern',['none','VSD','SD'])}
 {select('status','Project phase',['lead','brief_received','planning','in_progress','on_hold','completed','archived'])}
 {select('activation_type','Activation format',['In-store','Street','Roadshow','Event','Foodtruck','Sampling','Merchandising','Other'])}
 {text('start_date','Start date','date')}{text('end_date','End date','date')}</div></section>
 <section className="setup-section"><h3>02 · Promoters & payroll</h3><div className="form-grid">
 {select('promoters_required','Promoters required',['No','Yes'])}{text('promoter_count','Total promoter headcount','number')}
 {select('payroll_model','Payroll model',['Project salary','Custom per promoter','Mixed'])}{text('base_salary','Base salary (MAD)','number')}
 {area('allowances','Allowances / increments (transport, meal, medical test, documents)')}{area('staffing_plan','Promoter allocation by city / banner / store (one location per line; include headcount)')}{area('custom_payroll','Custom salary by promoter (name | base | transport | launch | medical | documents)')}</div></section>
 <section className="setup-section"><h3>03 · Tasting, PLV, goodies & uniforms</h3><div className="form-grid">
 {select('tasting_required','Tasting required',['No','Yes'])}{area('tasting_items','Tasting kit items')}
 {select('plv_required','PLV production required',['No','Yes'])}{area('plv_items','PLV types / quantities')}
 {select('bat_status','Artwork BAT status',['Pending','Confirmed','To redo','Not required'])}
 {select('goodies_required','Goodies required',['No','Yes'])}{area('goodies_items','Goodies / gifts items')}
 {select('uniforms_required','Uniforms required',['No','Yes'])}{area('uniform_details','Uniform details / sizes')}</div></section>
 <section className="setup-section"><h3>04 · Shopper engagement & triggers</h3><div className="form-grid">
 {select('tombola_enabled','Tombola',['No','Yes'])}{select('digital_game_enabled','Digital game',['No','Yes'])}
 {select('game_type','Game mechanic',['spin_wheel','scratch_card','quiz','instant_win'])}
 {select('survey_enabled','Survey enabled',['No','Yes'])}
 {select('survey_template','Survey template',['sampling-feedback','brand-awareness','store-execution','promoter-pulse','nps'])}
 <div className="trigger-grid"><strong>Automation triggers</strong>{[['trigger_on_create','On project creation'],['trigger_on_approval','On brief / scope confirmation'],['trigger_on_start','On activation start'],['trigger_on_end','On activation end']].map(([k,l])=><label key={k}><input type="checkbox" checked={!!value[k]} onChange={e=>set(k,e.target.checked)}/>{l}</label>)}</div>
 </div></section>
 <section className="setup-section"><h3>05 · Project identity</h3><div className="form-grid">
 {text('brand_primary_color','Primary brand color','color')}{text('brand_secondary_color','Secondary brand color','color')}
 {text('brand_logo_url','Logo URL','url')}{text('brand_background_url','Project background image URL','url')}
 </div></section></div>;
}
