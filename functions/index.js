const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated, onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
admin.initializeApp();

// Helper: ek user ke liye in-app notification doc banao + FCM push bhejo
async function notifyUser(userId, title, body, type) {
  const db = admin.firestore();

  await db.collection("notifications").add({
    userId,
    title,
    body,
    type,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.data();
  const token = userData?.fcmToken;
  const pushEnabled = userData?.pushEnabled !== false; // default true
  if (token && pushEnabled) {
    try {
      await admin.messaging().send({
        token,
        notification: { title, body },
      });
    } catch (err) {
      console.error(`Push failed for user ${userId}:`, err.message);
    }
  }
}

async function getUserName(userId) {
  const db = admin.firestore();
  const doc = await db.collection("users").doc(userId).get();
  return doc.data()?.name || "Someone";
}

const MSG91_AUTHKEY = defineSecret("MSG91_AUTHKEY");
const TEST_PHONE_NUMBER = defineSecret("TEST_PHONE_NUMBER");
const TEST_PHONE_OTP = defineSecret("TEST_PHONE_OTP");
const BACKFILL_SECRET = defineSecret("BACKFILL_SECRET");

// ONE-TIME SCRIPT: purani listings (jo searchKeywords field ke bina bani thi)
// ko ek baar backfill karta hai. Deploy karke sirf ek baar
// `?secret=...` ke saath call karo, phir is function ko hata dena — hamesha
// ke liye deployed rehne ki zaroorat nahi hai.
exports.backfillSearchKeywords = onRequest(
  { secrets: [BACKFILL_SECRET] },
  async (req, res) => {
    if (req.query.secret !== BACKFILL_SECRET.value()) {
      res.status(403).send("Forbidden");
      return;
    }
    const db = admin.firestore();
    try {
      const snap = await db.collection("listings").get();
      const docs = snap.docs;
      let count = 0;
      for (let i = 0; i < docs.length; i += 500) {
        const chunk = docs.slice(i, i + 500);
        const batch = db.batch();
        chunk.forEach((doc) => {
          batch.update(doc.ref, {
            searchKeywords: generateSearchKeywords(doc.data()),
          });
          count++;
        });
        await batch.commit();
      }
      res.status(200).send(`Backfilled ${count} listings.`);
    } catch (error) {
      console.error("Backfill error:", error);
      res.status(500).send("Backfill failed, check logs.");
    }
  }
);

// NAYA: Request accept/reject hone par doosre party ko notify karo (in-app + push)
exports.onRequestStatusChanged = onDocumentUpdated("requests/{requestId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === after.status) return; // status nahi badla, ignore
  if (after.status !== "accepted" && after.status !== "rejected") return;

  // Recipient = jisne original request bheji thi (sender ko hi pata chalna chahiye)
  const recipientId = after.senderType === "tenant" ? after.tenantId : after.ownerId;
  const actorId = after.respondedBy;
  const actorName = actorId ? await getUserName(actorId) : "Someone";

  const title = after.status === "accepted" ? "Request Accepted! ✅" : "Request Rejected";
  const body = `Request ${after.status} by ${actorName}`;

  await notifyUser(recipientId, title, body, `request_${after.status}`);
});

// NAYA: Admin panel se broadcast bheja jaye (target: 'tenant' | 'owner' | 'both')
exports.onBroadcastCreated = onDocumentCreated("broadcasts/{broadcastId}", async (event) => {
  const data = event.data.data();
  const { title, body, target } = data;

  if (!title || !body || !["tenant", "owner", "both"].includes(target)) {
    console.error("Invalid broadcast data:", data);
    return;
  }

  const db = admin.firestore();
  let usersQuery = db.collection("users");

  if (target !== "both") {
    usersQuery = usersQuery.where("roles", "array-contains", target);
  }

  const usersSnap = await usersQuery.get();
  console.log(`Broadcasting to ${usersSnap.size} users (target: ${target})`);

  // FIX: Firestore batch max 500 ops leti hai — chunks mein karo (jaisa cleanupInactiveUsers mein hai)
  const docs = usersSnap.docs;
  const tokens = [];

  for (let i = 0; i < docs.length; i += 500) {
    const chunk = docs.slice(i, i + 500);
    const batch = db.batch();
    chunk.forEach((doc) => {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: doc.id,
        title,
        body,
        type: "broadcast",
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      const token = doc.data()?.fcmToken;
      if (token) tokens.push(token);
    });
    await batch.commit();
  }

  // FCM multicast bhi 500 tokens/batch tak limited hai
  for (let i = 0; i < tokens.length; i += 500) {
    const tokenChunk = tokens.slice(i, i + 500);
    try {
      await admin.messaging().sendEachForMulticast({
        tokens: tokenChunk,
        notification: { title, body },
      });
    } catch (err) {
      console.error("Broadcast push batch failed:", err.message);
    }
  }
});

// NAYA: Naya request aane par doosre party ko notify karo (in-app + push)
exports.onNewRequestCreated = onDocumentCreated("requests/{requestId}", async (event) => {
  const data = event.data.data();

  // Recipient = jisko request bheji gayi hai (sender nahi, doosri party)
  const recipientId = data.senderType === "tenant" ? data.ownerId : data.tenantId;
  const senderId = data.senderType === "tenant" ? data.tenantId : data.ownerId;
  const senderName = await getUserName(senderId);

  const title = "New Request! 🔔";
  const body = `${senderName} sent you a request for ${data.area}`;

  await notifyUser(recipientId, title, body, "new_request");
});

// App OTP verify karne ke baad MSG91 se mila hua access-token yahan bhejta hai.
// Yeh function authkey (secret) se MSG91 ke paas double-check karta hai ki
// token asli hai, phir Firebase custom token deta hai login ke liye.
exports.verifyMsg91Token = onRequest(
  { secrets: [MSG91_AUTHKEY, TEST_PHONE_NUMBER, TEST_PHONE_OTP], cors: true },
  async (req, res) => {
    try {
      // Google Play review ke liye reserved test-account bypass.
      // Sirf ye EXACT number+OTP combo match hone par MSG91 ko poori tarah skip karta hai.
      const testPhone = String(req.body?.testPhone || "").trim();
      const testOtp = String(req.body?.testOtp || "").trim();
      if (testPhone && testOtp) {
        if (
          testPhone === TEST_PHONE_NUMBER.value() &&
          testOtp === TEST_PHONE_OTP.value()
        ) {
          const phoneNumber = `+91${TEST_PHONE_NUMBER.value()}`;
          let userRecord;
          try {
            userRecord = await admin.auth().getUserByPhoneNumber(phoneNumber);
          } catch (e) {
            userRecord = await admin.auth().createUser({ phoneNumber });
          }
          const customToken = await admin.auth().createCustomToken(userRecord.uid);
          return res.json({
            success: true,
            uid: userRecord.uid,
            customToken,
            phone: TEST_PHONE_NUMBER.value(),
          });
        }
        // Test fields bheje the par match nahi hue — reject, MSG91 tak mat jane do
        return res.status(400).json({ success: false, error: "Invalid test credentials" });
      }

      const accessToken = String(req.body?.accessToken || "").trim();
      if (!accessToken) {
        return res.status(400).json({ success: false, error: "Missing access token" });
      }

      const msgRes = await fetch("https://control.msg91.com/api/v5/widget/verifyAccessToken", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          authkey: MSG91_AUTHKEY.value(),
          "access-token": accessToken,
        }),
      });
      const data = await msgRes.json();

      if (data.type !== "success") {
        return res.status(400).json({ success: false, error: data.message || "Invalid token" });
      }

      // Verified mobile number nikaalo (MSG91 ka response format: message ke andar hota hai)
      let mobile = data.message?.identifier || data.message?.mobile || data.message;
      mobile = String(mobile).replace(/\D/g, ""); // sirf digits
      if (mobile.length > 10) mobile = mobile.slice(-10); // country code hata do
      if (mobile.length !== 10) {
        return res.status(400).json({ success: false, error: "Could not read verified mobile number" });
      }

      const phoneNumber = `+91${mobile}`;
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByPhoneNumber(phoneNumber);
      } catch (e) {
        userRecord = await admin.auth().createUser({ phoneNumber });
      }

      const customToken = await admin.auth().createCustomToken(userRecord.uid);
      return res.json({ success: true, uid: userRecord.uid, customToken, phone: mobile });
    } catch (error) {
      console.error("verifyMsg91Token error:", error);
      return res.status(500).json({ success: false, error: "Verification failed" });
    }
  }
);

// App yahan hit karega OTP verify karne ke liye

// Har raat 12 baje chalega - 180 din purane inactive accounts ko delete karne ke liye (DPDP Act Compliance)
// NAYA: area/city/subArea/landmark/propertyCategory se search keywords banata
// hai (prefix-based, taaki "Gore" type karne par bhi "Goregaon" match ho).
// Residential aur Commercial dono listings ke liye same logic — propertyKind
// se koi farak nahi padta, isliye dono tabs automatically fix ho jaate hain.
function generateSearchKeywords(data) {
  const fields = [
    data.area, data.city, data.subArea, data.landmark, data.propertyCategory,
  ];
  const keywords = new Set();

  for (const field of fields) {
    if (!field || typeof field !== "string") continue;
    const words = field.toLowerCase().trim().split(/\s+/);
    for (const word of words) {
      if (!word) continue;
      // har word ke saare prefixes daalo (min 2 chars): "goregaon" -> go, gor, gore, ...
      for (let i = 2; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }
  }
  return Array.from(keywords);
}

// NAYA: Listing create/update hone par searchKeywords auto-sync karo. Client
// pe depend nahi karte — isliye kabhi out-of-sync nahi hoga. Infinite loop se
// bachne ke liye sirf tab update karte hain jab keywords actually badle hon.
exports.onListingSearchKeywordsSync = onDocumentWritten("listings/{listingId}", async (event) => {
  if (!event.data.after.exists) return; // listing delete hui, kuch mat karo

  const after = event.data.after.data();
  const newKeywords = generateSearchKeywords(after);
  const oldKeywords = after.searchKeywords || [];

  const sameKeywords =
    newKeywords.length === oldKeywords.length &&
    newKeywords.every((k) => oldKeywords.includes(k));

  if (sameKeywords) return; // pehle se sahi hai, dobara mat likho (loop guard)

  await event.data.after.ref.update({ searchKeywords: newKeywords });
});

exports.cleanupInactiveUsers = onSchedule("0 0 * * *", async (event) => {
    const db = admin.firestore();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 180); // 180 days ago

    try {
        // 1. Inactive profiles find karo
        const usersSnap = await db.collection('users')
            .where('updatedAt', '<', cutoffDate)
            .where('active', '==', true)
            .get();

        if (usersSnap.empty) {
            console.log('Koi inactive account nahi mila.');
            return;
        }

        // FIX: Firestore batch max 500 ops leti hai — 500 ke chunks mein commit karo
        const docs = usersSnap.docs;
        let count = 0;
        for (let i = 0; i < docs.length; i += 500) {
            const chunk = docs.slice(i, i + 500);
            const batch = db.batch();
            chunk.forEach((doc) => {
                batch.update(doc.ref, {
                    active: false,
                    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                    deletionReason: 'DPDP 180-day retention policy'
                });
                count++;
            });
            await batch.commit();
        }
        console.log(`Successfully cleaned up ${count} inactive accounts.`);
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
});