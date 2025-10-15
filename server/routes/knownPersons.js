import express from 'express';
import { authenticate, requireRole } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { uploadLimiter } from '../middleware/rateLimiter.js';
import {
  createKnownPerson,
  listKnownPersons,
  getKnownPerson,
  updateKnownPerson,
  addImages,
  deleteKnownPerson
} from '../controllers/knownPersonsController.js';

const router = express.Router();

router.post('/', authenticate, requireRole('relative', 'admin', 'user'), uploadLimiter, upload.array('images', 10), createKnownPerson);
router.get('/', authenticate, listKnownPersons);
router.get('/:id', authenticate, getKnownPerson);
router.put('/:id', authenticate, updateKnownPerson);
router.post('/:id/images', authenticate, uploadLimiter, upload.array('images', 10), addImages);
router.delete('/:id', authenticate, deleteKnownPerson);

export default router;
