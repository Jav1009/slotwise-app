// controllers/serviceController.js
// Business logic for service management
// Using exports.functionName pattern

const db = require('../config/db');

/**
 * Get all active services
 * GET /api/services
 */
exports.getAllServices = async (req, res) => {
    try {
        const [services] = await db.query(
            'SELECT * FROM services WHERE is_active = TRUE ORDER BY created_at DESC'
        );

        res.json({
            success: true,
            data: { services }
        });
    } catch (error) {
        console.error('Get services error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch services'
        });
    }
};

/**
 * Get single service by ID
 * GET /api/services/:id
 */
exports.getServiceById = async (req, res) => {
    try {
        const { id } = req.params;

        const [services] = await db.query(
            'SELECT * FROM services WHERE id = ? AND is_active = TRUE',
            [id]
        );

        if (services.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Service not found'
            });
        }

        res.json({
            success: true,
            data: { service: services[0] }
        });
    } catch (error) {
        console.error('Get service error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch service'
        });
    }
};

/**
 * Create new service (Admin only)
 * POST /api/services
 */
exports.createService = async (req, res) => {
    try {
        const { name, description, duration_minutes, price, image_url } = req.body;

        // Validation
        if (!name || !duration_minutes || !price) {
            return res.status(400).json({
                success: false,
                message: 'Name, duration, and price are required'
            });
        }

        if (duration_minutes < 1 || price < 0) {
            return res.status(400).json({
                success: false,
                message: 'Invalid duration or price'
            });
        }

        const [result] = await db.query(
            `INSERT INTO services (name, description, duration_minutes, price, image_url) 
       VALUES (?, ?, ?, ?, ?)`,
            [name, description || null, duration_minutes, price, image_url || null]
        );

        res.status(201).json({
            success: true,
            message: 'Service created successfully',
            data: {
                service: {
                    id: result.insertId,
                    name,
                    description,
                    duration_minutes,
                    price,
                    image_url
                }
            }
        });
    } catch (error) {
        console.error('Create service error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create service'
        });
    }
};

/**
 * Update service (Admin only)
 * PUT /api/services/:id
 */
exports.updateService = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, duration_minutes, price, image_url } = req.body;

        // Check if service exists
        const [existing] = await db.query('SELECT id FROM services WHERE id = ?', [id]);
        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Service not found'
            });
        }

        // Build update query dynamically
        const updates = [];
        const values = [];

        if (name) {
            updates.push('name = ?');
            values.push(name);
        }
        if (description !== undefined) {
            updates.push('description = ?');
            values.push(description);
        }
        if (duration_minutes) {
            updates.push('duration_minutes = ?');
            values.push(duration_minutes);
        }
        if (price !== undefined) {
            updates.push('price = ?');
            values.push(price);
        }
        if (image_url !== undefined) {
            updates.push('image_url = ?');
            values.push(image_url);
        }

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(id);

        await db.query(
            `UPDATE services SET ${updates.join(', ')} WHERE id = ?`,
            values
        );

        res.json({
            success: true,
            message: 'Service updated successfully'
        });
    } catch (error) {
        console.error('Update service error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update service'
        });
    }
};

/**
 * Soft delete service (Admin only)
 * DELETE /api/services/:id
 */
exports.deleteService = async (req, res) => {
    try {
        const { id } = req.params;

        // Soft delete - set is_active to FALSE
        const [result] = await db.query(
            'UPDATE services SET is_active = FALSE WHERE id = ?',
            [id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Service not found'
            });
        }

        res.json({
            success: true,
            message: 'Service deleted successfully'
        });
    } catch (error) {
        console.error('Delete service error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete service'
        });
    }
};