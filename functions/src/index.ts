import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const REGION = "asia-south1";
const ANDROID_CHANNEL = "tester_mandi_high";

// ── Shared helpers ────────────────────────────────────────────────────────────

async function getFcmToken(userId: string): Promise<string | null> {
  if (!userId) return null;
  try {
    const doc = await db.collection("users").doc(userId).get();
    return (doc.data()?.fcmToken as string | undefined) ?? null;
  } catch {
    return null;
  }
}

async function removeStaleToken(userId: string): Promise<void> {
  if (!userId) return;
  try {
    await db.collection("users").doc(userId).update({ fcmToken: FieldValue.delete() });
    logger.info("[FCM] Stale token removed", { uid: userId });
  } catch (err) {
    logger.warn("[FCM] Could not remove stale token", { uid: userId, err });
  }
}

const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
]);

async function sendPush(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  const token = await getFcmToken(userId);
  if (!token) {
    logger.info("[FCM] No token for user — skipping push", { userId });
    return;
  }
  try {
    const messageId = await messaging.send({
      token,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: {
          channelId: ANDROID_CHANNEL,
          sound: "default",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: { aps: { sound: "default", badge: 1, "content-available": 1 } },
      },
    });
    logger.info("[FCM] Push sent", { userId, messageId, type: data.type });
  } catch (err: unknown) {
    const code = (err as { errorInfo?: { code?: string } })?.errorInfo?.code ?? "";
    if (INVALID_TOKEN_CODES.has(code)) {
      await removeStaleToken(userId);
    } else {
      logger.error("[FCM] Push failed", { userId, code, err });
    }
  }
}

async function sendTopicPush(
  topic: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  try {
    await messaging.send({
      topic,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: {
          channelId: ANDROID_CHANNEL,
          sound: "default",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: { aps: { sound: "default", badge: 1, "content-available": 1 } },
      },
    });
  } catch (err) {
    logger.error("[FCM] Topic push failed", { topic, err });
  }
}

// Uses a caller-supplied deterministic `notifId` so that if the Cloud Function
// retries (at-least-once delivery), the second write is a no-op merge rather
// than creating a duplicate document.
async function writeNotification(params: {
  notifId: string;
  recipientId: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, string>;
}): Promise<void> {
  await db.collection("notifications").doc(params.notifId).set(
    {
      recipientId: params.recipientId,
      title: params.title,
      body: params.body,
      type: params.type,
      data: params.data ?? {},
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

// ── Proof submitted ───────────────────────────────────────────────────────────
// Triggers when a tester submits a new proof document.
// Notifies the app owner to review it.

export const onProofCreated = onDocumentCreated(
  { document: "proofs/{proofId}", region: REGION },
  async (event) => {
    const proof = event.data?.data();
    if (!proof) return;

    const { participationId, appName, dayNumber, testerId } = proof as {
      participationId: string;
      appName: string;
      dayNumber: number;
      testerId: string;
    };

    if (!participationId || !appName || !testerId) {
      logger.warn("[onProofCreated] Missing fields", { proofId: event.params.proofId });
      return;
    }

    // Look up participation to get appOwnerId and testerName
    const partDoc = await db.collection("participations").doc(participationId).get();
    const part = partDoc.data();
    if (!part) {
      logger.warn("[onProofCreated] Participation not found", { participationId });
      return;
    }

    const appOwnerId = part.appOwnerId as string;
    const testerName = part.testerName as string;

    if (!appOwnerId) return;

    const title = "📸 New proof submitted!";
    const body = `${testerName} submitted their Day ${dayNumber} proof for "${appName}" — tap to review.`;
    const data: Record<string, string> = {
      type: "proof_submitted",
      participationId,
      appName,
      testerName,
      dayNumber: `${dayNumber}`,
    };

    const notifId = `proof_submitted_${event.params.proofId}`;
    // Include recipientId + notifId in data so the Flutter FCM receiver can
    // persist the notification idempotently even if Firestore write arrives late.
    const pushData = { ...data, recipientId: appOwnerId, notifId };
    await Promise.all([
      writeNotification({ notifId, recipientId: appOwnerId, title, body, type: "proof_submitted", data }),
      sendPush(appOwnerId, title, body, pushData),
      // Increment proof count on participation so the expiry processor
      // can determine completion tier without re-querying all proofs.
      db.collection("participations").doc(participationId).update({
        proofsSubmitted: FieldValue.increment(1),
        lastProofAt: FieldValue.serverTimestamp(),
      }),
    ]);

    logger.info("[onProofCreated] Notified owner", { appOwnerId, participationId });
  }
);

// ── Proof reviewed (approved / rejected) ─────────────────────────────────────
// Triggers when proof status changes. Notifies the tester.

export const onProofReviewed = onDocumentUpdated(
  { document: "proofs/{proofId}", region: REGION },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevStatus = before.status as string | undefined;
    const newStatus = after.status as string | undefined;

    // Only act when status changes to approved or rejected for the first time
    if (prevStatus === newStatus) return;
    if (newStatus !== "approved" && newStatus !== "rejected") return;

    const { testerId, appName, dayNumber } = after as {
      testerId: string;
      appName: string;
      dayNumber: number;
    };

    if (!testerId || !appName) return;

    const approved = newStatus === "approved";
    const title = approved ? "✅ Proof approved!" : "❌ Proof not accepted";
    const body = approved
      ? `Your Day ${dayNumber} proof for "${appName}" has been approved!`
      : `Your Day ${dayNumber} proof for "${appName}" was rejected. You may resubmit.`;
    const type = approved ? "proof_approved" : "proof_rejected";
    const data: Record<string, string> = { type, appName, dayNumber: `${dayNumber}` };

    const notifId = `proof_${newStatus}_${event.params.proofId}`;
    const pushData = { ...data, recipientId: testerId, notifId };
    await Promise.all([
      writeNotification({ notifId, recipientId: testerId, title, body, type, data }),
      sendPush(testerId, title, body, pushData),
    ]);

    logger.info("[onProofReviewed] Notified tester", { testerId, newStatus });
  }
);

// ── Swap request sent ─────────────────────────────────────────────────────────
// Triggers when a new swap request is created. Notifies the receiving user.

export const onSwapRequested = onDocumentCreated(
  { document: "swap_requests/{requestId}", region: REGION },
  async (event) => {
    const request = event.data?.data();
    if (!request) return;

    const { fromUserName, fromAppName, toUserId, toAppName, fromUserId } = request as {
      fromUserName: string;
      fromAppName: string;
      toUserId: string;
      toAppName: string;
      fromUserId: string;
    };

    if (!toUserId || !fromUserName) return;

    const requestId = event.params.requestId;
    const title = `${fromUserName} wants to swap!`;
    const body = `They want to test ${toAppName} in exchange for ${fromAppName}.`;
    const data: Record<string, string> = {
      type: "swap_request",
      swapRequestId: requestId,
      fromUserId,
    };

    const notifId = `swap_request_${requestId}`;
    const pushData = { ...data, recipientId: toUserId, notifId };
    await Promise.all([
      writeNotification({ notifId, recipientId: toUserId, title, body, type: "swap_request", data }),
      sendPush(toUserId, title, body, pushData),
    ]);

    logger.info("[onSwapRequested] Notified receiver", { toUserId, requestId });
  }
);

// ── Swap accepted / denied ────────────────────────────────────────────────────
// Triggers when swap request status changes. Notifies the original requester.

export const onSwapStatusChanged = onDocumentUpdated(
  { document: "swap_requests/{requestId}", region: REGION },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevStatus = before.status as string | undefined;
    const newStatus = after.status as string | undefined;

    if (prevStatus === newStatus) return;
    if (newStatus !== "accepted" && newStatus !== "denied") return;

    const { fromUserId, toUserId, toAppName } = after as {
      fromUserId: string;
      toUserId: string;
      toAppName: string;
    };

    const requestId = event.params.requestId;

    if (newStatus === "accepted") {
      // Get the accepting user's display name
      const toUserDoc = await db.collection("users").doc(toUserId).get();
      const toUserName =
        (toUserDoc.data()?.displayName as string | undefined) ?? "The owner";

      const title = "Swap Accepted! 🎉";
      const body = `${toUserName} accepted your swap request for ${toAppName}.`;
      const data: Record<string, string> = { type: "swap_accepted", swapRequestId: requestId };
      const acceptedNotifId = `swap_accepted_${requestId}`;

      await Promise.all([
        writeNotification({ notifId: acceptedNotifId, recipientId: fromUserId, title, body, type: "swap_accepted", data }),
        sendPush(fromUserId, title, body, { ...data, recipientId: fromUserId, notifId: acceptedNotifId }),
      ]);

      logger.info("[onSwapStatusChanged] Notified requester (accepted)", { fromUserId, requestId });
    } else {
      const title = "Swap Request Declined";
      const body = `Your swap request for ${toAppName} was not accepted.`;
      const data: Record<string, string> = { type: "swap_denied", swapRequestId: requestId };
      const deniedNotifId = `swap_denied_${requestId}`;

      await Promise.all([
        writeNotification({ notifId: deniedNotifId, recipientId: fromUserId, title, body, type: "swap_denied", data }),
        sendPush(fromUserId, title, body, { ...data, recipientId: fromUserId, notifId: deniedNotifId }),
      ]);

      logger.info("[onSwapStatusChanged] Notified requester (denied)", { fromUserId, requestId });
    }
  }
);

// ── Testing window expiry (daily at midnight IST) ────────────────────────────
// Runs daily and auto-deactivates participations that have passed the 14-day
// window. Sets status='deactivated' + deactivatedAt + completionTier and
// notifies both the tester (with a Reactivate prompt) and the app owner.

export const processTestingWindowExpiry = onSchedule(
  { schedule: "0 0 * * *", timeZone: "Asia/Kolkata", region: REGION },
  async () => {
    const now = new Date();
    // Deactivate after exactly 14 days have passed.
    const expiryThreshold = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

    // Query only active participations — filter joinedAt client-side to avoid
    // requiring a composite Firestore index.
    const snap = await db.collection("participations")
      .where("status", "==", "active")
      .get();

    if (snap.empty) {
      logger.info("[Expiry] No active participations found");
      return;
    }

    let processed = 0;

    for (const doc of snap.docs) {
      const part = doc.data();
      const joinedAt = (part.joinedAt as Timestamp | undefined)?.toDate();
      if (!joinedAt || joinedAt > expiryThreshold) continue; // still within window

      const proofsSubmitted = (part.proofsSubmitted as number | undefined) ?? 0;
      const testerId = part.testerId as string;
      const appOwnerId = part.appOwnerId as string;
      const appName = (part.appName as string | undefined) ?? "your app";
      const testerName = (part.testerName as string | undefined) ?? "Tester";

      // Determine completion tier based on proof count (for record-keeping).
      let completionTier: string;
      if (proofsSubmitted >= 12) {
        completionTier = "completed";
      } else if (proofsSubmitted >= 7) {
        completionTier = "partial";
      } else if (proofsSubmitted >= 1) {
        completionTier = "abandoned";
      } else {
        completionTier = "no_show";
      }

      await doc.ref.update({
        status: "deactivated",
        completionTier,
        deactivatedAt: FieldValue.serverTimestamp(),
      });

      const daysLabel = `${proofsSubmitted}/14`;
      const notifId = `deactivated_${doc.id}`;
      const testerTitle = "Testing window ended ⏸";
      const testerBody = proofsSubmitted === 0
        ? `Your 14-day window for testing "${appName}" ended with no proofs. Tap to reactivate and get another 14 days!`
        : `Your 14-day window for testing "${appName}" ended — ${daysLabel} proofs submitted. Tap to reactivate!`;

      await Promise.all([
        writeNotification({
          notifId,
          recipientId: testerId,
          title: testerTitle,
          body: testerBody,
          type: "testing_deactivated",
          data: { participationId: doc.id, appName, completionTier },
        }),
        sendPush(testerId, testerTitle, testerBody, {
          type: "testing_deactivated",
          participationId: doc.id,
          recipientId: testerId,
          notifId,
        }),
        writeNotification({
          notifId: `owner_${notifId}`,
          recipientId: appOwnerId,
          title: "Tester window ended",
          body: `${testerName}'s testing of "${appName}" ended — ${daysLabel} proofs. They can reactivate for another round.`,
          type: "tester_deactivated",
          data: { participationId: doc.id, appName, testerName, completionTier },
        }),
        sendPush(
          appOwnerId,
          "Tester window ended",
          `${testerName} submitted ${daysLabel} proofs for "${appName}". They can reactivate to continue.`,
          { type: "tester_deactivated", participationId: doc.id, recipientId: appOwnerId, notifId: `owner_${notifId}` }
        ),
      ]);

      processed++;
      logger.info("[Expiry] Deactivated", { participationId: doc.id, completionTier, proofsSubmitted });
    }

    logger.info(`[Expiry] Done — ${processed} participation(s) deactivated`);
  }
);

// ── Participation cleanup (daily at midnight IST) ─────────────────────────────
// Runs daily. Any participation that has been 'deactivated' for 14+ days
// without reactivation is permanently deleted along with its proofs and the
// linked swap request. The tester must send a new swap request to test again.

export const processParticipationCleanup = onSchedule(
  { schedule: "5 0 * * *", timeZone: "Asia/Kolkata", region: REGION },
  async () => {
    const now = new Date();
    const cleanupThreshold = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

    const snap = await db.collection("participations")
      .where("status", "==", "deactivated")
      .get();

    if (snap.empty) {
      logger.info("[Cleanup] No deactivated participations found");
      return;
    }

    let processed = 0;

    for (const doc of snap.docs) {
      const part = doc.data();
      const deactivatedAt = (part.deactivatedAt as Timestamp | undefined)?.toDate();
      if (!deactivatedAt || deactivatedAt > cleanupThreshold) continue;

      const testerId = part.testerId as string;
      const appId = part.appId as string;
      const appOwnerId = part.appOwnerId as string;
      const appName = (part.appName as string | undefined) ?? "your app";
      const testerName = (part.testerName as string | undefined) ?? "Tester";

      // 1. Find proofs for this participation
      const proofsSnap = await db.collection("proofs")
        .where("participationId", "==", doc.id)
        .get();

      // 2. Find the accepted swap request linking this tester to this app.
      //    Try both orientations of the swap (fromUserId/toAppId first, then
      //    toUserId/fromAppId) because either side could have been the requester.
      let swapSnap = await db.collection("swap_requests")
        .where("fromUserId", "==", testerId)
        .where("toAppId", "==", appId)
        .where("status", "==", "accepted")
        .get();

      if (swapSnap.empty) {
        swapSnap = await db.collection("swap_requests")
          .where("toUserId", "==", testerId)
          .where("fromAppId", "==", appId)
          .where("status", "==", "accepted")
          .get();
      }

      // 3. Batch-delete everything
      const batch = db.batch();

      // Remove tester from app's testerIds array
      if (appId) {
        batch.update(db.collection("apps").doc(appId), {
          testerIds: FieldValue.arrayRemove(testerId),
        });
      }

      // Delete proofs
      proofsSnap.docs.forEach((pDoc) => batch.delete(pDoc.ref));

      // Delete the swap request(s)
      swapSnap.docs.forEach((sDoc) => batch.delete(sDoc.ref));

      // Delete the participation itself
      batch.delete(doc.ref);

      await batch.commit();

      // 4. Notify tester and app owner
      const testerNotifId = `cleanup_tester_${doc.id}`;
      const ownerNotifId = `cleanup_owner_${doc.id}`;

      await Promise.all([
        writeNotification({
          notifId: testerNotifId,
          recipientId: testerId,
          title: "Testing data removed",
          body: `Your testing data for "${appName}" was deleted after 14 days inactive. Send a new swap request to test again!`,
          type: "participation_cleaned",
          data: { appId, appName },
        }),
        sendPush(
          testerId,
          "Testing data removed",
          `Your testing data for "${appName}" was deleted after 14 days inactive. Send a new swap request to test again!`,
          { type: "participation_cleaned", appId, appName, recipientId: testerId, notifId: testerNotifId }
        ),
        writeNotification({
          notifId: ownerNotifId,
          recipientId: appOwnerId,
          title: "Tester data removed",
          body: `${testerName}'s inactive testing data for "${appName}" was automatically deleted.`,
          type: "tester_cleaned",
          data: { appId, appName, testerName },
        }),
        sendPush(
          appOwnerId,
          "Tester data removed",
          `${testerName}'s inactive testing data for "${appName}" was automatically deleted.`,
          { type: "tester_cleaned", appId, appName, testerName, recipientId: appOwnerId, notifId: ownerNotifId }
        ),
      ]);

      processed++;
      logger.info("[Cleanup] Deleted participation", { participationId: doc.id, testerId, appId });
    }

    logger.info(`[Cleanup] Done — ${processed} participation(s) deleted`);
  }
);

// ── Testing window reminders (daily at 8am IST) ───────────────────────────────
// Sends nudge notifications at key milestones (day 7, 11, 13) when the tester
// hasn't submitted enough proofs, so they don't silently abandon testing.

export const sendTestingWindowReminders = onSchedule(
  { schedule: "0 8 * * *", timeZone: "Asia/Kolkata", region: REGION },
  async () => {
    const now = new Date();

    const snap = await db.collection("participations")
      .where("status", "==", "active")
      .get();

    if (snap.empty) return;

    let sent = 0;

    for (const doc of snap.docs) {
      const part = doc.data();
      const joinedAt = (part.joinedAt as Timestamp | undefined)?.toDate();
      if (!joinedAt) continue;

      const daysDiff = Math.floor((now.getTime() - joinedAt.getTime()) / (24 * 60 * 60 * 1000));
      const currentDay = daysDiff + 1;
      const proofsSubmitted = (part.proofsSubmitted as number | undefined) ?? 0;
      const testerId = part.testerId as string;
      const appName = (part.appName as string | undefined) ?? "your app";
      const participationId = doc.id;

      let notifId: string | null = null;
      let title = "";
      let body = "";

      if (currentDay === 7 && proofsSubmitted < 3) {
        notifId = `reminder_day7_${participationId}`;
        title = "Halfway there — keep going! 💪";
        body = `Day 7 of 14 for "${appName}" — you've submitted ${proofsSubmitted} proof${proofsSubmitted === 1 ? "" : "s"} so far. Don't give up!`;
      } else if (currentDay === 11 && proofsSubmitted < 6) {
        notifId = `reminder_day11_${participationId}`;
        title = "3 days left — submit now! ⚠️";
        body = `Only 3 days left to test "${appName}". You've submitted ${proofsSubmitted}/14 proofs — push through!`;
      } else if (currentDay === 13 && proofsSubmitted < 10) {
        notifId = `reminder_day13_${participationId}`;
        title = "Final day tomorrow! 🚨";
        body = `Last chance to submit proofs for "${appName}" — ${proofsSubmitted}/14 submitted. One more day!`;
      }

      if (!notifId) continue;

      await Promise.all([
        writeNotification({
          notifId,
          recipientId: testerId,
          title,
          body,
          type: "testing_reminder",
          data: { participationId, appName, currentDay: `${currentDay}`, proofsSubmitted: `${proofsSubmitted}` },
        }),
        sendPush(testerId, title, body, {
          type: "testing_reminder",
          participationId,
          recipientId: testerId,
          notifId,
        }),
      ]);

      sent++;
      logger.info("[Reminders] Sent", { participationId, currentDay, proofsSubmitted, notifId });
    }

    logger.info(`[Reminders] Done — ${sent} reminder(s) sent`);
  }
);

// ── notification_requests queue (kept for legacy / broadcast use) ─────────────
// Handles any remaining notification_requests documents written by the app
// (e.g. topic broadcasts for new apps). Individual notifications are now
// handled by the Firestore triggers above.

interface NotificationRequest {
  targetToken?: string;
  topic?: string;
  recipientId?: string;
  title?: string;
  body?: string;
  type?: string;
  data?: Record<string, string>;
}

export const processNotificationRequest = onDocumentCreated(
  { document: "notification_requests/{docId}", region: REGION, retry: false, maxInstances: 10 },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const {
      targetToken,
      topic,
      recipientId = "",
      title,
      body,
      type = "general",
      data = {},
    } = snap.data() as NotificationRequest;

    if (!title || !body) {
      logger.warn("[notification_requests] Missing title/body", { id: snap.id });
      await snap.ref.delete();
      return;
    }

    try {
      if (topic) {
        await sendTopicPush(topic, title, body, { type, ...data });
        logger.info("[notification_requests] Topic sent", { topic, type });
      } else if (targetToken) {
        const messageId = await messaging.send({
          token: targetToken,
          notification: { title, body },
          data: { type, recipientId, ...data },
          android: {
            priority: "high",
            notification: { channelId: ANDROID_CHANNEL, sound: "default", priority: "high" },
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default", badge: 1, "content-available": 1 } },
          },
        });
        logger.info("[notification_requests] Sent", { id: snap.id, messageId, type });
      } else {
        logger.warn("[notification_requests] No token or topic", { id: snap.id });
      }
    } catch (err: unknown) {
      const code = (err as { errorInfo?: { code?: string } })?.errorInfo?.code ?? "";
      if (INVALID_TOKEN_CODES.has(code)) {
        await removeStaleToken(recipientId);
      } else {
        logger.error("[notification_requests] Failed", { id: snap.id, code, err });
      }
    } finally {
      await snap.ref.delete();
    }
  }
);

// ── reminder_requests queue ───────────────────────────────────────────────────
// Handles user-triggered reminders between tester and app owner.

interface ReminderRequest {
  targetToken?: string;
  title?: string;
  body?: string;
  type?: string;
}

export const processReminderRequest = onDocumentCreated(
  { document: "reminder_requests/{docId}", region: REGION, retry: false, maxInstances: 10 },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { targetToken, title, body, type = "reminder" } = snap.data() as ReminderRequest;

    if (!targetToken || !title || !body) {
      logger.warn("[reminder_requests] Missing fields", { id: snap.id });
      await snap.ref.delete();
      return;
    }

    try {
      const messageId = await messaging.send({
        token: targetToken,
        notification: { title, body },
        data: { type },
        android: {
          priority: "high",
          notification: { channelId: ANDROID_CHANNEL, sound: "default", priority: "high" },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default", badge: 1 } },
        },
      });
      logger.info("[reminder_requests] Sent", { id: snap.id, messageId });
    } catch (err: unknown) {
      const code = (err as { errorInfo?: { code?: string } })?.errorInfo?.code ?? "";
      logger.error("[reminder_requests] Failed", { id: snap.id, code, err });
    } finally {
      await snap.ref.delete();
    }
  }
);
