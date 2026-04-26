import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const adminDb = admin.firestore();
const adminAuth = admin.auth();

async function seed() {
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
      console.log('Seeded user:', u.email, uid);
    }
  } catch(e) {
    console.error('Error:', e);
  }
}
seed();