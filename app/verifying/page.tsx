'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { doc, onSnapshot } from 'firebase/firestore';
import { db, auth } from '@/lib/firebase';
import { handleFirestoreError, OperationType } from '@/lib/firestore-error';
import { motion } from 'motion/react';
import { Brain, CheckCircle2 } from 'lucide-react';

function VerifyingView() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const id = searchParams.get('id');
  
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    if (!id) return;

    let check: () => void;
    let timer: NodeJS.Timeout;

    // Auto navigate after 5s max
    timer = setTimeout(() => {
      router.push(`/success?id=${id}`);
    }, 5000);

    if (auth.currentUser) {
      check = onSnapshot(doc(db, 'incidents', id), (snap) => {
        if (snap.exists() && snap.data().aiType) {
          setData(snap.data());
          if (snap.data().status === 'verified') {
            setTimeout(() => router.push(`/success?id=${id}`), 2000);
          } else if (snap.data().status === 'dismissed') {
             setTimeout(() => router.push(`/success?id=${id}`), 2000);
          }
        }
      }, (error) => handleFirestoreError(error, OperationType.GET, `incidents/${id}`));
    }

    return () => {
      if (timer) clearTimeout(timer);
      if (check) check();
    };
  }, [id, router]);

  return (
    <div className="w-full max-w-[360px] mx-auto min-h-screen bg-[#F5F5F0] flex flex-col items-center justify-center p-6 text-center">
      <motion.div
        animate={{ scale: [1, 1.05, 1] }}
        transition={{ repeat: Infinity, duration: 2 }}
        className="mb-6 w-20 h-20 bg-[#F5F5F0] rounded-full flex items-center justify-center border-2 border-[rgba(20,20,20,0.2)]"
      >
        <Brain className="w-10 h-10 text-[#141414]" />
      </motion.div>
      
      <h1 className="text-[28px] font-serif tracking-tight font-medium text-[#141414] mb-1">AI is verifying</h1>
      <p className="text-[13px] text-[rgba(20,20,20,0.6)] mb-8">Gemini Vision is analysing your photo</p>

      <div className="w-full bg-[#F5F5F0] border border-[rgba(20,20,20,0.2)] rounded-none p-4 text-left mb-8">
        <div className="text-[10px] uppercase font-medium text-[#141414] mb-4">Gemini Vision analysing</div>
        
        {!data ? (
          <div className="space-y-3 animate-pulse">
            <div className="h-4 bg-[rgba(20,20,20,0.1)] rounded w-full"></div>
            <div className="h-4 bg-[rgba(20,20,20,0.1)] rounded w-4/5"></div>
            <div className="h-4 bg-[rgba(20,20,20,0.1)] rounded w-full"></div>
          </div>
        ) : (
          <div className="space-y-3 text-[12px]">
            <div className="flex justify-between items-center">
              <span className="text-[rgba(20,20,20,0.6)] font-medium">Type</span>
              <span className="font-medium capitalize text-[#141414]">{data.aiType}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-[rgba(20,20,20,0.6)] font-medium w-16">Severity</span>
              <div className="flex-1 ml-4 flex items-center justify-end">
                <motion.div initial={{ width: 0 }} animate={{ width: `${(data.severity / 10) * 100}%` }} className="h-1.5 bg-[#5A5A40] rounded-full mr-2" />
                <span className="font-medium text-[#141414] text-[10px] whitespace-nowrap">{data.severity} out of 10</span>
              </div>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-[rgba(20,20,20,0.6)] font-medium">Confidence</span>
              <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-[#141414]/10 text-[#141414] capitalize">{data.confidence}</span>
            </div>
            <div className="pt-2 italic text-[#141414] text-center border-t border-[rgba(20,20,20,0.2)]/30 mt-2">
              &quot;{data.aiDescription}&quot;
            </div>
          </div>
        )}
      </div>

      <div className="w-full flex flex-col gap-4 text-left border border-[rgba(20,20,20,0.1)] rounded-none p-4">
        <div className="flex items-center opacity-50">
          <CheckCircle2 className="w-5 h-5 text-[#475B49] mr-3" />
          <span className="text-[14px] text-[#141414] font-medium line-through">Location captured</span>
        </div>
        <div className="flex items-center opacity-50">
          <CheckCircle2 className="w-5 h-5 text-[#475B49] mr-3" />
          <span className="text-[14px] text-[#141414] font-medium line-through">Photo uploading</span>
        </div>
        <div className="flex items-center">
          <CheckCircle2 className="w-5 h-5 text-[#475B49] mr-3" />
          <span className="text-[14px] text-[#141414] font-medium">AI verification</span>
        </div>
        <div className="flex items-center">
          <motion.div 
            animate={{ scale: [1, 1.2, 1], opacity: [0.5, 1, 0.5] }} 
            transition={{ repeat: Infinity, duration: 1.5 }}
            className="w-5 h-5 flex items-center justify-center mr-3"
          >
            <div className="w-2.5 h-2.5 bg-[#5A5A40] rounded-full" />
          </motion.div>
          <span className="text-[14px] text-[#141414] font-medium">Alerting responders</span>
        </div>
      </div>
    </div>
  );
}

export default function VerifyingPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#F5F5F0]"></div>}>
      <VerifyingView />
    </Suspense>
  );
}
