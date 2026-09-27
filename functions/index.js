const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// Fires whenever a payment document is updated. If its status just
// changed to "overdue", nudge that tenant immediately.
exports.sendPaymentReminder = onDocumentUpdated("payments/{paymentId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status !== "overdue" && after.status === "overdue") {
    const userDoc = await admin.firestore().collection("users").doc(after.tenantId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) return;

    await admin.messaging().send({
      token,
      notification: {
        title: "Rent Payment Overdue",
        body: `Your rent for ${after.monthYear} is overdue. Please make your payment.`,
      },
    });
  }
});

// Runs automatically at 8:00 AM on the 1st of every month (Kampala time).
// Reminds every tenant whose current-month payment isn't marked "paid".
exports.monthlyRentReminder = onSchedule(
  {
    schedule: "0 8 1 * *",
    timeZone: "Africa/Kampala",
  },
  async () => {
    const now = new Date();
    const monthYear = now.toLocaleString("en-US", { month: "long", year: "numeric" });
    // e.g. "September 2026" — must match how monthYear is generated elsewhere in the app

    const db = admin.firestore();
    const unpaidSnapshot = await db
      .collection("payments")
      .where("monthYear", "==", monthYear)
      .where("status", "!=", "paid")
      .get();

    const sends = unpaidSnapshot.docs.map(async (doc) => {
      const payment = doc.data();
      const userDoc = await db.collection("users").doc(payment.tenantId).get();
      const token = userDoc.data()?.fcmToken;
      if (!token) return;

      return admin.messaging().send({
        token,
        notification: {
          title: "Rent Due",
          body: `Your rent for ${monthYear} is due. Please make your payment.`,
        },
      });
    });

    await Promise.all(sends);
    console.log(`Sent ${sends.length} rent reminders for ${monthYear}`);
  }
);