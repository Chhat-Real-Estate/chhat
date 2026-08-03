const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
admin.initializeApp();

const MSG91_AUTHKEY = defineSecret("MSG91_AUTHKEY");

// App OTP verify karne ke baad MSG91 se mila hua access-token yahan bhejta hai.
// Yeh function authkey (secret) se MSG91 ke paas double-check karta hai ki
// token asli hai, phir Firebase custom token deta hai login ke liye.
exports.verifyMsg91Token = onRequest(
  { secrets: [MSG91_AUTHKEY], cors: true },
  async (req, res) => {
    try {
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