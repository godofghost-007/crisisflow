'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'motion/react';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { Triangle } from 'lucide-react';

export default function SplashScreen() {
  const router = useRouter();

  useEffect(() => {
    const timeout = setTimeout(() => {
      // Check auth state
      const unsubscribe = onAuthStateChanged(auth, async (user) => {
        if (!user) {
          router.replace('/report');
        } else {
          // Check role
          if (user.isAnonymous) {
            router.replace('/report');
            return;
          }
          const userDoc = await getDoc(doc(db, 'users', user.uid));
          if (userDoc.exists()) {
            const role = userDoc.data().role;
            if (role === 'staff') {
              router.replace('/staff');
            } else if (role === 'manager') {
              router.replace('/manager');
            } else {
              router.replace('/report');
            }
          } else {
            router.replace('/report');
          }
        }
      });
      return () => unsubscribe();
    }, 1800);
    return () => clearTimeout(timeout);
  }, [router]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-[#141414] text-[#F5F5F0] overflow-hidden relative">
      <motion.div
        initial={{ scale: 0.5, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: 'spring', duration: 0.8 }}
        className="flex flex-col items-center"
      >
        <div className="w-20 h-20 bg-[#5A5A40] rounded-none flex items-center justify-center mb-5">
          <Triangle className="w-10 h-10 text-[#F5F5F0] fill-[#F5F5F0]" />
        </div>
        <motion.h1 
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.5 }}
          className="text-[42px] font-serif tracking-tight leading-none font-medium tracking-tight"
        >
          CrisisFlow
        </motion.h1>
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.5 }}
          className="text-[14px] text-[#F5F5F0]/50 mt-2"
        >
          Emergency coordination platform
        </motion.p>
      </motion.div>

      <div className="absolute bottom-[60px] w-[200px] h-[3px] bg-[#F5F5F0]/15 rounded-sm overflow-hidden">
        <motion.div
          initial={{ width: '0%' }}
          animate={{ width: '100%' }}
          transition={{ duration: 1.8, ease: 'linear' }}
          className="h-full bg-[#5A5A40]"
        />
      </div>
    </div>
  );
}
