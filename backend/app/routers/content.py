"""
Drishti AI - Content Router

Static content endpoints for help, privacy policy, about, etc.
"""

from fastapi import APIRouter

router = APIRouter(prefix="/api/content", tags=["Content"])


@router.get("/help")
async def get_help():
    """Get help and FAQ content."""
    return {
        "title": "Drishti AI Help & FAQ",
        "sections": [
            {
                "title": "Getting Started",
                "items": [
                    {
                        "question": "How do I use voice commands?",
                        "answer": "Tap the large microphone button on the home screen and speak your command clearly. You can ask to scan surroundings, identify people, read text, and more."
                    },
                    {
                        "question": "How do I add relatives?",
                        "answer": "Go to the Relatives tab, tap the '+' button, take or upload a photo of the person, and fill in their details. The app will learn to recognize them."
                    },
                    {
                        "question": "What voice commands are available?",
                        "answer": "Try commands like 'Show obstacles', 'Who is near?', 'Read text', 'Scan surroundings', or 'Find [person name]'."
                    }
                ]
            },
            {
                "title": "Features",
                "items": [
                    {
                        "question": "How does face recognition work?",
                        "answer": "Drishti AI uses advanced AI to learn faces from photos you provide. The more photos you add of a person, the better the recognition accuracy."
                    },
                    {
                        "question": "Can I use Drishti offline?",
                        "answer": "Some features require an internet connection, but basic voice commands and face recognition work offline once set up."
                    },
                    {
                        "question": "How do I adjust voice speed?",
                        "answer": "Go to Settings > Voice Settings and adjust the voice speed slider to your preference."
                    }
                ]
            },
            {
                "title": "Troubleshooting",
                "items": [
                    {
                        "question": "Voice commands aren't working",
                        "answer": "Check your microphone permissions in device settings. Ensure you're in a quiet environment and speaking clearly."
                    },
                    {
                        "question": "Face recognition is inaccurate",
                        "answer": "Add more photos of the person from different angles and lighting conditions to improve accuracy."
                    },
                    {
                        "question": "App is slow or crashing",
                        "answer": "Try restarting the app. If issues persist, check for updates or contact support."
                    }
                ]
            },
            {
                "title": "Contact Support",
                "items": [
                    {
                        "question": "How do I contact support?",
                        "answer": "Email us at support@drishti-ai.com or visit our website at drishti-ai.com/support"
                    }
                ]
            }
        ]
    }


@router.get("/privacy")
async def get_privacy_policy():
    """Get privacy policy content."""
    return {
        "title": "Privacy Policy",
        "lastUpdated": "2026-01-26",
        "sections": [
            {
                "title": "Introduction",
                "content": "Drishti AI ('we', 'our', or 'us') is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your personal information when you use our mobile application."
            },
            {
                "title": "Information We Collect",
                "content": "We collect information you provide directly to us, including:\n\n• Account information (name, email address)\n• Photos you upload for face recognition\n• Voice recordings for command processing\n• Usage data and app interactions\n• Device information and location (with permission)"
            },
            {
                "title": "How We Use Your Information",
                "content": "We use the information we collect to:\n\n• Provide and improve our services\n• Process face recognition and voice commands\n• Send you notifications and updates\n• Analyze app usage to enhance user experience\n• Ensure security and prevent fraud"
            },
            {
                "title": "Data Storage and Security",
                "content": "Your data is stored securely using industry-standard encryption. Face recognition data is processed locally on your device when possible. We implement appropriate technical and organizational measures to protect your personal information."
            },
            {
                "title": "Data Sharing",
                "content": "We do not sell your personal information. We may share your information only:\n\n• With your explicit consent\n• To comply with legal obligations\n• With service providers who assist in app operations\n• With emergency contacts you designate"
            },
            {
                "title": "Your Rights",
                "content": "You have the right to:\n\n• Access your personal data\n• Correct inaccurate information\n• Delete your account and data\n• Opt-out of certain data collection\n• Export your data"
            },
            {
                "title": "Children's Privacy",
                "content": "Drishti AI is not intended for children under 13. We do not knowingly collect personal information from children under 13."
            },
            {
                "title": "Changes to This Policy",
                "content": "We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the 'Last Updated' date."
            },
            {
                "title": "Contact Us",
                "content": "If you have questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@drishti-ai.com\nWebsite: drishti-ai.com/privacy"
            }
        ]
    }


@router.get("/about")
async def get_about():
    """Get about app content."""
    return {
        "title": "About Drishti AI",
        "version": "1.0.0",
        "description": "Drishti AI is an advanced vision assistance application designed to help visually impaired individuals navigate their world with confidence. Using cutting-edge AI technology, we provide real-time object detection, face recognition, text reading, and voice-guided navigation.",
        "features": [
            "Voice-controlled interface for hands-free operation",
            "Advanced face recognition to identify family and friends",
            "Real-time obstacle detection and navigation assistance",
            "Text recognition and reading",
            "Emergency contact integration",
            "Customizable accessibility settings"
        ],
        "team": "Developed with ❤️ by the Drishti AI Team",
        "contact": {
            "email": "info@drishti-ai.com",
            "website": "drishti-ai.com",
            "support": "support@drishti-ai.com"
        },
        "legal": {
            "copyright": "© 2026 Drishti AI. All rights reserved.",
            "license": "Proprietary"
        }
    }
