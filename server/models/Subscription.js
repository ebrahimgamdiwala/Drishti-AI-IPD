import mongoose from 'mongoose';

const subscriptionSchema = new mongoose.Schema({
  relativeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  alertTypes: [{
    type: String,
    enum: ['close-call', 'life-threat', 'obstacle', 'warning', 'all']
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Ensure unique subscription per relative-user pair
subscriptionSchema.index({ relativeId: 1, userId: 1 }, { unique: true });

export default mongoose.model('Subscription', subscriptionSchema);
