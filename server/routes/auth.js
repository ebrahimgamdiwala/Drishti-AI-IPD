import express from 'express';
import { validateSignup, validateLogin } from '../middleware/validation.js';
import { authLimiter } from '../middleware/rateLimiter.js';
import { signup, login, verifyEmail, forgotPassword, resetPassword } from '../controllers/authController.js';

const router = express.Router();

router.post('/signup', authLimiter, validateSignup, signup);
router.post('/login', authLimiter, validateLogin, login);
router.post('/verify-email', verifyEmail);
router.post('/forgot-password', authLimiter, forgotPassword);
router.post('/reset-password', authLimiter, resetPassword);

export default router;
