'use client';
import { useState, useRef, useEffect, useCallback } from 'react';
import { Camera, X, RefreshCcw } from 'lucide-react';

export function CameraCapture({ onCapture, onCancel }: { onCapture: (dataUrl: string) => void, onCancel?: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [error, setError] = useState<string>('');
  const [facingMode, setFacingMode] = useState<'environment' | 'user'>('environment');

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
  }, []);

  const startCamera = useCallback(async () => {
    stopCamera();
    try {
      const newStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode }
      });
      streamRef.current = newStream;
      if (videoRef.current) {
        videoRef.current.srcObject = newStream;
      }
    } catch (err: any) {
      console.error('Camera error:', err);
      setError('Could not access camera. Please allow permissions or use upload instead.');
    }
  }, [facingMode, stopCamera]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    startCamera();
    return () => {
      stopCamera();
    };
  }, [startCamera, stopCamera]);

  const switchCamera = () => {
    setFacingMode(prev => prev === 'environment' ? 'user' : 'environment');
  };

  const capturePhoto = () => {
    if (videoRef.current && canvasRef.current) {
      const video = videoRef.current;
      const canvas = canvasRef.current;
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
        stopCamera();
        onCapture(dataUrl);
      }
    }
  };

  return (
    <div className="flex flex-col bg-black rounded overflow-hidden relative">
      {error ? (
        <div className="p-4 text-white text-sm text-center">
          <p className="mb-4">{error}</p>
          {onCancel && (
            <button onClick={onCancel} className="bg-white/20 px-4 py-2 rounded">Close</button>
          )}
        </div>
      ) : (
        <>
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className="w-full h-auto max-h-[60vh] object-cover bg-gray-900"
          />
          <canvas ref={canvasRef} className="hidden" />
          
          <div className="absolute top-4 right-4 flex gap-2">
            <button
              onClick={switchCamera}
              className="bg-black/50 p-2 rounded-full text-white hover:bg-black/70 transition-colors"
            >
              <RefreshCcw className="w-5 h-5" />
            </button>
            {onCancel && (
              <button
                onClick={onCancel}
                className="bg-black/50 p-2 rounded-full text-white hover:bg-black/70 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            )}
          </div>
          
          <div className="p-4 flex justify-center pb-6">
            <button
              onClick={capturePhoto}
              className="w-16 h-16 rounded-full border-4 border-white bg-white/20 flex items-center justify-center hover:bg-white/40 transition-colors"
            >
              <div className="w-12 h-12 rounded-full bg-white" />
            </button>
          </div>
        </>
      )}
    </div>
  );
}
