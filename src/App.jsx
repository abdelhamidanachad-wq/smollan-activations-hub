import React, { useMemo, useState } from 'react';
import {
  Activity, ArrowDownRight, ArrowRight, ArrowUpRight, Bell, CalendarDays,
  CheckCircle2, ChevronDown, ChevronLeft, ChevronRight, CircleDollarSign,
  ClipboardCheck, Clock3, Command, FileCheck2, FileText, Filter, FolderKanban,
  LayoutDashboard, Menu, MoreHorizontal,
  Package, Plus, Search, Settings2, ShieldCheck, Smartphone,
  Sparkles, Truck, Users, WalletCards, X, Zap, Building2,
  HardDrive, CalendarClock, Bot, MessageCircle, Workflow, Send, WandSparkles, Play, Pause, Check, Paperclip, Headphones, CircleHelp
} from 'lucide-react';

const navGroups = [
  { label: 'PILOTAGE', items: [
    { id: 'overview', label: 'Vue d’ensemble', icon: LayoutDashboard },
    { id: 'projects', label: 'Projets', icon: FolderKanban, count: '24' },
    { id: 'tasks', label: 'Tâches & validations', icon: ClipboardCheck, count: '12' },
    { id: 'calendar', label: 'Calendrier', icon: CalendarDays },
  ]},
  { label: 'OPÉRATIONS', items: [
    { id: 'people', label: 'Équipes terrain', icon: Users },
    { id: 'production', label: 'Production & BAT', icon: FileCheck2, count: '5' },
    { id: 'stock', label: 'PLV, goodies & stock', icon: Package },
    { id: 'digital', label: 'Jeux digitaux', icon: Zap },
    { id: 'assistant', label: 'Assistant IA', icon: Bot, count: 'IA' },
    { id: 'whatsapp', label: 'WhatsApp', icon: MessageCircle, count: '3' },
    { id: 'automations', label: 'Automatisations', icon: Workflow },
  ]},
  { label: 'GESTION', items: [
    { id: 'finance', label: 'Finance & documents', icon: WalletCards, count: '8' },
    { id: 'assets', label: 'Parc & assets', icon: Smartphone },
    { id: 'clients', label: 'Clients & fournisseurs', icon: Building2 },
    { id: 'integrations', label: 'Workspace & outils', icon: HardDrive },
    { id: 'superadmin', label: 'Super Admin', icon: ShieldCheck },
  ]},
];

const projects = [
  { client: 'Samsung', initials: 'S', color: 'blue', title: 'Galaxy — Roadshow Retail', type: 'Activation', cadence: '3 VSD', owner: 'Salma B.', city: 'Casablanca · Rabat', dates: '17 oct. — 1 nov.', stage: 'En production', progress: 74, risk: 'On track' },
  { client: "L’Oréal", initials: 'L', color: 'rose', title: 'Beauty Advisor — Permanent', type: 'Promoters permanents', cadence: 'VSD', owner: 'Youssef E.', city: 'National', dates: 'Continu', stage: 'En cours', progress: 86, risk: 'On track' },
  { client: 'Coca-Cola', initials: 'C', color: 'red', title: 'Sampling — Week-end', type: 'Animation magasin', cadence: '2 VSD', owner: 'Nadia A.', city: 'Marrakech · Agadir', dates: '24 — 25 oct.', stage: 'Recrutement', progress: 46, risk: 'Attention' },
  { client: 'P&G', initials: 'P', color: 'purple', title: 'Ariel — PLV & uniformes', type: 'Production seule', cadence: 'Livraison', owner: 'Mehdi R.', city: 'Casablanca', dates: '20 oct.', stage: 'BAT à valider', progress: 58, risk: 'Blocked' },
];

const tasksInitial = [
  { id: 1, title: 'Valider le BAT stand Galaxy', project: 'Samsung · Galaxy Roadshow', owner: 'Salma B.', due: 'Aujourd’hui · 12:00', state: 'Urgent', kind: 'BAT' },
  { id: 2, title: 'Confirmer les tailles uniformes', project: 'P&G · Ariel PLV', owner: 'Mehdi R.', due: 'Aujourd’hui · 15:00', state: 'À faire', kind: 'Production' },
  { id: 3, title: 'Clôturer le pointage SD', project: 'Coca-Cola · Sampling', owner: 'Nadia A.', due: 'Demain · 10:00', state: 'En cours', kind: 'Terrain' },
  { id: 4, title: 'Envoyer le devis révisé', project: 'L’Oréal · Beauty Advisor', owner: 'Youssef E.', due: 'Demain · 16:00', state: 'En attente', kind: 'Finance' },
];

const attentionItems = [
  { title: 'BAT en attente de validation', subtitle: 'P&G · Ariel — PLV & uniformes', tag: '2 jours', icon: FileCheck2, tone: 'amber' },
  { title: 'PO client manquant', subtitle: 'Coca-Cola · Sampling Week-end', tag: 'À relancer', icon: FileText, tone: 'rose' },
  { title: 'Dispatch à confirmer', subtitle: 'Samsung · 4 magasins', tag: 'Demain', icon: Truck, tone: 'blue' },
];

function App() {
  const [active, setActive] = useState('overview');
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('Tous');
  const [tasks, setTasks] = useState(tasksInitial);
  const [notice, setNotice] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [createTitle, setCreateTitle] = useState('');
  const [mobileNav, setMobileNav] = useState(false);
  const [lang, setLang] = useState('FR');

  const selected = navGroups.flatMap(g => g.items).find(i => i.id === active);
  const filteredProjects = useMemo(() => projects.filter(p => {
    const matchesText = [p.client, p.title, p.type, p.owner, p.city].join(' ').toLowerCase().includes(search.toLowerCase());
    const matchesStage = filter === 'Tous' || p.stage === filter || p.type === filter;
    return matchesText && matchesStage;
  }), [search, filter]);

  const acknowledge = msg => {
    setNotice(msg);
    window.setTimeout(() => setNotice(''), 3200);
  };

  const markDone = id => {
    setTasks(prev => prev.filter(t => t.id !== id));
    acknowledge('Tâche marquée comme terminée dans cette démo.');
  };

  const addTask = e => {
    e.preventDefault();
    if (!createTitle.trim()) return;
    setTasks(prev => [{ id: Date.now(), title: createTitle.trim(), project: 'Interne · À affecter', owner: 'Vous', due: 'À planifier', state: 'À faire', kind: 'Interne' }, ...prev]);
    setCreateTitle('');
    setShowCreate(false);
    setActive('tasks');
    acknowledge('Tâche ajoutée à la démonstration.');
  };

  return <div className="app-shell">
    <aside className={'sidebar ' + (mobileNav ? 'sidebar-open' : '')}>
      <div className="brand-lockup">
        <div className="brand-mark"><span></span><span></span><span></span></div>
        <div><div className="brand-name">SMOLLAN</div><div className="brand-location">MOROCCO <span>•</span> OPERATIONS</div></div>
        <button className="icon-button close-mobile" onClick={() => setMobileNav(false)} aria-label="Fermer le menu"><X size={18}/></button>
      </div>
      <div className="workspace-switcher">
        <div className="workspace-icon"><Command size={18}/></div>
        <div className="workspace-copy"><strong>SMOLLAN Hub</strong><span>Espace de travail</span></div>
        <ChevronDown size={15} className="muted"/>
      </div>
      <nav className="main-nav">
        {navGroups.map(group => <div className="nav-group" key={group.label}>
          <div className="nav-group-label">{group.label}</div>
          {group.items.map(item => {
            const Icon = item.icon;
            return <button key={item.id} className={'nav-item ' + (active === item.id ? 'active' : '')} onClick={() => { setActive(item.id); setMobileNav(false); }}>
              <Icon size={17} strokeWidth={1.8}/><span>{item.label}</span>{item.count && <span className="nav-count">{item.count}</span>}
            </button>;
          })}
        </div>)}
      </nav>
      <div className="sidebar-spacer"/>
      <div className="usage-card">
        <div className="usage-top"><div className="usage-icon"><Sparkles size={16}/></div><span>ESPACE OPÉRATIONNEL</span><MoreHorizontal size={16}/></div>
        <strong>Tout au même endroit.</strong>
        <p>Projets, équipes, production et finance réunis dans un seul hub.</p>
        <div className="usage-link" onClick={() => setActive('integrations')}>Configurer le workspace <ArrowRight size={14}/></div>
      </div>
      <div className="sidebar-bottom">
        <button className="nav-item" onClick={() => setActive('integrations')}><Settings2 size={17}/><span>Paramètres</span></button>
        <div className="user-profile">
          <div className="avatar avatar-self">SM</div><div className="user-copy"><strong>Workspace admin</strong><span>Accès démonstration</span></div><MoreHorizontal size={18} className="muted"/>
        </div>
      </div>
    </aside>

    <main className="main-area">
      <header className="topbar">
        <div className="breadcrumbs">
          <button className="icon-button hamburger" onClick={() => setMobileNav(true)} aria-label="Ouvrir le menu"><Menu size={19}/></button>
          <span>SMOLLAN Hub</span><ChevronRight size={14}/><strong>{selected?.label || 'Vue d’ensemble'}</strong>
        </div>
        <div className="top-actions">
          <div className="global-search"><Search size={16}/><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher un projet, client…"/><kbd>⌘ K</kbd></div>
          <button className="language-button" onClick={() => { setLang(lang === 'FR' ? 'EN' : 'FR'); acknowledge(lang === 'FR' ? 'English mode preview selected.' : 'Mode français sélectionné.'); }}>{lang}<ChevronDown size={13}/></button>
          <button className="icon-button notification-button" onClick={() => acknowledge('Vous êtes à jour : 3 points demandent votre attention.')} aria-label="Notifications"><Bell size={18}/><i/></button>
          <div className="avatar avatar-self top-avatar">SM</div>
        </div>
      </header>

      <div className="page-content">
        {active === 'overview' ? <Overview onCreate={() => setShowCreate(true)} setActive={setActive} tasks={tasks} markDone={markDone} filteredProjects={filteredProjects} search={search} filter={filter} setFilter={setFilter} acknowledge={acknowledge}/> :
          active === 'projects' ? <Projects filteredProjects={filteredProjects} filter={filter} setFilter={setFilter} onCreate={() => setShowCreate(true)} search={search} acknowledge={acknowledge}/> :
          active === 'tasks' ? <Tasks tasks={tasks} markDone={markDone} onCreate={() => setShowCreate(true)}/> :
          active === 'calendar' ? <CalendarPage acknowledge={acknowledge}/> :
          active === 'assistant' ? <AssistantPage acknowledge={acknowledge}/> :
          active === 'whatsapp' ? <WhatsAppPage acknowledge={acknowledge}/> :
          active === 'automations' ? <AutomationsPage acknowledge={acknowledge}/> :
          active === 'superadmin' ? <SuperAdminPage acknowledge={acknowledge}/> :
          <ModulePage active={active} selected={selected} acknowledge={acknowledge} onCreate={() => setShowCreate(true)}/>}
      </div>
      <footer className="app-footer"><span><i className="status-dot"/> Prototype opérationnel</span><span><ShieldCheck size={13}/> Accès interne prévu · SSO à configurer</span><span>SMOLLAN Morocco © 2026</span></footer>
    </main>

    {notice && <div role="status" className="toast"><CheckCircle2 size={17}/>{notice}<button onClick={() => setNotice('')} aria-label="Fermer"><X size={15}/></button></div>}
    {showCreate && <div className="modal-backdrop" onMouseDown={e => { if(e.target === e.currentTarget) setShowCreate(false); }}>
      <form className="create-modal" onSubmit={addTask}>
        <div className="modal-head"><div className="modal-icon"><Plus size={19}/></div><button type="button" className="icon-button" onClick={() => setShowCreate(false)} aria-label="Fermer"><X size={18}/></button></div>
        <h2>Créer une tâche</h2><p>Ajoutez une action au suivi opérationnel.</p>
        <label htmlFor="task-title">Nom de la tâche</label><input autoFocus id="task-title" value={createTitle} onChange={e => setCreateTitle(e.target.value)} placeholder="Ex. Confirmer le dispatch des goodies" required/>
        <div className="modal-note"><CalendarClock size={16}/> L’affectation, le projet et la date pourront être complétés dans le module Tâches.</div>
        <div className="modal-actions"><button type="button" className="button-secondary" onClick={() => setShowCreate(false)}>Annuler</button><button className="button-primary" type="submit">Ajouter la tâche <ArrowRight size={15}/></button></div>
      </form>
    </div>}
  </div>;
}

function Overview({ onCreate, setActive, tasks, markDone, filteredProjects, search, filter, setFilter, acknowledge }) {
  return <>
    <div className="welcome-row">
      <div><div className="eyebrow"><span className="eyebrow-dot"/> JEUDI · 15 OCTOBRE 2026</div><h1>Bonjour, l’équipe <span className="title-period">.</span></h1><p className="page-subtitle">Voici ce qui se passe sur vos opérations aujourd’hui.</p></div>
      <div className="welcome-actions"><button className="button-secondary" onClick={() => setActive('calendar')}><CalendarDays size={16}/> Voir le calendrier</button><button className="button-primary" onClick={onCreate}><Plus size={16}/> Nouvelle tâche</button></div>
    </div>
    <div className="demo-alert"><div className="demo-alert-icon"><Activity size={16}/></div><div><strong>Données de démonstration</strong><span>Projets et chiffres illustratifs — aucune donnée client ou RH réelle n’est connectée.</span></div><span className="demo-pill">PREVIEW</span></div>

    <section className="metric-grid">
      <Metric label="Projets actifs" value="24" delta="+3 ce mois" icon={FolderKanban} iconTone="blue" trend="up" footer="Sur l’ensemble du portefeuille"/>
      <Metric label="Activations à venir" value="08" delta="3 cette semaine" icon={CalendarDays} iconTone="violet" trend="up" footer="Prochain départ · vendredi"/>
      <Metric label="Tâches en retard" value="05" delta="2 critiques" icon={Clock3} iconTone="amber" trend="down" footer="À traiter en priorité"/>
      <Metric label="CA à facturer" value="486 k" suffix="MAD" delta="71% du prévisionnel" icon={CircleDollarSign} iconTone="green" trend="up" footer="Estimé · mois en cours"/>
    </section>

    <div className="content-grid">
      <section className="panel projects-panel">
        <div className="panel-header"><div><div className="section-eyebrow">VUE PORTEFEUILLE</div><h2>Projets en cours <span className="count-bubble">{filteredProjects.length}</span></h2><p>Suivez l’avancement, du brief à la clôture.</p></div><button className="text-button" onClick={() => setActive('projects')}>Tous les projets <ArrowRight size={15}/></button></div>
        <div className="table-toolbar"><div className="filter-tabs">{['Tous','En cours','En production','BAT à valider'].map(f => <button key={f} className={filter===f?'selected':''} onClick={() => setFilter(f)}>{f}</button>)}</div><button className="icon-button tiny-filter" onClick={() => setFilter('Tous')} title="Réinitialiser le filtre"><Filter size={15}/></button></div>
        <div className="project-list">
          {filteredProjects.slice(0,4).map((p, i) => <ProjectRow key={p.title} project={p} onClick={() => { setActive('projects'); acknowledge('Fiche projet de démonstration : ' + p.title); }}/>)}
          {filteredProjects.length===0 && <div className="empty-state">Aucun projet ne correspond à cette recherche.</div>}
        </div>
        <button className="panel-bottom-link" onClick={() => setActive('projects')}>Ouvrir le portefeuille complet <ArrowRight size={15}/></button>
      </section>

      <section className="panel attention-panel">
        <div className="panel-header compact"><div><div className="section-eyebrow">À SURVEILLER</div><h2>Points d’attention <span className="attention-count">3</span></h2><p>Les prochaines actions à sécuriser.</p></div><button className="icon-button" onClick={() => acknowledge('Liste des alertes actualisée (démo).')} aria-label="Actualiser"><Activity size={16}/></button></div>
        <div className="attention-list">{attentionItems.map(item => {const Icon=item.icon;return <button className="attention-item" key={item.title} onClick={() => acknowledge(item.title + ' — ouvert dans le suivi (démo).')}><div className={'attention-icon '+item.tone}><Icon size={17}/></div><div className="attention-copy"><strong>{item.title}</strong><span>{item.subtitle}</span></div><div className={'attention-tag '+item.tone}>{item.tag}</div><ChevronRight size={15} className="attention-chevron"/></button>;})}</div>
        <div className="attention-summary"><ShieldCheck size={17}/><div><strong>Le portefeuille est sous contrôle</strong><span>Traitez les validations avant les dispatchs.</span></div></div>
      </section>
    </div>

    <div className="bottom-grid">
      <section className="panel tasks-panel">
        <div className="panel-header compact"><div><div className="section-eyebrow">VOTRE JOURNÉE</div><h2>Mes prochaines tâches <span className="count-bubble">{tasks.length}</span></h2></div><button className="text-button" onClick={() => setActive('tasks')}>Tout voir <ArrowRight size={14}/></button></div>
        <div className="task-list">{tasks.slice(0,4).map(task => <div className="task-row" key={task.id}><button className="task-check" onClick={() => markDone(task.id)} aria-label={'Terminer ' + task.title}><CheckCircle2 size={17}/></button><div className="task-copy"><strong>{task.title}</strong><span>{task.project}</span></div><div className="task-meta"><span className={'task-state '+task.state.toLowerCase().replaceAll(' ','-')}>{task.state}</span><span className="task-due"><Clock3 size={12}/>{task.due}</span></div><button className="icon-button task-more" onClick={() => acknowledge('Action disponible dans la fiche de tâche (démo).')} aria-label="Options"><MoreHorizontal size={16}/></button></div>)}</div>
      </section>
      <section className="panel calendar-teaser">
        <div className="panel-header compact"><div><div className="section-eyebrow">PROCHAINS TEMPS FORTS</div><h2>Cette semaine</h2></div><button className="icon-button" onClick={() => setActive('calendar')} aria-label="Ouvrir le calendrier"><ArrowRight size={16}/></button></div>
        <div className="week-strip">{[['15','JEU'],['16','VEN'],['17','SAM'],['18','DIM'],['19','LUN']].map((d,i)=><button key={d[1]} className={'day-chip '+(i===0?'today':'')+(i===2||i===3?' event-day':'')} onClick={() => acknowledge(d[1]+' 15 octobre — planning de démonstration')}><span>{d[1]}</span><strong>{d[0]}</strong>{(i===2||i===3)&&<i/>}</button>)}</div>
        <div className="event-row"><div className="event-color blue-event"></div><div className="event-copy"><strong>Galaxy Roadshow</strong><span>Samedi · 09:00–18:00 · 4 magasins</span></div><span className="event-label">VSD</span></div>
        <div className="event-row"><div className="event-color rose-event"></div><div className="event-copy"><strong>Point formation animatrices</strong><span>Vendredi · 14:00 · Équipe terrain</span></div><span className="event-label muted-event">RH</span></div>
      </section>
    </div>
    <div className="integration-strip"><div className="integration-logo google">G</div><div><strong>Votre stack reste connectée à votre quotidien.</strong><span>Drive, Calendar, Gmail, Meet & WhatsApp — liens centralisés, synchronisation API à activer.</span></div><button onClick={() => setActive('integrations')}>Voir les intégrations <ArrowRight size={14}/></button></div>
  </>;
}

function Metric({label,value,suffix,delta,icon:Icon,iconTone,trend,footer}) {
 return <div className="metric-card"><div className="metric-top"><span>{label}</span><div className={'metric-icon '+iconTone}><Icon size={18} strokeWidth={1.8}/></div></div><div className="metric-value">{value}{suffix&&<small> {suffix}</small>}</div><div className="metric-bottom"><span className={'metric-delta '+iconTone}>{trend==='up'?<ArrowUpRight size={13}/>:<ArrowDownRight size={13}/>} {delta}</span></div><div className="metric-footer">{footer}</div></div>;
}
function ProjectRow({project:p,onClick}) {
 return <button className="project-row" onClick={onClick}><div className={'client-logo '+p.color}>{p.initials}</div><div className="project-main"><div className="project-title-line"><strong>{p.title}</strong><span className="project-type">{p.type}</span></div><div className="project-subline"><span>{p.client}</span><i/> <span>{p.city}</span><i/> <span>{p.cadence}</span></div></div><div className="project-progress-wrap"><div className="progress-label"><span>{p.stage}</span><strong>{p.progress}%</strong></div><div className="progress-track"><span style={{width:p.progress+'%'}}></span></div></div><ChevronRight size={16} className="project-chevron"/></button>;
}

function Projects({filteredProjects,filter,setFilter,onCreate,search,acknowledge}) {
 return <><div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> PORTEFEUILLE</div><h1>Projets <span className="title-period">.</span></h1><p className="page-subtitle">Tous les formats d’engagement, suivis de bout en bout.</p></div><button className="button-primary" onClick={onCreate}><Plus size={16}/> Nouvelle tâche</button></div><div className="demo-alert"><Activity size={16}/><div><strong>Mode démonstration</strong><span>Les projets affichés servent de maquette UX et ne représentent pas le portefeuille réel.</span></div></div><div className="module-filter-row"><div className="filter-tabs">{['Tous','En cours','En production','BAT à valider','Production seule','Animation magasin'].map(f=><button key={f} className={filter===f?'selected':''} onClick={()=>setFilter(f)}>{f}</button>)}</div><button className="button-secondary" onClick={()=>setFilter('Tous')}><Filter size={15}/> Effacer les filtres</button></div><div className="projects-grid">{filteredProjects.map(p=><div className="project-card" key={p.title}><div className="project-card-top"><div className={'client-logo large '+p.color}>{p.initials}</div><span className={'risk-dot '+(p.risk==='Blocked'?'risk-red':p.risk==='Attention'?'risk-amber':'risk-green')}>{p.risk==='Blocked'?'Bloqué':p.risk==='Attention'?'Attention':'En bonne voie'}</span></div><div className="project-card-kicker">{p.client} <span>·</span> {p.type}</div><h3>{p.title}</h3><p className="project-card-location">{p.city}</p><div className="project-card-meta"><span><CalendarDays size={14}/>{p.dates}</span><span><Users size={14}/>{p.owner}</span></div><div className="card-progress"><div className="progress-label"><span>{p.stage}</span><strong>{p.progress}%</strong></div><div className="progress-track"><span style={{width:p.progress+'%'}}></span></div></div><div className="project-card-footer"><span className="cadence-pill">{p.cadence}</span><button className="text-button" onClick={()=>acknowledge('Fiche complète à connecter pour '+p.title)}>Ouvrir la fiche <ArrowRight size={14}/></button></div></div>)}</div></>;
}

function Tasks({tasks,markDone,onCreate}) {
 return <><div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> EXÉCUTION</div><h1>Tâches & validations<span className="title-period">.</span></h1><p className="page-subtitle">Gardez les briefs, BAT, équipes et échéances alignés.</p></div><button className="button-primary" onClick={onCreate}><Plus size={16}/> Nouvelle tâche</button></div><div className="demo-alert"><Activity size={16}/><div><strong>Données locales de démonstration</strong><span>Les changements ici sont temporaires et ne sont pas partagés avec les équipes.</span></div></div><div className="panel task-page-panel"><div className="panel-header"><div><h2>À traiter <span className="count-bubble">{tasks.length}</span></h2><p>Actions conservées dans cette session de démonstration.</p></div><button className="button-secondary"><Filter size={15}/> Filtrer</button></div>{tasks.length?tasks.map(t=><div className="task-row full-task" key={t.id}><button className="task-check" onClick={()=>markDone(t.id)} aria-label={'Terminer '+t.title}><CheckCircle2 size={17}/></button><div className="task-copy"><strong>{t.title}</strong><span>{t.project} · {t.owner}</span></div><span className="task-kind">{t.kind}</span><div className="task-meta"><span className={'task-state '+t.state.toLowerCase().replaceAll(' ','-')}>{t.state}</span><span className="task-due"><Clock3 size={12}/>{t.due}</span></div><button className="icon-button" aria-label="Ouvrir la tâche"><ChevronRight size={16}/></button></div>):<div className="empty-state"><CheckCircle2 size={23}/><strong>Tout est traité</strong><span>Créez une tâche pour alimenter la liste.</span></div>}</div></>;
}

function CalendarPage({acknowledge}) {
 const events=[{day:'VEN',date:'16',month:'OCT',time:'14:00',title:'Formation animatrices',desc:'Équipe terrain · Casablanca',kind:'RH',color:'rose'},{day:'SAM',date:'17',month:'OCT',time:'09:00',title:'Galaxy Roadshow',desc:'4 magasins · Casablanca & Rabat',kind:'VSD',color:'blue'},{day:'DIM',date:'18',month:'OCT',time:'09:00',title:'Galaxy Roadshow',desc:'Jour 2 · Check-in & reporting',kind:'VSD',color:'blue'},{day:'MAR',date:'20',month:'OCT',time:'11:00',title:'Livraison PLV Ariel',desc:'Contrôle qualité & réception',kind:'PROD',color:'amber'},{day:'SAM',date:'24',month:'OCT',time:'08:30',title:'Sampling Coca-Cola',desc:'Marrakech & Agadir',kind:'2 VSD',color:'green'}];
 return <><div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> PLANNING</div><h1>Calendrier opérationnel<span className="title-period">.</span></h1><p className="page-subtitle">Un seul planning pour les animations, équipes, production et finance.</p></div><button className="button-secondary" onClick={()=>acknowledge('Export calendrier disponible après connexion Google Calendar.')}><CalendarDays size={15}/> Connecter Google Calendar</button></div><div className="demo-alert"><Activity size={16}/><div><strong>Planning illustratif</strong><span>Connectez les calendriers autorisés pour afficher les événements réels.</span></div></div><div className="calendar-layout"><div className="panel month-panel"><div className="panel-header"><div><div className="section-eyebrow">CALENDRIER</div><h2>Octobre 2026</h2></div><div className="month-arrows"><button className="icon-button" onClick={()=>acknowledge('Navigation mensuelle à connecter.')}><ChevronLeft size={17}/></button><button className="icon-button" onClick={()=>acknowledge('Navigation mensuelle à connecter.')}><ChevronRight size={17}/></button></div></div><div className="month-grid">{['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'].map(d=><span className="month-weekday" key={d}>{d}</span>)}{Array.from({length:35},(_,i)=>{const n=i-2;const day=n+1;const outside=day<1||day>31;const real=outside?(day<1?30+day:day-31):day;const hasEvent=[16,17,18,20,24,25].includes(real)&&!outside;return <button key={i} className={'month-day '+(outside?'outside':'')+(real===15&&!outside?' today':'')+(hasEvent?' has-event':'')} onClick={()=>hasEvent?acknowledge('Événement de démonstration du '+real+' octobre'):null}><span>{real}</span>{hasEvent&&<i/>}</button>;})}</div><div className="calendar-legend"><span><i className="legend-blue"/> Activation magasin</span><span><i className="legend-rose"/> Formation / RH</span><span><i className="legend-amber"/> Production / dispatch</span></div></div><div className="panel upcoming-panel"><div className="panel-header"><div><div className="section-eyebrow">AGENDA</div><h2>Prochains événements</h2></div><span className="count-bubble">{events.length}</span></div><div className="upcoming-list">{events.map(e=><button className="upcoming-event" key={e.title+e.date} onClick={()=>acknowledge(e.title+' — '+e.date+' '+e.month+' (démo)')}><div className="event-datebox"><span>{e.day}</span><strong>{e.date}</strong><small>{e.month}</small></div><div className="event-line"><i className={e.color}/></div><div className="upcoming-copy"><div className="upcoming-title"><strong>{e.title}</strong><span className={'event-label '+(e.kind==='VSD'?'':'muted-event')}>{e.kind}</span></div><span>{e.time} · {e.desc}</span></div><ChevronRight size={15}/></button>)}</div></div></div></>;
}

const moduleContent = {
 people:{eyebrow:'FIELD OPERATIONS',title:'Équipes terrain',subtitle:'Animatrices, superviseurs, field managers et merchandisers.',icon:Users,stats:[['Affectations actives','126'],['Présences à vérifier','09'],['Formations planifiées','04']],tasks:['Affectations par client, ville et magasin','Plannings VSD / SD et remplacement','Pointage : import, anomalies, validation superviseur','Formation, uniformes et équipements attribués'],next:'Connecter la webapp de pointage existante avant toute paie ou facturation.'},
 production:{eyebrow:'CRÉATION & ACHATS',title:'Production & BAT',subtitle:'Du brief créatif à la validation BAT, production et livraison.',icon:FileCheck2,stats:[['BAT en attente','05'],['Ordres en production','08'],['Livraisons à confirmer','03']],tasks:['Brief créatif et références par version','Circuit de validation BAT avec horodatage','Fournisseurs, quantités, prix et contrôle qualité','Bons de livraison, dispatch et preuves de réception'],next:'Définir les approbateurs BAT et les seuils de validation des commandes.'},
 stock:{eyebrow:'LOGISTIQUE',title:'PLV, goodies & stock',subtitle:'Visibilité sur les quantités, réservations, dispatchs et retours.',icon:Package,stats:[['Références catalogue','84'],['Dispatchs en cours','07'],['Articles sous seuil','03']],tasks:['Catalogue PLV, stands, goodies et uniformes','Lots, emplacements et stock disponible / réservé','Bons de sortie et dispatch par ville, magasin, projet','Retours, casse, perte et rapprochement physique'],next:'Le stock doit être calculé à partir des mouvements, pas seulement d’un chiffre modifié manuellement.'},
 digital:{eyebrow:'ENGAGEMENT',title:'Jeux digitaux',subtitle:'Centralisez mécaniques, dotations, liens, QR et reporting.',icon:Zap,stats:[['Campagnes actives','03'],['Lots à distribuer','240'],['Redemptions cette semaine','186']],tasks:['Paramètres et règles de jeu par projet','Gestion des dotations et prix','Suivi des liens / QR codes et preuves de remise','Rapports agrégés pour le client'],next:'Définir le niveau de données personnelles nécessaire et la durée de conservation.'},
 finance:{eyebrow:'FINANCE',title:'Finance & documents',subtitle:'Devis, PO, BL et factures clients et fournisseurs dans un workflow traçable.',icon:WalletCards,stats:[['Devis à valider','04'],['PO client à recevoir','03'],['Factures à émettre','08']],tasks:['Devis client versionné avec lignes, quantités et TVA','PO client relié au projet et au devis approuvé','BL / réception puis facture client et suivi de paiement','Devis fournisseur, PO, BL, facture et échéance de paiement'],next:'Avant émission, Finance doit confirmer la numérotation, les taux de TVA et les validations requises.'},
 assets:{eyebrow:'PARC & MAINTENANCE',title:'Parc & assets',subtitle:'Suivi des équipements, véhicules, affectations et restitutions.',icon:Smartphone,stats:[['Assets inventoriés','92'],['Équipements affectés','71'],['Maintenances à prévoir','06']],tasks:['Ordinateurs, téléphones, tablettes et accessoires','IMEI / numéro de série, état et affectataire','Voitures superviseurs et field managers','Remise, restitution, incident et maintenance'],next:'Prévoir un formulaire de remise / retour signé et l’historique des mouvements.'},
 clients:{eyebrow:'RELATIONS & ACHATS',title:'Clients & fournisseurs',subtitle:'Référentiels partagés pour éviter les informations dispersées.',icon:Building2,stats:[['Clients suivis','18'],['Fournisseurs référencés','27'],['Briefs en qualification','06']],tasks:['Fiches clients, contacts et historique des projets','Fournisseurs, catégories, conditions et documents','Magasins et points de vente avec géographie','Liens vers Drive, échanges Gmail et réunions Meet'],next:'Importer les référentiels approuvés en conservant le propriétaire et la date de mise à jour.'},
 integrations:{eyebrow:'WORKSPACE',title:'Workspace & outils',subtitle:'Un point d’accès à vos outils actuels, avec intégrations à activer de manière contrôlée.',icon:HardDrive,stats:[['Outils à relier','05'],['Dépendances admin','03'],['Intégrations actives','00']],tasks:['Google Drive — liens et pièces jointes privées','Google Calendar — événements et planning','Gmail / Meet — références de communication','WhatsApp — liens des groupes projet et terrain'],next:'Les synchronisations Google API nécessitent un client OAuth, des scopes minimaux et l’accord de l’administrateur Workspace.'}
};

function ModulePage({active,selected,acknowledge,onCreate}) {
 const c=moduleContent[active]||moduleContent.projects; const Icon=c.icon;
 return <><div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> {c.eyebrow}</div><h1>{c.title}<span className="title-period">.</span></h1><p className="page-subtitle">{c.subtitle}</p></div><button className="button-primary" onClick={onCreate}><Plus size={16}/> Nouvelle tâche</button></div><div className="demo-alert"><Activity size={16}/><div><strong>Module en préfiguration</strong><span>Chiffres et éléments ci-dessous sont des exemples de mise en page, pas des données opérationnelles réelles.</span></div><span className="demo-pill">PREVIEW</span></div><div className="module-stat-grid">{c.stats.map(s=><div className="module-stat" key={s[0]}><span>{s[0]}</span><strong>{s[1]}</strong><ArrowUpRight size={15}/></div>)}</div><div className="module-layout"><div className="panel module-checklist"><div className="panel-header"><div><div className="section-eyebrow">FONCTIONNALITÉS</div><h2>Ce que ce module centralise</h2></div><div className="module-big-icon"><Icon size={20}/></div></div><div className="feature-list">{c.tasks.map((t,i)=><button key={t} className="feature-item" onClick={()=>acknowledge('Fonction à relier à la base sécurisée : '+t)}><span className="feature-number">0{i+1}</span><span>{t}</span><ChevronRight size={15}/></button>)}</div></div><div className="panel next-steps"><div className="section-eyebrow">PROCHAINE ÉTAPE</div><div className="next-icon"><Sparkles size={20}/></div><h3>Mettre ce flux en place</h3><p>{c.next}</p><button className="button-secondary full-width" onClick={()=>acknowledge('Action notée dans la maquette. Le suivi réel sera disponible après connexion du backend.')}>Préparer la configuration <ArrowRight size={15}/></button><div className="security-note"><ShieldCheck size={15}/><span>Rôles et permissions requis avant accès aux données réelles.</span></div></div></div></>;
}



function AssistantPage({ acknowledge }) {
  const [input, setInput] = useState('');
  const [activePrompt, setActivePrompt] = useState('today');
  const [messages, setMessages] = useState([
    { role: 'assistant', text: "Bonjour ! Je suis l’assistant SMOLLAN. Je peux vous aider à préparer une activation, suivre les validations, rédiger un message terrain ou transformer une demande en tâches. Les réponses ci-dessous utilisent uniquement les données de démonstration." },
    { role: 'assistant', text: "J’ai repéré 3 priorités dans le scénario de démo : valider le BAT Galaxy, confirmer les tailles des uniformes Ariel et clôturer le pointage du sampling Coca-Cola." }
  ]);
  const prompts = [
    { id:'today', icon: CalendarDays, title:'Préparer ma journée', prompt:'Prépare ma journée et liste les priorités.' },
    { id:'activation', icon: Zap, title:'Lancer une activation', prompt:'Donne-moi une checklist de lancement d’activation retail.' },
    { id:'followup', icon: MessageCircle, title:'Rédiger une relance', prompt:'Rédige une relance professionnelle pour un BAT en attente.' },
    { id:'tasks', icon: ClipboardCheck, title:'Créer un plan d’action', prompt:'Transforme les validations en retard en plan d’action.' }
  ];
  const send = (text) => {
    const value=(text || input).trim(); if(!value) return;
    const lower=value.toLowerCase();
    let answer="Je peux préparer un brouillon, une checklist ou un plan d’action. Pour agir sur les données réelles, l’assistant devra être connecté aux outils autorisés et vérifier vos permissions.";
    if(lower.includes('journée') || lower.includes('priorit')) answer="Plan de journée proposé :\n1. Avant midi — obtenir la validation du BAT Galaxy et confirmer le bon à tirer final.\n2. Avant 15 h — récupérer les tailles et quantités d’uniformes Ariel.\n3. Fin de journée — vérifier le pointage du sampling Coca-Cola et signaler les écarts au chef de projet.\n\nJe peux convertir ces points en tâches assignables lorsque le backend sera connecté.";
    else if(lower.includes('activation') || lower.includes('checklist')) answer="Checklist de lancement : brief et objectifs validés → budget/devis et PO confirmés → magasins et dates verrouillés → recrutement/formation terminés → BAT, PLV et uniformes approuvés → stock préparé → dispatch confirmé → présence terrain planifiée → reporting, photos et bilan post-activation.";
    else if(lower.includes('relance') || lower.includes('bat')) answer="Objet : Relance — validation du BAT\n\nBonjour,\nNous revenons vers vous concernant le BAT en attente de validation. Afin de sécuriser le planning de production et la livraison, pourriez-vous nous transmettre votre retour ou votre bon pour accord ?\n\nMerci d’avance,\nL’équipe SMOLLAN Morocco\n\nBrouillon de démonstration — vérifiez le destinataire et les références avant envoi.";
    else if(lower.includes('plan d’action') || lower.includes('tâche')) answer="Plan d’action proposé :\n• BAT Galaxy — responsable projet, échéance aujourd’hui 12 h, dépendance : retour client.\n• Uniformes Ariel — responsable production, échéance aujourd’hui 15 h, dépendance : tailles finales.\n• Pointage sampling — responsable terrain, échéance demain 10 h, dépendance : validation des feuilles de présence.\n\nAucune tâche réelle n’a été créée dans cette maquette.";
    setMessages(prev=>[...prev,{role:'user',text:value},{role:'assistant',text:answer}]); setInput('');
  };
  return <>
    <div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> COPILOTE OPÉRATIONNEL</div><h1>Assistant IA<span className="title-period">.</span></h1><p className="page-subtitle">Un copilote pour aider chaque équipe à avancer, préparer et coordonner son travail.</p></div><span className="admin-preview-pill"><Bot size={14}/> IA · mode démo</span></div>
    <div className="demo-alert"><Bot size={17}/><div><strong>Assistant en mode démonstration</strong><span>Réponses simulées à partir d’exemples. Aucune donnée client réelle n’est consultée et aucune action n’est exécutée.</span></div><span className="demo-pill">PREVIEW</span></div>
    <div className="ai-workspace">
      <section className="panel ai-chat-panel">
        <div className="ai-chat-header"><div className="ai-avatar"><WandSparkles size={20}/></div><div><strong>SMOLLAN Copilot</strong><span><i/> Disponible · démo locale</span></div><button className="icon-button" onClick={()=>setMessages([{role:'assistant',text:"Nouvelle conversation. Que souhaitez-vous préparer ?"}])} aria-label="Nouvelle conversation"><Plus size={17}/></button></div>
        <div className="ai-context-strip"><span><FolderKanban size={13}/> Portefeuille</span><span><ClipboardCheck size={13}/> Tâches</span><span><CalendarDays size={13}/> Planning</span><span className="ai-context-demo">Données fictives</span></div>
        <div className="ai-messages">{messages.map((m,i)=><div key={i} className={'ai-message '+m.role}><div className="ai-message-avatar">{m.role==='assistant'?<Bot size={15}/>:<Users size={15}/>}</div><div className="ai-message-body"><span>{m.role==='assistant'?'SMOLLAN Copilot':'Vous'}</span><p>{m.text}</p></div></div>)}</div>
        <div className="ai-composer"><textarea value={input} onChange={e=>setInput(e.target.value)} onKeyDown={e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();send();}}} placeholder="Demandez un plan, un message, une checklist…" rows={2}/><div className="ai-composer-bottom"><span><Paperclip size={13}/> Connecteurs réels à configurer par Super Admin</span><button className="button-primary" onClick={()=>send()} disabled={!input.trim()}>Envoyer <Send size={14}/></button></div></div>
      </section>
      <aside className="ai-side-column"><section className="panel ai-suggestions"><div className="panel-header"><div><div className="section-eyebrow">POUR COMMENCER</div><h2>Raccourcis utiles</h2><p>Choisissez une tâche à préparer.</p></div></div><div className="ai-prompt-list">{prompts.map(p=>{const Icon=p.icon;return <button key={p.id} className={'ai-prompt '+(activePrompt===p.id?'selected':'')} onClick={()=>{setActivePrompt(p.id);send(p.prompt);}}><span><Icon size={16}/></span><div><strong>{p.title}</strong><small>{p.prompt}</small></div><ChevronRight size={15}/></button>;})}</div></section><section className="panel ai-capabilities"><div className="section-eyebrow">CAPACITÉS PRÉVUES</div><h3>De la question à l’action</h3><ul><li>Résumer les projets et les points bloquants</li><li>Préparer briefs, e-mails, relances et rapports</li><li>Transformer une demande en tâches assignées</li><li>Déclencher une automation après confirmation</li></ul><div className="security-note"><ShieldCheck size={15}/><span>Actions sensibles soumises aux permissions et à votre confirmation.</span></div></section></aside>
    </div>
  </>;
}

function WhatsAppPage({ acknowledge }) {
  const [selected, setSelected] = useState('field');
  const [draft, setDraft] = useState('');
  const [filter, setFilter] = useState('Tous');
  const [threads,setThreads]=useState([
    {id:'field',name:'Équipe terrain · Casablanca',avatar:'ET',color:'green',kind:'Groupe',time:'10:42',unread:3,preview:'Les photos du stand sont envoyées.',messages:[['other','Salma B.','Bonjour, le stand Galaxy est prêt pour le démarrage.'],['other','Yassine M.','Il manque encore deux polos taille M.'],['me','Vous','Merci, vérifiez le stock avant le départ.'],['other','Salma B.','Les photos du stand sont envoyées.']]},
    {id:'client',name:'Client · Activation Galaxy',avatar:'CG',color:'blue',kind:'Client',time:'09:18',unread:0,preview:'Merci pour le planning mis à jour.',messages:[['other','Client','Pouvez-vous confirmer le planning de samedi ?'],['me','Vous','Je vérifie avec le chef de projet et je reviens vers vous.'],['other','Client','Merci pour le planning mis à jour.']]},
    {id:'supplier',name:'Fournisseur · Production PLV',avatar:'FP',color:'amber',kind:'Fournisseur',time:'Hier',unread:1,preview:'Le BAT est prêt pour votre retour.',messages:[['other','Production PLV','Le BAT est prêt pour votre retour.'],['other','Production PLV','Nous attendons votre validation pour lancer la production.']]},
    {id:'hr',name:'Recrutement · Promotrices',avatar:'RH',color:'rose',kind:'Interne',time:'Hier',unread:0,preview:'Formation confirmée pour vendredi.',messages:[['other','Équipe RH','Formation confirmée pour vendredi.']]},
  ]);
  const thread=threads.find(t=>t.id===selected)||threads[0];
  const send=()=>{if(!draft.trim())return;setThreads(prev=>prev.map(t=>t.id===selected?{...t,preview:draft,time:'À l’instant',messages:[...t.messages,['me','Vous',draft]]}:t));setDraft('');acknowledge('Message ajouté à la conversation de démonstration — aucun WhatsApp réel envoyé.');};
  const visible=threads.filter(t=>(filter==='Tous'||(filter==='Non lus'&&t.unread>0)||t.kind===filter));
  return <>
    <div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> MESSAGERIE & COORDINATION</div><h1>WhatsApp Management<span className="title-period">.</span></h1><p className="page-subtitle">Centralisez les échanges terrain, clients et fournisseurs autour des activations.</p></div><span className="admin-preview-pill"><MessageCircle size={14}/> Canal non connecté</span></div>
    <div className="demo-alert"><MessageCircle size={17}/><div><strong>Boîte de réception fictive</strong><span>Messages et réponses simulés. La connexion réelle nécessitera WhatsApp Business Platform et un numéro autorisé.</span></div><span className="demo-pill">PREVIEW</span></div>
    <div className="wa-metrics"><div className="admin-stat"><span>Conversations</span><strong>{threads.length.toString().padStart(2,'0')}</strong><span className="admin-stat-note">dans la démo</span></div><div className="admin-stat"><span>Non lus</span><strong>{threads.reduce((n,t)=>n+t.unread,0).toString().padStart(2,'0')}</strong><span className="admin-stat-note">à traiter</span></div><div className="admin-stat"><span>Automations WhatsApp</span><strong>04</strong><span className="admin-stat-note">scénarios prévus</span></div></div>
    <div className="wa-layout"><section className="panel wa-inbox"><div className="wa-inbox-head"><strong>Boîte de réception</strong><button className="icon-button" onClick={()=>acknowledge('Synchronisation indisponible : connectez WhatsApp Business dans Super Admin.')} aria-label="Synchroniser"><Activity size={15}/></button></div><div className="wa-filters">{['Tous','Non lus','Groupe','Client','Fournisseur'].map(f=><button key={f} className={filter===f?'selected':''} onClick={()=>setFilter(f)}>{f}</button>)}</div><div className="wa-thread-list">{visible.map(t=><button key={t.id} className={'wa-thread '+(selected===t.id?'selected':'')} onClick={()=>setSelected(t.id)}><span className={'wa-contact-avatar '+t.color}>{t.avatar}</span><span className="wa-thread-copy"><strong>{t.name}</strong><small>{t.preview}</small></span><span className="wa-thread-meta"><small>{t.time}</small>{t.unread>0&&<i>{t.unread}</i>}</span></button>)}</div><div className="wa-connect-hint"><ShieldCheck size={14}/><span>Connexion et permissions à configurer dans Super Admin.</span></div></section>
    <section className="panel wa-conversation"><div className="wa-conversation-head"><span className={'wa-contact-avatar '+thread.color}>{thread.avatar}</span><div><strong>{thread.name}</strong><span>{thread.kind} · conversation de démonstration</span></div><button className="icon-button" onClick={()=>acknowledge('Fiche contact de démonstration.')} aria-label="Détails"><CircleHelp size={16}/></button></div><div className="wa-message-list">{thread.messages.map((m,i)=><div key={i} className={'wa-bubble-row '+(m[0]==='me'?'mine':'')}><div className="wa-bubble"><small>{m[1]}</small><p>{m[2]}</p><time>{i<2?'09:4'+i:'10:2'+i}</time></div></div>)}</div><div className="wa-reply-box"><textarea rows={2} value={draft} onChange={e=>setDraft(e.target.value)} onKeyDown={e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();send();}}} placeholder="Écrire une réponse (démo)…"/><div><span><Paperclip size={13}/> Réponse simulée</span><button className="button-primary" disabled={!draft.trim()} onClick={send}>Envoyer <Send size={14}/></button></div></div></section></div>
    <div className="wa-bottom-grid"><section className="panel wa-feature-card"><div className="admin-side-icon"><Workflow size={18}/></div><div><strong>Automatiser les échanges répétitifs</strong><p>Rappels de pointage, confirmation de dispatch, collecte de photos, relances de validation et escalades.</p></div><button className="button-secondary" onClick={()=>acknowledge('Ouvrez Automatisations pour préparer les scénarios WhatsApp.')}>Voir les scénarios <ArrowRight size={14}/></button></section><section className="panel wa-feature-card"><div className="admin-side-icon"><Bot size={18}/></div><div><strong>IA assistante de messagerie</strong><p>Résumer les fils, suggérer des réponses et extraire des tâches — après connexion autorisée.</p></div><button className="button-secondary" onClick={()=>acknowledge('Assistant IA disponible en mode démo dans le menu principal.')}>Assistant IA <ArrowRight size={14}/></button></section></div>
  </>;
}

function AutomationsPage({ acknowledge }) {
  const [automations,setAutomations]=useState([
    {id:1,name:'Rappel de pointage terrain',trigger:'Chaque jour · 09:00',detail:'Rappeler aux équipes de confirmer leur présence.',group:'Terrain',on:true},
    {id:2,name:'Alerte BAT en attente',trigger:'Si validation > 24 h',detail:'Alerter le chef de projet et proposer une relance.',group:'Production',on:true},
    {id:3,name:'Checklist avant dispatch',trigger:'À J-1 d’une activation',detail:'Vérifier stock, uniformes, adresses et contacts magasin.',group:'Logistique',on:true},
    {id:4,name:'Suivi PO et factures',trigger:'Chaque lundi · 10:00',detail:'Lister les PO manquants et les pièces fournisseurs attendues.',group:'Finance',on:false},
    {id:5,name:'Résumé WhatsApp terrain',trigger:'Chaque jour · 18:00',detail:'Préparer un résumé des incidents et actions à suivre.',group:'WhatsApp',on:false},
    {id:6,name:'Rapport de clôture activation',trigger:'Après la date de fin',detail:'Assembler présence, photos, KPI et éléments de facturation.',group:'Reporting',on:true},
  ]);
  const [filter,setFilter]=useState('Tous');
  const [showNew,setShowNew]=useState(false);
  const [name,setName]=useState('');
  const [trigger,setTrigger]=useState('À la création d’une tâche');
  const visible=automations.filter(a=>filter==='Tous'||a.group===filter||(filter==='Actives'&&a.on)||(filter==='Inactives'&&!a.on));
  const toggle=id=>setAutomations(prev=>prev.map(a=>a.id===id?{...a,on:!a.on}:a));
  const add=()=>{if(!name.trim())return;setAutomations(prev=>[{id:Date.now(),name:name.trim(),trigger,detail:'Nouveau scénario — étapes à configurer.',group:'Personnalisée',on:false},...prev]);setName('');setShowNew(false);acknowledge('Automation ajoutée à la démo. Elle reste inactive tant que ses étapes ne sont pas configurées.');};
  return <>
    <div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> WORKFLOWS & RÈGLES MÉTIER</div><h1>Automatisations<span className="title-period">.</span></h1><p className="page-subtitle">Réduisez les relances manuelles et sécurisez les étapes clés des opérations.</p></div><button className="button-primary" onClick={()=>setShowNew(v=>!v)}><Plus size={15}/> Nouvelle automation</button></div>
    <div className="demo-alert"><Workflow size={17}/><div><strong>Scénarios en mode démo</strong><span>Les interrupteurs modifient seulement cet écran. Aucun message, e-mail ou workflow réel n’est déclenché.</span></div><span className="demo-pill">PREVIEW</span></div>
    <div className="automation-summary"><div><span>Scénarios</span><strong>{automations.length.toString().padStart(2,'0')}</strong></div><div><span>Actifs en démo</span><strong>{automations.filter(a=>a.on).length.toString().padStart(2,'0')}</strong></div><div><span>À configurer</span><strong>{automations.filter(a=>!a.on).length.toString().padStart(2,'0')}</strong></div><div><span>Dernière exécution réelle</span><strong>—</strong></div></div>
    {showNew&&<section className="panel automation-new"><div><strong>Créer un scénario</strong><p>Définissez un nom et un déclencheur de départ.</p></div><div className="automation-new-fields"><input value={name} onChange={e=>setName(e.target.value)} placeholder="Ex. Relance des rapports terrain"/><select value={trigger} onChange={e=>setTrigger(e.target.value)}><option>À la création d’une tâche</option><option>À l’approche d’une échéance</option><option>Après une activation</option><option>À la réception d’un message WhatsApp</option><option>Selon un calendrier</option></select><button className="button-primary" onClick={add} disabled={!name.trim()}>Ajouter</button></div></section>}
    <div className="automation-toolbar"><div className="filter-tabs">{['Tous','Actives','Inactives','Terrain','Production','Logistique','Finance','WhatsApp','Reporting'].map(f=><button key={f} className={filter===f?'selected':''} onClick={()=>setFilter(f)}>{f}</button>)}</div></div>
    <div className="automation-grid">{visible.map(a=><section className="panel automation-card" key={a.id}><div className="automation-card-top"><span className="automation-icon"><Workflow size={17}/></span><button className={'admin-toggle '+(a.on?'on':'')} aria-label={(a.on?'Désactiver ':'Activer ')+a.name} onClick={()=>toggle(a.id)}><span/></button></div><span className="automation-category">{a.group}</span><h3>{a.name}</h3><p>{a.detail}</p><div className="automation-trigger"><Clock3 size={13}/><span>{a.trigger}</span></div><div className="automation-card-foot"><span className={'admin-status '+(a.on?'connected':'not-connected')}><i/>{a.on?'Activée en démo':'Inactive'}</span><button className="text-button" onClick={()=>acknowledge('Éditeur d’étapes disponible lorsque le moteur d’automatisation sera connecté.')}>Configurer <ArrowRight size={13}/></button></div></section>)}</div>
    <section className="panel automation-flow"><div className="panel-header"><div><div className="section-eyebrow">MODÈLE DE WORKFLOW</div><h2>Un workflow, des garde-fous</h2><p>Les automatisations réelles suivront une chaîne vérifiable.</p></div></div><div className="flow-steps"><div><span>01</span><strong>Déclencheur</strong><small>Événement ou horaire</small></div><ArrowRight size={16}/><div><span>02</span><strong>Vérifications</strong><small>Rôle, données et conditions</small></div><ArrowRight size={16}/><div><span>03</span><strong>Action</strong><small>Créer, notifier ou préparer</small></div><ArrowRight size={16}/><div><span>04</span><strong>Journal</strong><small>Trace et résultat</small></div></div></section>
  </>;
}

function SuperAdminPage({ acknowledge }) {
  const [tab, setTab] = useState('integrations');
  const [domain, setDomain] = useState('smollan.com');
  const [clientId, setClientId] = useState('');
  const [allowedScopes, setAllowedScopes] = useState(['openid', 'email', 'profile']);
  const [enabled, setEnabled] = useState({ google: false, drive: false, calendar: false, gmail: false, meet: false, whatsapp: false, supabase: false, ai: false });
  const integrations = [
    { id: 'google', name: 'Google Workspace SSO', detail: 'OAuth 2.0 · smollan.com', group: 'IDENTITY', tone: 'blue' },
    { id: 'drive', name: 'Google Drive', detail: 'Fichiers projet & documents finance', group: 'WORKSPACE', tone: 'green' },
    { id: 'calendar', name: 'Google Calendar', detail: 'Planning activations & équipes', group: 'WORKSPACE', tone: 'blue' },
    { id: 'gmail', name: 'Gmail', detail: 'Références de communication', group: 'WORKSPACE', tone: 'rose' },
    { id: 'meet', name: 'Google Meet', detail: 'Réunions & comptes rendus', group: 'WORKSPACE', tone: 'amber' },
    { id: 'whatsapp', name: 'WhatsApp Business', detail: 'Notifications via fournisseur officiel', group: 'MESSAGING', tone: 'green' },
    { id: 'supabase', name: 'Supabase', detail: 'Auth, base de données & RLS', group: 'PLATFORM', tone: 'green' },
    { id: 'ai', name: 'Assistant IA / fournisseur LLM', detail: 'API serveur · clés privées hors navigateur', group: 'AI', tone: 'purple' },
  ];
  const scopes = [
    ['openid', 'Identité OpenID'], ['email', 'Adresse e-mail'], ['profile', 'Profil de base'],
    ['drive.file', 'Drive — fichiers créés / partagés avec l’application'],
    ['calendar.events', 'Calendar — événements'], ['gmail.readonly', 'Gmail — lecture seule (à justifier)']
  ];
  const toggleScope = (scope) => setAllowedScopes(current => current.includes(scope) ? current.filter(s => s !== scope) : [...current, scope]);
  return <>
    <div className="page-heading-row"><div><div className="eyebrow"><span className="eyebrow-dot"/> CONTRÔLE & SÉCURITÉ</div><h1>Super Admin<span className="title-period">.</span></h1><p className="page-subtitle">Configuration centralisée des API, OAuth, accès et connexions de la plateforme.</p></div><span className="admin-preview-pill"><ShieldCheck size={14}/> Mode démo · accès simulé</span></div>
    <div className="demo-alert"><ShieldCheck size={17}/><div><strong>Console de configuration — maquette uniquement</strong><span>Aucun secret n’est envoyé ni enregistré. L’autorisation Super Admin réelle devra être vérifiée côté serveur avant la mise en production.</span></div><span className="demo-pill">PREVIEW</span></div>
    <div className="admin-stat-grid"><div className="admin-stat"><span>Intégrations configurées</span><strong>{Object.values(enabled).filter(Boolean).length}<small> / {integrations.length}</small></strong><span className="admin-stat-note">état local de démonstration</span></div><div className="admin-stat"><span>Domaines autorisés</span><strong>01</strong><span className="admin-stat-note">smollan.com · à vérifier côté serveur</span></div><div className="admin-stat"><span>Secrets exposés au navigateur</span><strong className="safe-zero">0</strong><span className="admin-stat-note">les clés privées restent côté serveur</span></div></div>
    <div className="admin-tabs">{[['integrations','Intégrations & API'],['oauth','OAuth & accès'],['security','Sécurité & audit']].map(([id,label])=><button key={id} className={tab===id?'selected':''} onClick={()=>setTab(id)}>{label}</button>)}</div>
    {tab==='integrations' && <div className="admin-layout"><section className="panel admin-integrations"><div className="panel-header"><div><div className="section-eyebrow">CONNEXIONS</div><h2>Services de la plateforme</h2><p>Activez les services dans la démo pour prévisualiser leur état.</p></div><span className="admin-lock"><LockKeyhole size={14}/> Secrets serveur</span></div><div className="admin-integration-list">{integrations.map(item=><div className="admin-integration-row" key={item.id}><div className={'admin-service-icon '+item.tone}>{item.id==='google'?'G':item.id==='supabase'?'S':item.id==='ai'?'AI':item.id==='whatsapp'?'W':item.id==='drive'?'D':item.id==='calendar'?'C':item.id==='gmail'?'M':'M'}</div><div className="admin-service-copy"><strong>{item.name}</strong><span>{item.detail}</span><small>{item.group}</small></div><span className={'admin-status '+(enabled[item.id]?'connected':'not-connected')}><i/>{enabled[item.id]?'Démo activée':'Non configurée'}</span><button className={'admin-toggle '+(enabled[item.id]?'on':'')} aria-label={(enabled[item.id]?'Désactiver ':'Activer ')+item.name} onClick={()=>setEnabled(current=>({...current,[item.id]:!current[item.id]}))}><span/></button></div>)}</div></section><aside className="panel admin-side-card"><div className="admin-side-icon"><KeyRound size={19}/></div><div className="section-eyebrow">GESTION DES SECRETS</div><h3>Pas de clés dans le frontend</h3><p>Les API keys privées, refresh tokens et client secrets seront stockés dans les variables d’environnement / coffre serveur, jamais dans le code client.</p><div className="vault-row"><LockKeyhole size={15}/><div><strong>Secret vault</strong><span>À connecter côté serveur</span></div><span className="vault-badge">À FAIRE</span></div><button className="button-secondary full-width" onClick={()=>acknowledge('Préparation notée : configurer les secrets via l’environnement serveur sécurisé, pas dans cette maquette.')}>Voir les prérequis <ArrowRight size={14}/></button></aside></div>}
    {tab==='oauth' && <div className="admin-layout"><section className="panel admin-config-panel"><div className="panel-header"><div><div className="section-eyebrow">IDENTITÉ</div><h2>Google OAuth & domaine</h2><p>Valeurs de préconfiguration — aucune connexion réelle n’est active.</p></div><span className="admin-status not-connected"><i/> Non connecté</span></div><div className="admin-form"><label htmlFor="admin-domain">Domaine autorisé</label><input id="admin-domain" value={domain} onChange={e=>setDomain(e.target.value)} /><p className="field-hint">Validation serveur requise : email_verified = true, domaine exact et membre actif autorisé.</p><label htmlFor="google-client-id">Google OAuth Client ID</label><input id="google-client-id" value={clientId} onChange={e=>setClientId(e.target.value)} placeholder="À renseigner par l’admin Google Workspace"/><p className="field-hint">Le Client ID n’est pas le Client Secret. Le secret ne doit jamais être saisi ici.</p><label>Scopes demandés</label><div className="scope-list">{scopes.map(([id,label])=><label key={id} className="scope-option"><input type="checkbox" checked={allowedScopes.includes(id)} onChange={()=>toggleScope(id)}/><span>{label}</span>{id==='gmail.readonly'&&<em>À justifier</em>}</label>)}</div><div className="admin-readonly-row"><span>Redirect URI Supabase</span><code>https://&lt;project-ref&gt;.supabase.co/auth/v1/callback</code><button className="text-button" onClick={()=>GenUICopyRedirect(acknowledge)}>Copier la structure</button></div><button className="button-primary" onClick={()=>acknowledge('Configuration OAuth enregistrée uniquement dans l’état de cette démo. Aucune clé ou connexion n’a été créée.')}>Enregistrer la préconfiguration <ArrowRight size={14}/></button></div></section><aside className="panel admin-side-card"><div className="admin-side-icon"><ShieldCheck size={19}/></div><div className="section-eyebrow">RÈGLES D’ACCÈS</div><h3>Allowlist + membership</h3><ul className="admin-rule-list"><li>Adresse e-mail vérifiée par Google</li><li>Domaine exact <strong>@{domain || 'smollan.com'}</strong></li><li>Membership SMOLLAN actif et rôle autorisé</li><li>Rôles contrôlés côté serveur / RLS</li></ul><div className="security-note"><ShieldCheck size={15}/><span>Masquer un bouton ne protège pas une API : chaque endpoint doit vérifier le rôle.</span></div></aside></div>}
    {tab==='security' && <div className="admin-layout"><section className="panel admin-config-panel"><div className="panel-header"><div><div className="section-eyebrow">GOUVERNANCE</div><h2>Garde-fous de sécurité</h2><p>État attendu avant de brancher des données réelles.</p></div></div><div className="admin-security-list">{[['Rôles côté serveur','Super Admin / Admin / Manager / Finance / Terrain','À implémenter'],['Audit trail','Tracer les changements de configuration et d’accès','Prévu'],['RLS Supabase','Politiques testées par rôle et par action','À vérifier'],['Secrets & rotation','Secrets chiffrés côté serveur, rotation documentée','À configurer'],['OAuth scopes','Scopes minimaux, consentement explicite','À valider']].map(([title,detail,status])=><div className="admin-security-row" key={title}><ShieldCheck size={17}/><div><strong>{title}</strong><span>{detail}</span></div><span className="admin-status not-connected"><i/>{status}</span></div>)}</div></section><aside className="panel admin-side-card"><div className="admin-side-icon"><Activity size={19}/></div><div className="section-eyebrow">AUDIT</div><h3>Journal d’administration</h3><p>La version connectée enregistrera qui a changé quoi, quand et depuis quelle session — sans jamais journaliser les valeurs de secrets.</p><button className="button-secondary full-width" onClick={()=>acknowledge('Le journal d’audit réel sera activé avec le backend et les politiques d’accès.')}>Vérifier le journal <ArrowRight size={14}/></button></aside></div>}
  </>;
}

function GenUICopyRedirect(acknowledge) {
  acknowledge('Structure de callback : https://<project-ref>.supabase.co/auth/v1/callback — remplacez <project-ref> par la référence du projet dédié SMOLLAN.');
}

export default App;
