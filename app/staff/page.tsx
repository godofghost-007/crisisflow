'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { collection, query, onSnapshot, orderBy, where, doc, addDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { handleFirestoreError, OperationType } from '@/lib/firestore-error';
import { Bell, ShieldCheck, ChevronRight, MapPin, AlertCircle, AlertTriangle, Info } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { motion, AnimatePresence } from 'motion/react';

export default function StaffDashboard() {
  const router = useRouter();
  const [incidents, setIncidents] = useState<any[]>([]);
  const [zones, setZones] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  const [sortOption, setSortOption] = useState<'time' | 'severity'>('time');
  const [toastAlert, setToastAlert] = useState<any>(null);

  useEffect(() => {
    let unsubUser: any = null;
    let unsubInc: any = null;
    let unsubZones: any = null;

    const unsubAuth = auth.onAuthStateChanged((u) => {
      if (!u || u.isAnonymous) {
        if (unsubUser) unsubUser();
        if (unsubInc) unsubInc();
        if (unsubZones) unsubZones();
        router.replace('/login');
        return;
      }
      
      unsubUser = onSnapshot(doc(db, 'users', u.uid), (d) => {
        if(d.exists()) setUser(d.data());
      }, (error) => handleFirestoreError(error, OperationType.GET, 'users'));

      const qIncidents = query(collection(db, 'incidents'), orderBy('timestamp', 'desc'));
      unsubInc = onSnapshot(qIncidents, (snap) => {
        const active = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .filter((i: any) => i.status === 'pending' || i.status === 'verified');
        
        setIncidents(active);
        setLoading(false);

        snap.docChanges().forEach(change => {
          if (change.type === 'modified' || change.type === 'added') {
            const data = change.doc.data();
            if (data.status === 'verified' && change.type === 'modified') {
               setToastAlert({ id: change.doc.id, ...data });
            }
          }
        });
      }, (error) => handleFirestoreError(error, OperationType.LIST, 'incidents'));

      const qZones = query(collection(db, 'zones'));
      unsubZones = onSnapshot(qZones, (snap) => {
        setZones(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }, (error) => handleFirestoreError(error, OperationType.LIST, 'zones'));
    });

    return () => {
      unsubAuth();
      if(unsubUser) unsubUser();
      if(unsubInc) unsubInc();
      if(unsubZones) unsubZones();
    };
  }, [router]);

  const activeIncidents = [...incidents].sort((a, b) => {
    if (sortOption === 'time') return b.timestamp?.toMillis() - a.timestamp?.toMillis();
    return (b.severity || 0) - (a.severity || 0);
  });

  const getStripeColor = (severity: number) => {
    if (severity >= 8) return 'bg-[#5A5A40]';
    if (severity >= 4) return 'bg-[#8A8263]';
    return 'bg-[#475B49]';
  };

  const activeCount = activeIncidents.length;

  const triggerEvacuation = async () => {
    if(confirm('Trigger Evacuation Alert?')) {
      await addDoc(collection(db, 'alerts'), {
        type: 'evacuation',
        message: 'Evacuate immediately',
        triggeredBy: auth.currentUser?.uid,
        triggeredByName: user?.name,
        venue: user?.venue,
        timestamp: serverTimestamp(),
        active: true
      });
      alert('Alert triggered.');
    }
  };

  return (
    <div className="min-h-screen bg-[#F5F5F0] flex flex-col font-sans">
      {/* App Bar */}
      <div className="h-14 bg-[#141414] flex items-center justify-between px-6 shrink-0 relative z-50">
        <div className="flex items-center">
          <div className="w-2 h-2 bg-[#5A5A40] rounded-full mr-2" />
          <span className="text-[#F5F5F0] font-medium text-[14px]">CrisisFlow</span>
          <span className="text-[#F5F5F0]/40 mx-2 text-[10px]">•</span>
          <span className="text-[#F5F5F0]/40 text-[10px] uppercase tracking-wider font-medium">Security Console</span>
        </div>
        
        <div className="text-[#F5F5F0]/50 text-[12px] absolute left-1/2 -translate-x-1/2">
          {user?.venue || 'The Oberoi Mumbai'}
        </div>

        <div className="flex items-center gap-4">
          <div className="relative">
             <Bell className="w-5 h-5 text-[#F5F5F0]" />
             {activeCount > 0 && (
               <div className="absolute -top-1 -right-1 bg-[#5A5A40] text-[#F5F5F0] text-[9px] w-3.5 h-3.5 rounded-full flex items-center justify-center font-medium">
                 {activeCount}
               </div>
             )}
          </div>
          
          <div className="flex items-center">
            <div className="w-7 h-7 rounded-full bg-[#475B49] flex items-center justify-center text-[#F5F5F0] text-[10px] font-medium mr-2 uppercase">
              {user?.name?.substring(0,2) || 'ST'}
            </div>
            <span className="text-[#F5F5F0]/70 text-[11px] mr-4">{user?.name}</span>
            <button onClick={() => auth.signOut().then(() => router.push('/login'))} className="text-[#F5F5F0]/40 text-[10px] hover:text-[#F5F5F0] transition-colors">Sign out</button>
          </div>
        </div>
      </div>

      {/* Toast Alert */}
      <AnimatePresence>
        {toastAlert && (
          <motion.div 
            initial={{ y: -100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -100, opacity: 0 }}
            onClick={() => router.push(`/staff/incident/${toastAlert.id}`)}
            className="absolute top-14 left-0 w-full bg-[#141414] py-3 px-4 z-40 cursor-pointer border-b border-[#F5F5F0]/10"
          >
            <div className="flex items-start">
              <div className="w-8 h-8 bg-[#5A5A40] rounded shadow-none flex items-center justify-center mr-3 shrink-0">
                 <AlertTriangle className="w-5 h-5 text-[#F5F5F0]" />
              </div>
              <div className="flex-1">
                <div className="text-[12px] font-medium text-[#F5F5F0]">EMERGENCY ALERT: {toastAlert.aiType?.toUpperCase() || toastAlert.type?.toUpperCase()}</div>
                <div className="text-[11px] text-[#F5F5F0]/60 mt-0.5 max-w-3xl truncate">
                  <span className="text-[#F5F5F0] font-medium">{toastAlert.severity}/10</span> • {toastAlert.aiDescription} • {toastAlert.location?.zoneName}
                </div>
              </div>
              <div className="text-[10px] text-[#F5F5F0]/30 ml-4 whitespace-nowrap">just now</div>
              <button 
                onClick={(e) => { e.stopPropagation(); setToastAlert(null); }}
                className="ml-4 text-[#F5F5F0]/50 hover:text-[#F5F5F0]"
              >
                ✕
              </button>
            </div>
            <motion.div 
              initial={{ width: '100%' }}
              animate={{ width: '0%' }}
              transition={{ duration: 8, ease: 'linear' }}
              onAnimationComplete={() => setToastAlert(null)}
              className="absolute bottom-0 left-0 h-[2px] bg-[#5A5A40]"
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Body */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left Panel */}
        <div className="flex-[3] p-6 md:p-10 flex flex-col h-full overflow-y-auto w-full">
           <div className="flex justify-between items-center mb-6">
             <div className="text-[12px] font-medium text-[rgba(20,20,20,0.6)] tracking-wider uppercase">Live Incident Feed</div>
             <div className="flex items-center gap-3">
               <div className="bg-[#141414] text-[#F5F5F0] text-[10px] px-2 py-0.5 rounded-full">{activeCount} active</div>
               <select 
                 value={sortOption} 
                 onChange={e => setSortOption(e.target.value as any)}
                 className="text-[11px] border border-[rgba(20,20,20,0.1)] rounded p-1"
               >
                 <option value="time">Sort by Time</option>
                 <option value="severity">Sort by Severity</option>
               </select>
             </div>
           </div>

           {loading ? (
             <div className="space-y-4">
               {[1,2,3].map(i => <div key={i} className="h-20 bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none animate-pulse" />)}
             </div>
           ) : activeIncidents.length === 0 ? (
             <div className="flex-1 flex flex-col items-center justify-center">
               <ShieldCheck className="w-12 h-12 text-[#475B49] mb-4" />
               <div className="text-[24px] font-serif tracking-tight font-medium text-[#475B49]">All clear</div>
               <div className="text-[13px] text-[rgba(20,20,20,0.6)]">No active incidents</div>
             </div>
           ) : (
             <div className="space-y-3 pb-10 w-full max-w-4xl">
               {activeIncidents.map(inc => (
                 <div 
                   key={inc.id}
                   onClick={() => router.push(`/staff/incident/${inc.id}`)}
                   className="flex bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none overflow-hidden cursor-pointer hover:border-[rgba(20,20,20,0.4)] transition-colors group"
                 >
                   <div className={`w-1 shrink-0 ${getStripeColor(inc.severity || 1)}`} />
                   <div className="p-4 w-full flex flex-col justify-center relative">
                     <div className="flex items-center justify-between mb-2">
                       <div className="flex items-center">
                         <span className="text-[13px] font-medium text-[#141414] capitalize mr-2">{inc.aiType || inc.type}</span>
                         {inc.severity && (
                           <div className={`text-[10px] px-1.5 rounded-sm text-[#F5F5F0] font-medium ${getStripeColor(inc.severity)}`}>
                             {inc.severity}
                           </div>
                         )}
                       </div>
                       <div>
                         {inc.status === 'verified' && <span className="bg-[#EFEFE8] text-[#475B49] text-[10px] px-2 py-0.5 rounded-full font-medium">AI Verified</span>}
                         {inc.status === 'pending' && <span className="bg-[#EFEFE8] text-[#8A8263] text-[10px] px-2 py-0.5 rounded-full font-medium">Pending</span>}
                       </div>
                     </div>
                     <div className="flex items-center text-[rgba(20,20,20,0.6)] text-[11px] mb-1">
                       <MapPin className="w-3 h-3 mr-1" />
                       <span className="truncate max-w-[200px]">{inc.location?.zoneName}</span>
                     </div>
                     <div className="flex items-center text-[rgba(20,20,20,0.4)] text-[10px]">
                       <span>{inc.timestamp ? formatDistanceToNow(inc.timestamp.toDate(), {addSuffix: true}) : 'Just now'}</span>
                       {inc.assignedName && (
                         <>
                           <span className="mx-1.5">•</span>
                           <span className="text-[#475B49] font-medium">{inc.assignedName}</span>
                         </>
                       )}
                     </div>
                     
                     <div className="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-3">
  <button
    onClick={async (e) => {
      e.stopPropagation();
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
    className="bg-[#475B49] text-white text-[11px] px-3 py-1 font-medium z-10 hidden group-hover:block"
  >
    Resolve
  </button>
  <ChevronRight className="w-4 h-4 text-[rgba(20,20,20,0.4)]" />
</div>
                   </div>
                 </div>
               ))}
             </div>
           )}
        </div>

        {/* Right Panel */}
        <div className="w-[320px] lg:w-[360px] bg-[#F5F5F0] border-l border-[rgba(20,20,20,0.1)] flex flex-col shrink-0">
          <div className="p-6 md:p-8 flex-1 overflow-y-auto">
            <div className="text-[11px] font-medium text-[rgba(20,20,20,0.6)] tracking-wider uppercase mb-3">Venue Zones</div>
            
            {/* Zone Grid */}
            <div className="grid grid-cols-3 gap-1">
              {zones.map((zone) => {
                const zoneIncidents = activeIncidents.filter(i => i.location?.zoneId === zone.id);
                const maxSeverity = zoneIncidents.reduce((max, i) => Math.max(max, i.severity || 0), 0);
                
                let bg = 'bg-[#475B49]/10 border-[#475B49] text-[#475B49]', font = 'font-normal';
                if (maxSeverity >= 8) { bg = 'bg-[#5A5A40]/20 border-[#5A5A40] text-[#5A5A40] font-medium'; }
                else if (maxSeverity >= 4) { bg = 'bg-[#8A8263]/15 border-[#8A8263] text-[#8A8263]'; }
                
                return (
                  <div key={zone.id} className={`aspect-square border flex items-center justify-center text-center p-1 rounded-none ${bg}`} title={`${zoneIncidents.length} incidents`}>
                    <span className="text-[9px] leading-tight break-words">{zone.shortName || zone.name}</span>
                  </div>
                );
              })}
            </div>

            {/* Legend */}
            <div className="flex gap-3 mt-4 justify-center">
              <div className="flex items-center"><div className="w-2 h-2 rounded-full bg-[#5A5A40] mr-1"/><span className="text-[10px] text-[rgba(20,20,20,0.6)]">Critical</span></div>
              <div className="flex items-center"><div className="w-2 h-2 rounded-full bg-[#8A8263] mr-1"/><span className="text-[10px] text-[rgba(20,20,20,0.6)]">Active</span></div>
              <div className="flex items-center"><div className="w-2 h-2 rounded-full bg-[#475B49] mr-1"/><span className="text-[10px] text-[rgba(20,20,20,0.6)]">Clear</span></div>
            </div>
          </div>

          <div className="p-6 md:p-8 border-t border-[rgba(20,20,20,0.1)]">
            <div className="text-[11px] font-medium text-[rgba(20,20,20,0.6)] tracking-wider uppercase mb-3">Quick Actions</div>
            <button onClick={triggerEvacuation} className="w-full h-[52px] bg-[#5A5A40] text-[#F5F5F0] rounded-none text-[14px] font-medium mb-3">
              Trigger Evacuation Alert
            </button>
            <button onClick={() => {
               if(user?.role === 'manager') router.push('/manager');
               else alert('Access denied: Managers only.');
            }} className="w-full h-[40px] bg-[#F5F5F0] border border-[#141414] text-[#141414] rounded-none text-[13px] font-medium">
              View Manager Panel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
