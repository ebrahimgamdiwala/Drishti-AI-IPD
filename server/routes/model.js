import express from 'express';
import { authenticate } from '../middleware/auth.js';
import { modelLimiter } from '../middleware/rateLimiter.js';
import { analyze, health, identify } from '../controllers/modelController.js';

const router = express.Router();

router.post('/analyze', authenticate, modelLimiter, analyze);
router.get('/health', health);
router.post('/identify', authenticate, modelLimiter, identify);

export default router;
