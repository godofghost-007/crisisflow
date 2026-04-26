'use client';

import { Suspense, useEffect, useState, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { signInAnonymously } from 'firebase/auth';
import { collection, addDoc, serverTimestamp, getDocs } from 'firebase/firestore';
import { ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { auth, db, storage } from '@/lib/firebase';
import { Triangle, Plus, Shield, CircleDot, QrCode, Camera, Check } from 'lucide-react';
import { motion } from 'motion/react';
import { Scanner } from '@yudiel/react-qr-scanner';
import { CameraCapture } from '@/components/CameraCapture';

function ReportForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  const [zoneId, setZoneId] = useState(searchParams.get('zone') || '');
  const [zoneName, setZoneName] = useState(searchParams.get('name') || '');
  const [floor, setFloor] = useState(searchParams.get('floor') || '');
  
  const [type, setType] = useState<string>('');
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [showCamera, setShowCamera] = useState(false);
  const [note, setNote] = useState('');
  
  const [showScanner, setShowScanner] = useState(false);
  const [allZones, setAllZones] = useState<any[]>([]);
  const [showZoneSelect, setShowZoneSelect] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  const fetchZones = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'zones'));
      const zonesList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setAllZones(zonesList);
    } catch (err: any) {
      console.warn('Failed to fetch zones. Proceeding without zone list.', err);
    }
  };

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      if (user) {
        fetchZones();
      } else {
        signInAnonymously(auth).catch(console.error);
      }
    });
    return () => unsubscribe();
  }, []);

  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setPhotoFile(file);
      setPhotoPreview(URL.createObjectURL(file));
    }
  };

  const handleCameraCapture = (dataUrl: string) => {
    setPhotoPreview(dataUrl);
    // Convert dataUrl to File
    const arr = dataUrl.split(',');
    const mimeMatch = arr[0].match(/:(.*?);/);
    if (!mimeMatch) return;
    const mime = mimeMatch[1];
    const bstr = atob(arr[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) {
      u8arr[n] = bstr.charCodeAt(n);
    }
    const file = new File([u8arr], 'capture.jpg', { type: mime });
    setPhotoFile(file);
    setShowCamera(false);
  };

  const handleQrScan = (text: string) => {
    try {
      const url = new URL(text);
      const z = url.searchParams.get('zone');
      const n = url.searchParams.get('name');
      const f = url.searchParams.get('floor');
      if (z) {
        setZoneId(z);
        if (n) setZoneName(n);
        if (f) setFloor(f);
        setShowScanner(false);
      }
    } catch (e) {
      console.error('Invalid QR code');
    }
  };

  const handleSubmit = async () => {
    if (!type || !photoFile || isSubmitting) return;
    setIsSubmitting(true);
    
    try {
      let photoURL = null;
      if (photoFile) {
        setUploadProgress(10);
        // We will generate the doc ID first
        const newIncidentRef = collection(db, 'incidents');
        const docRef = await addDoc(newIncidentRef, {
           type,
           status: 'pending',
           location: {
             zoneId,
             zoneName,
             floor,
             section: ''
           },
           photoURL: null, // placeholder
           timestamp: serverTimestamp(),
           reportedBy: auth.currentUser?.uid || 'guest',
           note,
        });

        setUploadProgress(40);
        
        // Helper to resize image
        const resizeImage = (file: File): Promise<string> => {
          return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
              const canvas = document.createElement('canvas');
              let width = img.width;
              let height = img.height;
              const max = 800;
              if (width > height && width > max) {
                height *= max / width;
                width = max;
              } else if (height > max) {
                width *= max / height;
                height = max;
              }
              canvas.width = width || 800;
              canvas.height = height || 600;
              const ctx = canvas.getContext('2d');
              ctx?.drawImage(img, 0, 0, width, height);
              resolve(canvas.toDataURL('image/jpeg', 0.6));
            };
            img.onerror = (e) => reject(e);
            img.src = URL.createObjectURL(file);
          });
        };
        
        const base64Photo = await resizeImage(photoFile);
        setUploadProgress(80);
        
        await fetch('/api/triggerAI', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            incidentId: docRef.id,
            photoURL: base64Photo
          })
        });

        router.push(`/uploading?id=${docRef.id}`);
        return;
      }
      
      // If no photo
      const docRef = await addDoc(collection(db, 'incidents'), {
         type,
         status: 'pending',
         location: { zoneId, zoneName, floor, section: '' },
         photoURL: null,
         timestamp: serverTimestamp(),
         reportedBy: auth.currentUser?.uid || 'guest',
         note,
      });
      // automatically classify as none if no photo?
      router.push(`/uploading?id=${docRef.id}`);
      
    } catch (error) {
      console.error(error);
      alert("Failed to submit report. Ensure your photo is valid and try again.");
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  return (
    <div className="w-full max-w-[420px] mx-auto min-h-screen bg-[#F5F5F0] flex flex-col">
      {/* App Bar */}
      <div className="bg-[#141414] h-14 flex items-center justify-between px-4 shrink-0">
        <div className="flex items-center">
          <div className="w-[9px] h-[9px] bg-[#5A5A40] rounded-full mr-2" />
          <div className="flex flex-col">
            <span className="text-[#F5F5F0] font-medium text-[16px] font-serif tracking-tight leading-tight">CrisisFlow</span>
            <span className="text-[#F5F5F0]/50 text-[11px] leading-tight mt-0.5">Scan QR to report</span>
          </div>
        </div>
        <button onClick={() => router.push('/login')} className="text-[#5A5A40] font-medium text-sm">
          Staff login
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-6 md:p-8 flex flex-col gap-8">
        {/* Type Selection */}
        <section>
          <div className="text-[10px] font-medium text-[rgba(20,20,20,0.6)] tracking-[0.07em] mb-3 uppercase">Select Incident Type</div>
          <div className="grid grid-cols-2 gap-[10px]">
            {/* Fire */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setType('fire')}
              className={`h-[88px] rounded-none border-[1.5px] flex flex-col items-center justify-center transition-colors ${type === 'fire' ? 'bg-[#E8E8E0] border-[#5A5A40] border-2' : 'bg-[#EFEFE8] border-[rgba(20,20,20,0.1)]'}`}
            >
              <Triangle className={`w-7 h-7 mb-2 ${type === 'fire' ? 'text-[#5A5A40] fill-[#5A5A40]/20' : 'text-[#5A5A40]'}`} />
              <span className="text-[13px] font-medium text-[#5A5A40]">Fire</span>
            </motion.button>
            
            {/* Medical */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setType('medical')}
              className={`h-[88px] rounded-none border-[1.5px] flex flex-col items-center justify-center transition-colors ${type === 'medical' ? 'bg-[#E8E8E0] border-[#4A5868] border-2' : 'bg-[#EFEFE8] border-[rgba(20,20,20,0.1)]'}`}
            >
              <Plus className="w-7 h-7 mb-2 text-[#4A5868]" />
              <span className="text-[13px] font-medium text-[#4A5868]">Medical</span>
            </motion.button>

            {/* Security */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setType('security')}
              className={`h-[88px] rounded-none border-[1.5px] flex flex-col items-center justify-center transition-colors ${type === 'security' ? 'bg-[#E8E8E0] border-[#8A8263] border-2' : 'bg-[#EFEFE8] border-[rgba(20,20,20,0.1)]'}`}
            >
              <Shield className="w-7 h-7 mb-2 text-[#8A8263]" />
              <span className="text-[13px] font-medium text-[#8A8263]">Security</span>
            </motion.button>

            {/* Other */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => setType('other')}
              className={`h-[88px] rounded-none border-[1.5px] flex flex-col items-center justify-center transition-colors ${type === 'other' ? 'bg-[rgba(20,20,20,0.1)] border-[rgba(20,20,20,0.6)] border-2' : 'bg-[#EBEBE4] border-[#E0E0E0]'}`}
            >
              <CircleDot className="w-7 h-7 mb-2 text-[rgba(20,20,20,0.6)]" />
              <span className="text-[13px] font-medium text-[rgba(20,20,20,0.6)]">Other</span>
            </motion.button>
          </div>
        </section>

        {/* Location */}
        <section>
          <div className="text-[10px] font-medium text-[rgba(20,20,20,0.6)] tracking-[0.07em] mb-3 uppercase">Your Location</div>
          {zoneId ? (
            <div className="bg-[#EFEFE8] border border-[rgba(20,20,20,0.15)] rounded-none p-3 flex items-start">
              <div className="w-2 h-2 rounded-full bg-[#475B49] mt-1 mr-2 shrink-0" />
              <div className="flex flex-col">
                <span className="text-[13px] font-medium text-[#141414]">{zoneName || zoneId}</span>
                <span className="text-[10px] text-[#475B49] mt-0.5">Scanned from QR code</span>
              </div>
            </div>
          ) : (
            <div className="bg-[#F2F2EC] rounded-none p-[14px] border border-solid border-[rgba(20,20,20,0.4)] flex flex-col items-center text-center">
              <QrCode className="w-8 h-8 text-[rgba(20,20,20,0.6)] mb-2" />
              <span className="text-[13px] font-medium text-[rgba(20,20,20,0.6)]">Scan the QR code at your location</span>
              <span className="text-[11px] text-[rgba(20,20,20,0.4)] mt-1 mb-4">QR codes are posted throughout the venue</span>
              
              <button onClick={() => setShowScanner(true)} className="px-5 py-2 rounded-none border border-[#5A5A40] text-[#5A5A40] font-medium text-sm mb-3">
                Scan QR Code
              </button>
              
              <button onClick={() => setShowZoneSelect(!showZoneSelect)} className="text-[rgba(20,20,20,0.6)] text-sm">
                Enter location manually
              </button>

              {showZoneSelect && (
                <select 
                  className="mt-3 w-full p-2 border border-[rgba(20,20,20,0.1)] rounded-none text-sm bg-[#F5F5F0] text-[#141414]"
                  onChange={(e) => {
                    const z = allZones.find(x => x.id === e.target.value);
                    if(z) { setZoneId(z.id); setZoneName(z.name); setFloor(z.floor); }
                  }}
                  defaultValue=""
                >
                  <option value="" disabled>Select a zone...</option>
                  {allZones.map(z => (
                    <option key={z.id} value={z.id}>{z.name} - {z.floor}</option>
                  ))}
                </select>
              )}
            </div>
          )}

          {showScanner && (
            <div className="fixed inset-0 z-50 bg-black flex flex-col">
              <div className="flex-1 relative">
                <Scanner onScan={(result) => handleQrScan(result[0].rawValue)} />
                <button onClick={() => setShowScanner(false)} className="absolute top-6 right-6 text-[#F5F5F0] bg-black/50 px-4 py-2 rounded-full font-medium z-50">Close</button>
              </div>
            </div>
          )}
        </section>

        {/* Photo */}
        <section>
          <div className="text-[10px] font-medium text-[rgba(20,20,20,0.6)] tracking-[0.07em] mb-3 uppercase">Add a Photo (Required)</div>
          
          <input type="file" accept="image/*" capture="environment" className="hidden" ref={fileInputRef} onChange={handlePhotoSelect} />
          
          {showCamera ? (
            <div className="fixed inset-0 z-50 bg-black flex flex-col justify-center">
              <CameraCapture onCapture={handleCameraCapture} onCancel={() => setShowCamera(false)} />
            </div>
          ) : !photoFile ? (
            <div className="flex gap-2">
              <button onClick={() => setShowCamera(true)} className="flex-1 bg-[#EFEFDF] border border-solid border-[rgba(20,20,20,0.4)] rounded-none p-5 flex flex-col items-center justify-center hover:bg-[#E8E8D8] transition-colors">
                <Camera className="w-8 h-8 text-[#475B49] mb-2" />
                <span className="text-[13px] text-[#475B49] font-medium">Take Photo Live</span>
                <span className="text-[11px] text-[rgba(20,20,20,0.4)] mt-1 text-center">Required for verification</span>
              </button>
              <button onClick={() => fileInputRef.current?.click()} className="flex-1 bg-white border border-dashed border-[rgba(20,20,20,0.3)] rounded-none p-5 flex flex-col items-center justify-center hover:bg-gray-50 transition-colors">
                <Triangle className="w-8 h-8 text-[rgba(20,20,20,0.4)] mb-2 rotate-180" />
                <span className="text-[13px] text-[rgba(20,20,20,0.6)] font-medium">Upload File</span>
                <span className="text-[11px] text-[rgba(20,20,20,0.4)] mt-1 text-center">If camera fails</span>
              </button>
            </div>
          ) : (
            <div>
              <img src={photoPreview || ''} alt="Preview" className="h-[100px] w-full object-cover rounded-none border border-[rgba(20,20,20,0.1)]" />
              <div className="flex justify-between items-center mt-3">
                <div className="flex items-center text-[#475B49]">
                  <Check className="w-4 h-4 mr-1" />
                  <span className="text-[11px] font-medium">Photo ready</span>
                </div>
                <button onClick={() => { setPhotoFile(null); setPhotoPreview(null); }} className="text-[#5A5A40] text-[11px] font-medium">
                  Remove
                </button>
              </div>
            </div>
          )}
        </section>

        {/* Note */}
        <section className="mb-4">
          <div className="text-[10px] font-medium text-[rgba(20,20,20,0.6)] tracking-[0.07em] mb-3 uppercase">Add a Note (Optional)</div>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            rows={3}
            placeholder="Describe what you see"
            className="w-full p-3 rounded-none border border-[rgba(20,20,20,0.1)] focus:border-[#5A5A40] focus:ring-1 focus:ring-[#5A5A40] outline-none resize-none text-[14px]"
          />
        </section>

        {/* Submit */}
        <div className="mt-auto pb-6">
          <button
            onClick={handleSubmit}
            disabled={!type || !photoFile || isSubmitting}
            className={`w-full h-[52px] rounded-none flex items-center justify-center font-medium text-[16px] font-serif tracking-tight transition-colors ${(!type || !photoFile || isSubmitting) ? 'bg-[#F0AEAE] text-[#F5F5F0]/80' : 'bg-[#5A5A40] text-[#F5F5F0]'}`}
          >
            {isSubmitting ? (
              <span>Uploading {uploadProgress}%</span>
            ) : (
              <>
                <Check className="w-5 h-5 mr-2" />
                Report Emergency
              </>
            )}
          </button>
          
          <div className="text-center mt-4">
            <span className="text-[11px] text-[rgba(20,20,20,0.6)]">Already staff? </span>
            <button onClick={() => router.push('/login')} className="text-[11px] text-[#5A5A40] font-medium ml-1">Sign in →</button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function ReportPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#F5F5F0]"></div>}>
      <ReportForm />
    </Suspense>
  );
}
