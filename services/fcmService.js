const admin = require('firebase-admin');

// Initialize Firebase Admin (add this to your config)
const serviceAccount = require('../config/firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

class FCMService {
  /**
   * Send notification to a specific device
   */
  static async sendToDevice(fcmToken, notification, data = {}) {
    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            channelId: data.type === 'admin' ? 'admin_channel' : 'bookings_channel',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Notification sent:', response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send notification to multiple devices (topic)
   */
  static async sendToTopic(topic, notification, data = {}) {
    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        topic: topic,
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Notification sent to topic ${topic}:`, response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ Error sending topic notification:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send notifications to all admins
   */
  static async notifyAdmins(notification, data = {}) {
    return await FCMService.sendToTopic('admins', notification, {
      ...data,
      type: 'admin',
    });
  }

  /**
   * Send booking confirmation to user
   */
  static async sendBookingConfirmation(userFcmToken, bookingData) {
    const notification = {
      title: 'Booking Confirmed! 🎉',
      body: `Your appointment for ${bookingData.serviceName} on ${bookingData.date} at ${bookingData.time} has been confirmed.`,
    };

    const data = {
      type: 'booking_confirmed',
      booking_id: bookingData.id.toString(),
      action: 'open_booking',
      service: bookingData.serviceName,
      date: bookingData.date,
      time: bookingData.time,
    };

    return await FCMService.sendToDevice(userFcmToken, notification, data);
  }

  /**
   * Send booking cancellation notification
   */
  static async sendBookingCancellation(userFcmToken, bookingData) {
    const notification = {
      title: 'Booking Cancelled',
      body: `Your appointment for ${bookingData.serviceName} on ${bookingData.date} has been cancelled.`,
    };

    const data = {
      type: 'booking_cancelled',
      booking_id: bookingData.id.toString(),
      action: 'open_booking',
    };

    return await FCMService.sendToDevice(userFcmToken, notification, data);
  }

  /**
   * Send reminder notification
   */
  static async sendReminder(userFcmToken, bookingData) {
    const notification = {
      title: '⏰ Appointment Reminder',
      body: `Your ${bookingData.serviceName} appointment is in 1 hour!`,
    };

    const data = {
      type: 'reminder',
      booking_id: bookingData.id.toString(),
      action: 'open_booking',
    };

    return await FCMService.sendToDevice(userFcmToken, notification, data);
  }

  /**
   * Notify admin of new booking
   */
  static async notifyAdminNewBooking(bookingData) {
    const notification = {
      title: '📅 New Booking!',
      body: `${bookingData.userName} booked ${bookingData.serviceName} at ${bookingData.time}`,
    };

    const data = {
      type: 'new_booking',
      booking_id: bookingData.id.toString(),
      action: 'open_admin',
    };

    return await FCMService.sendToTopic('admins', notification, data);
  }
}

module.exports = FCMService;
