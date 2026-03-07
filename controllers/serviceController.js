const Service = require('../models/Service');
const Slot = require('../models/Slot');

exports.getAllServices = async (req, res) => {
    try {
        const services = await Service.findAll(req.query.includeInactive === 'true');
        res.json(services);
    } catch (error) {
        console.error('Get services error:', error);
        res.status(500).json({ message: 'Failed to get services' });
    }
};

exports.getServiceById = async (req, res) => {
    try {
        const service = await Service.findById(req.params.id);
        if (!service) {
            return res.status(404).json({ message: 'Service not found' });
        }
        res.json(service);
    } catch (error) {
        console.error('Get service error:', error);
        res.status(500).json({ message: 'Failed to get service' });
    }
};

exports.createService = async (req, res) => {
    try {
        const serviceId = await Service.create(req.body);
        const service = await Service.findById(serviceId);
        
        res.status(201).json({
            message: 'Service created successfully',
            service
        });
    } catch (error) {
        console.error('Create service error:', error);
        res.status(500).json({ message: 'Failed to create service' });
    }
};

exports.updateService = async (req, res) => {
    try {
        const updated = await Service.update(req.params.id, req.body);
        if (!updated) {
            return res.status(400).json({ message: 'No updates provided or service not found' });
        }
        
        const service = await Service.findById(req.params.id);
        res.json({
            message: 'Service updated successfully',
            service
        });
    } catch (error) {
        console.error('Update service error:', error);
        res.status(500).json({ message: 'Failed to update service' });
    }
};

exports.deleteService = async (req, res) => {
    try {
        const deleted = await Service.delete(req.params.id);
        if (!deleted) {
            return res.status(404).json({ message: 'Service not found' });
        }
        
        res.json({ message: 'Service deactivated successfully' });
    } catch (error) {
        console.error('Delete service error:', error);
        res.status(500).json({ message: 'Failed to delete service' });
    }
};

exports.getServiceStats = async (req, res) => {
    try {
        const stats = await Service.getStats();
        res.json(stats);
    } catch (error) {
        console.error('Get service stats error:', error);
        res.status(500).json({ message: 'Failed to get service statistics' });
    }
};

exports.getServiceSlots = async (req, res) => {
    try {
        const { date } = req.query;
        if (!date) {
            return res.status(400).json({ message: 'Date is required' });
        }
        
        const slots = await Slot.findAvailable(req.params.id, date);
        res.json(slots);
    } catch (error) {
        console.error('Get service slots error:', error);
        res.status(500).json({ message: 'Failed to get available slots' });
    }
};