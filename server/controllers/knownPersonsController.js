import KnownPerson from '../models/KnownPerson.js';

export const createKnownPerson = async (req, res) => {
  try {
    const { name, relationship, forUserId, notes, phoneNumber, email } = req.body;

    if (!name || !relationship || !forUserId) {
      return res.status(400).json({ error: 'Name, relationship, and forUserId are required' });
    }

    const images = req.files.map(file => ({ filename: file.filename, path: `/uploads/${file.filename}`, uploadedAt: new Date() }));

    const knownPerson = new KnownPerson({ name, relationship, addedBy: req.user._id, forUser: forUserId, images, notes, phoneNumber, email });
    await knownPerson.save();

    res.status(201).json({ message: 'Known person added successfully', person: knownPerson });
  } catch (error) {
    console.error('Create known person error:', error);
    res.status(500).json({ error: 'Failed to add known person' });
  }
};

export const listKnownPersons = async (req, res) => {
  try {
    const { forUserId } = req.query;
    let query = {};
    if (req.user.role === 'admin') {
      if (forUserId) query.forUser = forUserId;
    } else if (req.user.role === 'relative') {
      query.addedBy = req.user._id;
      if (forUserId) query.forUser = forUserId;
    } else {
      query.forUser = req.user._id;
    }

    const knownPersons = await KnownPerson.find(query).populate('addedBy', 'name email').populate('forUser', 'name email').sort({ createdAt: -1 });
    res.json({ knownPersons });
  } catch (error) {
    console.error('Get known persons error:', error);
    res.status(500).json({ error: 'Failed to get known persons' });
  }
};

export const getKnownPerson = async (req, res) => {
  try {
    const knownPerson = await KnownPerson.findById(req.params.id).populate('addedBy', 'name email').populate('forUser', 'name email');
    if (!knownPerson) return res.status(404).json({ error: 'Known person not found' });

    const canView = req.user.role === 'admin' || knownPerson.addedBy._id.toString() === req.user._id.toString() || knownPerson.forUser._id.toString() === req.user._id.toString();
    if (!canView) return res.status(403).json({ error: 'Access denied' });

    res.json({ knownPerson });
  } catch (error) {
    console.error('Get known person error:', error);
    res.status(500).json({ error: 'Failed to get known person' });
  }
};

export const updateKnownPerson = async (req, res) => {
  try {
    const knownPerson = await KnownPerson.findById(req.params.id);
    if (!knownPerson) return res.status(404).json({ error: 'Known person not found' });

    const canEdit = req.user.role === 'admin' || knownPerson.addedBy.toString() === req.user._id.toString();
    if (!canEdit) return res.status(403).json({ error: 'Access denied' });

    const { name, relationship, notes, phoneNumber, email } = req.body;
    if (name) knownPerson.name = name;
    if (relationship) knownPerson.relationship = relationship;
    if (notes !== undefined) knownPerson.notes = notes;
    if (phoneNumber !== undefined) knownPerson.phoneNumber = phoneNumber;
    if (email !== undefined) knownPerson.email = email;

    await knownPerson.save();

    res.json({ message: 'Known person updated successfully', knownPerson });
  } catch (error) {
    console.error('Update known person error:', error);
    res.status(500).json({ error: 'Failed to update known person' });
  }
};

export const addImages = async (req, res) => {
  try {
    const knownPerson = await KnownPerson.findById(req.params.id);
    if (!knownPerson) return res.status(404).json({ error: 'Known person not found' });

    const canEdit = req.user.role === 'admin' || knownPerson.addedBy.toString() === req.user._id.toString();
    if (!canEdit) return res.status(403).json({ error: 'Access denied' });

    const newImages = req.files.map(file => ({ filename: file.filename, path: `/uploads/${file.filename}`, uploadedAt: new Date() }));
    knownPerson.images.push(...newImages);
    await knownPerson.save();

    res.json({ message: 'Images added successfully', knownPerson });
  } catch (error) {
    console.error('Add images error:', error);
    res.status(500).json({ error: 'Failed to add images' });
  }
};

export const deleteKnownPerson = async (req, res) => {
  try {
    const knownPerson = await KnownPerson.findById(req.params.id);
    if (!knownPerson) return res.status(404).json({ error: 'Known person not found' });

    const canDelete = req.user.role === 'admin' || knownPerson.addedBy.toString() === req.user._id.toString();
    if (!canDelete) return res.status(403).json({ error: 'Access denied' });

    await KnownPerson.findByIdAndDelete(req.params.id);
    res.json({ message: 'Known person deleted successfully' });
  } catch (error) {
    console.error('Delete known person error:', error);
    res.status(500).json({ error: 'Failed to delete known person' });
  }
};
