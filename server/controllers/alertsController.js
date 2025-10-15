import Alert from '../models/Alert.js';
import Subscription from '../models/Subscription.js';

export const listAlerts = async (req, res) => {
  try {
    const { limit = 50, severity, acknowledged, type } = req.query;

    const query = { userId: req.user._id };
    if (severity) query.severity = severity;
    if (acknowledged !== undefined) query.acknowledged = acknowledged === 'true';
    if (type) query.type = type;

    const alerts = await Alert.find(query).sort({ createdAt: -1 }).limit(parseInt(limit));
    res.json({ alerts });
  } catch (error) {
    console.error('Get alerts error:', error);
    res.status(500).json({ error: 'Failed to get alerts' });
  }
};

export const getAlert = async (req, res) => {
  try {
    const alert = await Alert.findById(req.params.id);
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    if (alert.userId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json({ alert });
  } catch (error) {
    console.error('Get alert error:', error);
    res.status(500).json({ error: 'Failed to get alert' });
  }
};

export const createAlert = async (req, res) => {
  try {
    const { type, severity, description, imageRef, detectedObjects, location } = req.body;

    const alert = new Alert({
      userId: req.user._id,
      type: type || 'info',
      severity: severity || 'medium',
      description,
      imageRef,
      detectedObjects,
      location
    });

    await alert.save();

    res.status(201).json({ message: 'Alert created successfully', alert });
  } catch (error) {
    console.error('Create alert error:', error);
    res.status(500).json({ error: 'Failed to create alert' });
  }
};

export const acknowledgeAlert = async (req, res) => {
  try {
    const alert = await Alert.findById(req.params.id);
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    const canAcknowledge =
      alert.userId.toString() === req.user._id.toString() ||
      req.user.role === 'admin' ||
      req.user.role === 'relative';

    if (!canAcknowledge) return res.status(403).json({ error: 'Access denied' });

    alert.acknowledged = true;
    alert.acknowledgedBy = req.user._id;
    alert.acknowledgedAt = new Date();
    await alert.save();

    res.json({ message: 'Alert acknowledged', alert });
  } catch (error) {
    console.error('Acknowledge alert error:', error);
    res.status(500).json({ error: 'Failed to acknowledge alert' });
  }
};

export const statsSummary = async (req, res) => {
  try {
    const userId = req.user._id;

    const stats = await Alert.aggregate([
      { $match: { userId: userId } },
      { $group: { _id: '$severity', count: { $sum: 1 } } }
    ]);

    const total = await Alert.countDocuments({ userId });
    const unacknowledged = await Alert.countDocuments({ userId, acknowledged: false });

    res.json({
      total,
      unacknowledged,
      bySeverity: stats.reduce((acc, item) => {
        acc[item._id] = item.count;
        return acc;
      }, {})
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to get statistics' });
  }
};

export const deleteAlert = async (req, res) => {
  try {
    const alert = await Alert.findByIdAndDelete(req.params.id);
    if (!alert) return res.status(404).json({ error: 'Alert not found' });
    res.json({ message: 'Alert deleted successfully' });
  } catch (error) {
    console.error('Delete alert error:', error);
    res.status(500).json({ error: 'Failed to delete alert' });
  }
};
