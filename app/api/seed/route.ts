import { NextResponse } from 'next/server';
import { adminDb, adminAuth } from '@/lib/firebase-admin';

export async function GET() {
  try {
    const users = [
      { email: 'rahul@theoberoi.com', pass: 'CrisisFlow@2024', name: 'Rahul Sharma', role: 'staff', venue: 'The Oberoi Mumbai' },
      { email: 'priya@theoberoi.com', pass: 'CrisisFlow@2024', name: 'Priya Mehta', role: 'manager', venue: 'The Oberoi Mumbai' },
      { email: 'suresh@theoberoi.com', pass: 'CrisisFlow@2024', name: 'Suresh Kumar', role: 'staff', venue: 'The Oberoi Mumbai' }
    ];

    for (const u of users) {
      let uid;
      try {
        const userRec = await adminAuth.getUserByEmail(u.email);
        uid = userRec.uid;
      } catch(e) {
        const userRec = await adminAuth.createUser({ email: u.email, password: u.pass, displayName: u.name });
        uid = userRec.uid;
      }
      await adminDb.collection('users').doc(uid).set({
        name: u.name, email: u.email, role: u.role, venue: u.venue, fcmToken: null, fcmTokenUpdatedAt: null, createdAt: new Date()
      }, { merge: true });
    }

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
       await adminDb.collection('zones').doc(z.id).set({
         name: z.name, floor: z.floor, section: z.section, shortName: z.shortName, adjacentZones: z.adjacent, createdAt: new Date(), createdBy: 'seed',
         qrData: `https://${process.env.NEXT_PUBLIC_APP_URL || process.env.APP_URL || 'crisisflow.web.app'}/report?zone=${z.id}&name=${encodeURIComponent(z.name)}&floor=${encodeURIComponent(z.floor)}`
       });
    }

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
      // Find exact doc name if we want, or just addDoc
      const snapshot = await adminDb.collection('resources').where('name','==',r.name).get();
      if (snapshot.empty) {
        await adminDb.collection('resources').add({
           ...r, available: true, currentIncidentId: null, lastUpdated: new Date(), createdAt: new Date(), createdBy: 'seed'
        });
      }
    }

    return NextResponse.json({ success: true, message: 'Seeded successfully' });
  } catch(error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
