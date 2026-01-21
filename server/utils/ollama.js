import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const MODEL = process.env.OLLAMA_MODEL || 'llava:7b';

/**
 * Analyze image with Ollama vision model
 */
export const analyzeImage = async (imageInput, prompt) => {
  try {
    // Normalize imageInput into a data URL expected by Ollama
    let imageData = imageInput || '';

    if (!imageData) {
      return { success: false, error: 'No image data provided' };
    }

    // If caller provided a data URL, extract the base64 payload
    const dataUrlMatch = /^data:(image\/[^;]+);base64,(.+)$/i.exec(imageData);
    let base64Only = imageData;
    if (dataUrlMatch) {
      base64Only = dataUrlMatch[2];
    }

    // Basic sanity check: don't send extremely large payloads unnecessarily
    const sizeKb = Math.round((base64Only.length * 3) / 4 / 1024);
    if (sizeKb > 10000) { // > ~10MB
      console.warn(`Ollama image payload is large (~${sizeKb} KB)`);
    }
    console.debug('Sending image to Ollama (sizeKB):', sizeKb, 'model:', MODEL);

    const payload = {
      model: MODEL,
      prompt: prompt,
      // Ollama expects raw base64 strings for images (without the data: prefix)
      images: [base64Only],
      stream: false
    };

    const response = await axios.post(`${OLLAMA_URL}/api/generate`, payload, {
      timeout: 60000, // 60 second timeout
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json'
      }
    });

    // Ollama may return different shapes; attempt to normalize
    const respText = response.data?.response ?? response.data ?? null;

    return {
      success: true,
      response: respText,
      model: MODEL,
      context: response.data?.context
    };
  } catch (error) {
    console.error('Ollama analysis error:', error?.response?.data ?? error.message);

    if (error.code === 'ECONNREFUSED') {
      return {
        success: false,
        error: 'Cannot connect to Ollama. Make sure Ollama is running on ' + OLLAMA_URL
      };
    }

    return {
      success: false,
      error: error.response?.data?.error || error.message
    };
  }
};

/**
 * Check if Ollama is available
 */
export const checkOllamaHealth = async () => {
  try {
    const response = await axios.get(`${OLLAMA_URL}/api/tags`, {
      timeout: 5000
    });
    
    const hasModel = response.data.models?.some(m => m.name.includes(MODEL));
    
    return {
      available: true,
      models: response.data.models?.map(m => m.name) || [],
      hasRequiredModel: hasModel
    };
  } catch (error) {
    return {
      available: false,
      error: error.message
    };
  }
};

/**
 * Detect potential threats and hazards in the model response
 */
export const detectThreat = (modelResponse) => {
  const response = modelResponse.toLowerCase();
  
  // Critical threats
  const criticalKeywords = [
    'danger', 'hazard', 'collision', 'emergency', 'fire',
    'falling', 'cliff', 'edge', 'vehicle approaching',
    'life threat', 'immediate danger'
  ];
  
  // Warning level
  const warningKeywords = [
    'obstacle', 'close', 'near', 'blocked', 'stairs',
    'uneven', 'wet floor', 'construction', 'caution',
    'watch out', 'be careful'
  ];
  
  // Check for critical threats
  for (const keyword of criticalKeywords) {
    if (response.includes(keyword)) {
      return {
        severity: 'critical',
        type: 'life-threat',
        detected: true,
        keywords: [keyword]
      };
    }
  }
  
  // Check for warnings
  for (const keyword of warningKeywords) {
    if (response.includes(keyword)) {
      return {
        severity: 'high',
        type: 'close-call',
        detected: true,
        keywords: [keyword]
      };
    }
  }
  
  return {
    severity: 'low',
    type: 'info',
    detected: false,
    keywords: []
  };
};
