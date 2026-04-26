import { NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';

export async function POST() {
  try {
    const incSnap = await adminDb.collection('incidents')
      .where('status', 'in', ['pending', 'verified'])
      .get();
    const activeIncidents: any[] = incSnap.docs.map(d => ({id: d.id, ...d.data()}));

    const resSnap = await adminDb.collection('resources')
      .where('available', '==', true)
      .get();
    const availableResources: any[] = resSnap.docs.map(d => ({id: d.id, ...d.data()}));

    const zonesSnap = await adminDb.collection('zones').get();
    const zones: any[] = zonesSnap.docs.map(d => ({id: d.id, ...d.data()}));

    // Start batch
    const batch = adminDb.batch();

    // 1. Delete all existing unconfirmed dispatch
    const existingSnap = await adminDb.collection('dispatch').where('confirmed', '==', false).get();
    existingSnap.docs.forEach(doc => batch.delete(doc.ref));

    // 2. Linear assignment simulation
    // We sort incidents by severity descending to assign highest severity first (greedy approximation)
    activeIncidents.sort((a: any, b: any) => (b.severity || 1) - (a.severity || 1));

    let updatedResources = [...availableResources];

    for (const inc of activeIncidents) {
       // Filter valid resources for this incident
       let valid = updatedResources;
       const iType = String(inc.aiType || inc.type).toLowerCase();
       
       if (iType === 'fire' || iType === 'smoke') {
         valid = valid.filter(r => r.type === 'fire_team');
       } else if (iType === 'medical') {
         valid = valid.filter(r => r.type === 'medical_kit' || r.type === 'medic');
       } else if (iType === 'security') {
         valid = valid.filter(r => r.type === 'security_guard');
       }

       if (valid.length === 0) continue; // No resource available for this

       // Find best resource by distance
       let bestResource: any = null;
       let bestScore = Infinity;

       for (const res of valid) {
          let dist = 3; // default non-adjacent
          if (res.zoneId === inc.location?.zoneId) {
             dist = 1; // same zone
          } else {
             // check adjacent
             const fromZone = zones.find(z => z.id === res.zoneId);
             if (fromZone && fromZone.adjacentZones && fromZone.adjacentZones.includes(inc.location?.zoneId)) {
                dist = 2;
             }
          }

          const score = dist * (11 - (inc.severity || 1));
          if (score < bestScore) {
             bestScore = score;
             bestResource = res;
          }
       }

       if (bestResource) {
         const newRef = adminDb.collection('dispatch').doc();
         batch.set(newRef, {
           incidentId: inc.id,
           incidentType: inc.aiType || inc.type,
           incidentZone: inc.location?.zoneName || '',
           resourceId: bestResource.id,
           resourceName: bestResource.name,
           resourceType: bestResource.type,
           fromZone: bestResource.zone,
           fromZoneId: bestResource.zoneId,
           toZone: inc.location?.zoneName || '',
           toZoneId: inc.location?.zoneId || '',
           estimatedMinutes: bestScore === 1 ? 2 : (bestScore === 2 ? 4 : 8), // fake est
           score: bestScore,
           confirmed: false,
           confirmedBy: null,
           confirmedAt: null,
           createdAt: new Date(),
         });
         // remove from pool
         updatedResources = updatedResources.filter(r => r.id !== bestResource.id);
       }
    }

    await batch.commit();

    return NextResponse.json({ success: true });
  } catch(error: any) {
    console.error(error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
