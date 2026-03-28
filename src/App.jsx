import React, { useState, useMemo, useEffect } from 'react';
import { 
  LayoutDashboard, Users, FileText, Package, Search, 
  AlertTriangle, CheckCircle, Clock, Download, UserPlus, 
  History, Smartphone, ChevronRight, Filter, LogOut, 
  MapPin, Shirt, ShieldCheck, X, Eye, CreditCard, 
  UserCircle, Briefcase, Building2, Calendar, Edit3, ArrowRightLeft,
  TrendingUp, BarChart3, Layers, Mail, FileStack, Settings, 
  MonitorSmartphone, Database
} from 'lucide-react';

// --- CONFIGURATION & GÉNÉRATEUR DE DONNÉES CENTRALISÉ ---
const AGENCES = ["ARTUS", "SOS Interim", "Crit", "Interne"];
const CLIENTS = ["Samsung", "L'Oréal", "Coca-Cola", "P&G", "Nestlé", "Unilever", "Danone"];
const VILLES = ["Casablanca", "Rabat", "Marrakech", "Tanger", "Agadir", "Fès", "Oujda"];
const STORES = ["Marjane", "Carrefour", "BIM", "LabelVie", "Acima"];

const PROJETS_PAR_CLIENT = {
  "Samsung": ["Lancement S24", "Promo Galaxy Tab", "Roadshow Z-Flip"],
  "L'Oréal": ["Gamme Revitalift", "Coloration Excellence", "Lancement Parfum"],
  "Coca-Cola": ["Campagne Ramadan", "Sampling Euro2024", "Zero Sugar Tour"],
  "P&G": ["Ariel Pods Demo", "Pampers Premium", "Gillette Labs"],
  "Nestlé": ["Nescafé Gold", "Fitness Breakfast", "Purina Pro Plan"],
  "Unilever": ["Dove Spa", "Magnum Pleasure Store", "Skip Ultimate"],
  "Danone": ["Activia Challenge", "Danup Promo", "Centrale Laitière"]
};

const generateExpiryDate = (index) => {
  const d = new Date();
  if (index % 15 === 0) d.setDate(d.getDate() + 3); 
  else if (index % 10 === 0) d.setDate(d.getDate() - 2); 
  else d.setDate(d.getDate() + (30 + (index % 60))); 
  return d.toISOString().split('T')[0];
};

const generateInitialData = (count) => {
  const lastNames = ["Bennani", "Alami", "Idrissi", "Mansouri", "Kabbaj", "Tazi", "Zouhair", "Fassi", "Chraibi", "Amrani"];
  const firstNames = ["Sara", "Mehdi", "Yassine", "Leila", "Driss", "Zineb", "Omar", "Meryem", "Hamza", "Anas"];
  
  return Array.from({ length: count }, (_, i) => {
    const client = CLIENTS[i % CLIENTS.length];
    const projets = PROJETS_PAR_CLIENT[client];
    const projet = projets[Math.floor(Math.random() * projets.length)];
    const status = Math.random() > 0.15 ? "Active" : "Disponible";
    
    return {
      id: i + 1,
      nom: lastNames[Math.floor(Math.random() * lastNames.length)],
      prenom: firstNames[Math.floor(Math.random() * firstNames.length)],
      cin: `${String.fromCharCode(65 + (i % 26))}${String.fromCharCode(66 + (i % 26))}${100000 + i}`,
      type: i % 3 === 0 ? "Permanante" : "Ponctuelle",
      agence: AGENCES[Math.floor(Math.random() * AGENCES.length)],
      phones: { pro: `0661${100000 + i}`, perso: `0670${200000 + i}` },
      photos: {
        profile: `https://i.pravatar.cc/150?u=smollan${i}`,
        cinRecto: "https://images.unsplash.com/photo-1554126807-6b10f6f6692a?w=400&q=80",
        cinVerso: "https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=400&q=80"
      },
      rh: { statut: status, joined: "2023-01-01" },
      affectation: { 
        client, projet,
        magasin: STORES[Math.floor(Math.random() * STORES.length)],
        ville: VILLES[Math.floor(Math.random() * VILLES.length)],
      },
      logistique: { 
        taille: ["S", "M", "L", "XL"][Math.floor(Math.random() * 4)], 
        statutUniforme: status === "Active" ? "Reçu" : "Restitué", 
        tablette: i % 4 === 0 ? `SN-TAB-${888000 + i}` : "N/A" 
      },
      pec: { fin: generateExpiryDate(i), etat: i % 12 === 0 ? "Manquant" : "Original Papier" },
      historique: [{ client: "Historique", projet: "Mission Q4 2023", magasin: "LabelVie", date: "2023-11-20" }]
    };
  });
};

const INITIAL_DB = generateInitialData(258);

// --- VISUAL ENGINE ---
const VisualEffects = () => {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  useEffect(() => {
    const handleMouseMove = (e) => setMousePos({ x: e.clientX, y: e.clientY });
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return (
    <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden bg-[#010413]">
      <div className="absolute top-[-20%] left-[-10%] w-[60%] h-[60%] bg-blue-600/10 blur-[180px] rounded-full animate-pulse" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[60%] h-[60%] bg-indigo-600/10 blur-[180px] rounded-full" />
      <div className="absolute w-[800px] h-[800px] bg-blue-500/5 blur-[140px] rounded-full transition-transform duration-700 ease-out"
        style={{ transform: `translate(${mousePos.x - 400}px, ${mousePos.y - 400}px)` }} />
      <div className="absolute inset-0 opacity-20">
        {[...Array(40)].map((_, i) => (
          <div key={i} className="absolute bg-white rounded-full blur-[1px] animate-float"
            style={{ width: '2px', height: '2px', top: Math.random() * 100 + '%', left: Math.random() * 100 + '%', animationDelay: `${i*0.5}s` }} />
        ))}
      </div>
      <style>{`@keyframes float { 0%, 100% { transform: translate(0,0); } 50% { transform: translate(40px, -40px); } } .animate-float { animation: float 15s infinite linear; }`}</style>
    </div>
  );
};

const GlassCard = ({ children, className = "" }) => (
  <div className={`backdrop-blur-3xl bg-white/[0.03] border border-white/10 rounded-[32px] shadow-2xl transition-all duration-500 ${className}`}>
    {children}
  </div>
);

const Badge = ({ dateFin }) => {
  const today = new Date();
  const end = new Date(dateFin);
  const diff = Math.ceil((end - today) / (1000 * 60 * 60 * 24));
  if (diff < 0) return <span className="px-3 py-1 rounded-full text-[9px] font-black bg-red-500/20 text-red-400 border border-red-500/20 uppercase">Expiré</span>;
  if (diff <= 7) return <span className="px-3 py-1 rounded-full text-[9px] font-black bg-orange-500/20 text-orange-400 border border-orange-500/20 uppercase tracking-widest">J-{diff}</span>;
  return <span className="px-3 py-1 rounded-full text-[9px] font-black bg-green-500/20 text-green-400 border border-green-500/20 uppercase">Valide</span>;
};

// --- APP COMPONENT ---
const App = () => {
  const [view, setView] = useState('dashboard');
  const [data, setData] = useState(INITIAL_DB);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAnimator, setSelectedAnimator] = useState(null);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [isReassignModalOpen, setIsReassignModalOpen] = useState(false);
  const [selectedAgencyFilter, setSelectedAgencyFilter] = useState("TOUTES");

  // Global Sync Stats
  const globalStats = useMemo(() => {
    const actives = data.filter(a => a.rh.statut === 'Active');
    const alerts = data.filter(a => (new Date(a.pec.fin) - new Date()) / (1000 * 60 * 60 * 24) <= 7);
    const tablets = data.filter(a => a.logistique.tablette !== 'N/A').length;
    return { total: data.length, actives: actives.length, alerts: alerts.length, tablets, projects: 18 };
  }, [data]);

  const filteredData = data.filter(a => 
    (a.nom + a.prenom + a.cin + a.agence + a.affectation.projet).toLowerCase().includes(searchTerm.toLowerCase()) &&
    (selectedAgencyFilter === "TOUTES" || a.agence === selectedAgencyFilter)
  );

  const handleUpdatePec = (id) => {
    setData(prev => prev.map(a => {
      if (a.id === id) {
        const nextYear = new Date(); nextYear.setFullYear(nextYear.getFullYear() + 1);
        return { ...a, pec: { fin: nextYear.toISOString().split('T')[0], etat: "Original Papier" } };
      }
      return a;
    }));
  };

  const handleMutation = (animId, newAffect) => {
    setData(prev => prev.map(a => {
      if (a.id === animId) {
        const h = { ...a.affectation, date: new Date().toLocaleDateString() };
        return { ...a, affectation: { ...a.affectation, ...newAffect }, rh: { statut: 'Active' }, historique: [h, ...a.historique] };
      }
      return a;
    }));
    setIsReassignModalOpen(false);
  };

  // --- SUB-VIEWS ---

  const Sidebar = () => (
    <div className="w-72 fixed left-0 top-0 h-screen z-30 p-6">
      <GlassCard className="h-full flex flex-col p-4 border-white/5">
        <div className="flex items-center gap-4 px-3 py-8 mb-8 border-b border-white/5">
          <div className="w-12 h-12 bg-blue-600 rounded-2xl flex items-center justify-center font-black text-white shadow-[0_0_20px_rgba(37,99,235,0.4)]">S</div>
          <div>
            <h1 className="text-white font-black text-xl tracking-tighter">SMOLLAN</h1>
            <p className="text-[9px] text-blue-400 font-black uppercase tracking-[0.3em] mt-1 italic">Activation Hub</p>
          </div>
        </div>
        <nav className="flex-1 space-y-2">
          {[
            { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
            { id: 'base', label: 'Base Animatrices', icon: Users },
            { id: 'control', label: 'Control Tower', icon: Briefcase },
            { id: 'agences', label: 'Suivi Agences', icon: ShieldCheck },
            { id: 'inventory', label: 'Inventaire Global', icon: Package },
          ].map((item) => (
            <button key={item.id} onClick={() => setView(item.id)}
              className={`w-full flex items-center gap-4 px-5 py-4 rounded-2xl transition-all duration-500 ${
                view === item.id ? 'bg-blue-600 text-white shadow-xl' : 'text-slate-400 hover:bg-white/5 hover:text-white'
              }`}>
              <item.icon size={18} />
              <span className="text-sm font-bold">{item.label}</span>
            </button>
          ))}
        </nav>
        <div className="pt-6 border-t border-white/5 flex flex-col gap-2">
           <button className="flex items-center gap-3 px-4 py-3 text-red-400 hover:bg-red-500/10 rounded-2xl transition-all font-bold text-sm"><LogOut size={18}/> Quitter</button>
           <p className="text-[10px] text-slate-600 font-bold uppercase tracking-widest text-center mt-2">v4.8.2 Stable Build</p>
        </div>
      </GlassCard>
    </div>
  );

  const ControlTower = () => (
    <div className="p-10 space-y-10 animate-in fade-in duration-700 overflow-y-auto">
      <header className="flex justify-between items-end">
        <div>
          <h2 className="text-4xl font-black text-white tracking-tighter italic uppercase">Control Tower Projets</h2>
          <p className="text-slate-400 mt-2 font-medium">Monitoring des {CLIENTS.length} clients et 18+ projets</p>
        </div>
        <div className="bg-white/5 border border-white/10 px-6 py-3 rounded-2xl text-white font-bold text-sm flex items-center gap-2 tracking-widest uppercase">
          <Database size={16} className="text-blue-500"/> Synchronisé
        </div>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {CLIENTS.map(client => {
          const clientStaff = data.filter(a => a.affectation.client === client);
          return (
            <GlassCard key={client} className="p-8 hover:border-blue-500/30">
               <div className="flex justify-between items-center mb-6">
                 <h3 className="text-2xl font-black text-white">{client}</h3>
                 <span className="bg-blue-600/10 text-blue-400 px-3 py-1 rounded-full text-[10px] font-black border border-blue-500/20">{clientStaff.length} AGENTS</span>
               </div>
               <div className="space-y-4">
                 {PROJETS_PAR_CLIENT[client].map(proj => {
                   const count = clientStaff.filter(a => a.affectation.projet === proj).length;
                   return (
                     <div key={proj} className="p-5 rounded-2xl bg-white/[0.02] border border-white/5 flex justify-between items-center group hover:bg-white/[0.05] transition-all">
                        <div>
                          <p className="text-white text-sm font-bold">{proj}</p>
                          <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">Top Magasins: Marjane, LabelVie</p>
                        </div>
                        <div className="text-right">
                          <p className="text-blue-500 font-black">{count}</p>
                          <p className="text-[9px] text-slate-600 uppercase font-black">Effectif</p>
                        </div>
                     </div>
                   );
                 })}
               </div>
            </GlassCard>
          );
        })}
      </div>
    </div>
  );

  const InventoryView = () => (
    <div className="p-10 space-y-10 animate-in fade-in duration-700 overflow-y-auto">
      <header>
        <h2 className="text-4xl font-black text-white tracking-tighter italic uppercase">Inventaire Global Assets</h2>
        <p className="text-slate-400 mt-2 font-medium italic">Tracking des 258 kits (Uniformes & IT)</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <GlassCard className="p-8 lg:col-span-1">
           <h3 className="text-white text-xl font-black mb-8 flex items-center gap-3 uppercase italic"><Shirt className="text-amber-500"/> Uniformes</h3>
           <div className="space-y-6">
             {['S', 'M', 'L', 'XL'].map(size => {
               const count = data.filter(a => a.logistique.taille === size).length;
               const percent = (count / data.length) * 100;
               return (
                 <div key={size} className="space-y-2">
                   <div className="flex justify-between text-[10px] font-black text-slate-500 uppercase tracking-widest">
                     <span>Taille {size}</span>
                     <span className="text-white">{count} UNITÉS</span>
                   </div>
                   <div className="h-2 w-full bg-white/5 rounded-full overflow-hidden">
                     <div className="h-full bg-amber-500 rounded-full" style={{ width: `${percent}%` }}></div>
                   </div>
                 </div>
               );
             })}
           </div>
        </GlassCard>

        <GlassCard className="p-8 lg:col-span-2">
          <h3 className="text-white text-xl font-black mb-8 flex items-center gap-3 uppercase italic"><Smartphone className="text-blue-500"/> Parc IT & Tablettes</h3>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 max-h-[400px] overflow-y-auto custom-scrollbar pr-2">
            {data.filter(a => a.logistique.tablette !== 'N/A').map(a => (
              <div key={a.id} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5 flex flex-col justify-between hover:bg-white/[0.08] transition-all">
                <p className="text-[10px] text-blue-400 font-black uppercase tracking-widest mb-2">{a.logistique.tablette}</p>
                <p className="text-white text-xs font-bold truncate">{a.nom} {a.prenom}</p>
                <div className="flex justify-between items-center mt-3 pt-3 border-t border-white/5">
                  <span className="text-[9px] text-green-400 font-black">EN LIGNE</span>
                  <MonitorSmartphone size={14} className="text-slate-600"/>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>
      </div>
    </div>
  );

  const AgencesView = () => {
    const alertsByAgency = filteredData.filter(a => {
      const diff = (new Date(a.pec.fin) - new Date()) / (1000 * 60 * 60 * 24);
      return diff <= 7;
    }).length;

    return (
      <div className="p-10 space-y-10 animate-in fade-in duration-500 overflow-y-auto">
        <header className="flex flex-col lg:flex-row justify-between items-start lg:items-end gap-6">
          <div>
            <h2 className="text-4xl font-black text-white tracking-tighter italic uppercase">Suivi Agences & PEC</h2>
            <p className="text-slate-400 mt-2 font-medium">Gestion contractuelle des {selectedAgencyFilter === "TOUTES" ? "4" : "1"} partenaires</p>
          </div>
          <div className="flex bg-white/5 p-2 rounded-[24px] border border-white/10 backdrop-blur-xl">
             {["TOUTES", ...AGENCES].map(ag => (
               <button key={ag} onClick={() => setSelectedAgencyFilter(ag)}
                className={`px-5 py-3 rounded-2xl text-[10px] font-black transition-all ${
                  selectedAgencyFilter === ag ? 'bg-blue-600 text-white shadow-lg' : 'text-slate-500 hover:text-white'
                }`}>
                 {ag}
               </button>
             ))}
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
           <GlassCard className="p-8 border-l-4 border-l-blue-600">
             <p className="text-[10px] font-black text-slate-500 uppercase mb-2 tracking-widest">Effectif Sélectionné</p>
             <h3 className="text-5xl font-black text-white tracking-tighter tabular-nums">{filteredData.length}</h3>
           </GlassCard>
           <GlassCard className="p-8 border-l-4 border-l-red-500">
             <p className="text-[10px] font-black text-slate-500 uppercase mb-2 tracking-widest">Contrats à Renouveler</p>
             <h3 className="text-5xl font-black text-red-500 tracking-tighter tabular-nums">{alertsByAgency}</h3>
           </GlassCard>
           <GlassCard className="p-8 border-l-4 border-l-green-500">
              <p className="text-[10px] font-black text-slate-500 uppercase mb-2 tracking-widest">Conformité Globale</p>
              <h3 className="text-5xl font-black text-green-500 tracking-tighter tabular-nums">{Math.round(((filteredData.length - alertsByAgency) / filteredData.length) * 100)}%</h3>
           </GlassCard>
        </div>

        <GlassCard className="overflow-hidden">
          <div className="p-6 bg-white/[0.02] border-b border-white/5 flex justify-between items-center">
             <h4 className="text-white font-black text-xs uppercase tracking-[0.3em] italic">Liste Contractuelle : {selectedAgencyFilter}</h4>
             <button className="bg-blue-600 text-white px-6 py-3 rounded-2xl text-[10px] font-black uppercase hover:bg-blue-700 transition-all flex items-center gap-2 shadow-xl">
                <Mail size={16} /> Demande de PEC Groupée
             </button>
          </div>
          <div className="max-h-[500px] overflow-y-auto custom-scrollbar">
            <table className="w-full text-left">
              <thead className="bg-[#020617] sticky top-0 z-10 text-[10px] font-black text-slate-500 uppercase tracking-widest border-b border-white/5">
                <tr>
                  <th className="px-8 py-5">Agent</th>
                  <th className="px-8 py-5">Échéance PEC</th>
                  <th className="px-8 py-5">Status</th>
                  <th className="px-8 py-5">Projet</th>
                  <th className="px-8 py-5 text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {filteredData.map(a => (
                  <tr key={a.id} className="group hover:bg-white/[0.02] transition-all">
                    <td className="px-8 py-5 flex items-center gap-4">
                       <img src={a.photos.profile} className="w-10 h-10 rounded-xl" />
                       <div>
                         <p className="text-white text-sm font-bold leading-tight">{a.nom} {a.prenom}</p>
                         <p className="text-[10px] text-slate-500 font-mono tracking-tighter">{a.cin}</p>
                       </div>
                    </td>
                    <td className="px-8 py-5">
                       <p className="text-sm text-white font-mono font-bold tracking-tight italic">{a.pec.fin}</p>
                    </td>
                    <td className="px-8 py-5">
                       <Badge dateFin={a.pec.fin} />
                    </td>
                    <td className="px-8 py-5">
                       <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest">{a.affectation.projet}</p>
                    </td>
                    <td className="px-8 py-5 text-center">
                       <button onClick={() => handleUpdatePec(a.id)}
                        className="p-3 bg-white/5 text-blue-500 hover:bg-blue-600 hover:text-white rounded-2xl transition-all shadow-xl group/btn">
                         <FileStack size={20} className="group-hover/btn:scale-110 transition-transform" />
                       </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </GlassCard>
      </div>
    );
  };

  const AnimatorList = () => (
    <div className="p-10 space-y-10 animate-in fade-in duration-500">
      <header className="flex justify-between items-end">
        <div>
          <h2 className="text-4xl font-black text-white tracking-tighter italic uppercase underline decoration-blue-600 decoration-4 underline-offset-8">Base de Données</h2>
          <p className="text-slate-400 mt-4 font-medium italic">Accès aux {data.length} dossiers agents</p>
        </div>
        <div className="flex gap-4">
           <div className="relative group">
              <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-500 group-hover:text-blue-500 transition-colors" size={20} />
              <input type="text" placeholder="Recherche massive (CIN, Agence, Projet)..."
                className="bg-white/5 border border-white/10 rounded-full pl-14 pr-8 py-4 text-white text-sm focus:ring-4 focus:ring-blue-500/20 outline-none w-[450px] transition-all backdrop-blur-xl"
                value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
           </div>
        </div>
      </header>

      <GlassCard className="overflow-hidden">
        <div className="max-h-[600px] overflow-y-auto custom-scrollbar">
          <table className="w-full text-left border-collapse">
            <thead className="sticky top-0 z-10 bg-[#020617] backdrop-blur-md border-b border-white/10">
              <tr className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                <th className="px-8 py-6">Fiche Agent</th>
                <th className="px-8 py-6">Contrat & Interim</th>
                <th className="px-8 py-6">Mission & Point de Vente</th>
                <th className="px-8 py-6">Validité PEC</th>
                <th className="px-8 py-6 text-center">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filteredData.map(a => (
                <tr key={a.id} className="group hover:bg-white/[0.04] transition-all duration-300">
                  <td className="px-8 py-6 flex items-center gap-5">
                    <img src={a.photos?.profile} className="w-14 h-14 rounded-2xl object-cover border-2 border-white/10 group-hover:border-blue-500/40 transition-all" />
                    <div>
                      <p className="text-white font-black text-lg group-hover:text-blue-400 transition-colors leading-none">{a.nom} {a.prenom}</p>
                      <p className="text-[10px] text-slate-500 font-mono tracking-widest uppercase mt-1 italic">{a.cin}</p>
                    </div>
                  </td>
                  <td className="px-8 py-6">
                    <p className="text-sm text-white font-black">{a.agence}</p>
                    <p className="text-[10px] text-blue-500 font-black uppercase tracking-widest mt-0.5">{a.type}</p>
                  </td>
                  <td className="px-8 py-6">
                    <p className="text-white text-sm font-black">{a.affectation?.projet}</p>
                    <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tight italic">{a.affectation?.magasin} • {a.affectation?.ville}</p>
                  </td>
                  <td className="px-8 py-6">
                     <Badge dateFin={a.pec.fin} />
                  </td>
                  <td className="px-8 py-6 text-center">
                     <div className="flex justify-center gap-2">
                       <button onClick={() => { setSelectedAnimator(a); setIsDetailModalOpen(true); }} className="p-3 bg-white/5 hover:bg-white/10 rounded-2xl text-slate-400 hover:text-white transition-all"><Eye size={18} /></button>
                       <button onClick={() => { setSelectedAnimator(a); setIsReassignModalOpen(true); }} className="p-3 bg-blue-600/10 hover:bg-blue-600 rounded-2xl text-blue-400 hover:text-white transition-all"><ArrowRightLeft size={18} /></button>
                     </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </GlassCard>
    </div>
  );

  return (
    <div className="min-h-screen bg-[#010413] text-slate-100 font-sans antialiased selection:bg-blue-500/30 overflow-hidden">
      <VisualEffects />
      <Sidebar />
      <main className="pl-72 relative z-10 h-screen flex flex-col">
        <div className="flex-1 overflow-y-auto custom-scrollbar">
          {view === 'dashboard' && <div className="p-10 space-y-10 animate-in fade-in duration-1000">
            <header className="flex justify-between items-end">
              <div>
                <h2 className="text-4xl font-black text-white tracking-tighter italic uppercase">Pilotage Hub</h2>
                <p className="text-slate-400 mt-2 font-medium italic">Monitoring consolidé des 258 ressources</p>
              </div>
            </header>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
              {[
                { label: 'Effectif Total', val: globalStats.total, icon: Users, color: 'text-blue-400' },
                { label: 'Animatrices Actives', val: globalStats.actives, icon: CheckCircle, color: 'text-green-400' },
                { label: 'Alertes PEC (J-7)', val: globalStats.alerts, icon: AlertTriangle, color: 'text-orange-400' },
                { label: 'Parc Tablettes', val: globalStats.tablets, icon: Smartphone, color: 'text-purple-400' },
              ].map((s, i) => (
                <GlassCard key={i} className="p-8 group hover:scale-[1.03] transition-all">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest mb-1">{s.label}</p>
                      <h3 className="text-5xl font-black text-white tabular-nums tracking-tighter">{s.val}</h3>
                    </div>
                    <div className={`${s.color} p-4 bg-white/5 rounded-3xl`}><s.icon size={28} /></div>
                  </div>
                </GlassCard>
              ))}
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
               <GlassCard className="p-8"><h3 className="text-white text-xl font-black mb-6">Urgences PEC Immédiates</h3>
                 <div className="space-y-4 max-h-[300px] overflow-y-auto custom-scrollbar pr-2">
                   {data.filter(a => (new Date(a.pec.fin) - new Date()) / (1000 * 60 * 60 * 24) <= 3).slice(0, 10).map(a => (
                     <div key={a.id} className="flex justify-between items-center p-4 bg-white/5 rounded-2xl border border-white/5">
                        <div className="flex items-center gap-4">
                          <img src={a.photos.profile} className="w-10 h-10 rounded-xl" />
                          <div><p className="text-white text-sm font-bold">{a.nom} {a.prenom}</p><p className="text-[10px] text-slate-500">{a.agence}</p></div>
                        </div>
                        <Badge dateFin={a.pec.fin} />
                     </div>
                   ))}
                 </div>
               </GlassCard>
               <GlassCard className="p-8 flex flex-col justify-center items-center text-center space-y-4">
                  <TrendingUp size={48} className="text-blue-500 animate-bounce" />
                  <h3 className="text-2xl font-black text-white italic">Performance Activation</h3>
                  <p className="text-slate-400 text-sm max-w-xs">Le hub est synchronisé. Toutes les données reflètent l'état actuel du vivier Smollan.</p>
               </GlassCard>
            </div>
          </div>}
          {view === 'base' && <AnimatorList />}
          {view === 'control' && <ControlTower />}
          {view === 'agences' && <AgencesView />}
          {view === 'inventory' && <InventoryView />}
        </div>
      </main>

      {/* DETAIL MODAL */}
      {isDetailModalOpen && selectedAnimator && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-950/95 backdrop-blur-3xl" onClick={() => setIsDetailModalOpen(false)} />
          <GlassCard className="w-full max-w-5xl h-[85vh] relative overflow-hidden flex border-white/10 animate-in zoom-in duration-500">
             <div className="w-80 border-r border-white/10 p-10 flex flex-col items-center bg-white/[0.02]">
                <img src={selectedAnimator.photos?.profile} className="w-40 h-40 rounded-[40px] object-cover mb-8 shadow-2xl border-2 border-white/10 scale-110" />
                <h2 className="text-2xl font-black text-white text-center leading-tight italic uppercase tracking-tighter">{selectedAnimator.prenom}<br/>{selectedAnimator.nom}</h2>
                <div className="mt-10 w-full space-y-4">
                   <div className="p-4 bg-white/5 rounded-3xl border border-white/5">
                      <p className="text-[9px] text-slate-500 font-black uppercase tracking-widest mb-1">Identité CIN</p>
                      <p className="text-sm font-black text-white italic">{selectedAnimator.cin}</p>
                   </div>
                   <div className="p-4 bg-white/5 rounded-3xl border border-white/5">
                      <p className="text-[9px] text-slate-500 font-black uppercase tracking-widest mb-1">Contact Pro</p>
                      <p className="text-sm font-black text-blue-400 italic font-mono">{selectedAnimator.phones?.pro}</p>
                   </div>
                </div>
             </div>
             <div className="flex-1 p-16 overflow-y-auto space-y-16">
                <section>
                   <h4 className="text-white font-black text-xl mb-10 italic uppercase tracking-widest underline decoration-blue-500 decoration-2 underline-offset-8">Vérification Documents</h4>
                   <div className="grid grid-cols-2 gap-10">
                      <div className="space-y-4">
                         <p className="text-[10px] text-slate-500 font-black uppercase tracking-[0.2em]">CIN Recto Officiel</p>
                         <img src={selectedAnimator.photos?.cinRecto} className="rounded-[40px] border-2 border-white/10 shadow-2xl transition hover:scale-[1.03] duration-500" />
                      </div>
                      <div className="space-y-4">
                         <p className="text-[10px] text-slate-500 font-black uppercase tracking-[0.2em]">CIN Verso Officiel</p>
                         <img src={selectedAnimator.photos?.cinVerso} className="rounded-[40px] border-2 border-white/10 shadow-2xl transition hover:scale-[1.03] duration-500" />
                      </div>
                   </div>
                </section>
                <section className="pt-16 border-t border-white/10">
                   <h4 className="text-white font-black mb-8 italic uppercase tracking-widest underline decoration-amber-500 decoration-2 underline-offset-8">Traçabilité & Historique</h4>
                   <div className="space-y-4">
                     {selectedAnimator.historique.map((h, i) => (
                       <div key={i} className="flex justify-between items-center p-6 bg-white/[0.03] rounded-3xl border border-white/5">
                         <div>
                            <p className="text-white font-black text-lg">{h.projet}</p>
                            <p className="text-[10px] text-slate-500 font-bold uppercase mt-1 tracking-widest">{h.client} • {h.magasin}</p>
                         </div>
                         <div className="text-right">
                            <p className="text-blue-400 font-black text-xs uppercase tracking-widest">{h.date}</p>
                            <p className="text-[9px] text-slate-600 font-black uppercase tracking-widest mt-1">Archivé</p>
                         </div>
                       </div>
                     ))}
                   </div>
                </section>
             </div>
          </GlassCard>
        </div>
      )}

      {/* REASSIGN MODAL */}
      {isReassignModalOpen && selectedAnimator && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-950/90 backdrop-blur-2xl" onClick={() => setIsReassignModalOpen(false)} />
          <GlassCard className="w-full max-w-xl relative overflow-hidden animate-in zoom-in duration-500 border-white/20">
            <div className="p-10 bg-gradient-to-br from-blue-700 via-blue-600 to-indigo-800 text-white relative">
              <h3 className="text-3xl font-black tracking-tighter italic uppercase">Flux de Mutation</h3>
              <p className="text-blue-100/70 text-sm font-bold mt-2 uppercase tracking-widest">Mutation de {selectedAnimator.nom} {selectedAnimator.prenom}</p>
            </div>
            <div className="p-10 space-y-8">
              <div className="space-y-6">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em]">Nouvelle Affectation Projet</label>
                <select className="w-full bg-white/5 border border-white/10 rounded-3xl p-5 text-white font-bold outline-none focus:ring-4 focus:ring-blue-500/20 transition-all cursor-pointer">
                  {CLIENTS.map(c => <optgroup key={c} label={c} className="bg-[#020617]">{PROJETS_PAR_CLIENT[c].map(p => <option key={p} className="bg-[#020617]">{p}</option>)}</optgroup>)}
                </select>
                <div className="grid grid-cols-2 gap-4">
                   <select className="bg-white/5 border border-white/10 rounded-3xl p-4 text-white text-sm outline-none"><option className="bg-[#020617]">Magasin...</option>{STORES.map(s => <option key={s} className="bg-[#020617]">{s}</option>)}</select>
                   <select className="bg-white/5 border border-white/10 rounded-3xl p-4 text-white text-sm outline-none"><option className="bg-[#020617]">Ville...</option>{VILLES.map(v => <option key={v} className="bg-[#020617]">{v}</option>)}</select>
                </div>
                <div className="bg-blue-600/10 p-6 rounded-3xl border border-blue-600/20 flex gap-4">
                  <AlertTriangle size={24} className="text-blue-400 shrink-0" />
                  <p className="text-slate-400 text-[11px] leading-relaxed italic">
                    Cette action va clore la mission actuelle <strong className="text-white">({selectedAnimator.affectation.projet})</strong> et l'archiver dans l'historique de traçabilité.
                  </p>
                </div>
              </div>
            </div>
            <div className="p-10 border-t border-white/10 flex gap-4 bg-white/[0.02]">
              <button onClick={() => setIsReassignModalOpen(false)} className="flex-1 py-5 bg-white/5 text-white font-black rounded-3xl hover:bg-white/10 transition-all uppercase tracking-widest text-[10px]">Annuler</button>
              <button onClick={() => handleMutation(selectedAnimator.id, { client: "Samsung", projet: "Mutation Q1", magasin: "Marjane", ville: "Casablanca" })}
                className="flex-1 py-5 bg-blue-600 text-white font-black rounded-3xl hover:bg-blue-700 shadow-xl uppercase tracking-widest text-[10px]">Confirmer Mutation</button>
            </div>
          </GlassCard>
        </div>
      )}

      <style>{`
        .custom-scrollbar::-webkit-scrollbar { width: 6px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.08); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.15); }
      `}</style>
    </div>
  );
};

export default App;