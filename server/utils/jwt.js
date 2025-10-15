import jwt from 'jsonwebtoken';

/**
 * Generate JWT token
 */
export const generateToken = (userId, expiresIn = '7d') => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn }
  );
};

/**
 * Generate verification token
 */
export const generateVerificationToken = () => {
  return jwt.sign(
    { purpose: 'email-verification', timestamp: Date.now() },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );
};

/**
 * Generate reset token
 */
export const generateResetToken = () => {
  return jwt.sign(
    { purpose: 'password-reset', timestamp: Date.now() },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
};

/**
 * Verify token
 */
export const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return null;
  }
};
