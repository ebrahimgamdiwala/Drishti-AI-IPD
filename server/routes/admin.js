import express from 'express';
import { authenticate, requireRole } from '../middleware/auth.js';
import { listUsers, getUser, updateUserRole, listAlertsAdmin, stats, deleteUser, getAuditLogs } from '../controllers/adminController.js';

const router = express.Router();

router.get('/users', authenticate, requireRole('admin'), listUsers);
router.get('/users/:id', authenticate, requireRole('admin'), getUser);
router.put('/users/:id/role', authenticate, requireRole('admin'), updateUserRole);
router.get('/alerts', authenticate, requireRole('admin'), listAlertsAdmin);
router.get('/stats', authenticate, requireRole('admin'), stats);
router.delete('/users/:id', authenticate, requireRole('admin'), deleteUser);
router.get('/audit-logs', authenticate, requireRole('admin'), getAuditLogs);

export default router;
