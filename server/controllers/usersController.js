import User from '../models/User.js';

export const getProfile = async (req, res) => {
  try {
    res.json({ user: req.user });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { name, emergencyContacts, settings } = req.body;

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (name) user.name = name;
    if (emergencyContacts) user.emergencyContacts = emergencyContacts;
    if (settings) user.settings = { ...user.settings, ...settings };

    await user.save();

    res.json({ message: 'Profile updated successfully', user });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

export const connectUser = async (req, res) => {
  try {
    const { targetUserId } = req.body;

    if (!targetUserId) {
      return res.status(400).json({ error: 'Target user ID is required' });
    }

    const targetUser = await User.findById(targetUserId);
    if (!targetUser) return res.status(404).json({ error: 'User not found' });

    const currentUser = await User.findById(req.user._id);
    if (!currentUser) return res.status(404).json({ error: 'Current user not found' });

    if (!currentUser.connectedUsers.includes(targetUserId)) {
      currentUser.connectedUsers.push(targetUserId);
      await currentUser.save();
    }

    res.json({
      message: 'Connected successfully',
      connectedUser: {
        id: targetUser._id,
        name: targetUser.name,
        email: targetUser.email,
        role: targetUser.role
      }
    });
  } catch (error) {
    console.error('Connect user error:', error);
    res.status(500).json({ error: 'Failed to connect' });
  }
};

export const getConnectedUsers = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('connectedUsers', 'name email role');
    res.json({ connectedUsers: user.connectedUsers });
  } catch (error) {
    console.error('Get connected users error:', error);
    res.status(500).json({ error: 'Failed to get connected users' });
  }
};
