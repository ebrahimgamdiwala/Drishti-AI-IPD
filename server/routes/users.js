import express from 'express';
import { authenticate } from '../middleware/auth.js';
import { generalLimiter } from '../middleware/rateLimiter.js';
import { getProfile, updateProfile, connectUser, getConnectedUsers } from '../controllers/usersController.js';

const router = express.Router();

router.get('/me', authenticate, getProfile);
router.put('/me', authenticate, generalLimiter, updateProfile);
router.post('/connect', authenticate, connectUser);
router.get('/connected', authenticate, getConnectedUsers);

export default router;
