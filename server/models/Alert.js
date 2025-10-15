import mongoose from 'mongoose';

const alertSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['close-call', 'life-threat', 'obstacle', 'warning', 'info'],
    default: 'info'
  },
  severity: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'medium'
  },
  description: {
    type: String,
    required: true
  },
  imageRef: {
    type: String
  },
  detectedObjects: [{
    object: String,
    confidence: Number,
    distance: String
  }],
  location: {
    latitude: Number,
    longitude: Number
  },
  modelResponse: {
    type: String
  },
  acknowledged: {
    type: Boolean,
    default: false
  },
  acknowledgedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  acknowledgedAt: Date,
  emailsSent: [{
    recipientEmail: String,
    sentAt: Date,
    status: String
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for efficient queries
alertSchema.index({ userId: 1, createdAt: -1 });
alertSchema.index({ severity: 1, acknowledged: 1 });

export default mongoose.model('Alert', alertSchema);
