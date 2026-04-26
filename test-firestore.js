const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, getDoc } = require('firebase/firestore');
const { signInWithEmailAndPassword, getAuth } = require('firebase/auth');
const config = require('./firebase-applet-config.json');

const app = initializeApp(config);
const db = getFirestore(app, config.firestoreDatabaseId);
const auth = getAuth(app);

async function test() {
  try {
    const cred = await signInWithEmailAndPassword(auth, 'priya@theoberoi.com', 'CrisisFlow@2024');
    console.log("Logged in:", cred.user.uid);
    const snap = await getDocs(collection(db, 'zones'));
    console.log("Zones read successful:", snap.size);
    const incidents = await getDocs(collection(db, 'incidents'));
    console.log("Incidents read successful:", incidents.size);
  } catch(e) {
    console.error("Test failed:", e.code, e.message);
  }
}
test();