'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { auth, db } from '@/lib/firebase';
import { onSnapshot, doc, collection, query, orderBy, where, updateDoc, writeBatch, serverTimestamp, setDoc, deleteDoc, addDoc } from 'firebase/firestore';
import { handleFirestoreError, OperationType } from '@/lib/firestore-error';
import { Bell, User as UserIcon, Grid, Plus, Download, Printer, Trash2 } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { format, differenceInMinutes } from 'date-fns';

export default function ManagerDashboard() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [activeTab, setActiveTab] = useState<'Command'|'Resources'|'QR Zones'|'Analytics'>('Command');

  // Command Data
  const [incidents, setIncidents] = useState<any[]>([]);
  const [resources, setResources] = useState<any[]>([]);
  const [dispatches, setDispatches] = useState<any[]>([]);
  const [zones, setZones] = useState<any[]>([]);

  useEffect(() => {
    let unsubUser: any = null;
    let unsubInc: any = null;
    let unsubRes: any = null;
    let unsubDisp: any = null;
    let unsubZones: any = null;

    const unsubAuth = auth.onAuthStateChanged((u) => {
      if (!u || u.isAnonymous) {
        if(unsubUser) unsubUser();
        if(unsubInc) unsubInc();
        if(unsubRes) unsubRes();
        if(unsubDisp) unsubDisp();
        if(unsubZones) unsubZones();
        router.replace('/login');
        return;
      }

      unsubUser = onSnapshot(doc(db, 'users', u.uid), (d) => {
        if(d.exists()) setUser(d.data());
      }, (error) => handleFirestoreError(error, OperationType.GET, 'users'));
      
      unsubInc = onSnapshot(query(collection(db, 'incidents'), orderBy('timestamp', 'desc')), snap => {
         setIncidents(snap.docs.map(d => ({id: d.id, ...d.data()})));
      }, (error) => handleFirestoreError(error, OperationType.LIST, 'incidents'));

      unsubRes = onSnapshot(collection(db, 'resources'), snap => {
         setResources(snap.docs.map(d => ({id: d.id, ...d.data()})));
      }, (error) => handleFirestoreError(error, OperationType.LIST, 'resources'));

      unsubDisp = onSnapshot(query(collection(db, 'dispatch'), where('confirmed', '==', false)), snap => {
         setDispatches(snap.docs.map(d => ({id: d.id, ...d.data()})));
      }, (error) => handleFirestoreError(error, OperationType.LIST, 'dispatch'));

      unsubZones = onSnapshot(collection(db, 'zones'), snap => {
         setZones(snap.docs.map(d => ({id: d.id, ...d.data()})));
      }, (error) => handleFirestoreError(error, OperationType.LIST, 'zones'));
    });

    return () => { 
      unsubAuth();
      if(unsubUser) unsubUser(); 
      if(unsubInc) unsubInc(); 
      if(unsubRes) unsubRes(); 
      if(unsubDisp) unsubDisp(); 
      if(unsubZones) unsubZones(); 
    };
  }, [router]);

  // Command Math
  const activeIncidentsCount = incidents.filter(i => i.status === 'pending' || i.status === 'verified').length;
  const deployedResCount = resources.filter(r => !r.available).length;
  const availableResCount = resources.filter(r => r.available).length;
  const resolvedToday = incidents.filter(i => i.status === 'resolved' && i.resolvedAt && (new Date().getTime() - i.resolvedAt.toMillis() < 86400000));
  const avgResponseMs = resolvedToday.length > 0 ? resolvedToday.reduce((acc, i) => acc + (i.responseTimeMs || 0), 0) / resolvedToday.length : 0;
  const avgResponseMin = avgResponseMs > 0 ? (avgResponseMs / 60000).toFixed(1) + 'm' : '0m';

  const confirmDispatch = async (disp: any) => {
    const batch = writeBatch(db);
    batch.update(doc(db, 'dispatch', disp.id), {
      confirmed: true,
      confirmedBy: auth.currentUser?.uid,
      confirmedAt: serverTimestamp()
    });
    batch.update(doc(db, 'resources', disp.resourceId), {
      available: false,
      currentIncidentId: disp.incidentId
    });
    batch.update(doc(db, 'incidents', disp.incidentId), {
      assignedTo: disp.resourceId,
      assignedName: disp.resourceName
    });
    await batch.commit();
  };

  const exportCSV = () => {
    let csv = 'ID,Type,Zone,Status,ReportedAt\n';
    incidents.forEach(i => {
      csv += `"${i.id}","${i.type}","${i.location?.zoneName}","${i.status}","${i.timestamp ? i.timestamp.toDate().toISOString() : ''}"\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `incident_log_${format(new Date(), 'yyyy-MM-dd')}.csv`;
    a.click();
  };

  // QR Zones Tab
  const [showNewZone, setShowNewZone] = useState(false);
  const [zoneName, setZoneName] = useState('');
  const [zoneFloor, setZoneFloor] = useState('');
  const [zoneSection, setZoneSection] = useState('');

  const handleCreateZone = async () => {
    if (!zoneName || !zoneFloor) return;
    const shortName = zoneName.substring(0,8);
    const docRef = await addDoc(collection(db, 'zones'), {
      name: zoneName,
      floor: zoneFloor,
      section: zoneSection,
      shortName,
      adjacentZones: [],
      createdAt: serverTimestamp(),
      createdBy: auth.currentUser?.uid,
    });
    // Add qrData
    const qrData = `https://${process.env.NEXT_PUBLIC_APP_URL || window.location.host}/report?zone=${docRef.id}&name=${encodeURIComponent(zoneName)}&floor=${encodeURIComponent(zoneFloor)}`;
    await updateDoc(docRef, { qrData });
    setShowNewZone(false);
    setZoneName(''); setZoneFloor(''); setZoneSection('');
  };

  const deleteZone = async (zId: string) => {
    if (confirm('Are you sure you want to delete this zone?')) {
      await deleteDoc(doc(db, 'zones', zId));
    }
  };

  const printQR = () => {
    window.print();
  };

  // Analytics Math
  const countsByType = {
    fire: incidents.filter(i => (i.aiType || i.type) === 'fire' || i.type === 'smoke').length,
    medical: incidents.filter(i => (i.aiType || i.type) === 'medical').length,
    security: incidents.filter(i => (i.aiType || i.type) === 'security').length,
    other: incidents.filter(i => (i.aiType || i.type) === 'other' || i.type === 'none').length,
  };
  const maxTypeCount = Math.max(...Object.values(countsByType)) || 1;
  const verifiedCount = incidents.filter(i => i.status === 'verified' || i.status === 'resolved').length;
  const dismissedCount = incidents.filter(i => i.status === 'dismissed').length;
  const pendingCount = incidents.filter(i => i.status === 'pending').length;
  const totalAI = verifiedCount + dismissedCount + pendingCount || 1;
  const verifiedPercent = Math.round((verifiedCount / totalAI) * 100);

  const avgByType = (type: string) => {
     const incs = incidents.filter(i => i.status === 'resolved' && (i.aiType || i.type) === type);
     if (incs.length === 0) return 0;
     return incs.reduce((a, b) => a + (b.responseTimeMs || 0), 0) / incs.length;
  };
  
  const mFire = (avgByType('fire') / 60000);
  const mMed = (avgByType('medical') / 60000);
  const mSec = (avgByType('security') / 60000);

  return (
    <div className="flex min-h-screen bg-[#F5F5F0] text-[#141414] font-sans antialiased">
      {/* Sidebar (Desktop) */}
      <aside className="hidden md:flex w-64 border-r border-[rgba(20,20,20,0.1)] flex-col justify-between bg-[#F5F5F0] shrink-0">
        <div>
          <div className="p-8">
            <h1 className="text-[24px] font-serif font-medium tracking-tight mb-8">CrisisFlow</h1>
            <nav className="flex flex-col gap-2">
              {['Command', 'Resources', 'QR Zones', 'Analytics'].map(t => (
                <button
                  key={t}
                  onClick={() => setActiveTab(t as any)}
                  className={`text-left px-4 py-2 text-[14px] transition-colors border-l-2 ${activeTab === t ? 'border-[#141414] text-[#141414] font-medium' : 'border-transparent text-[rgba(20,20,20,0.6)] hover:text-[#141414]'}`}
                >
                  {t}
                </button>
              ))}
            </nav>
          </div>
        </div>
        <div className="p-6 border-t border-[rgba(20,20,20,0.1)]">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-8 h-8 rounded-full bg-[#8A8263] flex items-center justify-center text-[#F5F5F0] text-[10px] font-medium uppercase shrink-0">
              {user?.name?.substring(0,2) || 'MG'}
            </div>
            <div className="overflow-hidden">
              <div className="text-[13px] font-medium truncate text-[#141414]">{user?.name || 'Manager'}</div>
              <div className="text-[11px] text-[rgba(20,20,20,0.6)] uppercase tracking-wider font-medium truncate">Manager Command</div>
            </div>
          </div>
          <button onClick={() => auth.signOut().then(() => router.push('/login'))} className="text-[12px] text-[rgba(20,20,20,0.6)] hover:text-[#141414] transition-colors font-medium">Sign out</button>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Mobile Header */}
        <div className="md:hidden">
          <div className="h-14 bg-[#141414] flex items-center justify-between px-6 shrink-0 relative z-50">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-[#5A5A40] rounded-full mr-2" />
              <span className="text-[#F5F5F0] font-medium text-[14px]">CrisisFlow</span>
              <span className="text-[#F5F5F0]/40 mx-2 text-[10px]">•</span>
              <span className="text-[#F5F5F0]/40 text-[10px] uppercase tracking-wider font-medium">Command</span>
            </div>
            <div className="flex items-center gap-2">
              <button onClick={() => auth.signOut().then(() => router.push('/login'))} className="text-[#F5F5F0]/40 text-[10px] hover:text-[#F5F5F0] transition-colors">Sign out</button>
            </div>
          </div>
          <div className="bg-[#141414] px-6 pb-4 flex gap-2 overflow-x-auto no-scrollbar">
             {['Command', 'Resources', 'QR Zones', 'Analytics'].map(t => (
               <button 
                 key={t}
                 onClick={() => setActiveTab(t as any)}
                 className={`px-4 py-1.5 rounded-none text-[13px] font-medium whitespace-nowrap transition-colors ${activeTab === t ? 'bg-[#F5F5F0] text-[#141414]' : 'text-[#F5F5F0]/50 hover:text-[#F5F5F0]'}`}
               >
                 {t}
               </button>
             ))}
          </div>
        </div>

        {/* Desktop Header area not really needed but we can add title if desired, let's just use the fluid padding */}
        <div className="hidden md:flex h-20 border-b border-[rgba(20,20,20,0.1)] items-center px-10 shrink-0">
           <h2 className="text-[28px] font-serif font-medium tracking-tight text-[#141414]">{activeTab}</h2>
        </div>

        <div className="flex-1 overflow-auto md:p-6 lg:p-10">
        {activeTab === 'Command' && (
          <div className="p-0 md:p-4 max-w-7xl mx-auto flex flex-col gap-6">
            {/* Stats Row */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
               <div className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-6">
                 <div className="text-[32px] font-medium text-[#5A5A40] font-serif">{activeIncidentsCount}</div>
                 <div className="text-[12px] font-medium text-[rgba(20,20,20,0.6)] uppercase tracking-wider">Active</div>
               </div>
               <div className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-6">
                 <div className="text-[32px] font-medium text-[#8A8263] font-serif">{deployedResCount}</div>
                 <div className="text-[12px] font-medium text-[rgba(20,20,20,0.6)] uppercase tracking-wider">Deployed</div>
               </div>
               <div className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-6">
                 <div className="text-[32px] font-medium text-[#475B49] font-serif">{availableResCount}</div>
                 <div className="text-[12px] font-medium text-[rgba(20,20,20,0.6)] uppercase tracking-wider">Available</div>
               </div>
               <div className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-6">
                 <div className="text-[32px] font-medium text-[#141414] font-serif">{avgResponseMin}</div>
                 <div className="text-[12px] font-medium text-[rgba(20,20,20,0.6)] uppercase tracking-wider">Avg response</div>
               </div>
            </div>

            <div className="flex flex-col md:flex-row gap-4 md:gap-6">
              <div className="flex-1 bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-6 flex flex-col">
                 <div className="text-[11px] font-medium text-[rgba(20,20,20,0.6)] uppercase tracking-wider mb-4">Incident Log Today</div>
                 <div className="flex-1 overflow-y-auto pr-2 pb-2">
                   {incidents.slice(0,20).map(inc => (
                     <div key={inc.id} className="flex justify-between items-center py-2 border-b border-[rgba(20,20,20,0.1)] group">
                       <div className="cursor-pointer" onClick={() => router.push(`/staff/incident/${inc.id}`)}>
                         <div className="text-[12px] font-medium text-[#141414] capitalize">{inc.aiType || inc.type}</div>
                         <div className="text-[10px] text-[rgba(20,20,20,0.6)] mt-0.5">{inc.location?.zoneName}</div>
                       </div>
                       <div className="flex items-center gap-2">
                         {(inc.status === 'verified' || inc.status === 'pending') && (
                            <button
                               onClick={async (e) => {
                                 try {
                                   const { updateDoc, doc, serverTimestamp } = await import('firebase/firestore');
                                   await updateDoc(doc(db, 'incidents', inc.id), {
                                     status: 'resolved',
                                     resolvedAt: serverTimestamp()
                                   });
                                 } catch (error) {
                                   const { handleFirestoreError, OperationType } = await import('@/lib/firestore-error');
                                   handleFirestoreError(error, OperationType.UPDATE, `incidents/${inc.id}`);
                                 }
                               }}
                               className="hidden group-hover:block bg-[#475B49] rounded-sm text-white text-[10px] px-2 py-0.5 font-medium z-10"
                            >
                              Resolve
                            </button>
                         )}
                       {inc.status === 'verified' || inc.status === 'pending' ? (
                          <span className="bg-[#5A5A40]/10 text-[#5A5A40] text-[10px] px-2 py-0.5 rounded-full font-medium capitalize shrink-0">{inc.status}</span>
                       ) : inc.status === 'resolved' ? (
                          <span className="bg-[#475B49]/10 text-[#475B49] text-[10px] px-2 py-0.5 rounded-full font-medium capitalize shrink-0">{inc.status}</span>
                       ) : (
                          <span className="bg-[#EBEBE4] text-[rgba(20,20,20,0.6)] text-[10px] px-2 py-0.5 rounded-full font-medium capitalize shrink-0">{inc.status}</span>
                       )}
                       </div>
                     </div>
                   ))}
                 </div>
                 <button onClick={exportCSV} className="w-full mt-2 py-2 text-[12px] font-medium text-[rgba(20,20,20,0.6)] hover:text-[#141414] transition-colors rounded">
                   Export as CSV
                 </button>
              </div>

              <div className="flex-1 bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-6 flex flex-col">
                 <div className="flex justify-between items-center mb-4">
                   <div className="text-[11px] font-medium text-[rgba(20,20,20,0.6)] uppercase tracking-wider">Dispatch Plan</div>
                   <div className="bg-[#475B49]/10 text-[#475B49] text-[9px] px-2 py-0.5 rounded uppercase font-medium tracking-wider">OR-Tools Optimized</div>
                 </div>
                 
                 <div className="flex-1 overflow-y-auto pr-2">
                   {dispatches.length === 0 ? (
                     <div className="h-full flex flex-col items-center justify-center pt-10">
                       <div className="w-4 h-4 border-2 border-[#475B49] border-t-transparent rounded-full animate-spin mb-2" />
                       <div className="text-[11px] text-[rgba(20,20,20,0.6)]">Calculating optimal routes...</div>
                     </div>
                   ) : dispatches.map(disp => (
                     <div key={disp.id} className="bg-[#F2F2EC] border border-[rgba(20,20,20,0.1)] rounded-none p-3 mb-2">
                       <div className="flex justify-between items-start mb-2">
                         <div className="text-[12px] font-medium text-[#141414]">{disp.resourceName}</div>
                         <div className="text-[9px] bg-[rgba(20,20,20,0.1)] text-[rgba(20,20,20,0.6)] px-1.5 py-0.5 rounded font-medium uppercase">{disp.resourceType?.replace('_', ' ')}</div>
                       </div>
                       <div className="flex items-center text-[11px] text-[rgba(20,20,20,0.6)] mb-1">
                         <span>{disp.fromZone}</span> <ChevronRightIcon className="w-3 h-3 mx-1"/> <span>{disp.toZone}</span>
                       </div>
                       <div className="text-[10px] text-[rgba(20,20,20,0.4)] mb-3">Est 2 min</div>
                       <button onClick={() => confirmDispatch(disp)} className="w-full h-9 bg-[#475B49] text-[#F5F5F0] rounded-none text-[13px] font-medium">
                         Confirm dispatch
                       </button>
                     </div>
                   ))}
                 </div>
                 <div className="text-[9px] text-[rgba(20,20,20,0.4)] text-center mt-3 uppercase tracking-wider">Powered by Google OR-Tools minimises response time</div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'QR Zones' && (
          <div className="p-4 max-w-7xl mx-auto flex flex-col gap-4">
            <div className="flex justify-between items-center px-4">
              <div>
                <h2 className="text-[18px] font-serif tracking-tight font-medium text-[#141414]">Venue Zone QR Codes</h2>
                <p className="text-[12px] text-[rgba(20,20,20,0.6)]">Place these QR codes throughout your venue</p>
              </div>
              <button 
                onClick={() => setShowNewZone(true)}
                className="bg-[#141414] text-[#F5F5F0] h-9 px-4 rounded-none text-[13px] font-medium flex items-center"
              >
                <Plus className="w-4 h-4 mr-2" /> New zone
              </button>
            </div>

            <div className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-3.5 mx-4 flex items-center gap-4 hidden @md:flex">
              <div className="flex-1 flex flex-col"><span className="text-[11px] font-medium text-[#141414]">1. Create zone</span><span className="text-[10px] text-[rgba(20,20,20,0.6)]">Manager creates a zone with name and floor.</span></div>
              <div className="flex-1 flex flex-col"><span className="text-[11px] font-medium text-[#141414]">2. Print QR code</span><span className="text-[10px] text-[rgba(20,20,20,0.6)]">Download and print the QR code.</span></div>
              <div className="flex-1 flex flex-col"><span className="text-[11px] font-medium text-[#141414]">3. Guest scans</span><span className="text-[10px] text-[rgba(20,20,20,0.6)]">Location auto-fills in the report form.</span></div>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2.5 px-4 pb-12 print-hide">
              {zones.map(zone => (
                <div key={zone.id} className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-4 flex flex-col items-center relative">
                  <button onClick={() => deleteZone(zone.id)} className="absolute top-3 right-3 text-[#5A5A40] hover:bg-[#5A5A40]/10 p-1.5 rounded-full transition-colors">
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                  <div className="flex w-full justify-between items-center mb-4">
                    <span className="text-[14px] font-medium text-[#141414] truncate max-w-[120px]">{zone.name}</span>
                    <span className="bg-[#141414]/10 text-[#141414] text-[10px] rounded px-1.5 py-0.5 font-medium">{zone.floor}</span>
                  </div>
                  
                  <div className="bg-[#F5F5F0] p-2 mb-3">
                    <QRCodeSVG 
                      value={`https://${process.env.NEXT_PUBLIC_APP_URL || window.location.host}/report?zone=${zone.id}&name=${encodeURIComponent(zone.name)}&floor=${encodeURIComponent(zone.floor)}`} 
                      size={120} 
                      level="H" 
                      fgColor="#141414" 
                    />
                  </div>

                  <div className="text-[11px] font-medium text-[#141414] text-center mb-0.5">{zone.name}</div>
                  <div className="text-[10px] text-[rgba(20,20,20,0.6)] text-center">{zone.floor} • {zone.section || 'General'}</div>

                  <div className="flex gap-2 w-full mt-4">
                    <button className="flex-1 h-8 rounded border border-[#141414] text-[#141414] text-[11px] font-medium">Download QR</button>
                    <button onClick={printQR} className="flex-1 h-8 rounded bg-[#141414] text-[#F5F5F0] text-[11px] font-medium">Print</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Similar for Resources and Analytics... */}
        {activeTab === 'Analytics' && (
          <div className="p-4 max-w-7xl mx-auto flex flex-col gap-4 pb-12">
             <div className="bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-4">
               <div className="text-[14px] font-medium text-[#141414] mb-4">Incidents by type</div>
               <div className="space-y-3">
                 {[
                   {label: 'Fire/Smoke', count: countsByType.fire, color: '#5A5A40'},
                   {label: 'Medical', count: countsByType.medical, color: '#4A5868'},
                   {label: 'Security', count: countsByType.security, color: '#8A8263'},
                   {label: 'Other', count: countsByType.other, color: 'rgba(20,20,20,0.6)'},
                 ].map(item => (
                   <div key={item.label} className="flex items-center text-[12px]">
                     <div className="w-[80px] font-medium text-[rgba(20,20,20,0.6)]">{item.label}</div>
                     <div className="flex-1 bg-[#E8E8E8] h-2 rounded-full overflow-hidden mx-3">
                        <div className="h-full rounded-full transition-all duration-1000" style={{ width: `${(item.count/maxTypeCount)*100}%`, backgroundColor: item.color }} />
                     </div>
                     <div className="w-6 text-right font-medium text-[#141414]">{item.count}</div>
                   </div>
                 ))}
               </div>
             </div>

             <div className="flex gap-4">
                <div className="flex-1 bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-4">
                  <div className="text-[14px] font-medium text-[#141414] mb-4">Avg response times</div>
                  <div className="space-y-3">
                    <div className="flex justify-between items-center text-[12px]"><span className="text-[rgba(20,20,20,0.6)]">Fire</span><span className={`font-medium ${mFire > 5 ? 'text-[#5A5A40]' : 'text-[#141414]'}`}>{mFire.toFixed(1)}m</span></div>
                    <div className="flex justify-between items-center text-[12px]"><span className="text-[rgba(20,20,20,0.6)]">Medical</span><span className={`font-medium ${mMed > 5 ? 'text-[#5A5A40]' : 'text-[#141414]'}`}>{mMed.toFixed(1)}m</span></div>
                    <div className="flex justify-between items-center text-[12px]"><span className="text-[rgba(20,20,20,0.6)]">Security</span><span className={`font-medium ${mSec > 5 ? 'text-[#5A5A40]' : 'text-[#141414]'}`}>{mSec.toFixed(1)}m</span></div>
                  </div>
                </div>

                <div className="flex-1 bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-4 flex flex-col items-center">
                  <div className="text-[14px] font-medium text-[#141414] mb-4 w-full text-left">AI verification</div>
                  {/* Basic Donut using SVG */}
                  <div className="relative w-24 h-24">
                     <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                       <path className="text-[#E8E8E8]" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="currentColor" strokeWidth="3" />
                       <path className="text-[#475B49]" strokeDasharray={`${verifiedPercent}, 100`} d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="currentColor" strokeWidth="4" />
                     </svg>
                     <div className="absolute inset-0 flex items-center justify-center flex-col">
                       <span className="text-[14px] font-medium text-[#141414]">{verifiedPercent}%</span>
                     </div>
                  </div>
                  <div className="flex gap-2 mt-4 text-[10px] text-[rgba(20,20,20,0.6)]">
                    <div className="flex items-center"><div className="w-2 h-2 rounded-full bg-[#475B49] mr-1" />Verified</div>
                    <div className="flex items-center"><div className="w-2 h-2 rounded-full bg-[#8A8263] mr-1" />Pending</div>
                  </div>
                </div>
             </div>
          </div>
        )}
      </div>
      </div>

      {showNewZone && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
           <div className="bg-[#F5F5F0] rounded-none w-full max-w-[360px] p-5 shadow-none border border-[rgba(20,20,20,0.1)]">
             <div className="text-[18px] font-serif tracking-tight font-medium text-[#141414] mb-4">Create new zone</div>
             <div className="space-y-4 mb-6">
                <div><label className="text-[10px] uppercase font-medium text-[rgba(20,20,20,0.6)] mb-1.5 block">Zone Name</label><input value={zoneName} onChange={e=>setZoneName(e.target.value)} className="w-full h-10 px-3 border border-[rgba(20,20,20,0.1)] rounded-none text-[13px] outline-none" placeholder="Lobby Level 1" /></div>
                <div><label className="text-[10px] uppercase font-medium text-[rgba(20,20,20,0.6)] mb-1.5 block">Floor</label><input value={zoneFloor} onChange={e=>setZoneFloor(e.target.value)} className="w-full h-10 px-3 border border-[rgba(20,20,20,0.1)] rounded-none text-[13px] outline-none" placeholder="Level 1" /></div>
                <div><label className="text-[10px] uppercase font-medium text-[rgba(20,20,20,0.6)] mb-1.5 block">Section</label><input value={zoneSection} onChange={e=>setZoneSection(e.target.value)} className="w-full h-10 px-3 border border-[rgba(20,20,20,0.1)] rounded-none text-[13px] outline-none" placeholder="Zone A East Wing" /></div>
             </div>
             <div className="flex gap-2">
               <button onClick={()=>setShowNewZone(false)} className="flex-1 h-10 border border-[rgba(20,20,20,0.1)] rounded-none text-[13px] font-medium text-[rgba(20,20,20,0.6)]">Cancel</button>
               <button onClick={handleCreateZone} className="flex-1 h-10 bg-[#141414] text-[#F5F5F0] rounded-none text-[13px] font-medium">Create zone</button>
             </div>
           </div>
        </div>
      )}
    </div>
  );
}

function ChevronRightIcon({className}:{className?:string}){
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><polyline points="9 18 15 12 9 6"></polyline></svg>;
}
