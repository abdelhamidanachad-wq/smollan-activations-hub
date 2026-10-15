import React, { useMemo, useRef, useState } from 'react';
import * as XLSX from 'xlsx';
import {
  Activity, ArrowDownRight, ArrowRight, ArrowUpRight, Bell, CalendarDays, Check,
  CheckCircle2, ChevronDown, ChevronRight, CircleDollarSign, ClipboardCheck, Clock3,
  Download, FileCheck2, FileSpreadsheet, FileText, Filter, FolderKanban, LayoutDashboard,
  Menu, MessageCircle, MoreHorizontal, Package, Plus, Search, Settings2, ShieldCheck,
  Smartphone, Sparkles, Truck, Users, WalletCards, X, Zap, Building2, Bot, Workflow,
  Send, WandSparkles, Play, Pause, Paperclip, Headphones, CircleHelp, Store, UserRound,
  ClipboardList, Gift, Boxes, CalendarClock, Upload, SlidersHorizontal, MapPin, BriefcaseBusiness
} from 'lucide-react';

const nav = [
  { label: 'WORKSPACE', items: [
    ['Overview', LayoutDashboard], ['Projects', FolderKanban], ['Tasks', ClipboardList], ['Calendar', CalendarDays]
  ]},
  { label: 'FIELD OPERATIONS', items: [
    ['Promoters', Users], ['Promoter Portal', Smartphone], ['Supervisors', UserRound], ['Stores', Store], ['Assignments', BriefcaseBusiness], ['Attendance', Clock3], ['Resource Requests', ClipboardCheck]
  ]},
  { label: 'RESOURCES', items: [
    ['Gifts & Goodies', Gift], ['PLV / POSM', Boxes], ['Clients', Building2]
  ]},
  { label: 'BUSINESS', items: [
    ['Finance', WalletCards], ['Excel Import', FileSpreadsheet]
  ]},
  { label: 'CONNECTED WORKSPACE', items: [
    ['AI Assistant', Bot], ['WhatsApp', MessageCircle], ['Automations', Workflow]
  ]},
  { label: 'ADMINISTRATION', items: [
    ['Super Admin', ShieldCheck]
  ]}
];

const seed = {
  Projects: [
    {code:'PRJ-2601',name:'SMART — Carrefour Casablanca',client:'Carrefour',type:'Permanent (SMART)',status:'Active',city:'Casablanca',start:'2026-01-01',end:'2026-12-31',budget:480000,stores:18,promoters:34,supervisor:'Youssef Amrani'},
    {code:'PRJ-2602',name:'Summer Beauty Activation',client:'L’Oréal',type:'Temporary (Activation)',status:'Planning',city:'Rabat',start:'2026-06-01',end:'2026-08-31',budget:185000,stores:12,promoters:24,supervisor:'Salma Idrissi'},
    {code:'PRJ-2603',name:'Back to School — Marjane',client:'Marjane',type:'Temporary (Activation)',status:'Active',city:'Marrakech',start:'2026-09-01',end:'2026-10-31',budget:265000,stores:9,promoters:18,supervisor:'Hamza El Fassi'},
    {code:'PRJ-2604',name:'Samsung Experience Zones',client:'Samsung',type:'Permanent (SMART)',status:'On Hold',city:'Tangier',start:'2026-03-01',end:'2026-12-31',budget:320000,stores:8,promoters:16,supervisor:'Nadia Bennis'}
  ],
  Promoters: [
    {cin:'BK123456',name:'Sara El Mansouri',phone:'+212 6 12 34 56 78',email:'sara.demo@example.com',city:'Casablanca',contract:'Permanent',status:'Assigned',uniform:'M',project:'PRJ-2601',pec:'Valid',device:'Tablet',rating:'4.8'},
    {cin:'CD234567',name:'Omar Benali',phone:'+212 6 22 45 67 89',email:'omar.demo@example.com',city:'Rabat',contract:'Activation',status:'Available',uniform:'L',project:'—',pec:'Pending',device:'Phone',rating:'4.5'},
    {cin:'EF345678',name:'Imane Alaoui',phone:'+212 6 33 56 78 90',email:'imane.demo@example.com',city:'Marrakech',contract:'Freelance',status:'Assigned',uniform:'S',project:'PRJ-2603',pec:'Valid',device:'Phone',rating:'4.7'},
    {cin:'GH456789',name:'Mehdi Tazi',phone:'+212 6 44 67 89 01',email:'mehdi.demo@example.com',city:'Tangier',contract:'Permanent',status:'On Leave',uniform:'XL',project:'PRJ-2604',pec:'Expiring',device:'Tablet',rating:'4.3'}
  ],
  Supervisors: [
    {name:'Youssef Amrani',email:'youssef.demo@example.com',phone:'+212 6 11 22 33 44',city:'Casablanca',zone:'Centre',status:'Active',projects:2,stores:14},
    {name:'Salma Idrissi',email:'salma.demo@example.com',phone:'+212 6 22 33 44 55',city:'Rabat',zone:'Nord-Ouest',status:'Active',projects:1,stores:12},
    {name:'Hamza El Fassi',email:'hamza.demo@example.com',phone:'+212 6 33 44 55 66',city:'Marrakech',zone:'Sud',status:'Active',projects:1,stores:9}
  ],
  Stores: [
    {code:'CAS-001',name:'Carrefour Sidi Maarouf',city:'Casablanca',banner:'Carrefour',format:'Hypermarket',address:'Sidi Maarouf',status:'Active',projects:'PRJ-2601',supervisor:'Youssef Amrani'},
    {code:'RBT-004',name:'Marjane Hay Riad',city:'Rabat',banner:'Marjane',format:'Hypermarket',address:'Hay Riad',status:'Active',projects:'PRJ-2602',supervisor:'Salma Idrissi'},
    {code:'MRK-002',name:'Marjane Menara',city:'Marrakech',banner:'Marjane',format:'Hypermarket',address:'Route de Casablanca',status:'Active',projects:'PRJ-2603',supervisor:'Hamza El Fassi'},
    {code:'TNG-003',name:'Electroplanet City Center',city:'Tangier',banner:'Electroplanet',format:'Electronics',address:'City Center',status:'Inactive',projects:'PRJ-2604',supervisor:'Nadia Bennis'}
  ],
  Assignments: [
    {id:'ASN-1001',promoter:'Sara El Mansouri',cin:'BK123456',project:'PRJ-2601',store:'CAS-001',supervisor:'Youssef Amrani',start:'2026-01-01',end:'2026-12-31',status:'Active'},
    {id:'ASN-1002',promoter:'Imane Alaoui',cin:'EF345678',project:'PRJ-2603',store:'MRK-002',supervisor:'Hamza El Fassi',start:'2026-09-01',end:'2026-10-31',status:'Active'},
    {id:'ASN-1003',promoter:'Mehdi Tazi',cin:'GH456789',project:'PRJ-2604',store:'TNG-003',supervisor:'Nadia Bennis',start:'2026-03-01',end:'2026-12-31',status:'Completed'}
  ],
  Attendance: [
    {date:'2026-10-15',promoter:'Sara El Mansouri',project:'PRJ-2601',store:'CAS-001',checkin:'08:57',checkout:'17:02',status:'Present',source:'Supervisor App',validation:'Validated'},
    {date:'2026-10-15',promoter:'Imane Alaoui',project:'PRJ-2603',store:'MRK-002',checkin:'09:18',checkout:'—',status:'Late',source:'Portal',validation:'Pending'},
    {date:'2026-10-15',promoter:'Omar Benali',project:'PRJ-2602',store:'RBT-004',checkin:'—',checkout:'—',status:'Absent',source:'Manual',validation:'Pending'}
  ],
  'Resource Requests': [
    {id:'REQ-0201',type:'PEC',promoter:'Omar Benali',project:'PRJ-2602',store:'RBT-004',requester:'Salma Idrissi',date:'2026-10-14',status:'Pending',decision:'Awaiting coordinator'},
    {id:'REQ-0202',type:'Tablet',promoter:'Sara El Mansouri',project:'PRJ-2601',store:'CAS-001',requester:'Youssef Amrani',date:'2026-10-12',status:'Approved',decision:'Approved by coordinator'},
    {id:'REQ-0203',type:'Uniform',promoter:'Imane Alaoui',project:'PRJ-2603',store:'MRK-002',requester:'Hamza El Fassi',date:'2026-10-11',status:'Rejected',decision:'Incorrect size — resubmit'}
  ],
  'Gifts & Goodies': [
    {name:'L’Oréal Sample Kit',category:'Samples',project:'PRJ-2602',total:1200,allocated:900,distributed:642,unitValue:38,status:'In progress'},
    {name:'School Starter Pack',category:'Gift pack',project:'PRJ-2603',total:800,allocated:600,distributed:418,unitValue:65,status:'In progress'},
    {name:'Samsung Tote Bag',category:'Merchandise',project:'PRJ-2604',total:500,allocated:250,distributed:201,unitValue:22,status:'On hold'}
  ],
  'PLV / POSM': [
    {name:'Beauty Counter Display',type:'Display',project:'PRJ-2602',quantity:24,unitCost:2200,production:'In production',deadline:'2026-10-24',installed:12,status:'In progress'},
    {name:'Back to School Endcap',type:'Endcap',project:'PRJ-2603',quantity:18,unitCost:1850,production:'Ready to dispatch',deadline:'2026-10-18',installed:7,status:'In progress'},
    {name:'Samsung Demo Stand',type:'Demo stand',project:'PRJ-2604',quantity:8,unitCost:7800,production:'On hold',deadline:'2026-11-01',installed:2,status:'On hold'}
  ],
  Tasks: [
    {title:'Validate attendance for 15 Oct',project:'PRJ-2601',assignee:'Youssef Amrani',priority:'High',due:'2026-10-16',status:'In Progress'},
    {title:'Approve PEC request for Omar',project:'PRJ-2602',assignee:'Coordinator',priority:'Urgent',due:'2026-10-16',status:'To Do'},
    {title:'Confirm POSM delivery window',project:'PRJ-2603',assignee:'Hamza El Fassi',priority:'Medium',due:'2026-10-17',status:'To Do'},
    {title:'Reconcile gift stock count',project:'PRJ-2604',assignee:'Finance',priority:'Low',due:'2026-10-20',status:'Done'}
  ],
  Finance: [
    {project:'PRJ-2601',category:'Promoter payroll',budget:210000,actual:178500,funding:'Client',status:'On track'},
    {project:'PRJ-2602',category:'Production & POSM',budget:65000,actual:28400,funding:'Client',status:'On track'},
    {project:'PRJ-2603',category:'Gifts & goodies',budget:52000,actual:59700,funding:'Client',status:'Over budget'},
    {project:'PRJ-2604',category:'Activation operations',budget:85000,actual:42600,funding:'Client',status:'On track'}
  ],
  Clients: [
    {name:'Carrefour',industry:'Retail',contact:'Demo contact',email:'client.demo@example.com',phone:'—',status:'Active',projects:1},
    {name:'L’Oréal',industry:'Beauty & FMCG',contact:'Demo contact',email:'client.demo@example.com',phone:'—',status:'Active',projects:1},
    {name:'Marjane',industry:'Retail',contact:'Demo contact',email:'client.demo@example.com',phone:'—',status:'Active',projects:1},
    {name:'Samsung',industry:'Electronics',contact:'Demo contact',email:'client.demo@example.com',phone:'—',status:'On Hold',projects:1}
  ]
};

const roles = ['Admin','Coordinator','Field Manager','Supervisor','HR Coordinator','Finance','Promoter'];
const money = n => new Intl.NumberFormat('fr-MA',{style:'currency',currency:'MAD',maximumFractionDigits:0}).format(n||0);
const Status = ({value}) => <span className={'status status-'+String(value||'').toLowerCase().replace(/[^a-z]+/g,'-')}>{value}</span>;
const initials = name => String(name||'SM').split(' ').map(x=>x[0]).slice(0,2).join('').toUpperCase();

function App(){
  const [active,setActive]=useState('Overview');
  const [data,setData]=useState(seed);
  const [role,setRole]=useState('Admin');
  const [query,setQuery]=useState('');
  const [modal,setModal]=useState(null);
  const [selectedProject,setSelectedProject]=useState(null);
  const [mobileOpen,setMobileOpen]=useState(false);
  const [toast,setToast]=useState('');
  const [importRows,setImportRows]=useState([]);
  const [importHeaders,setImportHeaders]=useState([]);
  const [importSheet,setImportSheet]=useState('');
  const [importMap,setImportMap]=useState({});
  const [importMode,setImportMode]=useState('create-only');
  const [importResult,setImportResult]=useState(null);
  const [assistantInput,setAssistantInput]=useState('');
  const [assistantMessages,setAssistantMessages]=useState([{from:'assistant',text:'Bonjour ! I can help you plan today’s field operations, review project risks, or prepare a client follow-up. This is a demo assistant; no external AI provider is connected.'}]);
  const [waText,setWaText]=useState('');
  const [waConversation,setWaConversation]=useState('field');
  const [waMessages,setWaMessages]=useState([{from:'them',text:'Morning team — store setup is complete at CAS-001.'},{from:'me',text:'Thanks. Please upload the opening photo when ready.'}]);
  const fileRef=useRef(null);

  const visibleNav=useMemo(()=>nav.map(g=>({...g,items:g.items.filter(([name])=>{
    if(role==='Promoter') return ['Promoter Portal'].includes(name);
    if(role==='Finance') return ['Overview','Projects','Tasks','Finance','Clients','Super Admin'].includes(name);
    if(role==='HR Coordinator') return ['Overview','Promoters','Attendance','Resource Requests','Tasks'].includes(name);
    if(role==='Supervisor') return ['Overview','Projects','Promoters','Stores','Assignments','Attendance','Resource Requests','Tasks','Gifts & Goodies','PLV / POSM'].includes(name);
    return true;
  })})).filter(g=>g.items.length),[role]);

  const showToast = msg => {setToast(msg); setTimeout(()=>setToast(''),2800);};
  const currentRows = data[active] || [];
  const filteredRows = currentRows.filter(row=>Object.values(row).some(v=>String(v??'').toLowerCase().includes(query.toLowerCase())));
  const totalBudget = data.Projects.reduce((a,p)=>a+p.budget,0);
  const activeProjects = data.Projects.filter(p=>p.status==='Active').length;
  const pendingRequests = data['Resource Requests'].filter(r=>r.status==='Pending').length;
  const pendingAttendance = data.Attendance.filter(a=>a.validation==='Pending').length;

  const updateRow=(module,index,patch)=>setData(prev=>({...prev,[module]:prev[module].map((r,i)=>i===index?{...r,...patch}:r)}));
  const addRow=(module,row)=>{setData(prev=>({...prev,[module]:[row,...(prev[module]||[])]}));setModal(null);showToast('Record added to this demo session');};
  const handleFile=async file=>{
    if(!file)return;
    try{
      const buffer=await file.arrayBuffer();
      const wb=XLSX.read(buffer,{type:'array',cellDates:true});
      const sheet=wb.SheetNames[0];
      const rows=XLSX.utils.sheet_to_json(wb.Sheets[sheet],{defval:'',raw:false});
      const headers=rows.length?Object.keys(rows[0]):(wb.Sheets[sheet]?Object.keys(XLSX.utils.sheet_to_json(wb.Sheets[sheet],{header:1})[0]||[]):[]);
      setImportSheet(sheet);setImportRows(rows);setImportHeaders(headers);
      const fields=['code','name','client','type','status','city','start','end','budget','cin','phone','email','contract','uniform','project','store','supervisor','date','checkin','checkout','category','quantity','amount'];
      const map={};headers.forEach(h=>{const key=h.toLowerCase().replace(/[^a-z]/g,'');const match=fields.find(f=>key===f||key.includes(f));if(match)map[h]=match;});
      setImportMap(map);setImportResult(null);showToast('Worksheet loaded for preview');
    }catch(e){showToast('Could not read this workbook. Please check the file format.');}
  };
  const runImport=()=>{
    const mapped=importRows.map(row=>Object.fromEntries(Object.entries(importMap).filter(([,field])=>field).map(([header,field])=>[field,row[header]])));
    const mappedFields=Object.values(importMap);
    const module=mappedFields.includes('cin')?'Promoters':mappedFields.includes('store')?'Stores':mappedFields.includes('date')?'Attendance':mappedFields.includes('category')?'Finance':'Projects';
    const required=module==='Promoters'?'cin':module==='Stores'?'code':module==='Attendance'?'date':'code';
    const seen=new Set();let valid=0,invalid=0,duplicates=0;
    const good=[];
    mapped.forEach((row,i)=>{const key=String(row[required]||'').trim().toLowerCase();if(!key){invalid++;return;}if(seen.has(key)){duplicates++;return;}seen.add(key);valid++;good.push({...row,_sourceRow:i+2});});
    if(importMode==='create-only'){
      const existing=new Set((data[module]||[]).map(r=>String(r[required]||'').toLowerCase()));
      const fresh=good.filter(r=>!existing.has(String(r[required]).toLowerCase()));
      duplicates+=good.length-fresh.length;
      setImportResult({module,valid:fresh.length,invalid,duplicates,rows:fresh});
    }else setImportResult({module,valid,invalid,duplicates,rows:good});
  };
  const confirmImport=()=>{
    if(!importResult?.rows?.length)return;
    const rows=importResult.rows.map(r=>{const out={...r};delete out._sourceRow;return out;});
    setData(prev=>({...prev,[importResult.module]:[...rows,...(prev[importResult.module]||[])]}));
    showToast(importResult.rows.length+' rows added to demo session');
    setImportResult({...importResult,done:true});
  };
  const sendAssistant=()=>{
    if(!assistantInput.trim())return;
    const prompt=assistantInput.trim();
    const answer=/attendance|absence|présence/i.test(prompt)?'Suggested next steps: review the pending attendance validations, compare today’s check-ins against active assignments, then route ambiguous records to the field manager. No records have been changed.':/budget|finance|cost/i.test(prompt)?'Start with PRJ-2603: its illustrative actuals exceed the category budget. Confirm the source records and approvals before treating this as a financial exception.':/project|priorit|today/i.test(prompt)?'Suggested priorities: (1) resolve pending resource requests, (2) validate attendance, (3) confirm the POSM delivery deadline, and (4) review gift distribution variances. These are suggestions based on sample data.':'I can help structure that task. Tell me the project, owner, deadline and desired outcome, and I’ll draft a checklist. This demo does not call a live AI model.';
    setAssistantMessages(prev=>[...prev,{from:'user',text:prompt},{from:'assistant',text:answer}]);setAssistantInput('');
  };

  const renderOverview=()=> <div className="page-content">
    <div className="welcome-row"><div><div className="eyebrow">THURSDAY, 15 OCTOBER 2026</div><h1>Good morning, team <span>✳</span></h1><p className="subheading">Here’s the operational picture across your projects today.</p></div><button className="btn primary" onClick={()=>setModal({type:'create',module:'Projects'})}><Plus size={16}/> New project</button></div>
    <div className="metric-grid">
      <Metric icon={FolderKanban} label="Active projects" value={activeProjects} note="Across current activations" trend="+2 this month" />
      <Metric icon={Users} label="Assigned promoters" value={data.Promoters.filter(p=>p.status==='Assigned').length} note="In illustrative sample data" trend="Field coverage" />
      <Metric icon={Clock3} label="Attendance to review" value={pendingAttendance} note="Records awaiting validation" trend="Needs attention" warn />
      <Metric icon={ClipboardCheck} label="Pending requests" value={pendingRequests} note="Coordinator decisions needed" trend="Open approvals" />
    </div>
    <div className="dashboard-grid">
      <section className="panel project-panel"><div className="panel-head"><div><h2>Project portfolio</h2><p>Track status, coverage and budget</p></div><button className="text-action" onClick={()=>setActive('Projects')}>View all <ArrowRight size={15}/></button></div>
        <div className="project-list">{data.Projects.slice(0,4).map(p=><button className="project-row" key={p.code} onClick={()=>setSelectedProject(p)}><div className="project-mark">{p.client.slice(0,1)}</div><div className="project-info"><strong>{p.name}</strong><span>{p.client} · {p.city} · {p.promoters} promoters</span><div className="progress"><i style={{width:(p.status==='Active'?'72%':p.status==='Planning'?'28%':p.status==='On Hold'?'42%':'100%')}}/></div></div><div className="project-meta"><Status value={p.status}/><b>{money(p.budget)}</b></div><ChevronRight size={16} className="row-chevron"/></button>)}</div>
      </section>
      <section className="panel attention-panel"><div className="panel-head"><div><h2>Needs your attention</h2><p>Items requiring a decision</p></div><span className="count-badge">{pendingRequests+pendingAttendance}</span></div>
        <div className="attention-list"><button onClick={()=>setActive('Resource Requests')} className="attention-item"><span className="attention-icon amber"><ClipboardCheck size={18}/></span><span><strong>{pendingRequests} resource request pending</strong><small>Coordinator review required</small></span><ChevronRight size={16}/></button><button onClick={()=>setActive('Attendance')} className="attention-item"><span className="attention-icon blue"><Clock3 size={18}/></span><span><strong>{pendingAttendance} attendance records</strong><small>Validation pending for today</small></span><ChevronRight size={16}/></button><button onClick={()=>setActive('Finance')} className="attention-item"><span className="attention-icon rose"><CircleDollarSign size={18}/></span><span><strong>Budget variance to review</strong><small>PRJ-2603 sample actuals over plan</small></span><ChevronRight size={16}/></button></div>
      </section>
      <section className="panel"><div className="panel-head"><div><h2>Today in the field</h2><p>Attendance snapshot · sample records</p></div><button className="icon-button" onClick={()=>setActive('Attendance')}><ArrowRight size={16}/></button></div><div className="attendance-summary"><div><span className="summary-number">{data.Attendance.filter(a=>a.status==='Present').length}</span><span>Present</span></div><div><span className="summary-number">{data.Attendance.filter(a=>a.status==='Late').length}</span><span>Late</span></div><div><span className="summary-number">{data.Attendance.filter(a=>a.status==='Absent').length}</span><span>Absent</span></div></div><div className="mini-list">{data.Attendance.slice(0,3).map((a,i)=><div className="mini-row" key={i}><Avatar name={a.promoter}/><span><strong>{a.promoter}</strong><small>{a.store} · {a.checkin}</small></span><Status value={a.status}/></div>)}</div></section>
      <section className="panel"><div className="panel-head"><div><h2>Upcoming tasks</h2><p>Next operational deadlines</p></div><button className="text-action" onClick={()=>setActive('Tasks')}>View tasks <ArrowRight size={15}/></button></div><div className="task-list">{data.Tasks.filter(t=>t.status!=='Done').slice(0,4).map((t,i)=><div className="task-row" key={i}><button className={'task-check '+(t.status==='Done'?'checked':'')} onClick={()=>updateRow('Tasks',data.Tasks.indexOf(t),{status:t.status==='Done'?'To Do':'Done'})}>{t.status==='Done'&&<Check size={13}/>}</button><div className="task-copy"><strong>{t.title}</strong><small>{t.project} · Due {t.due}</small></div><Status value={t.priority}/></div>)}</div></section>
    </div>
    <div className="footnote"><ShieldCheck size={15}/> Demo workspace · All names, metrics and records shown here are illustrative. Changes stay in this browser session.</div>
  </div>;

  const columns={
    Projects:[['code','Project ID'],['name','Project'],['client','Client'],['type','Type'],['city','City'],['status','Status'],['budget','Budget']],
    Promoters:[['cin','CIN'],['name','Promoter'],['phone','Phone'],['city','City'],['contract','Contract'],['project','Project'],['status','Status'],['pec','PEC']],
    Supervisors:[['name','Supervisor'],['email','Email'],['phone','Phone'],['city','City'],['zone','Zone'],['projects','Projects'],['status','Status']],
    Stores:[['code','Store code'],['name','Store'],['city','City'],['banner','Banner'],['format','Format'],['supervisor','Supervisor'],['status','Status']],
    Assignments:[['id','Assignment'],['promoter','Promoter'],['project','Project'],['store','Store'],['supervisor','Supervisor'],['start','Start date'],['end','End date'],['status','Status']],
    Attendance:[['date','Date'],['promoter','Promoter'],['project','Project'],['store','Store'],['checkin','Check-in'],['checkout','Check-out'],['status','Status'],['validation','Validation']],
    'Resource Requests':[['id','Request'],['type','Type'],['promoter','Promoter'],['project','Project'],['store','Store'],['requester','Requested by'],['date','Date'],['status','Status'],['decision','Decision']],
    'Gifts & Goodies':[['name','Item'],['category','Category'],['project','Project'],['total','Total qty'],['allocated','Allocated'],['distributed','Distributed'],['unitValue','Unit value'],['status','Status']],
    'PLV / POSM':[['name','Material'],['type','Type'],['project','Project'],['quantity','Qty'],['production','Production'],['deadline','Deadline'],['installed','Installed'],['status','Status']],
    Tasks:[['title','Task'],['project','Project'],['assignee','Assignee'],['priority','Priority'],['due','Due date'],['status','Status']],
    Finance:[['project','Project'],['category','Category'],['budget','Budget'],['actual','Actual'],['funding','Funding source'],['status','Status']],
    Clients:[['name','Client'],['industry','Industry'],['contact','Contact'],['email','Email'],['phone','Phone'],['projects','Projects'],['status','Status']]
  };
  const formatCell=(key,value)=>key==='budget'||key==='actual'||key==='unitValue'?money(value):key==='total'||key==='allocated'||key==='distributed'||key==='quantity'||key==='installed'?Number(value||0).toLocaleString('fr-MA'):key==='status'||key==='validation'||key==='priority'||key==='pec'?<Status value={value}/>:value??'—';
  const renderTable=module=>{
    const cols=columns[module]||[];
    return <div className="page-content"><div className="page-heading"><div><div className="eyebrow">OPERATIONS / {module.toUpperCase()}</div><h1>{module}</h1><p className="subheading">{module==='Projects'?'Your project-centric operational portfolio.':module==='Promoters'?'Promoter profiles, contracts, status and project links.':module==='Attendance'?'Daily attendance records and validation queue.':module==='Finance'?'Budget versus actuals by project and cost category.':'Manage records and navigate related operational data.'}</p></div><div className="heading-actions"><button className="btn secondary" onClick={()=>setQuery('')}><Filter size={15}/> Reset filters</button><button className="btn primary" onClick={()=>setModal({type:'create',module})}><Plus size={16}/> Add {module==='Projects'?'project':module==='Promoters'?'promoter':'record'}</button></div></div>
      {module==='Projects'&&<div className="metric-grid compact"><Metric icon={FolderKanban} label="Total projects" value={data.Projects.length} note="Across all statuses"/><Metric icon={Activity} label="Active" value={data.Projects.filter(p=>p.status==='Active').length} note="Currently running"/><Metric icon={CircleDollarSign} label="Portfolio budget" value={money(totalBudget)} note="Illustrative MAD budget"/><Metric icon={Users} label="Promoter capacity" value={data.Projects.reduce((a,p)=>a+p.promoters,0)} note="Planned assignments"/></div>}
      <div className="panel table-panel"><div className="table-toolbar"><div className="searchbox"><Search size={16}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder={'Search '+module.toLowerCase()+'…'}/>{query&&<button onClick={()=>setQuery('')}><X size={14}/></button>}</div><div className="toolbar-right"><span>{filteredRows.length} records</span><button className="icon-button" onClick={()=>showToast('Export is available after selecting a format in a future integration.')}><Download size={16}/></button><button className="icon-button" onClick={()=>setModal({type:'create',module})}><Plus size={16}/></button></div></div>
      <div className="table-scroll"><table><thead><tr>{cols.map(([key,label])=><th key={key}>{label}</th>)}<th></th></tr></thead><tbody>{filteredRows.map((row,i)=><tr key={i} onClick={()=>module==='Projects'&&setSelectedProject(row)} className={module==='Projects'?'clickable':''}>{cols.map(([key])=><td key={key}>{formatCell(key,key==='budget'||key==='actual'||key==='unitValue'?row[key]:row[key])}</td>)}<td><button className="icon-button row-menu" onClick={e=>{e.stopPropagation();setModal({type:'edit',module,row,index:data[module].indexOf(row)});}}><MoreHorizontal size={17}/></button></td></tr>)}</tbody></table></div>
      {filteredRows.length===0&&<div className="empty-state"><Search size={26}/><strong>No matching records</strong><span>Try a different search or add a record.</span></div>}</div><div className="footnote"><ShieldCheck size={15}/> Sample data only · Record changes are local to this demo session until live persistence is implemented.</div></div>;
  };

  const renderImport=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">DATA MANAGEMENT</div><h1>Excel workbook import</h1><p className="subheading">Preview, map and validate worksheet data before adding records.</p></div></div><div className="import-layout"><section className="panel import-main"><div className="panel-head"><div><h2>1. Upload workbook</h2><p>Excel .xlsx/.xls or CSV · source identifiers are preserved</p></div><FileSpreadsheet size={20}/></div><div className="upload-zone" onClick={()=>fileRef.current?.click()}><input ref={fileRef} type="file" accept=".xlsx,.xls,.csv" hidden onChange={e=>handleFile(e.target.files?.[0])}/><span className="upload-icon"><Upload size={23}/></span><strong>Choose a workbook to preview</strong><span>Click to select a file from your computer</span><button className="btn secondary"><Upload size={15}/> Select file</button></div>
      {importHeaders.length>0&&<><div className="import-section-head"><div><h3>2. Map columns</h3><p>Worksheet: <b>{importSheet}</b> · {importRows.length} data rows</p></div><select value={importMode} onChange={e=>setImportMode(e.target.value)}><option value="create-only">Create only — don't overwrite</option><option value="review-updates">Review mapped rows</option></select></div><div className="mapping-list">{importHeaders.map(h=><div className="mapping-row" key={h}><span title={h}>{h}</span><ArrowRight size={15}/><select value={importMap[h]||''} onChange={e=>setImportMap(prev=>({...prev,[h]:e.target.value}))}><option value="">Unmapped — ignore</option>{['code','name','client','type','status','city','start','end','budget','cin','phone','email','contract','uniform','project','store','supervisor','date','checkin','checkout','category','quantity','amount'].map(f=><option key={f} value={f}>{f}</option>)}</select></div>)}</div><div className="import-section-head"><div><h3>3. Preview and validate</h3><p>Required keys depend on the target entity. Ambiguous relationships need manual resolution.</p></div><button className="btn primary" onClick={runImport}><ClipboardCheck size={15}/> Validate preview</button></div><div className="table-scroll preview-table"><table><thead><tr>{importHeaders.slice(0,6).map(h=><th key={h}>{h}</th>)}</tr></thead><tbody>{importRows.slice(0,5).map((r,i)=><tr key={i}>{importHeaders.slice(0,6).map(h=><td key={h}>{String(r[h]??'')}</td>)}</tr>)}</tbody></table></div></>}
      {importResult&&!importResult.done&&<div className="validation-result"><h3>Validation summary · {importResult.module}</h3><div className="validation-stats"><div><b>{importResult.valid}</b><span>Rows ready</span></div><div><b>{importResult.invalid}</b><span>Missing key</span></div><div><b>{importResult.duplicates}</b><span>Duplicate/existing</span></div></div><p>Import only adds rows to the local demo session. No Supabase records are written by this preview.</p><button className="btn primary" disabled={!importResult.valid} onClick={confirmImport}><Check size={15}/> Confirm demo import</button></div>}
      {importResult?.done&&<div className="success-banner"><CheckCircle2 size={18}/> Added {importResult.valid} rows to this demo session. Nothing was written to Supabase.</div>}
    </section><aside className="panel import-guidance"><h2>Import safeguards</h2>{[['Preserve source IDs','Keep CIN, store codes and project codes as supplied.'],['Preview before write','See sample rows and map every column deliberately.'],['No silent overwrites','Create-only mode skips keys already present.'],['Resolve ambiguity','Do not infer a project/store/person match from names alone.'],['Reconcile results','Production import must return row-level success and error reports.']].map(([t,d])=><div className="guidance-row" key={t}><CheckCircle2 size={17}/><div><strong>{t}</strong><p>{d}</p></div></div>)}<div className="notice"><ShieldCheck size={17}/><span>Current import writes to temporary UI state only. A production importer needs authenticated server-side writes, transaction handling and audit events.</span></div></aside></div></div>;

  const renderAssistant=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">CONNECTED WORKSPACE</div><h1>AI Assistant</h1><p className="subheading">Operational copilot for planning, field coordination and follow-ups.</p></div><span className="demo-pill"><Sparkles size={14}/> Demo mode</span></div><div className="assistant-layout"><div className="assistant-main panel"><div className="assistant-top"><span className="assistant-avatar"><Bot size={21}/></span><div><strong>Smollan Copilot</strong><small>Operational support · no live AI provider connected</small></div><span className="online-dot"/> </div><div className="chat-messages">{assistantMessages.map((m,i)=><div className={'chat-message '+m.from} key={i}><div className="chat-avatar">{m.from==='assistant'?<Sparkles size={15}/>:<UserRound size={15}/>}</div><div className="chat-bubble">{m.text}</div></div>)}</div><div className="prompt-chips">{['Summarize today’s priorities','Review attendance risks','Draft client follow-up'].map(p=><button key={p} onClick={()=>{setAssistantInput(p);}}>{p}</button>)}</div><form className="chat-compose" onSubmit={e=>{e.preventDefault();sendAssistant();}}><input value={assistantInput} onChange={e=>setAssistantInput(e.target.value)} placeholder="Ask about projects, field operations, or next steps…"/><button className="btn primary" type="submit"><Send size={15}/> Send</button></form></div><aside className="panel assistant-side"><h3>What I can help with</h3>{[['Daily priorities','Turn operational status into a clear action list.'],['Field checklist','Draft store visit and activation checklists.'],['Client follow-up','Prepare a message for human review.'],['Task planning','Break a goal into owners and deadlines.']].map(([t,d])=><div className="capability" key={t}><span><WandSparkles size={16}/></span><div><strong>{t}</strong><p>{d}</p></div></div>)}<div className="notice"><ShieldCheck size={17}/><span>Do not paste CINs, bank details, identity documents or other sensitive personal information.</span></div></aside></div></div>;

  const renderWhatsApp=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">CONNECTED WORKSPACE</div><h1>WhatsApp workspace</h1><p className="subheading">Conversation triage for field teams, clients and suppliers.</p></div><span className="demo-pill"><MessageCircle size={14}/> Local demo inbox</span></div><div className="whatsapp-layout panel"><div className="conversation-list"><div className="conversation-search"><Search size={15}/><input placeholder="Search conversations"/></div>{[['field','Field operations','CAS-001 setup is complete','09:42'],['client','Client — L’Oréal','Can you confirm delivery timing?','09:18'],['supplier','POSM supplier','Dispatch planned for Friday','Yesterday'],['hr','HR coordination','PEC documents ready for review','Yesterday']].map(([id,name,last,time])=><button className={'conversation-item '+(waConversation===id?'selected':'')} key={id} onClick={()=>{setWaConversation(id);setWaMessages([{from:'them',text:last},{from:'me',text:'Thanks — we will review and confirm shortly.'}]);}}><Avatar name={name}/><span><strong>{name}</strong><small>{last}</small></span><time>{time}</time></button>)}</div><div className="conversation-thread"><div className="thread-header"><Avatar name={waConversation==='field'?'Field operations':waConversation==='client'?'L’Oréal':waConversation==='supplier'?'POSM supplier':'HR coordination'}/><div><strong>{waConversation==='field'?'Field operations':waConversation==='client'?'Client — L’Oréal':waConversation==='supplier'?'POSM supplier':'HR coordination'}</strong><small>Mock conversation · not connected to WhatsApp Business</small></div><button className="icon-button"><MoreHorizontal size={18}/></button></div><div className="thread-messages">{waMessages.map((m,i)=><div className={'wa-bubble '+m.from} key={i}>{m.text}<small>Demo · {m.from==='me'?'You':'Contact'}</small></div>)}</div><form className="wa-compose" onSubmit={e=>{e.preventDefault();if(waText.trim()){setWaMessages(p=>[...p,{from:'me',text:waText.trim()}]);setWaText('');showToast('Added to local demo thread — not sent');}}}><button type="button" className="icon-button"><Paperclip size={17}/></button><input value={waText} onChange={e=>setWaText(e.target.value)} placeholder="Write a demo message…"/><button className="btn primary" type="submit"><Send size={15}/></button></form><div className="thread-warning">Demo only — messages are not sent to WhatsApp.</div></div></div></div>;

  const renderAutomations=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">CONNECTED WORKSPACE</div><h1>Automations</h1><p className="subheading">Define operational triggers and review workflow readiness.</p></div><button className="btn primary" onClick={()=>setModal({type:'automation'})}><Plus size={16}/> New automation</button></div><div className="notice wide-notice"><Zap size={17}/><span>These are draft workflow definitions. Switches only change this demo screen; no messages, approvals or scheduled jobs execute.</span></div><div className="automation-grid">{[{name:'Attendance reminder',desc:'Notify supervisors when expected check-ins are missing.',trigger:'09:30 every workday',icon:Clock3,enabled:true},{name:'Resource request routing',desc:'Route new PEC, MDM, uniform and tablet requests to coordinators.',trigger:'When request is submitted',icon:ClipboardCheck,enabled:true},{name:'Dispatch checklist',desc:'Create a store checklist before each POSM/gift dispatch.',trigger:'Before dispatch date',icon:Truck,enabled:false},{name:'PO & invoice follow-up',desc:'Flag overdue supplier paperwork for Finance review.',trigger:'Daily · 10:00',icon:FileCheck2,enabled:false},{name:'WhatsApp daily summary',desc:'Prepare a digest of field updates for the operations lead.',trigger:'18:00 every workday',icon:MessageCircle,enabled:false},{name:'Post-activation report',desc:'Collect attendance, distribution and expense metrics after close.',trigger:'When project is completed',icon:FileText,enabled:false}].map((a,i)=><AutomationCard key={a.name} item={a} onToggle={()=>showToast('Demo automation setting changed; no workflow executed.')} onEdit={()=>setModal({type:'editAutomation',item:a})}/>)}</div></div>;

  const renderSuperAdmin=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">ADMINISTRATION</div><h1>Super Admin</h1><p className="subheading">Integration readiness, access governance and system configuration.</p></div><span className="demo-pill"><ShieldCheck size={14}/> Not connected</span></div><div className="admin-banner"><ShieldCheck size={21}/><div><strong>Integration setup is not complete</strong><p>This console is a readiness checklist, not a live credential manager. Do not paste secrets here.</p></div></div><div className="admin-grid">{[{name:'Supabase',desc:'Database, Auth and Row Level Security',status:'Schema initialized',icon:Activity,items:['Project: SMOLLAN','Region: eu-west-1','5 core tables with RLS enabled']},{name:'Google Workspace SSO',desc:'Verified identity and @smollan.com access',status:'Not configured',icon:ShieldCheck,items:['Enable Google OAuth provider','Verify email_verified and exact domain server-side','Require active membership']},{name:'Drive & Calendar',desc:'Project documents and operational schedules',status:'Not connected',icon:FolderKanban,items:['OAuth scopes need review','Store file references, not public links','Restrict access by project role']},{name:'WhatsApp Business',desc:'Official messaging integration',status:'Not connected',icon:MessageCircle,items:['Business account and webhook','Template approval and opt-in','Server-side token storage']},{name:'AI provider',desc:'Secure server-side assistant requests',status:'Demo responses only',icon:Bot,items:['Configure server-side provider key','Apply sensitive-data safeguards','Log usage and errors']},{name:'Automations',desc:'Scheduled and event-driven workflows',status:'Draft only',icon:Workflow,items:['Choose trusted execution service','Define retries and idempotency','Audit each action'] }].map((it,i)=><div className="admin-card" key={it.name}><div className="admin-card-head"><span className="admin-icon"><it.icon size={19}/></span><span className="admin-state">{it.status}</span></div><h3>{it.name}</h3><p>{it.desc}</p><ul>{it.items.map(x=><li key={x}>{x}</li>)}</ul><button className="btn secondary full" onClick={()=>showToast('Setup checklist only — no credentials stored.')}>Review setup <ArrowRight size={15}/></button></div>)}</div><div className="footnote"><ShieldCheck size={15}/> Never trust navigation hiding for authorization. Enforce roles and record-level access on the server/database.</div></div>;

  const renderCalendar=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">WORKSPACE</div><h1>Calendar</h1><p className="subheading">Upcoming project dates, tasks and field checkpoints.</p></div><button className="btn primary" onClick={()=>setModal({type:'create',module:'Tasks'})}><Plus size={16}/> Add task</button></div><div className="panel calendar-panel"><div className="calendar-head"><h2>October 2026</h2><span>Sample schedule · local demo</span></div>{[['15','Today','Attendance validation · PRJ-2601','09:00','blue'],['16','Tomorrow','PEC request review · PRJ-2602','11:00','amber'],['17','Saturday','POSM delivery window · PRJ-2603','14:00','purple'],['20','Tuesday','Gift stock reconciliation · PRJ-2604','10:30','green'],['24','Saturday','Beauty counter deadline · PRJ-2602','16:00','rose']].map(([day,tag,title,time,color])=><div className="calendar-event" key={day}><div className="calendar-date"><strong>{day}</strong><small>OCT</small></div><div className={'event-dot '+color}/><div className="event-copy"><span>{tag}</span><strong>{title}</strong></div><time>{time}</time></div>)}</div></div>;

  const renderPortal=()=> <div className="page-content"><div className="page-heading"><div><div className="eyebrow">PROMOTER SELF-SERVICE</div><h1>My field portal</h1><p className="subheading">A focused view of your assignment, attendance and requests.</p></div><span className="demo-pill">Demo profile</span></div><div className="portal-grid"><div className="panel portal-assignment"><div className="panel-head"><div><h2>My active assignment</h2><p>Example promoter profile · not signed in</p></div><Status value="Active"/></div><h3>SMART — Carrefour Casablanca</h3><div className="portal-details"><span><Store size={16}/> Carrefour Sidi Maarouf</span><span><MapPin size={16}/> Casablanca</span><span><UserRound size={16}/> Youssef Amrani</span><span><CalendarDays size={16}/> Permanent · VSD</span></div><div className="clock-actions"><button className="btn primary" onClick={()=>showToast('Demo clock-in recorded locally only.')}><Clock3 size={16}/> Clock in</button><button className="btn secondary" onClick={()=>showToast('Demo clock-out recorded locally only.')}><CheckCircle2 size={16}/> Clock out</button></div><p className="muted-small">Clock actions are disabled from live attendance systems in this demo.</p></div><div className="panel"><div className="panel-head"><div><h2>My requests</h2><p>Status of submitted resources</p></div></div>{data['Resource Requests'].slice(0,3).map(r=><div className="mini-row" key={r.id}><span className="request-icon"><Package size={17}/></span><span><strong>{r.type}</strong><small>{r.project} · {r.date}</small></span><Status value={r.status}/></div>)}</div><div className="panel"><h2>Attendance summary</h2><div className="attendance-summary"><div><span className="summary-number">18</span><span>Present days</span></div><div><span className="summary-number">1</span><span>Late</span></div><div><span className="summary-number">0</span><span>Pending</span></div></div><p className="muted-small">Illustrative summary only.</p></div><div className="panel"><h2>My compliance</h2>{[['PEC contract','Valid'],['IT policy / MDM','Pending'],['Uniform','Issued'],['Tablet','Requested']].map(([t,s])=><div className="compliance-row" key={t}><span>{t}</span><Status value={s}/></div>)}</div></div></div>;

  const renderContent=()=>{
    if(active==='Overview')return renderOverview();
    if(active==='Excel Import')return renderImport();
    if(active==='AI Assistant')return renderAssistant();
    if(active==='WhatsApp')return renderWhatsApp();
    if(active==='Automations')return renderAutomations();
    if(active==='Super Admin')return renderSuperAdmin();
    if(active==='Calendar')return renderCalendar();
    if(active==='Promoter Portal')return renderPortal();
    if(data[active])return renderTable(active);
    return <div className="page-content"><div className="page-heading"><div><div className="eyebrow">WORKSPACE</div><h1>{active}</h1><p className="subheading">Operational records and project-linked workflows.</p></div></div><div className="panel empty-state"><FolderKanban size={28}/><strong>{active} workspace</strong><span>This module is planned in the product blueprint. Connect its entity and role rules before entering production data.</span><button className="btn secondary" onClick={()=>setActive('Projects')}>Back to projects</button></div></div>;
  };

  return <div className="app-shell">
    <aside className={'sidebar '+(mobileOpen?'open':'')}><div className="brand"><div className="brand-mark">S<span>.</span></div><div><strong>SMOLLAN</strong><small>MOROCCO · OPERATIONS</small></div><button className="sidebar-close" onClick={()=>setMobileOpen(false)}><X size={18}/></button></div><div className="workspace-switch"><div className="workspace-avatar">M</div><div><strong>Morocco Operations</strong><small>Workspace</small></div><ChevronDown size={15}/></div><div className="nav-scroll">{visibleNav.map(group=><div className="nav-group" key={group.label}><div className="nav-label">{group.label}</div>{group.items.map(([name,Icon])=><button key={name} className={'nav-item '+(active===name?'active':'')} onClick={()=>{setActive(name);setQuery('');setMobileOpen(false);}}><Icon size={17}/><span>{name}</span>{name==='Resource Requests'&&pendingRequests>0&&<i className="nav-count">{pendingRequests}</i>}</button>)}</div>)}</div><div className="sidebar-bottom"><div className="support-card"><span><Headphones size={16}/></span><div><strong>Need a hand?</strong><small>Help & documentation</small></div><ChevronRight size={14}/></div><div className="profile-row"><div className="profile-avatar">AD</div><div className="profile-copy"><strong>Admin Demo</strong><small>Workspace preview</small></div><button className="icon-button"><MoreHorizontal size={18}/></button></div></div></aside>
    {mobileOpen&&<div className="mobile-backdrop" onClick={()=>setMobileOpen(false)}/>}
    <main className="main-area"><header className="topbar"><div className="topbar-left"><button className="mobile-menu" onClick={()=>setMobileOpen(true)}><Menu size={20}/></button><div className="breadcrumb">Workspace <ChevronRight size={14}/><strong>{active}</strong></div></div><div className="topbar-right"><div className="global-search"><Search size={15}/><input value={query} onChange={e=>setQuery(e.target.value)} onKeyDown={e=>e.key==='Enter'&&showToast('Search applied to the current module.')} placeholder="Search anything…"/><kbd>⌘ K</kbd></div><button className="icon-button notification" onClick={()=>setActive('Resource Requests')}><Bell size={18}/><i/></button><span className="topbar-divider"/><label className="role-select"><span>View as</span><select value={role} onChange={e=>{setRole(e.target.value);setActive(e.target.value==='Promoter'?'Promoter Portal':'Overview');}}>{roles.map(r=><option key={r}>{r}</option>)}</select><ChevronDown size={13}/></label></div></header>{renderContent()}</main>
    {selectedProject&&<div className="modal-backdrop" onClick={()=>setSelectedProject(null)}><div className="modal project-detail" onClick={e=>e.stopPropagation()}><div className="modal-head"><div><div className="eyebrow">PROJECT OPERATIONAL HUB</div><h2>{selectedProject.name}</h2><p>{selectedProject.code} · {selectedProject.client}</p></div><button className="icon-button" onClick={()=>setSelectedProject(null)}><X size={18}/></button></div><div className="project-detail-stats"><div><span>Status</span><Status value={selectedProject.status}/></div><div><span>Budget</span><strong>{money(selectedProject.budget)}</strong></div><div><span>Promoters</span><strong>{selectedProject.promoters}</strong></div><div><span>Stores</span><strong>{selectedProject.stores}</strong></div></div><div className="detail-section"><h3>Related operational records</h3><div className="related-grid">{[['Promoters',Users],['Stores',Store],['Assignments',BriefcaseBusiness],['Attendance',Clock3],['Tasks',ClipboardList],['Gifts & Goodies',Gift],['PLV / POSM',Boxes],['Finance',WalletCards]].map(([name,Icon])=><button key={name} onClick={()=>{setActive(name);setQuery(selectedProject.code);setSelectedProject(null);}}><Icon size={17}/><span>{name}</span><ArrowRight size={14}/></button>)}</div></div><div className="modal-actions"><button className="btn secondary" onClick={()=>setSelectedProject(null)}>Close</button><button className="btn primary" onClick={()=>{setActive('Projects');setModal({type:'edit',module:'Projects',row:selectedProject,index:data.Projects.indexOf(selectedProject)});setSelectedProject(null);}}>Edit project <ArrowRight size={15}/></button></div></div></div>}
    {modal&&<RecordModal modal={modal} data={data} onClose={()=>setModal(null)} onSave={row=>modal.type==='edit'? (updateRow(modal.module,modal.index,row),setModal(null),showToast('Record updated in demo session')):modal.type==='create'?addRow(modal.module,row):(setModal(null),showToast('Automation draft saved locally'))} />}
    {toast&&<div className="toast"><CheckCircle2 size={17}/>{toast}</div>}
  </div>;
}

function Metric({icon:Icon,label,value,note,trend,warn}){return <div className="metric-card"><div className="metric-top"><span className={'metric-icon '+(warn?'warn':'')}><Icon size={18}/></span>{trend&&<span className={'metric-trend '+(warn?'warn':'')}><ArrowUpRight size={13}/>{trend}</span>}</div><div className="metric-value">{value}</div><div className="metric-label">{label}</div><div className="metric-note">{note}</div></div>}
function Avatar({name}){return <span className="avatar">{initials(name)}</span>}
function AutomationCard({item,onToggle,onEdit}){const [enabled,setEnabled]=useState(item.enabled);const Icon=item.icon;return <div className="automation-card"><div className="automation-card-top"><span className="automation-icon"><Icon size={19}/></span><button className={'toggle '+(enabled?'on':'')} onClick={()=>{setEnabled(!enabled);onToggle();}} aria-label="Toggle demo automation"><i/></button></div><h3>{item.name}</h3><p>{item.desc}</p><div className="automation-trigger"><Clock3 size={14}/>{item.trigger}</div><div className="automation-card-bottom"><span className={enabled?'enabled-label':'disabled-label'}><i/>{enabled?'Enabled in demo':'Paused'}</span><button className="text-action" onClick={onEdit}>Configure <ChevronRight size={14}/></button></div></div>}
function RecordModal({modal,data,onClose,onSave}){
  if(modal.type==='automation'||modal.type==='editAutomation') return <AutomationModal modal={modal} onClose={onClose} onSave={onSave}/>;
  return <RecordFieldsModal modal={modal} data={data} onClose={onClose} onSave={onSave}/>;
}
function AutomationModal({modal,onClose,onSave}){
  const [automationName,setAutomationName]=useState(modal.item?.name||'');
  return <div className="modal-backdrop" onClick={onClose}><div className="modal" onClick={e=>e.stopPropagation()}><div className="modal-head"><div><h2>{modal.type==='automation'?'New automation draft':'Configure automation'}</h2><p>Draft only · no workflow will execute</p></div><button className="icon-button" onClick={onClose}><X size={18}/></button></div><label className="field-label">Automation name<input value={automationName} onChange={e=>setAutomationName(e.target.value)} placeholder="e.g. Missing attendance check"/></label><label className="field-label">Trigger<select><option>On record change</option><option>Scheduled time</option><option>When project status changes</option></select></label><label className="field-label">Action<select><option>Create task for review</option><option>Prepare notification draft</option><option>Flag record for approval</option></select></label><div className="modal-actions"><button className="btn secondary" onClick={onClose}>Cancel</button><button className="btn primary" onClick={()=>onSave({name:automationName})}>Save draft</button></div></div></div>;
}
function RecordFieldsModal({modal,data,onClose,onSave}){
  const module=modal.module;
  const defaults={Projects:{code:'',name:'',client:'',type:'Temporary (Activation)',status:'Planning',city:'',start:'',end:'',budget:0,stores:0,promoters:0,supervisor:''},Promoters:{cin:'',name:'',phone:'',email:'',city:'',contract:'Permanent',status:'Available',uniform:'M',project:'—',pec:'Pending',device:'Phone',rating:'—'},Supervisors:{name:'',email:'',phone:'',city:'',zone:'',status:'Active',projects:0,stores:0},Stores:{code:'',name:'',city:'',banner:'',format:'Supermarket',address:'',status:'Active',projects:'',supervisor:''},Assignments:{id:'',promoter:'',cin:'',project:'',store:'',supervisor:'',start:'',end:'',status:'Active'},Attendance:{date:'2026-10-15',promoter:'',project:'',store:'',checkin:'',checkout:'',status:'Present',source:'Manual',validation:'Pending'},'Resource Requests':{id:'',type:'PEC',promoter:'',project:'',store:'',requester:'',date:'2026-10-15',status:'Pending',decision:''},'Gifts & Goodies':{name:'',category:'Samples',project:'',total:0,allocated:0,distributed:0,unitValue:0,status:'In progress'},'PLV / POSM':{name:'',type:'Display',project:'',quantity:0,unitCost:0,production:'Planning',deadline:'',installed:0,status:'Planning'},Tasks:{title:'',project:'',assignee:'',priority:'Medium',due:'',status:'To Do'},Finance:{project:'',category:'',budget:0,actual:0,funding:'Client',status:'On track'},Clients:{name:'',industry:'',contact:'',email:'',phone:'',status:'Active',projects:0}};
  const base=modal.type==='edit'?form:(defaults[module]||{name:''});
  const [values,setValues]=useState(base);
  const enums={status:module==='Projects'?['Planning','Active','Completed','On Hold']:module==='Promoters'?['Available','Assigned','On Leave','Inactive']:module==='Attendance'?['Present','Absent','Late','Half-Day','Replaced']:module==='Resource Requests'?['Pending','Approved','Rejected']:['Active','Planning','Completed','On Hold'],type:module==='Projects'?['Permanent (SMART)','Temporary (Activation)']:module==='Resource Requests'?['PEC','IT Policy / MDM','Uniform','Tablet']:['Permanent','Activation','Freelance'],contract:['Permanent','Activation','Freelance'],priority:['Low','Medium','High','Urgent'],pec:['Valid','Pending','Expiring','Expired']};
  const fields=Object.keys({...defaults[module],...(modal.type==='edit'?modal.row:{})});
  const label=k=>({cin:'National ID / CIN',pec:'PEC status',unitValue:'Unit value (MAD)',unitCost:'Unit cost (MAD)',actual:'Actual amount (MAD)',budget:'Budget (MAD)',due:'Deadline',start:'Start date',end:'End date',checkin:'Check-in',checkout:'Check-out',client:'Client',name:'Name',code:'Source ID / code',id:'Record ID'}[k]||k.charAt(0).toUpperCase()+k.slice(1).replace(/([A-Z])/g,' $1'));
  return <div className="modal-backdrop" onClick={onClose}><div className="modal record-modal" onClick={e=>e.stopPropagation()}><div className="modal-head"><div><h2>{modal.type==='edit'?'Edit':'Add'} {module?.replace(' & Goodies','')}</h2><p>Changes remain in this demo session.</p></div><button className="icon-button" onClick={onClose}><X size={18}/></button></div><div className="form-grid">{fields.map(k=><label className="field-label" key={k}>{label(k)}{enums[k]?<select value={values[k]??''} onChange={e=>setValues(v=>({...v,[k]:e.target.value}))}>{enums[k].map(o=><option key={o}>{o}</option>)}</select>:<input type={['budget','actual','unitValue','unitCost','total','allocated','distributed','quantity','installed','promoters','stores','projects'].includes(k)?'number':k==='email'?'email':/date|start|end|due|deadline/.test(k)?'date':'text'} value={values[k]??''} onChange={e=>setValues(v=>({...v,[k]:e.target.value}))} placeholder={label(k)}/>}</label>)}</div><div className="modal-actions"><button className="btn secondary" onClick={onClose}>Cancel</button><button className="btn primary" onClick={()=>onSave(values)}><Check size={15}/> Save record</button></div></div></div>;
}
export default App;
