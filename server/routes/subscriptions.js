import express from 'express';
import { authenticate, requireRole } from '../middleware/auth.js';
import { generalLimiter } from '../middleware/rateLimiter.js';
import {
  subscribe,
  listSubscriptions,
  listSubscribers,
  updateSubscription,
  unsubscribe
} from '../controllers/subscriptionsController.js';

const router = express.Router();

router.post('/', authenticate, generalLimiter, subscribe);
router.get('/', authenticate, listSubscriptions);
router.get('/subscribers/:userId', authenticate, requireRole('admin'), listSubscribers);
router.put('/:id', authenticate, updateSubscription);
router.delete('/:id', authenticate, unsubscribe);

export default router;
