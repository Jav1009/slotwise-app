// controllers/slotController.js
// Time slot management logic
// Using exports.functionName pattern

const db = require('../config/db');

/**
 * Get available slots for a service on a specific date
 * GET /api/slots/available/:serviceId?date=YYYY-MM-DD
 */
exports.getAvailableSlots = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: 'Date parameter is required (format: YYYY-MM-DD)'
      });
    }

    // Get all available slots for this service and date
    const [slots] = await db.query(
      `SELECT 
        ts.id,
        ts.service_id,
        ts.date,
        ts.start_time,
        ts.end_time,
        ts.is_available,
        s.name as service_name,
        s.duration_minutes
      FROM time_slots ts
      JOIN services s ON ts.service_id = s.id
      WHERE ts.service_id = ? 
        AND ts.date = ? 
        AND ts.is_available = TRUE
      ORDER BY ts.start_time ASC`,
      [serviceId, date]
    );

    res.json({
      success: true,
      data: { slots }
    });
  } catch (error) {
    console.error('Get available slots error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available slots'
    });
  }
};

/**
 * Get all slots (Admin view)
 * GET /api/slots?date=YYYY-MM-DD&service_id=X
 */
exports.getAllSlots = async (req, res) => {
  try {
    const { date, service_id } = req.query;

    let query = `
      SELECT 
        ts.id,
        ts.service_id,
        ts.date,
        ts.start_time,
        ts.end_time,
        ts.is_available,
        ts.created_at,
        s.name as service_name,
        s.duration_minutes,
        u.name as created_by_name
      FROM time_slots ts
      JOIN services s ON ts.service_id = s.id
      LEFT JOIN users u ON ts.created_by = u.id
      WHERE 1=1
    `;

    const params = [];

    if (date) {
      query += ' AND ts.date = ?';
      params.push(date);
    }

    if (service_id) {
      query += ' AND ts.service_id = ?';
      params.push(service_id);
    }

    query += ' ORDER BY ts.date DESC, ts.start_time ASC';

    const [slots] = await db.query(query, params);

    res.json({
      success: true,
      data: { slots }
    });
  } catch (error) {
    console.error('Get all slots error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch slots'
    });
  }
};

/**
 * Create new time slot (Admin only)
 * POST /api/slots
 */
exports.createSlot = async (req, res) => {
  try {
    const { service_id, date, start_time } = req.body;
    const adminId = req.user.id;

    // Validation
    if (!service_id || !date || !start_time) {
      return res.status(400).json({
        success: false,
        message: 'Service ID, date, and start time are required'
      });
    }

    // Get service duration to calculate end_time
    const [services] = await db.query(
      'SELECT duration_minutes FROM services WHERE id = ?',
      [service_id]
    );

    if (services.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    const duration = services[0].duration_minutes;

    // Calculate end_time
    // MySQL TIME_FORMAT and ADDTIME handle this properly
    const [result] = await db.query(
      `INSERT INTO time_slots 
       (service_id, date, start_time, end_time, is_available, created_by)
       VALUES (?, ?, ?, ADDTIME(?, SEC_TO_TIME(? * 60)), TRUE, ?)`,
      [service_id, date, start_time, start_time, duration, adminId]
    );

    res.status(201).json({
      success: true,
      message: 'Time slot created successfully',
      data: {
        slot: {
          id: result.insertId,
          service_id,
          date,
          start_time
        }
      }
    });
  } catch (error) {
    console.error('Create slot error:', error);

    // Check for duplicate slot conflict
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        success: false,
        message: 'A slot already exists for this time'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to create slot'
    });
  }
};

/**
 * Update slot availability (Admin only)
 * PUT /api/slots/:id
 */
exports.updateSlot = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_available } = req.body;

    if (typeof is_available !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'is_available must be true or false'
      });
    }

    // Check if slot has an active booking
    if (is_available === false) {
      const [bookings] = await db.query(
        `SELECT id FROM bookings 
         WHERE slot_id = ? AND status IN ('pending', 'confirmed')`,
        [id]
      );

      if (bookings.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Cannot block a slot that has an active booking'
        });
      }
    }

    const [result] = await db.query(
      'UPDATE time_slots SET is_available = ? WHERE id = ?',
      [is_available, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Slot not found'
      });
    }

    res.json({
      success: true,
      message: 'Slot updated successfully'
    });
  } catch (error) {
    console.error('Update slot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update slot'
    });
  }
};

/**
 * Delete slot (Admin only)
 * DELETE /api/slots/:id
 */
exports.deleteSlot = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if slot has any bookings (even cancelled ones)
    const [bookings] = await db.query(
      'SELECT id FROM bookings WHERE slot_id = ?',
      [id]
    );

    if (bookings.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete a slot that has booking history. Block it instead.'
      });
    }

    const [result] = await db.query(
      'DELETE FROM time_slots WHERE id = ?',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Slot not found'
      });
    }

    res.json({
      success: true,
      message: 'Slot deleted successfully'
    });
  } catch (error) {
    console.error('Delete slot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete slot'
    });
  }
};