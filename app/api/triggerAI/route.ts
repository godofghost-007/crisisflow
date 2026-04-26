import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenAI } from '@google/genai';
import { adminDb } from '@/lib/firebase-admin';

export async function POST(req: NextRequest) {
  try {
    const { incidentId, photoURL } = await req.json();
    
    if (!incidentId) return NextResponse.json({ error: 'Missing incidentId' }, { status: 400 });

    const ai = new GoogleGenAI({ apiKey: process.env.NEXT_PUBLIC_GEMINI_API_KEY });
    let mimeType = 'image/jpeg';
    let dataContents = '';

    if (photoURL) {
      if (photoURL.startsWith('data:')) {
        const parts = photoURL.split(',');
        const match = parts[0].match(/:(.*?);/);
        mimeType = match && match[1] ? match[1] : 'image/jpeg';
        dataContents = parts[1];
      } else {
        // Download image to buffer
        const res = await fetch(photoURL);
        const arrayBuffer = await res.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        dataContents = buffer.toString('base64');
        mimeType = res.headers.get('content-type') || 'image/jpeg';
      }
    } else {
      // If no photo, standard none response
      await adminDb.collection('incidents').doc(incidentId).update({
        status: 'dismissed',
        aiType: 'none',
        severity: 1,
        confidence: 'low',
        aiDescription: 'No photo provided',
        processedAt: new Date()
      });
      return NextResponse.json({ success: true, fake: true });
    }

    const prompt = `You are an emergency incident classifier. Return ONLY a valid JSON object with no markdown fences, no explanation, no extra text. The JSON must have exactly these fields: "type" (one of: fire, smoke, medical, security, none), "severity" (integer 1-10), "confidence" (low, medium, high), "description" (one sentence, max 20 words). If unclear or no emergency, return type none, severity 1, confidence low.`;

    const response = await ai.models.generateContent({
      model: 'gemini-1.5-flash',
      contents: [
        { role: 'user', parts: [
            { text: prompt }, 
            { inlineData: { mimeType, data: dataContents } }
          ] 
        }
      ]
    });

    let text = response.text || '';
    text = text.replace(/```json/g, '').replace(/```/g, '').trim();
    
    let parsed: any;
    try {
      parsed = JSON.parse(text);
    } catch(e) {
      parsed = { type: 'none', severity: 1, confidence: 'low', description: 'AI processing error' };
    }

    // Validate
    const validTypes = ['fire', 'smoke', 'medical', 'security', 'none'];
    if (!validTypes.includes(parsed.type)) parsed.type = 'none';
    
    const dbStatus = parsed.type === 'none' ? 'dismissed' : 'verified';

    await adminDb.collection('incidents').doc(incidentId).update({
      status: dbStatus,
      aiType: parsed.type,
      severity: parsed.severity || 1,
      confidence: parsed.confidence || 'low',
      aiDescription: parsed.description || 'Verified by AI',
      photoURL: photoURL, // Store base64 so UI can show it
      processedAt: new Date()
    });

    // We can also run the optimizer asynchronously if it's verified!
    // Simply firing a fetch without awaiting avoids blocking.
    if (dbStatus === 'verified') {
       const baseUrl = req.nextUrl.origin || 'http://localhost:3000';
       fetch(`${baseUrl}/api/runOptimizer`, { method: 'POST' }).catch(console.error);
    }

    return NextResponse.json({ success: true, parsed });
  } catch (error: any) {
    console.error(error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
