import { Resend } from 'resend';

// Lazily initialize Resend client to avoid crashing at module import time when
// environment variables may not yet be available (or missing in local dev).
let resend = null;
function getResend() {
  if (resend) return resend;
  const key = process.env.RESEND_API_KEY;
  if (!key) {
    // Don't throw here to avoid crashing the entire app during startup.
    // Caller functions will surface a helpful error instead.
    return null;
  }
  resend = new Resend(key);
  return resend;
}

/**
 * Send verification email
 */
export const sendVerificationEmail = async (email, name, token) => {
  try {
    const verificationUrl = `${process.env.FRONTEND_URL}/verify-email?token=${token}`;
    
    const client = getResend();
    if (!client) {
      const msg = 'Missing RESEND_API_KEY. Set RESEND_API_KEY in your environment.';
      console.error(msg);
      return { success: false, error: msg };
    }

    // Determine 'from' address. Prefer explicit EMAIL_FROM, otherwise construct one
    const defaultDomain = process.env.RESEND_DEFAULT_DOMAIN || 'drishti.ai'
    const defaultFrom = `Drishti AI <noreply@${defaultDomain}>`
    const fromAddress = process.env.EMAIL_FROM || defaultFrom

    const { data, error } = await client.emails.send({
      from: fromAddress,
      to: [email],
      subject: 'Verify Your Drishti AI Account',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .button { 
                display: inline-block; 
                padding: 12px 24px; 
                background: #6366f1; 
                color: white; 
                text-decoration: none; 
                border-radius: 6px; 
                margin: 20px 0;
              }
              .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>Welcome to Drishti AI, ${name}!</h1>
              <p>Thank you for signing up. Please verify your email address to activate your account.</p>
              <a href="${verificationUrl}" class="button">Verify Email Address</a>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
              <p>This link will expire in 24 hours.</p>
              <div class="footer">
                <p>If you didn't create this account, please ignore this email.</p>
                <p>© ${new Date().getFullYear()} Drishti AI - Empowering Vision Through AI</p>
              </div>
            </div>
          </body>
        </html>
      `
    });

    if (error) {
      // If resend reports the domain isn't verified, provide a clearer log
      if (error?.message && error.message.includes('domain is not verified')) {
        console.error('Email send error: domain not verified. Make sure the sending domain is verified on Resend:', error.message);
        console.error('Configured from address:', fromAddress);
        console.error('You can add and verify your domain at https://resend.com/domains');
      } else {
        console.error('Email send error:', error);
      }
      return { success: false, error };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Failed to send verification email:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send password reset email
 */
export const sendPasswordResetEmail = async (email, name, token) => {
  try {
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;
    
    const client = getResend();
    if (!client) {
      const msg = 'Missing RESEND_API_KEY. Set RESEND_API_KEY in your environment.';
      console.error(msg);
      return { success: false, error: msg };
    }

    const defaultDomain = process.env.RESEND_DEFAULT_DOMAIN || 'drishti.ai'
    const defaultFrom = `Drishti AI <noreply@${defaultDomain}>`
    const fromAddress = process.env.EMAIL_FROM || defaultFrom

    const { data, error } = await client.emails.send({
      from: fromAddress,
      to: [email],
      subject: 'Reset Your Drishti AI Password',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .button { 
                display: inline-block; 
                padding: 12px 24px; 
                background: #6366f1; 
                color: white; 
                text-decoration: none; 
                border-radius: 6px; 
                margin: 20px 0;
              }
              .warning { background: #fef3c7; padding: 12px; border-radius: 6px; margin: 20px 0; }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>Password Reset Request</h1>
              <p>Hi ${name},</p>
              <p>We received a request to reset your Drishti AI password.</p>
              <a href="${resetUrl}" class="button">Reset Password</a>
              <p>Or copy and paste this link:</p>
              <p style="word-break: break-all; color: #666;">${resetUrl}</p>
              <div class="warning">
                <strong>⚠️ Security Note:</strong> This link expires in 1 hour. If you didn't request this reset, please ignore this email.
              </div>
              <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666;">
                <p>© ${new Date().getFullYear()} Drishti AI</p>
              </div>
            </div>
          </body>
        </html>
      `
    });

    if (error) {
      if (error?.message && error.message.includes('domain is not verified')) {
        console.error('Email send error: domain not verified. Make sure the sending domain is verified on Resend:', error.message);
        console.error('Configured from address:', fromAddress);
        console.error('You can add and verify your domain at https://resend.com/domains');
      } else {
        console.error('Email send error:', error);
      }
      return { success: false, error };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Failed to send reset email:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send alert notification email
 */
export const sendAlertEmail = async (recipientEmail, recipientName, alert, userName) => {
  try {
    const severityColors = {
      low: '#10b981',
      medium: '#f59e0b',
      high: '#f97316',
      critical: '#ef4444'
    };

    const client = getResend();
    if (!client) {
      const msg = 'Missing RESEND_API_KEY. Set RESEND_API_KEY in your environment.';
      console.error(msg);
      return { success: false, error: msg };
    }
    const defaultDomain = process.env.RESEND_DEFAULT_DOMAIN || 'drishti.ai'
    const defaultFrom = `Drishti AI <alerts@${defaultDomain}>`
    const fromAddress = process.env.EMAIL_FROM || defaultFrom

    const { data, error } = await client.emails.send({
      from: fromAddress,
      to: [recipientEmail],
      subject: `🚨 ${alert.severity.toUpperCase()} Alert for ${userName}`,
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .alert-box { 
                padding: 20px; 
                border-left: 4px solid ${severityColors[alert.severity]}; 
                background: #f9fafb; 
                margin: 20px 0;
                border-radius: 6px;
              }
              .severity { 
                display: inline-block;
                padding: 4px 12px;
                background: ${severityColors[alert.severity]};
                color: white;
                border-radius: 4px;
                font-weight: bold;
                text-transform: uppercase;
                font-size: 12px;
              }
              .button { 
                display: inline-block; 
                padding: 12px 24px; 
                background: #6366f1; 
                color: white; 
                text-decoration: none; 
                border-radius: 6px; 
                margin: 20px 0;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>🚨 Alert Notification</h1>
              <p>Hi ${recipientName},</p>
              <p>An alert has been detected for <strong>${userName}</strong>:</p>
              
              <div class="alert-box">
                <p><span class="severity">${alert.severity}</span></p>
                <h3>${alert.type}</h3>
                <p><strong>Description:</strong> ${alert.description}</p>
                <p><strong>Time:</strong> ${new Date(alert.createdAt).toLocaleString()}</p>
                ${alert.detectedObjects?.length ? `
                  <p><strong>Detected:</strong> ${alert.detectedObjects.map(o => o.object).join(', ')}</p>
                ` : ''}
              </div>

              <a href="${process.env.FRONTEND_URL}/dashboard" class="button">View Dashboard</a>

              <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666;">
                <p>You're receiving this because you subscribed to alerts for ${userName}.</p>
                <p>© ${new Date().getFullYear()} Drishti AI</p>
              </div>
            </div>
          </body>
        </html>
      `
    });

    if (error) {
      if (error?.message && error.message.includes('domain is not verified')) {
        console.error('Alert email send error: domain not verified. Make sure the sending domain is verified on Resend:', error.message);
        console.error('Configured from address:', fromAddress);
        console.error('You can add and verify your domain at https://resend.com/domains');
      } else {
        console.error('Alert email send error:', error);
      }
      return { success: false, error };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Failed to send alert email:', error);
    return { success: false, error: error.message };
  }
};
