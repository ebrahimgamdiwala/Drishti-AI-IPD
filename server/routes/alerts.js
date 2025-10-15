import express from 'express';
import { authenticate, requireRole } from '../middleware/auth.js';
import { generalLimiter } from '../middleware/rateLimiter.js';
import { validateAlert } from '../middleware/validation.js';
import { listAlerts, getAlert, createAlert, acknowledgeAlert, statsSummary, deleteAlert } from '../controllers/alertsController.js';

const router = express.Router();

router.get('/', authenticate, listAlerts);
router.get('/:id', authenticate, getAlert);
router.post('/', authenticate, generalLimiter, validateAlert, createAlert);
router.post('/:id/acknowledge', authenticate, acknowledgeAlert);
router.get('/stats/summary', authenticate, statsSummary);
router.delete('/:id', authenticate, requireRole('admin'), deleteAlert);

export default router;
