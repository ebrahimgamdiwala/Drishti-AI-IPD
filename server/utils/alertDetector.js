/**
 * Enhanced alert detection with configurable rules
 */

export const alertRules = {
  critical: {
    keywords: [
      'danger', 'hazard', 'collision', 'emergency', 'fire', 'smoke',
      'falling', 'cliff', 'edge', 'vehicle approaching', 'car coming',
      'life threat', 'immediate danger', 'toxic', 'electric'
    ],
    severity: 'critical',
    type: 'life-threat',
    emailAlert: true
  },
  high: {
    keywords: [
      'obstacle ahead', 'close', 'very near', 'blocked path', 'stairs ahead',
      'uneven ground', 'construction zone', 'caution required',
      'watch out', 'be careful', 'step down', 'curb ahead',
      'person approaching', 'bicycle'
    ],
    severity: 'high',
    type: 'close-call',
    emailAlert: true
  },
  medium: {
    keywords: [
      'door', 'wall', 'furniture', 'slight obstacle', 'narrow path',
      'crowded area', 'noisy environment', 'poor lighting'
    ],
    severity: 'medium',
    type: 'warning',
    emailAlert: false
  }
};

/**
 * Analyze model response and detect alerts
 */
export const analyzeForAlerts = (modelResponse) => {
  const response = modelResponse.toLowerCase();
  const detectedAlerts = [];
  
  // Check each rule category
  for (const [level, rule] of Object.entries(alertRules)) {
    const matchedKeywords = rule.keywords.filter(keyword => 
      response.includes(keyword.toLowerCase())
    );
    
    if (matchedKeywords.length > 0) {
      detectedAlerts.push({
        level,
        severity: rule.severity,
        type: rule.type,
        emailAlert: rule.emailAlert,
        matchedKeywords,
        confidence: calculateConfidence(matchedKeywords.length, rule.keywords.length)
      });
    }
  }
  
  // Return highest severity alert
  if (detectedAlerts.length === 0) {
    return {
      severity: 'low',
      type: 'info',
      detected: false,
      emailAlert: false,
      keywords: []
    };
  }
  
  // Sort by severity (critical > high > medium)
  const severityOrder = { critical: 0, high: 1, medium: 2 };
  detectedAlerts.sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity]);
  
  return {
    ...detectedAlerts[0],
    detected: true,
    keywords: detectedAlerts[0].matchedKeywords
  };
};

/**
 * Calculate confidence score
 */
const calculateConfidence = (matched, total) => {
  return Math.min(0.5 + (matched / total) * 0.5, 1.0);
};

/**
 * Extract detected objects from model response
 */
export const extractObjects = (modelResponse) => {
  const objects = [];
  const response = modelResponse.toLowerCase();
  
  // Common objects to detect
  const objectPatterns = [
    { name: 'person', patterns: ['person', 'people', 'human', 'pedestrian'] },
    { name: 'vehicle', patterns: ['car', 'vehicle', 'bicycle', 'motorcycle', 'truck', 'bus'] },
    { name: 'obstacle', patterns: ['obstacle', 'barrier', 'pole', 'post', 'sign'] },
    { name: 'furniture', patterns: ['chair', 'table', 'desk', 'shelf', 'cabinet'] },
    { name: 'door', patterns: ['door', 'doorway', 'entrance', 'exit'] },
    { name: 'stairs', patterns: ['stairs', 'staircase', 'steps'] },
    { name: 'wall', patterns: ['wall'] },
    { name: 'floor_hazard', patterns: ['wet floor', 'uneven', 'curb', 'pothole'] }
  ];
  
  for (const obj of objectPatterns) {
    for (const pattern of obj.patterns) {
      if (response.includes(pattern)) {
        // Try to extract distance if mentioned
        const distanceMatch = response.match(new RegExp(`${pattern}.*?(\\d+)\\s*(meter|feet|foot|m|ft)`, 'i'));
        const distance = distanceMatch ? `${distanceMatch[1]} ${distanceMatch[2]}` : 'unknown';
        
        objects.push({
          object: obj.name,
          confidence: 0.8,
          distance: distance
        });
        break; // Only add once per object type
      }
    }
  }
  
  return objects;
};
