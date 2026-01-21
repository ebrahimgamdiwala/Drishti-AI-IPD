"""
Drishti AI - Email Service

Email sending via Resend API.
"""

from typing import Optional
from app.config import get_settings

# Lazy initialization of Resend client
_resend_client = None


def get_resend():
    """Get or initialize Resend client."""
    global _resend_client
    
    if _resend_client is not None:
        return _resend_client
    
    settings = get_settings()
    
    if not settings.resend_api_key:
        return None
    
    try:
        import resend
        resend.api_key = settings.resend_api_key
        _resend_client = resend
        return _resend_client
    except Exception as e:
        print(f"Failed to initialize Resend: {e}")
        return None


async def send_verification_email(email: str, name: str, token: str) -> dict:
    """Send verification email to user."""
    settings = get_settings()
    client = get_resend()
    
    if not client:
        return {"success": False, "error": "Email service not configured"}
    
    verification_url = f"{settings.frontend_url}/verify-email?token={token}"
    
    try:
        response = client.Emails.send({
            "from": settings.email_from,
            "to": [email],
            "subject": "Verify Your Drishti AI Account",
            "html": f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .button {{ 
                            display: inline-block; 
                            padding: 12px 24px; 
                            background: #6366f1; 
                            color: white; 
                            text-decoration: none; 
                            border-radius: 6px; 
                            margin: 20px 0;
                        }}
                        .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }}
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h1>Welcome to Drishti AI, {name}!</h1>
                        <p>Thank you for signing up. Please verify your email address to activate your account.</p>
                        <a href="{verification_url}" class="button">Verify Email Address</a>
                        <p>Or copy and paste this link into your browser:</p>
                        <p style="word-break: break-all; color: #666;">{verification_url}</p>
                        <p>This link will expire in 24 hours.</p>
                        <div class="footer">
                            <p>If you didn't create this account, please ignore this email.</p>
                            <p>© 2024 Drishti AI - Empowering Vision Through AI</p>
                        </div>
                    </div>
                </body>
                </html>
            """
        })
        
        return {"success": True, "data": response}
    except Exception as e:
        print(f"Failed to send verification email: {e}")
        return {"success": False, "error": str(e)}


async def send_password_reset_email(email: str, name: str, token: str) -> dict:
    """Send password reset email to user."""
    settings = get_settings()
    client = get_resend()
    
    if not client:
        return {"success": False, "error": "Email service not configured"}
    
    reset_url = f"{settings.frontend_url}/reset-password?token={token}"
    
    try:
        response = client.Emails.send({
            "from": settings.email_from,
            "to": [email],
            "subject": "Reset Your Drishti AI Password",
            "html": f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .button {{ 
                            display: inline-block; 
                            padding: 12px 24px; 
                            background: #6366f1; 
                            color: white; 
                            text-decoration: none; 
                            border-radius: 6px; 
                            margin: 20px 0;
                        }}
                        .warning {{ background: #fef3c7; padding: 12px; border-radius: 6px; margin: 20px 0; }}
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h1>Password Reset Request</h1>
                        <p>Hi {name},</p>
                        <p>We received a request to reset your Drishti AI password.</p>
                        <a href="{reset_url}" class="button">Reset Password</a>
                        <p>Or copy and paste this link:</p>
                        <p style="word-break: break-all; color: #666;">{reset_url}</p>
                        <div class="warning">
                            <strong>⚠️ Security Note:</strong> This link expires in 1 hour. If you didn't request this reset, please ignore this email.
                        </div>
                        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666;">
                            <p>© 2024 Drishti AI</p>
                        </div>
                    </div>
                </body>
                </html>
            """
        })
        
        return {"success": True, "data": response}
    except Exception as e:
        print(f"Failed to send reset email: {e}")
        return {"success": False, "error": str(e)}


async def send_alert_email(
    recipient_email: str, 
    recipient_name: str, 
    alert, 
    user_name: str
) -> dict:
    """Send alert notification email."""
    settings = get_settings()
    client = get_resend()
    
    if not client:
        return {"success": False, "error": "Email service not configured"}
    
    severity_colors = {
        "low": "#10b981",
        "medium": "#f59e0b",
        "high": "#f97316",
        "critical": "#ef4444"
    }
    
    severity = alert.severity if hasattr(alert, 'severity') else "medium"
    severity_color = severity_colors.get(severity, "#f59e0b")
    
    try:
        detected_objects_html = ""
        if hasattr(alert, 'detected_objects') and alert.detected_objects:
            objects = [obj.object for obj in alert.detected_objects]
            detected_objects_html = f"<p><strong>Detected:</strong> {', '.join(objects)}</p>"
        
        response = client.Emails.send({
            "from": settings.email_from,
            "to": [recipient_email],
            "subject": f"🚨 {severity.upper()} Alert for {user_name}",
            "html": f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .alert-box {{ 
                            padding: 20px; 
                            border-left: 4px solid {severity_color}; 
                            background: #f9fafb; 
                            margin: 20px 0;
                            border-radius: 6px;
                        }}
                        .severity {{ 
                            display: inline-block;
                            padding: 4px 12px;
                            background: {severity_color};
                            color: white;
                            border-radius: 4px;
                            font-weight: bold;
                            text-transform: uppercase;
                            font-size: 12px;
                        }}
                        .button {{ 
                            display: inline-block; 
                            padding: 12px 24px; 
                            background: #6366f1; 
                            color: white; 
                            text-decoration: none; 
                            border-radius: 6px; 
                            margin: 20px 0;
                        }}
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h1>🚨 Alert Notification</h1>
                        <p>Hi {recipient_name},</p>
                        <p>An alert has been detected for <strong>{user_name}</strong>:</p>
                        
                        <div class="alert-box">
                            <p><span class="severity">{severity}</span></p>
                            <h3>{alert.type if hasattr(alert, 'type') else 'Alert'}</h3>
                            <p><strong>Description:</strong> {alert.description}</p>
                            <p><strong>Time:</strong> {alert.created_at if hasattr(alert, 'created_at') else 'Now'}</p>
                            {detected_objects_html}
                        </div>

                        <a href="{settings.frontend_url}/dashboard" class="button">View Dashboard</a>

                        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666;">
                            <p>You're receiving this because you subscribed to alerts for {user_name}.</p>
                            <p>© 2024 Drishti AI</p>
                        </div>
                    </div>
                </body>
                </html>
            """
        })
        
        return {"success": True, "data": response}
    except Exception as e:
        print(f"Failed to send alert email: {e}")
        return {"success": False, "error": str(e)}
