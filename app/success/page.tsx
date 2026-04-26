'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { doc, getDoc } from 'firebase/firestore';
import { db, auth } from '@/lib/firebase';
import { motion } from 'motion/react';
import { Check, AlertTriangle } from 'lucide-react';

function SuccessView() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const id = searchParams.get('id');
  
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    if (id) {
       const unsubscribeAuth = auth.onAuthStateChanged((user) => {
         if (!user) return;
         getDoc(doc(db, 'incidents', id)).then(snap => {
           if(snap.exists()) setData(snap.data());
         });
       });
       return () => unsubscribeAuth();
    }
  }, [id]);

  if (!data) return <div className="min-h-screen bg-[#F5F5F0]" />;

  const isDismissed = data.status === 'dismissed';

  return (
    <div className="w-full max-w-[420px] mx-auto min-h-screen bg-[#F5F5F0] flex flex-col items-center p-6 text-center pt-24">
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", stiffness: 200, damping: 20 }}
        className={`mb-6 w-24 h-24 rounded-full flex items-center justify-center ${isDismissed ? 'bg-[#EBEBE4] text-[rgba(20,20,20,0.6)]' : 'bg-[#475B49] text-[#F5F5F0]'}`}
      >
        <Check className="w-12 h-12" />
      </motion.div>
      
      <h1 className="text-[32px] font-serif tracking-tight leading-none font-medium text-[#141414] mb-2">{isDismissed ? 'No threat detected' : 'Report received'}</h1>
      <p className="text-[13px] text-[rgba(20,20,20,0.6)] mb-8 max-w-[280px]">
        {isDismissed ? 'AI analysis indicates no dangerous situation present.' : 'Responders have been notified and are on their way.'}
      </p>

      <div className={`w-full text-left rounded-none p-4 mb-6 ${isDismissed ? 'bg-[#EBEBE4] border border-[rgba(20,20,20,0.1)]' : 'bg-[#EFEFE8] border border-[rgba(20,20,20,0.15)]'}`}>
        <div className={`text-[11px] font-medium uppercase mb-4 ${isDismissed ? 'text-[rgba(20,20,20,0.6)]' : 'text-[#141414]'}`}>Your report</div>
        <div className="space-y-3">
          <div className="flex justify-between items-center text-[12px]">
            <span className="text-[rgba(20,20,20,0.6)]">Type</span>
            <span className="text-[#141414] font-medium capitalize">{data.type}</span>
          </div>
          <div className="flex justify-between items-center text-[12px]">
            <span className="text-[rgba(20,20,20,0.6)]">Zone</span>
            <span className="text-[#141414] font-medium">{data.location?.zoneName || 'Unknown'}</span>
          </div>
          <div className="flex justify-between items-center text-[12px]">
            <span className="text-[rgba(20,20,20,0.6)]">AI severity</span>
            <span className="text-[#141414] font-medium">{data.severity || 1}/10 ({data.confidence})</span>
          </div>
          <div className="flex justify-between items-center text-[12px]">
            <span className="text-[rgba(20,20,20,0.6)]">Responders</span>
            <span className="text-[#141414] font-medium">{isDismissed ? '0 notified' : '1+ notified'}</span>
          </div>
          <div className="flex justify-between items-center text-[12px]">
            <span className="text-[rgba(20,20,20,0.6)]">Reference</span>
            <span className="text-[#141414] font-mono bg-[#F5F5F0] px-2 py-0.5 rounded border border-[rgba(20,20,20,0.1)]">{id?.substring(0, 8)}</span>
          </div>
        </div>
      </div>

      {data.severity >= 6 && !isDismissed && (
        <div className="w-full bg-[#EFEFE8] border border-[rgba(20,20,20,0.1)] rounded-none p-[14px] text-left mb-6">
          <div className="flex items-center text-[#141414] mb-2">
            <AlertTriangle className="w-4 h-4 mr-2" />
            <span className="text-[12px] font-medium">Evacuation guidance</span>
          </div>
          <p className="text-[12px] text-[#141414] leading-[1.7]">
            Proceed to the nearest marked exit. Do not use lifts. Assembly point is Main Car Park. Follow staff instructions.
          </p>
        </div>
      )}

      <div className="w-full mt-auto mb-8 flex flex-col gap-4">
         <button onClick={() => router.push('/report')} className="w-full h-[52px] bg-[#5A5A40] text-[#F5F5F0] rounded-none font-medium text-[16px] font-serif tracking-tight">
            Submit another report
         </button>
         <button onClick={() => router.push('/report')} className="w-full h-[40px] text-[rgba(20,20,20,0.6)] font-medium text-[14px]">
            Back to home
         </button>
      </div>

    </div>
  );
}

export default function SuccessPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#F5F5F0]" />}>
      <SuccessView />
    </Suspense>
  );
}
