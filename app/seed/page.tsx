'use client';

import { useState, useEffect } from 'react';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { doc, setDoc, addDoc, collection, getDocs, query, where } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { Loader2, Check } from 'lucide-react';

export default function SeedPage() {
  const [status, setStatus] = useState<string>('Ready to seed data. Please ensure Email/Password Auth is enabled in Firebase Console.');
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  const performSeed = async () => {
    setLoading(true);
    setStatus('Seeding users...');
    try {
      const users = [
        { email: 'rahul@theoberoi.com', pass: 'CrisisFlow@2024', name: 'Rahul Sharma', role: 'staff', venue: 'The Oberoi Mumbai' },
        { email: 'priya@theoberoi.com', pass: 'CrisisFlow@2024', name: 'Priya Mehta', role: 'manager', venue: 'The Oberoi Mumbai' },
        { email: 'suresh@theoberoi.com', pass: 'CrisisFlow@2024', name: 'Suresh Kumar', role: 'staff', venue: 'The Oberoi Mumbai' }
      ];

      for (const u of users) {
        let uid;
        try {
          const cred = await createUserWithEmailAndPassword(auth, u.email, u.pass);
          uid = cred.user.uid;
        } catch (err: any) {
          if (err.code === 'auth/email-already-in-use') {
            // we skip or can't easily get UID without logging in
            // if we really wanted, we could signInWithEmailAndPassword to get the uid
            setStatus(`User ${u.email} already exists. Attempting sign in to get UID...`);
            const { signInWithEmailAndPassword } = await import('firebase/auth');
            const cred = await signInWithEmailAndPassword(auth, u.email, u.pass);
            uid = cred.user.uid;
          } else {
            throw err;
          }
        }
        
        await setDoc(doc(db, 'users', uid), {
          name: u.name, email: u.email, role: u.role, venue: u.venue, fcmToken: null, fcmTokenUpdatedAt: null, createdAt: new Date()
        }, { merge: true });
      }

      setStatus('Seeding zones...');
      const zones = [
        { id: 'zone_lobby_l1', name: 'Lobby Level 1 Zone A', floor: 'Level 1', section: 'Zone A', shortName: 'Lobby', adjacent: ['zone_reception_l1','zone_cafe_l1','zone_lifts_l1'] },
        { id: 'zone_reception_l1', name: 'Reception Level 1 Zone B', floor: 'Level 1', section: 'Zone B', shortName: 'Reception', adjacent: ['zone_lobby_l1','zone_cafe_l1'] },
        { id: 'zone_cafe_l1', name: 'Cafe Level 1', floor: 'Level 1', section: 'Cafe', shortName: 'Cafe', adjacent: ['zone_lobby_l1','zone_reception_l1','zone_lifts_l1'] },
        { id: 'zone_lifts_l1', name: 'Lifts Level 1', floor: 'Level 1', section: 'Lifts', shortName: 'Lifts', adjacent: ['zone_lobby_l1','zone_cafe_l1','zone_corridor_l2'] },
        { id: 'zone_corridor_l2', name: 'Corridor Level 2', floor: 'Level 2', section: 'Corridor', shortName: 'Corridor', adjacent: ['zone_lifts_l1','zone_rooms_l2','zone_gym_l2','zone_conf_a_l2'] },
        { id: 'zone_rooms_l2', name: 'Guest Rooms Level 2', floor: 'Level 2', section: 'Rooms', shortName: 'Rooms 101', adjacent: ['zone_corridor_l2'] },
        { id: 'zone_gym_l2', name: 'Gym Level 2', floor: 'Level 2', section: 'Gym', shortName: 'Gym', adjacent: ['zone_corridor_l2','zone_pool_l1'] },
        { id: 'zone_conf_a_l2', name: 'Conference A Level 2', floor: 'Level 2', section: 'Conf A', shortName: 'Conf A', adjacent: ['zone_corridor_l2','zone_conf_b_l2'] },
        { id: 'zone_conf_b_l2', name: 'Conference B Level 2', floor: 'Level 2', section: 'Conf B', shortName: 'Conf B', adjacent: ['zone_conf_a_l2','zone_corridor_l2'] },
        { id: 'zone_kitchen_l3', name: 'Kitchen Level 3', floor: 'Level 3', section: 'Kitchen', shortName: 'Kitchen', adjacent: ['zone_storage_l3'] },
        { id: 'zone_storage_l3', name: 'Storage Level 3', floor: 'Level 3', section: 'Storage', shortName: 'Storage', adjacent: ['zone_kitchen_l3'] },
        { id: 'zone_pool_l1', name: 'Pool Deck Ground', floor: 'Ground', section: 'Pool', shortName: 'Pool deck', adjacent: ['zone_gym_l2','zone_gate_l1'] },
        { id: 'zone_gate_l1', name: 'Main Gate Ground', floor: 'Ground', section: 'Gate', shortName: 'Gate', adjacent: ['zone_pool_l1'] },
      ];

      for (const z of zones) {
        await setDoc(doc(db, 'zones', z.id), {
          name: z.name, floor: z.floor, section: z.section, shortName: z.shortName, adjacentZones: z.adjacent, createdAt: new Date(), createdBy: 'seed',
          qrData: `https://${process.env.NEXT_PUBLIC_APP_URL || process.env.APP_URL || 'crisisflow.web.app'}/report?zone=${z.id}&name=${encodeURIComponent(z.name)}&floor=${encodeURIComponent(z.floor)}`
        });
      }

      setStatus('Seeding resources...');
      const resources = [
        { name: 'Fire Team Alpha', type: 'fire_team', zone: 'Lobby', zoneId: 'zone_lobby_l1' },
        { name: 'Fire Team Beta', type: 'fire_team', zone: 'Level 2 Corridor', zoneId: 'zone_corridor_l2' },
        { name: 'Medical Kit 1', type: 'medical_kit', zone: 'Reception', zoneId: 'zone_reception_l1' },
        { name: 'Medical Kit 2', type: 'medical_kit', zone: 'Level 3 Storage', zoneId: 'zone_storage_l3' },
        { name: 'Dr Sharma', type: 'medic', zone: 'Lobby', zoneId: 'zone_lobby_l1' },
        { name: 'Security Guard 1', type: 'security_guard', zone: 'Main Gate', zoneId: 'zone_gate_l1' },
        { name: 'Security Guard 2', type: 'security_guard', zone: 'Level 2 Corridor', zoneId: 'zone_corridor_l2' },
        { name: 'Security Guard 3', type: 'security_guard', zone: 'Pool Deck', zoneId: 'zone_pool_l1' },
      ];

      for (const r of resources) {
        const snap = await getDocs(query(collection(db, 'resources'), where('name', '==', r.name)));
        if (snap.empty) {
          await addDoc(collection(db, 'resources'), {
            ...r, available: true, currentIncidentId: null, lastUpdated: new Date(), createdAt: new Date(), createdBy: 'seed'
          });
        }
      }

      setStatus('Seeding complete! You can now log in.');
      setDone(true);
    } catch (err: any) {
      console.error(err);
      setStatus(`Error: ${err.message}`);
    } finally {
      setLoading(false);
      auth.signOut(); // sign out the last created user
    }
  };

  return (
    <div className="p-8 max-w-xl mx-auto font-sans">
      <h1 className="text-2xl font-bold mb-4 font-serif">Setup Database & Users</h1>
      <div className="bg-orange-50 border border-orange-200 p-4 rounded-lg mb-6">
        <h2 className="font-semibold text-orange-800 mb-2">Important Instructions</h2>
        <ol className="list-decimal list-inside text-sm text-orange-900 space-y-1">
          <li>Go to <a href="https://console.firebase.google.com" target="_blank" className="underline font-medium">Firebase Console</a></li>
          <li>Select your project <strong>{process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'current project'}</strong></li>
          <li>Go to <strong>Authentication &rarr; Sign-in method</strong></li>
          <li>Click <strong>Add new provider</strong> and enable <strong>Email/Password</strong></li>
          <li>Click the button below to generate demo users</li>
        </ol>
      </div>

      <button disabled={loading || done} onClick={performSeed} className="bg-[#141414] text-white px-6 py-3 rounded w-full flex items-center justify-center disabled:opacity-50 font-medium">
        {loading ? <Loader2 className="w-5 h-5 animate-spin mr-2" /> : (done ? <Check className="w-5 h-5 mr-2" /> : null)}
        {loading ? 'Seeding...' : (done ? 'Seed Complete' : 'Run Data Seed')}
      </button>

      <div className="mt-4 text-sm text-gray-600 bg-gray-50 border border-gray-100 p-4 rounded-lg">
        {status}
      </div>
      
      {done && (
         <div className="mt-8 pt-8 border-t border-gray-200">
           <h3 className="font-bold mb-4">You can now login with:</h3>
           <div className="space-y-4">
             <div>
               <div className="font-medium text-sm text-gray-500 uppercase tracking-widest mb-1">Staff / Security</div>
               <div className="text-sm">Email: <span className="font-mono bg-gray-100 px-1 py-0.5 rounded">rahul@theoberoi.com</span></div>
               <div className="text-sm">Password: <span className="font-mono bg-gray-100 px-1 py-0.5 rounded">CrisisFlow@2024</span></div>
             </div>
             <div>
               <div className="font-medium text-sm text-gray-500 uppercase tracking-widest mb-1">Manager</div>
               <div className="text-sm">Email: <span className="font-mono bg-gray-100 px-1 py-0.5 rounded">priya@theoberoi.com</span></div>
               <div className="text-sm">Password: <span className="font-mono bg-gray-100 px-1 py-0.5 rounded">CrisisFlow@2024</span></div>
             </div>
           </div>
           <button onClick={() => window.location.href = '/login'} className="mt-6 border border-black px-4 py-2 text-sm font-medium">
             Go to Login Page
           </button>
         </div>
      )}
    </div>
  );
}