const Slot = require('../models/Slot');
const Service = require('../models/Service');

exports.getAvailableSlots = async (req, res) => {
    try {
        const { service_id, date } = req.query;
        
        if (!service_id || !date) {
            return res.status(400).json({ message: 'Service ID and date are required' });
        }

        const slots = await Slot.findAvailable(service_id, date);
        res.json(slots);
    } catch (error) {
        console.error('Get slots error:', error);
        res.status(500).json({ message: 'Failed to get slots' });
    }
};

exports.createSlot = async (req, res) => {
    try {
        const slotData = {
            ...req.body,
            created_by: req.user.id
        };

        const slotId = await Slot.create(slotData);
        const slot = await Slot.findById(slotId);

        res.status(201).json({
            message: 'Slot created successfully',
            slot
        });
    } catch (error) {
        console.error('Create slot error:', error);
        res.status(500).json({ message: 'Failed to create slot' });
    }
};

exports.createBatchSlots = async (req, res) => {
    try {
        const { slots } = req.body;
        
        if (!Array.isArray(slots) || slots.length === 0) {
            return res.status(400).json({ message: 'Slots array is required' });
        }

        // Add created_by to each slot
        const slotsWithCreator = slots.map(slot => ({
            ...slot,
            created_by: req.user.id
        }));

        const slotIds = await Slot.createBatch(slotsWithCreator);
        
        res.status(201).json({
            message: `${slotIds.length} slots created successfully`,
            slot_ids: slotIds
        });
    } catch (error) {
        console.error('Create batch slots error:', error);
        res.status(500).json({ message: 'Failed to create slots' });
    }
};

exports.updateSlot = async (req, res) => {
    try {
        const updated = await Slot.update(req.params.id, req.body);
        if (!updated) {
            return res.status(400).json({ message: 'No updates provided or slot not found' });
        }

        const slot = await Slot.findById(req.params.id);
        res.json({
            message: 'Slot updated successfully',
            slot
        });
    } catch (error) {
        console.error('Update slot error:', error);
        res.status(500).json({ message: 'Failed to update slot' });
    }
};

exports.deleteSlot = async (req, res) => {
    try {
        const deleted = await Slot.delete(req.params.id);
        if (!deleted) {
            return res.status(400).json({ 
                message: 'Slot not found or cannot be deleted (may be booked)' 
            });
        }

        res.json({ message: 'Slot deleted successfully' });
    } catch (error) {
        console.error('Delete slot error:', error);
        res.status(500).json({ message: 'Failed to delete slot' });
    }
};

exports.getSlotsByDateRange = async (req, res) => {
    try {
        const { service_id, start_date, end_date } = req.query;
        
        if (!service_id || !start_date || !end_date) {
            return res.status(400).json({ 
                message: 'Service ID, start date, and end date are required' 
            });
        }

        const slots = await Slot.findByServiceAndDateRange(service_id, start_date, end_date);
        res.json(slots);
    } catch (error) {
        console.error('Get slots by date range error:', error);
        res.status(500).json({ message: 'Failed to get slots' });
    }
};