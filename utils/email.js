// utils/email.js
const nodemailer = require('nodemailer');// Import nodemailer for sending emails

// Email class to handle sending different types of emails (e.g., password change, password reset)
class Email {
    constructor(data, url = null) {
        this.to = data.email;// Recipient's email address
        this.subject = data.subject;// Email subject
        this.from = process.env.EMAIL_FROM;// Sender's email address from environment variable
        this.url = url;// Optional URL to include in the email
        this.fullName = data.fullName;// Recipient's full name
        this.resetCode = data.resetCode;// Optional reset code for password reset emails
    }

    // Create a transporter using SMTP settings from environment variables
    createMailTtransport() {
        if (process.env.NODE_ENV === 'production') {
            // In production, use a real email service (e.g., SendGrid, Mailgun)
            return nodemailer.createTransport({
                host: process.env.MAIL_HOST,// Email service host from environment variable
                port: process.env.MAIL_PORT,// Email service port from environment variable
                auth: {
                    user: process.env.MAILTRAP_USER,// MailTrap username from environment variable
                    pass: process.env.MAILTRAP_PASS,// MailTrap password from environment variable
                },
                debug: true, // Enable debug output for production
                logger: true, // Enable logging for production
            });
        } else {
            // In development, use MailTrap for testing emails
            return nodemailer.createTransport({
                host: process.env.MAIL_HOST,// MailTrap host from environment variable
                port: process.env.MAIL_PORT,// MailTrap port from environment variable
                auth: {
                    user: process.env.MAILTRAP_USER,// MailTrap username from environment variable
                    pass: process.env.MAILTRAP_PASS,// MailTrap password from environment variable
                },
                debug: true, // Enable debug output for development
                logger: true, // Enable logging for development
            });
        }
    }

    // Send an email notifying the user that their password has been changed
    async sendPasswordChangeEmail() {
        const emailTransporter = this.createMailTtransport();// Create a transporter for sending the email

        await emailTransporter.sendMail({
            from: this.from,
            to: this.to,
            subject: this.subject,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #667EEA;">Password Changed</h2>
                    <p>Hello ${this.fullName},</p>
                    <p>Your password has been changed successfully.</p>
                    <p><strong>Change Date:</strong> ${new Date().toLocaleString()}</p>
                    <p>If you did not make this change, please contact support immediately.</p>
                    <hr style="border: 1px solid #eee; margin: 20px 0;">
                    <p style="color: #666; font-size: 12px;">
                        This is an automated message from Notes App. Please do not reply to this email.
                    </p>
                </div>`
        });
    }

    // Send an email with a password reset code to the user
    async sendPasswordResetEmail() {
        const emailTransporter = this.createMailTtransport();// Create a transporter for sending the email

        await emailTransporter.sendMail({
            from: this.from,
            to: this.to,
            subject: this.subject,
            html: `
                <strong>Your Reset Code:</strong>
            </p>

            <div style="
                background: #f4f6ff;
                padding: 15px;
                text-align:center;
                font-size:24px;
                letter-spacing:4px;
                font-weight:bold;
                color:#333;
                border-radius: 8px;">
                ${this.resetCode}
            </div>
            <p style="margin-top: 20px;">
                This code will expire in <strong>10 minutes</strong>.
            </p>
            <p>If you did not request this reset, you can safely ignore this email.</p>
            
            <hr style="border: 1px solid #eee; margin: 20px 0;">
            <p style="color: #666; font-size: 12px;">
                This is an automated message from Mini Inventory App. Please do not reply.
            </p>
            </div>
                `
        });
    }
}

module.exports = Email;// Export the Email class for use in other parts of the application