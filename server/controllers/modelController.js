import { analyzeImage, checkOllamaHealth } from '../utils/ollama.js';
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { analyzeForAlerts, extractObjects } from '../utils/alertDetector.js';
import Alert from '../models/Alert.js';
import Subscription from '../models/Subscription.js';
import { sendAlertEmail } from '../utils/email.js';

export const analyze = async (req, res) => {
  try {
    const { image, prompt, sessionId } = req.body;
    if (!image || !prompt) return res.status(400).json({ error: 'Image and prompt are required' });

    // Prepare base64 image and optionally save to uploads with a timestamped filename
  let savedImageUrl = null;
  let savedFilePath = null;
    // image may be a data URL or raw base64; detect and normalize
    let base64Only = image;
    let mimeType = 'image/jpeg';
    const dataUrlMatch = /^data:(image\/[^;]+);base64,(.+)$/i.exec(image);
    if (dataUrlMatch) {
      mimeType = dataUrlMatch[1];
      base64Only = dataUrlMatch[2];
    } else {
      // Strip any possible prefix that isn't data:...;base64,
      base64Only = image.replace(/^data:image\/\w+;base64,/, '');
    }

    // Validate base64 length
    if (!base64Only || typeof base64Only !== 'string' || base64Only.length < 20) {
      return res.status(400).json({ error: 'Invalid image data' });
    }
    try {
      const __filename = fileURLToPath(import.meta.url)
      const __dirname = path.dirname(__filename)
      const uploadsDir = path.join(__dirname, '..', 'uploads')
      if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true })
        const buffer = Buffer.from(base64Only, 'base64')
        // Use provided MIME (if any) to determine extension
        const imageMimeFromClient = req.body.imageMime || 'image/jpeg'
        const ext = imageMimeFromClient.split('/')[1] || 'jpg'
        const filename = `capture-${Date.now()}-${Math.random().toString(36).slice(2,8)}.${ext}`
    const filepath = path.join(uploadsDir, filename)
      fs.writeFileSync(filepath, buffer)
      // Save absolute file path for later readback and construct URL path for clients
      savedFilePath = filepath;
      savedImageUrl = `/uploads/${filename}`;
    } catch (err) {
      console.warn('Failed to save incoming image:', err)
      savedImageUrl = null
    }

  // Read the saved image file back and send its base64 to Ollama
  // This ensures Ollama receives exactly what was saved to disk
  let imageBase64ForOllama = base64Only;
  if (savedFilePath) {
    try {
      const savedBuffer = fs.readFileSync(savedFilePath);
      imageBase64ForOllama = savedBuffer.toString('base64');
      console.debug('Read saved image from disk for Ollama. Size:', savedBuffer.length, 'bytes');
    } catch (readErr) {
      console.warn('Failed to read saved image, using original base64:', readErr);
      imageBase64ForOllama = base64Only;
    }
  } else if (savedImageUrl) {
    try {
      const __filename = fileURLToPath(import.meta.url);
      const __dirname = path.dirname(__filename);
      const savedFilePathFallback = path.join(__dirname, '..', savedImageUrl);
      const savedBuffer = fs.readFileSync(savedFilePathFallback);
      imageBase64ForOllama = savedBuffer.toString('base64');
      console.debug('Read saved image from disk (fallback path) for Ollama. Size:', savedBuffer.length, 'bytes');
    } catch (readErr) {
      console.warn('Failed to read saved image via fallback path, using original base64:', readErr);
      imageBase64ForOllama = base64Only;
    }
  }

  console.debug('Analyze request. prompt length:', (prompt || '').length, 'image bytes ~', imageBase64ForOllama.length);

  // Compute simple djb2 hash of the base64 payload for quick integrity checks
  const djb2 = (s) => {
    let h = 5381
    for (let i = 0; i < s.length; i++) {
      h = ((h << 5) + h) + s.charCodeAt(i)
      h = h & 0xffffffff
    }
    return (h >>> 0).toString(16)
  }

  const serverImageHash = djb2(imageBase64ForOllama)

  const result = await analyzeImage(imageBase64ForOllama, prompt)

    if (!result.success) return res.status(503).json({ error: result.error || 'AI analysis failed' });

    const alertAnalysis = analyzeForAlerts(result.response);
    const detectedObjects = extractObjects(result.response);

    let alertId = null;
    if (alertAnalysis.detected && alertAnalysis.severity !== 'low') {
      const alert = new Alert({ userId: req.user._id, type: alertAnalysis.type, severity: alertAnalysis.severity, description: result.response, modelResponse: result.response, detectedObjects });
      await alert.save();
      alertId = alert._id;

      if (alertAnalysis.emailAlert) {
        const subscriptions = await Subscription.find({ userId: req.user._id, isActive: true, alertTypes: { $in: [alertAnalysis.type, 'all'] } }).populate('relativeId', 'name email');
        for (const sub of subscriptions) {
          if (sub.relativeId && sub.relativeId.email) {
            const emailResult = await sendAlertEmail(sub.relativeId.email, sub.relativeId.name, alert, req.user.name);
            if (emailResult.success) {
              alert.emailsSent.push({ recipientEmail: sub.relativeId.email, sentAt: new Date(), status: 'sent' });
            }
          }
        }
        await alert.save();
      }
    }

  // Provide a small sample of the base64 to help debugging (do not leak large payloads)
  const serverBase64Sample = base64Only.slice(0, 120)

  res.json({ success: true, response: result.response, model: result.model, savedImageUrl: savedImageUrl, sessionId: sessionId || null, serverImageHash, serverBase64Sample, alert: { detected: alertAnalysis.detected, severity: alertAnalysis.severity, type: alertAnalysis.type, keywords: alertAnalysis.keywords, alertId }, detectedObjects });
  } catch (error) {
    console.error('Model analyze error:', error);
    res.status(500).json({ error: 'Analysis failed' });
  }
};

export const health = async (req, res) => {
  try {
    const health = await checkOllamaHealth();
    res.json(health);
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({ available: false, error: 'Health check failed' });
  }
};

export const identify = async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) return res.status(400).json({ error: 'Image is required' });

    res.json({ success: true, identified: false, message: 'Face recognition feature coming soon', confidence: 0, person: null });
  } catch (error) {
    console.error('Identify error:', error);
    res.status(500).json({ error: 'Identification failed' });
  }
};
