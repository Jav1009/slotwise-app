// scheduler.js
//
// Automated background jobs for SlotWise.
// Uses node-cron (install: npm install node-cron)
//
// JOBS:
//   1. markMissedBookings()    — runs every 15 min
//      Finds confirmed/pending bookings whose slot time has passed,
//      marks them 'missed', sends in-app notification + push to customer.
//
//   2. sendUpcomingReminders() — runs every hour on the :00
//      Sends a push + in-app reminder to customers with confirmed bookings
//      that start in approximately 24h and approximately 1h.
//
// HOW TO MOUNT:
//   In server.js, add:
//     require('./scheduler');
//
// NOTE: node-cron runs in the same process as Express.
//   For production consider a separate worker process or a managed scheduler.

const cron = require('node-cron');
const pool = require('./config/db');
const { sendToToken } = require('./utils/fcmHelper'); // see note below

// ─────────────────────────────────────────────────────────────────────────────
// HELPER — insert an in-app notification row
// ─────────────────────────────────────────────────────────────────────────────
async function insertNotification(conn, userId, bookingId, message) {
  await conn.execute(
    `INSERT INTO notifications (user_id, booking_id, message, is_read, created_at)
     VALUES (?, ?, ?, FALSE, NOW())`,
    [userId, bookingId, message]
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB 1 — Mark missed bookings + notify customer
// Cron: every 15 minutes  →  "*/15 * * * *"
// ─────────────────────────────────────────────────────────────────────────────
async function markMissedBookings() {
  const conn = await pool.getConnection();
  try {
    // Find all pending/confirmed bookings whose slot end time has passed
    // and the customer has NOT disabled notifications (notifications_enabled = 1)
    const [overdueRows] = await conn.execute(`
      SELECT
        b.id          AS booking_id,
        b.user_id,
        b.status,
        s.name        AS service_name,
        t.slot_date,
        t.start_time,
        t.end_time,
        u.fcm_token,
        COALESCE(u.notifications_enabled, 1) AS notif_enabled
      FROM   bookings   b
      JOIN   time_slots t ON b.slot_id    = t.id
      JOIN   services   s ON b.service_id = s.id
      JOIN   users      u ON b.user_id    = u.id
      WHERE  b.status IN ('pending', 'confirmed')
        AND  CONCAT(t.slot_date, ' ', t.end_time) < NOW()
    `);

    if (overdueRows.length === 0) return;

    console.log(`[Scheduler] markMissedBookings: found ${overdueRows.length} overdue booking(s)`);

    for (const row of overdueRows) {
      await conn.beginTransaction();
      try {
        // 1. Update status to missed
        await conn.execute(
          `UPDATE bookings SET status = 'missed', updated_at = NOW() WHERE id = ?`,
          [row.booking_id]
        );

        const message = `You missed your ${row.service_name} appointment on ${row.slot_date} at ${row.start_time.substring(0,5)}.`;

        // 2. Insert in-app notification (always — so it shows in the notification list)
        await insertNotification(conn, row.user_id, row.booking_id, message);

        // 3. Send push notification — only if customer hasn't disabled them
        if (row.notif_enabled && row.fcm_token) {
          await sendToToken(
            row.fcm_token,
            '📅 Missed Appointment',
            message,
            {
              type:         'booking_missed',
              booking_id:   String(row.booking_id),
              service_name: row.service_name,
              booking_date: row.slot_date,
            }
          );
        }

        await conn.commit();
        console.log(`[Scheduler] Booking #${row.booking_id} → missed. User #${row.user_id} notified.`);
      } catch (innerErr) {
        await conn.rollback();
        console.error(`[Scheduler] Failed to mark booking #${row.booking_id} as missed:`, innerErr.message);
      }
    }
  } catch (err) {
    console.error('[Scheduler] markMissedBookings error:', err.message);
  } finally {
    conn.release();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB 2 — Send upcoming booking reminders
// Cron: every hour at :00  →  "0 * * * *"
//
// Reminder windows:
//   • 24-hour reminder: slot starts between NOW+23h and NOW+25h
//   • 1-hour  reminder: slot starts between NOW+50min and NOW+70min
//
// We track sent reminders in a separate table to avoid duplicate sends.
// See migration: add_reminder_tracking.sql
// ─────────────────────────────────────────────────────────────────────────────
async function sendUpcomingReminders() {
  const conn = await pool.getConnection();
  try {
    // Fetch confirmed bookings in the two reminder windows
    // LEFT JOIN reminder_log to skip already-sent reminders
    const [rows] = await conn.execute(`
      SELECT
        b.id          AS booking_id,
        b.user_id,
        s.name        AS service_name,
        t.slot_date,
        t.start_time,
        u.fcm_token,
        COALESCE(u.notifications_enabled, 1) AS notif_enabled,
        COALESCE(u.reminders_enabled,     1) AS reminders_enabled,
        TIMESTAMPDIFF(MINUTE, NOW(), CONCAT(t.slot_date, ' ', t.start_time)) AS minutes_until,
        CASE
          WHEN TIMESTAMPDIFF(MINUTE, NOW(), CONCAT(t.slot_date, ' ', t.start_time)) BETWEEN 50 AND 70
            THEN '1h'
          WHEN TIMESTAMPDIFF(MINUTE, NOW(), CONCAT(t.slot_date, ' ', t.start_time)) BETWEEN 1380 AND 1500
            THEN '24h'
          ELSE NULL
        END AS reminder_window
      FROM   bookings   b
      JOIN   time_slots t ON b.slot_id    = t.id
      JOIN   services   s ON b.service_id = s.id
      JOIN   users      u ON b.user_id    = u.id
      WHERE  b.status = 'confirmed'
        AND  CONCAT(t.slot_date, ' ', t.start_time) > NOW()
      HAVING reminder_window IS NOT NULL
    `);

    if (rows.length === 0) return;

    console.log(`[Scheduler] sendUpcomingReminders: found ${rows.length} reminder(s) to send`);

    for (const row of rows) {
      // Skip if reminders are disabled for this user
      if (!row.reminders_enabled) {
        console.log(`[Scheduler] Reminders disabled for user #${row.user_id}. Skipping.`);
        continue;
      }

      // Check if this reminder was already sent (dedup)
      const [already] = await conn.execute(
        `SELECT id FROM reminder_log WHERE booking_id = ? AND reminder_type = ?`,
        [row.booking_id, row.reminder_window]
      );
      if (already.length > 0) continue; // Already sent

      const label   = row.reminder_window === '1h' ? '1 hour' : '24 hours';
      const timeStr = row.start_time.substring(0, 5);
      const message = `Reminder: Your ${row.service_name} appointment is in ${label} — ${row.slot_date} at ${timeStr}.`;

      await conn.beginTransaction();
      try {
        // 1. Log the reminder so it won't be sent again
        await conn.execute(
          `INSERT INTO reminder_log (booking_id, user_id, reminder_type, sent_at)
           VALUES (?, ?, ?, NOW())`,
          [row.booking_id, row.user_id, row.reminder_window]
        );

        // 2. Insert in-app notification
        await insertNotification(conn, row.user_id, row.booking_id, message);

        // 3. Send push — only if both notifications AND reminders are enabled
        if (row.notif_enabled && row.fcm_token) {
          await sendToToken(
            row.fcm_token,
            `⏰ Appointment in ${label}`,
            message,
            {
              type:         'reminder',
              booking_id:   String(row.booking_id),
              service_name: row.service_name,
              booking_date: row.slot_date,
              reminder:     row.reminder_window,
            }
          );
        }

        await conn.commit();
        console.log(`[Scheduler] ${row.reminder_window} reminder → booking #${row.booking_id}, user #${row.user_id}`);
      } catch (innerErr) {
        await conn.rollback();
        console.error(`[Scheduler] Failed to send reminder for booking #${row.booking_id}:`, innerErr.message);
      }
    }
  } catch (err) {
    console.error('[Scheduler] sendUpcomingReminders error:', err.message);
  } finally {
    conn.release();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER CRON JOBS
// ─────────────────────────────────────────────────────────────────────────────

// Every 15 minutes — mark missed bookings
cron.schedule('*/15 * * * *', () => {
  console.log('[Scheduler] Running markMissedBookings...');
  markMissedBookings();
});

// Every hour at :00 — send reminders
cron.schedule('0 * * * *', () => {
  console.log('[Scheduler] Running sendUpcomingReminders...');
  sendUpcomingReminders();
});

console.log('✅  SlotWise scheduler loaded. Jobs: markMissed (*/15min), reminders (hourly)');

module.exports = { markMissedBookings, sendUpcomingReminders }; // exported for testing