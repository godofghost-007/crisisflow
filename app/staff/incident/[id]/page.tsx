'use client';

import { use, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { doc, onSnapshot, getDocs, collection, query, where, writeBatch, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { handleFirestoreError, OperationType } from '@/lib/firestore-error';
import { ArrowLeft, Clock, MapPin, User, Brain, Camera, Check } from 'lucide-react';
import { format } from 'date-fns';
import { formatDistanceToNow } from 'date-fns';

export default function IncidentDetailScreen({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const { id } = use(params);
  
  const [incident, setIncident] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [availableResources, setAvailableResources] = useState<any[]>([]);

  useEffect(() => {
    let unsub: any = null;

    const unsubAuth = auth.onAuthStateChanged((u) => {
      if (!u || u.isAnonymous) {
        if (unsub) unsub();
        router.replace('/login');
        return;
      }
      
      unsub = onSnapshot(doc(db, 'incidents', id), (snap) => {
        if (snap.exists()) {
          setIncident({ id: snap.id, ...snap.data() });
        }
        setLoading(false);
      }, (error) => handleFirestoreError(error, OperationType.GET, `incidents/${id}`));
    });

    return () => {
      unsubAuth();
      if(unsub) unsub();
    };
  }, [id, router]);

  const fetchAvailableResources = async (type: string) => {
    const snap = await getDocs(query(collection(db, 'resources'), where('available', '==', true)));
    let resources: any[] = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    
    // Filter matching types
    if (type === 'fire' || type === 'smoke') {
      resources = resources.filter(r => r.type === 'fire_team');
    } else if (type === 'medical') {
      resources = resources.filter(r => r.type === 'medical_kit' || r.type === 'medic');
    } else if (type === 'security') {
      resources = resources.filter(r => r.type === 'security_guard');
    }
    
    setAvailableResources(resources);
    setShowAssignModal(true);
  };

  const handleAssignResource = async (resource: any) => {
    try {
      const batch = writeBatch(db);
      
      const incRef = doc(db, 'incidents', id);
      batch.update(incRef, {
        assignedTo: resource.id,
        assignedName: resource.name
      });
      
      const resRef = doc(db, 'resources', resource.id);
      batch.update(resRef, {
        available: false,
        currentIncidentId: id
      });
      
      await batch.commit();
      setShowAssignModal(false);
    } catch(e) {
      console.error(e);
      alert('Error assigning resource');
    }
  };

  const handleResolve = async () => {
    if(!confirm('Mark incident as resolved?')) return;
    try {
      const batch = writeBatch(db);
      const incRef = doc(db, 'incidents', id);
      batch.update(incRef, {
        status: 'resolved',
        resolvedAt: serverTimestamp(),
        resolvedBy: auth.currentUser?.uid
      });
      
      if (incident.assignedTo) {
        const resRef = doc(db, 'resources', incident.assignedTo);
        batch.update(resRef, {
          available: true,
          currentIncidentId: null
        });
      }

      await batch.commit();
      
      // Async trigger syncAnalytics
      fetch('/api/syncAnalytics', {
         method: 'POST', body: JSON.stringify({ incidentId: id })
      }).catch(console.error);

      router.back();
    } catch(e) {
      console.error(e);
      alert('Error resolving');
    }
  };

  if (loading) return <div className="min-h-screen bg-[#F5F5F0]" />;
  if (!incident) return <div className="min-h-screen bg-[#F5F5F0] flex justify-center items-center">Not found</div>;

  const severityColor = incident.severity >= 8 ? 'bg-[#5A5A40]' : (incident.severity >= 4 ? 'bg-[#8A8263]' : 'bg-[#475B49]');

  return (
    <div className="min-h-screen bg-[#F5F5F0] flex flex-col items-center">
      {/* App Bar */}
      <div className="w-full h-14 bg-[#141414] flex items-center px-4 shrink-0">
        <button onClick={() => router.back()} className="p-2 -ml-2 text-[#F5F5F0]/70 hover:text-[#F5F5F0] mr-2">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <span className="text-[#F5F5F0] font-medium text-[16px] font-serif tracking-tight capitalize flex-1">{incident.aiType || incident.type}</span>
        {incident.severity && (
          <div className={`${severityColor} text-[#F5F5F0] text-[10px] px-2 py-0.5 rounded font-medium`}>
            {incident.severity}/10
          </div>
        )}
      </div>

      <div className="flex-1 w-full max-w-[700px] p-5 overflow-y-auto pb-24">
         {/* Photo Section */}
         <div className="w-full h-[180px] bg-[#EBEBE4] rounded-none overflow-hidden mb-3 flex items-center justify-center relative">
           {incident.photoURL ? (
             <img src={incident.photoURL} alt="Incident" className="w-full h-full object-cover" />
           ) : (
             <div className="flex flex-col items-center justify-center">
               <Camera className="w-8 h-8 text-[rgba(20,20,20,0.6)] mb-2" />
               <span className="text-[12px] text-[rgba(20,20,20,0.6)]">No photo provided</span>
             </div>
           )}
         </div>
         <div className="text-[11px] text-[rgba(20,20,20,0.6)] mb-6 flex items-center justify-center">
           Reported {formatDistanceToNow(incident.timestamp?.toDate() || new Date(), {addSuffix: true})} from <span className="font-medium text-[#141414] ml-1">{incident.location?.zoneName}</span>
         </div>

         {/* AI Card */}
         <div className="w-full bg-[#F5F5F0] border border-[rgba(20,20,20,0.2)] rounded-none p-4 mb-6">
           <div className="flex items-center mb-4">
             <Brain className="w-4 h-4 text-[#141414] mr-2" />
             <span className="text-[12px] font-medium text-[#141414]">Gemini AI result</span>
           </div>
           
           {!incident.aiType ? (
             <div className="animate-pulse space-y-2">
               <div className="h-3 bg-[rgba(20,20,20,0.1)] w-full rounded" />
               <div className="h-3 bg-[rgba(20,20,20,0.1)] w-2/3 rounded" />
             </div>
           ) : (
             <div className="space-y-3 text-[12px]">
                <div className="flex justify-between items-center">
                  <span className="text-[rgba(20,20,20,0.6)]">Type</span>
                  <span className="px-2 py-0.5 rounded-full bg-[#141414]/10 text-[#141414] font-medium capitalize">{incident.aiType}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-[rgba(20,20,20,0.6)]">Severity</span>
                  <div className="flex items-center flex-1 justify-end ml-4">
                    <div className="h-1.5 w-1/2 bg-[rgba(20,20,20,0.1)] rounded-full mr-2 overflow-hidden flex justify-end">
                      <div className="h-full bg-[#5A5A40]" style={{ width: `${(incident.severity / 10) * 100}%` }} />
                    </div>
                    <span className="text-[#141414] font-medium">{incident.severity}/10</span>
                  </div>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-[rgba(20,20,20,0.6)]">Confidence</span>
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${incident.confidence === 'high' ? 'bg-[#475B49]/10 text-[#475B49]' : (incident.confidence==='medium' ? 'bg-[#4A5868]/10 text-[#4A5868]' : 'bg-[#8A8263]/10 text-[#8A8263]')}`}>
                    <span className="capitalize">{incident.confidence}</span>
                  </span>
                </div>
                <div className="pt-2 mt-2 border-t border-[rgba(20,20,20,0.2)]/30 text-center italic text-[#141414]">
                  &quot;{incident.aiDescription}&quot;
                </div>
             </div>
           )}
         </div>

         {/* Details Card */}
         <div className="w-full bg-[#F5F5F0] border border-[rgba(20,20,20,0.1)] rounded-none p-4 flex flex-col mb-6">
            <div className="flex justify-between py-2 border-b border-[rgba(20,20,20,0.1)]">
              <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Reported by</span>
              <span className="text-[12px] text-[#141414] font-medium">{incident.reportedBy?.startsWith('anon') ? 'Guest anonymous' : 'Guest'}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-[rgba(20,20,20,0.1)]">
               <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Zone</span>
               <span className="text-[12px] text-[#141414] font-medium">{incident.location?.zoneName}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-[rgba(20,20,20,0.1)]">
               <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Floor</span>
               <span className="text-[12px] text-[#141414] font-medium">{incident.location?.floor}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-[rgba(20,20,20,0.1)]">
               <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Reported at</span>
               <span className="text-[12px] text-[#141414] font-medium">{incident.timestamp ? format(incident.timestamp.toDate(), 'HH:mm dd MMM yyyy') : ''}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-[rgba(20,20,20,0.1)]">
               <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Assigned to</span>
               <span className={`text-[12px] font-medium ${incident.assignedTo ? 'text-[#475B49]' : 'text-[rgba(20,20,20,0.6)]'}`}>{incident.assignedName || 'Unassigned'}</span>
            </div>
            <div className="flex justify-between py-2">
               <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Reference</span>
               <span className="text-[12px] text-[#141414] font-mono">{incident.id.substring(0,8)}</span>
            </div>
         </div>

         {/* Actions */}
         {incident.status === 'verified' && !incident.assignedTo && (
           <button onClick={() => fetchAvailableResources(incident.aiType || incident.type)} className="w-full h-[52px] bg-[#141414] text-[#F5F5F0] rounded-none font-medium text-[14px]">
             Acknowledge and assign
           </button>
         )}

         {incident.status !== 'resolved' && incident.assignedTo && (
           <button onClick={handleResolve} className="w-full h-[52px] bg-[#475B49] text-[#F5F5F0] rounded-none font-medium text-[14px]">
             Mark as resolved
           </button>
         )}
      </div>

      {/* Assign Modal */}
      {showAssignModal && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowAssignModal(false)} />
          <div className="bg-[#F5F5F0] w-full rounded-t-2xl p-6 relative z-10 max-h-[80vh] overflow-y-auto">
             <div className="text-[18px] font-serif tracking-tight font-medium text-[#141414] mb-4">Select a resource</div>
             {availableResources.length === 0 ? (
               <div className="text-[13px] text-[rgba(20,20,20,0.6)] py-4 text-center">No matching resources available.</div>
             ) : (
               <div className="space-y-2">
                 {availableResources.map(r => (
                   <button 
                     key={r.id} 
                     onClick={() => handleAssignResource(r)}
                     className="w-full text-left p-4 rounded-none border border-[rgba(20,20,20,0.1)] hover:border-[#475B49] transition-colors"
                   >
                     <div className="font-medium text-[#141414] text-[14px]">{r.name}</div>
                     <div className="text-[12px] text-[rgba(20,20,20,0.6)] mt-1">Currently at <span className="font-medium text-[#141414]">{r.zone}</span></div>
                   </button>
                 ))}
               </div>
             )}
          </div>
        </div>
      )}
    </div>
  );
}
