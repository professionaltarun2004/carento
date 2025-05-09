import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize nodemailer
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass,
  },
});

// Send FCM notification
export const sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to send notifications'
    );
  }

  const { userId, title, body, notificationData } = data;

  try {
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError(
        'not-found',
        'User FCM token not found'
      );
    }

    // Send FCM notification
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: notificationData,
    };

    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send notification'
    );
  }
});

// Send email notification
export const sendEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to send emails'
    );
  }

  const { email, subject, template, templateData } = data;

  try {
    // Get email template
    const templateDoc = await admin.firestore()
      .collection('emailTemplates')
      .doc(template)
      .get();

    if (!templateDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Email template not found'
      );
    }

    const templateContent = templateDoc.data()?.content;
    const htmlContent = replaceTemplateVariables(templateContent, templateData);

    // Send email
    const mailOptions = {
      from: functions.config().email.user,
      to: email,
      subject,
      html: htmlContent,
    };

    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send email'
    );
  }
});

// Helper function to replace template variables
function replaceTemplateVariables(template: string, data: any): string {
  let result = template;
  for (const [key, value] of Object.entries(data)) {
    result = result.replace(new RegExp(`{{${key}}}`, 'g'), String(value));
  }
  return result;
}

// Trigger notifications on booking status change
export const onBookingStatusChange = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    if (newData?.status === previousData?.status) {
      return null;
    }

    const bookingId = context.params.bookingId;
    const userId = newData?.userId;

    try {
      // Get user data
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const userData = userDoc.data();

      // Send FCM notification
      const message = {
        token: userData?.fcmToken,
        notification: {
          title: 'Booking Status Updated',
          body: `Your booking status has been updated to ${newData?.status}`,
        },
        data: {
          type: 'booking',
          bookingId,
          status: newData?.status,
        },
      };

      await admin.messaging().send(message);

      // Send email notification
      const emailData = {
        bookingId,
        status: newData?.status,
        carName: newData?.carName,
        pickupDate: newData?.pickupDate.toDate().toLocaleDateString(),
        dropoffDate: newData?.dropoffDate.toDate().toLocaleDateString(),
      };

      await sendEmail({
        email: userData?.email,
        subject: 'Booking Status Update',
        template: 'bookingStatusUpdate',
        templateData: emailData,
      });

      return null;
    } catch (error) {
      console.error('Error sending booking status notifications:', error);
      return null;
    }
  }); 