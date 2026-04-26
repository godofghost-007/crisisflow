'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { Triangle, User, LayoutGrid, Loader2 } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  
  const [loadingRole, setLoadingRole] = useState<'staff' | 'manager' | null>(null);
  const [error, setError] = useState('');

  const handleQuickLogin = async (role: 'staff' | 'manager') => {
    setLoadingRole(role);
    setError('');
    
    // Quick login credentials matching our seed data
    const email = role === 'staff' ? 'rahul@theoberoi.com' : 'priya@theoberoi.com';
    const password = 'CrisisFlow@2024';
    
    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);
      // Fetch user role
      const userRef = doc(db, 'users', cred.user.uid);
      const userDoc = await getDoc(userRef);
      
      if (userDoc.exists()) {
        const data = userDoc.data();
        if (data.role !== role) {
          setError('User role mismatch in database');
          setLoadingRole(null);
          return;
        }
        
        // Mock token update since we aren't using real FCM on web easily
        await updateDoc(userRef, {
           fcmToken: 'dummy-token-' + Date.now(),
           fcmTokenUpdatedAt: serverTimestamp()
        });

        if (role === 'staff') {
          router.push('/staff');
        } else {
          router.push('/manager');
        }
      } else {
        setError('User record not found');
        setLoadingRole(null);
      }
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to sign in');
      setLoadingRole(null);
    }
  };

  return (
    <div className="w-full max-w-[420px] mx-auto min-h-screen bg-[#F5F5F0] flex flex-col">
      {/* Header */}
      <div className="bg-[#141414] pt-10 px-6 pb-8">
        <div className="flex items-center mb-8">
          <div className="w-9 h-9 bg-[#5A5A40] rounded-none flex items-center justify-center mr-3">
             <Triangle className="w-5 h-5 text-[#F5F5F0] fill-[#F5F5F0]" />
          </div>
          <span className="text-[#F5F5F0] font-medium text-[18px] font-serif tracking-tight">CrisisFlow</span>
        </div>
        <h1 className="text-[36px] font-serif tracking-tight leading-none font-medium text-[#F5F5F0] mb-2">Welcome back</h1>
        <p className="text-[13px] text-[#F5F5F0]/50">Select your role to sign in</p>
      </div>

      {/* Body */}
      <div className="p-6 flex-1 flex flex-col">
        {/* Roles - Quick Login */}
        <div className="mb-8">
          <label className="text-[10px] uppercase font-medium text-[rgba(20,20,20,0.6)] tracking-[0.07em] block mb-2">Continue as</label>
          <div className="flex flex-col gap-4">
            <button 
              onClick={() => handleQuickLogin('staff')}
              disabled={loadingRole !== null}
              className={`w-full rounded-none p-5 border-2 flex items-start transition-colors ${loadingRole === 'staff' ? 'bg-[#EFEFE8] border-[#475B49]' : 'bg-[#F5F5F0] border-[rgba(20,20,20,0.1)] hover:bg-[#EFEFE8] hover:border-[#475B49]'}`}
            >
              <div className="bg-white p-3 rounded-full mr-4 shadow-sm">
                <User className="w-6 h-6 text-[#475B49]" />
              </div>
              <div className="flex-1 text-left">
                <div className="text-[15px] font-medium mb-1 text-[#141414] flex items-center">
                  Staff / Security
                  {loadingRole === 'staff' && <Loader2 className="w-4 h-4 ml-2 animate-spin text-[#475B49]" />}
                </div>
                <div className="text-[12px] text-[rgba(20,20,20,0.5)]">Guards, floor managers</div>
              </div>
            </button>

            <button 
              onClick={() => handleQuickLogin('manager')}
              disabled={loadingRole !== null}
              className={`w-full rounded-none p-5 border-2 flex items-start transition-colors ${loadingRole === 'manager' ? 'bg-[#EFEFE8] border-[#8A8263]' : 'bg-[#F5F5F0] border-[rgba(20,20,20,0.1)] hover:bg-[#EFEFE8] hover:border-[#8A8263]'}`}
            >
              <div className="bg-white p-3 rounded-full mr-4 shadow-sm">
                <LayoutGrid className="w-6 h-6 text-[#8A8263]" />
              </div>
              <div className="flex-1 text-left">
                <div className="text-[15px] font-medium mb-1 text-[#141414] flex items-center">
                  Manager
                  {loadingRole === 'manager' && <Loader2 className="w-4 h-4 ml-2 animate-spin text-[#8A8263]" />}
                </div>
                <div className="text-[12px] text-[rgba(20,20,20,0.5)]">Operations, safety officers</div>
              </div>
            </button>
          </div>
        </div>

        {error && <div className="text-[#5A5A40] text-[12px] font-medium text-center mb-4">{error}</div>}

        <div className="mt-8 flex items-center mb-8">
          <div className="flex-1 h-px bg-[rgba(20,20,20,0.1)]" />
          <span className="px-4 text-[11px] text-[rgba(20,20,20,0.4)] font-medium">OR</span>
          <div className="flex-1 h-px bg-[rgba(20,20,20,0.1)]" />
        </div>

        <button 
          onClick={() => router.push('/report')}
          disabled={loadingRole !== null}
          className="w-full h-[52px] rounded-none border border-[rgba(20,20,20,0.1)] text-[rgba(20,20,20,0.6)] font-medium hover:bg-[rgba(20,20,20,0.02)] transition-colors"
        >
          Report an emergency as guest
        </button>
      </div>
    </div>
  );
}
