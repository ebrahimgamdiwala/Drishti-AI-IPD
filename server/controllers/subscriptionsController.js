import Subscription from '../models/Subscription.js';
import User from '../models/User.js';

export const subscribe = async (req, res) => {
  try {
    const { userId, alertTypes } = req.body;
    if (!userId) return res.status(400).json({ error: 'User ID is required' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    let subscription = await Subscription.findOne({ relativeId: req.user._id, userId });
    if (subscription) {
      subscription.alertTypes = alertTypes || ['all'];
      subscription.isActive = true;
      await subscription.save();
    } else {
      subscription = new Subscription({ relativeId: req.user._id, userId, alertTypes: alertTypes || ['all'], isActive: true });
      await subscription.save();
    }

    res.json({ message: 'Subscribed successfully', subscription });
  } catch (error) {
    console.error('Subscribe error:', error);
    res.status(500).json({ error: 'Failed to subscribe' });
  }
};

export const listSubscriptions = async (req, res) => {
  try {
    const subscriptions = await Subscription.find({ relativeId: req.user._id }).populate('userId', 'name email');
    res.json({ subscriptions });
  } catch (error) {
    console.error('Get subscriptions error:', error);
    res.status(500).json({ error: 'Failed to get subscriptions' });
  }
};

export const listSubscribers = async (req, res) => {
  try {
    const subscriptions = await Subscription.find({ userId: req.user._id, isActive: true }).populate('relativeId', 'name email');
    res.json({ subscribers: subscriptions.map(s => s.relativeId) });
  } catch (error) {
    console.error('Get subscribers error:', error);
    res.status(500).json({ error: 'Failed to get subscribers' });
  }
};

export const updateSubscription = async (req, res) => {
  try {
    const subscription = await Subscription.findById(req.params.id);
    if (!subscription) return res.status(404).json({ error: 'Subscription not found' });

    if (subscription.relativeId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { alertTypes, isActive } = req.body;
    if (alertTypes) subscription.alertTypes = alertTypes;
    if (isActive !== undefined) subscription.isActive = isActive;
    await subscription.save();

    res.json({ message: 'Subscription updated', subscription });
  } catch (error) {
    console.error('Update subscription error:', error);
    res.status(500).json({ error: 'Failed to update subscription' });
  }
};

export const unsubscribe = async (req, res) => {
  try {
    const subscription = await Subscription.findById(req.params.id);
    if (!subscription) return res.status(404).json({ error: 'Subscription not found' });

    if (subscription.relativeId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }

    await Subscription.findByIdAndDelete(req.params.id);
    res.json({ message: 'Unsubscribed successfully' });
  } catch (error) {
    console.error('Unsubscribe error:', error);
    res.status(500).json({ error: 'Failed to unsubscribe' });
  }
};
