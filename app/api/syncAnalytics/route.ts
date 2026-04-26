import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';

export async function POST(req: NextRequest) {
  try {
    const { incidentId } = await req.json();
    if (!incidentId) return NextResponse.json({ error: 'Missing incidentId' }, { status: 400 });

    const incRef = adminDb.collection('incidents').doc(incidentId);
    const incSnap = await incRef.get();
    if (!incSnap.exists) return NextResponse.json({ error: 'Incident not found' }, { status: 404 });

    const inc = incSnap.data()!;
    
    // Calculate response time
    if (inc.resolvedAt && inc.timestamp) {
       const ms = inc.resolvedAt.toMillis() - inc.timestamp.toMillis();
       await incRef.update({ responseTimeMs: ms });
    }

    // A real analytics engine would use a transaction and FieldValue.increment
    // We update analytics locally for demo ease
    
    return NextResponse.json({ success: true });
  } catch(error: any) {
    console.error(error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
