'use client';

import { Suspense, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { doc, onSnapshot } from 'firebase/firestore';
import { db, auth } from '@/lib/firebase';
import { handleFirestoreError, OperationType } from '@/lib/firestore-error';
import { motion, useAnimation } from 'motion/react';
import { CheckCircle2, Loader2 } from 'lucide-react';

function UploadingView() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const id = searchParams.get('id');

  useEffect(() => {
    if (!id) return;

    let check: () => void;
    let timer: NodeJS.Timeout;

    // Auto navigation as optimistic
    timer = setTimeout(() => {
      router.push(`/verifying?id=${id}`);
    }, 4000);

    if (auth.currentUser) {
      check = onSnapshot(doc(db, 'incidents', id), (snap) => {
        if (snap.exists()) {
          const status = snap.data().status;
          if (status === 'verified') {
            router.push(`/verifying?id=${id}`);
          } else if (status === 'dismissed') {
            router.push('/success?id=' + id);
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
        animate={{ rotate: 360 }}
        transition={{ repeat: Infinity, duration: 2, ease: "linear" }}
        className="mb-6"
      >
        <Loader2 className="w-16 h-16 text-[#8A8263]" />
      </motion.div>
      
      <h1 className="text-[28px] font-serif tracking-tight font-medium text-[#141414] mb-1">Sending your report</h1>
      <p className="text-[13px] text-[rgba(20,20,20,0.6)] mb-8">Processing securely</p>

      <div className="w-full bg-[#EFEFDF] h-[4px] rounded-sm overflow-hidden mb-8">
        <motion.div
          initial={{ width: '0%' }}
          animate={{ width: '100%' }}
          transition={{ duration: 2, ease: 'linear' }}
          className="h-full bg-[#5A5A40]"
        />
      </div>

      <div className="w-full flex flex-col gap-4 text-left border border-[rgba(20,20,20,0.1)] rounded-none p-4">
        <div className="flex items-center">
          <CheckCircle2 className="w-5 h-5 text-[#475B49] mr-3" />
          <span className="text-[14px] text-[#141414] font-medium">Location captured</span>
        </div>
        <div className="flex items-center">
          <motion.div 
            animate={{ scale: [1, 1.2, 1], opacity: [0.5, 1, 0.5] }} 
            transition={{ repeat: Infinity, duration: 1.5 }}
            className="w-5 h-5 flex items-center justify-center mr-3"
          >
            <div className="w-2.5 h-2.5 bg-[#5A5A40] rounded-full" />
          </motion.div>
          <span className="text-[14px] text-[#141414] font-medium">Photo uploading</span>
        </div>
        <div className="flex items-center">
          <div className="w-5 h-5 bg-[#EBEBE4] text-[rgba(20,20,20,0.6)] rounded-full flex items-center justify-center text-[10px] font-medium mr-3">3</div>
          <span className="text-[14px] text-[rgba(20,20,20,0.6)] font-medium">AI verification</span>
        </div>
        <div className="flex items-center">
          <div className="w-5 h-5 bg-[#EBEBE4] text-[rgba(20,20,20,0.6)] rounded-full flex items-center justify-center text-[10px] font-medium mr-3">4</div>
          <span className="text-[14px] text-[rgba(20,20,20,0.6)] font-medium">Alerting responders</span>
        </div>
      </div>
    </div>
  );
}

export default function UploadingPage() {
  return (
    <Suspense fallback={<div className="bg-[#F5F5F0] min-h-screen"></div>}>
      <UploadingView />
    </Suspense>
  );
}
