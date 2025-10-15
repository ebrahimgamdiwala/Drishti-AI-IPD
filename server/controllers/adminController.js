import User from '../models/User.js';
import Alert from '../models/Alert.js';
import AuditLog from '../models/AuditLog.js';
import KnownPerson from '../models/KnownPerson.js';

export const listUsers = async (req, res) => {
  try {
    const { role, limit = 100, page = 1 } = req.query;
    const query = role ? { role } : {};
    const skip = (page - 1) * limit;

    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    const total = await User.countDocuments(query);

    res.json({ users, pagination: { total, page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(total / limit) } });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
};

export const getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password').populate('connectedUsers', 'name email role');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
};

export const updateUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    if (!['admin', 'user', 'relative'].includes(role)) return res.status(400).json({ error: 'Invalid role' });

    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.role = role;
    await user.save();

    await AuditLog.create({ userId: req.user._id, action: 'update_user_role', resource: 'user', details: { targetUserId: user._id, newRole: role } });

    res.json({ message: 'Role updated successfully', user });
  } catch (error) {
    console.error('Update role error:', error);
    res.status(500).json({ error: 'Failed to update role' });
  }
};

export const listAlertsAdmin = async (req, res) => {
  try {
    const { severity, acknowledged, limit = 100, page = 1 } = req.query;
    const query = {};
    if (severity) query.severity = severity;
    if (acknowledged !== undefined) query.acknowledged = acknowledged === 'true';
    const skip = (page - 1) * limit;

    const alerts = await Alert.find(query).populate('userId', 'name email').populate('acknowledgedBy', 'name').sort({ createdAt: -1 }).limit(parseInt(limit)).skip(skip);
    const total = await Alert.countDocuments(query);

    res.json({ alerts, pagination: { total, page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(total / limit) } });
  } catch (error) {
    console.error('Get alerts error:', error);
    res.status(500).json({ error: 'Failed to get alerts' });
  }
};

export const stats = async (req, res) => {
  try {
    const userCount = await User.countDocuments();
    const usersByRole = await User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]);

    const alertCount = await Alert.countDocuments();
    const alertsBySeverity = await Alert.aggregate([{ $group: { _id: '$severity', count: { $sum: 1 } } }]);

    const unacknowledgedAlerts = await Alert.countDocuments({ acknowledged: false });
    const criticalAlerts = await Alert.countDocuments({ severity: 'critical', acknowledged: false });

    const knownPersonCount = await KnownPerson.countDocuments();

    const recentAlerts = await Alert.find().sort({ createdAt: -1 }).limit(5).populate('userId', 'name email');

    res.json({
      users: { total: userCount, byRole: usersByRole.reduce((acc, item) => { acc[item._id] = item.count; return acc; }, {}) },
      alerts: { total: alertCount, unacknowledged: unacknowledgedAlerts, critical: criticalAlerts, bySeverity: alertsBySeverity.reduce((acc, item) => { acc[item._id] = item.count; return acc; }, {}) },
      knownPersons: knownPersonCount,
      recentActivity: recentAlerts
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to get statistics' });
  }
};

export const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user._id.toString() === req.user._id.toString()) return res.status(400).json({ error: 'Cannot delete your own account' });

    await User.findByIdAndDelete(req.params.id);

    await AuditLog.create({ userId: req.user._id, action: 'delete_user', resource: 'user', details: { deletedUserId: user._id, deletedUserEmail: user.email } });

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
};

export const getAuditLogs = async (req, res) => {
  try {
    const { limit = 50, page = 1 } = req.query;
    const skip = (page - 1) * limit;

    const logs = await AuditLog.find().populate('userId', 'name email').sort({ timestamp: -1 }).limit(parseInt(limit)).skip(skip);
    const total = await AuditLog.countDocuments();

    res.json({ logs, pagination: { total, page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(total / limit) } });
  } catch (error) {
    console.error('Get audit logs error:', error);
    res.status(500).json({ error: 'Failed to get audit logs' });
  }
};
