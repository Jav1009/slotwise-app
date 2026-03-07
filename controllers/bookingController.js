const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const Slot = require('../models/Slot');
const Service = require('../models/Service');

exports.createBooking = async (req, res) => {
    try {
        const { service_id, slot_id, notes } = req.body;

        // Verify slot is available
        const isAvailable = await Slot.checkAvailability(slot_id);
        if (!isAvailable) {
            return res.status(409).json({ message: 'Slot is no longer available' });
        }

        // Get service details for notification
        const service = await Service.findById(service_id);
        const slot = await Slot.findById(slot_id);

        // Create booking
        const bookingData = {
            user_id: req.user.id,
            service_id,
            slot_id,
            notes
        };

        const bookingId = await Booking.create(bookingData);

        // Create notifications
        const dateStr = slot.date.toISOString().split('T')[0];
        const timeStr = slot.start_time.substring(0, 5);
        
        await Notification.createBookingNotifications(
            bookingId,
            req.user.id,
            service.name,
            dateStr,
            timeStr
        );

        // Get full booking details
        const booking = await Booking.findById(bookingId);

        res.status(201).json({
            message: 'Booking created successfully',
            booking
        });
    } catch (error) {
        console.error('Create booking error:', error);
        if (error.message === 'Slot is no longer available') {
            return res.status(409).json({ message: error.message });
        }
        res.status(500).json({ message: 'Failed to create booking' });
    }
};

exports.getMyBookings = async (req, res) => {
    try {
        const bookings = await Booking.findByUser(req.user.id);
        res.json(bookings);
    } catch (error) {
        console.error('Get my bookings error:', error);
        res.status(500).json({ message: 'Failed to get bookings' });
    }
};

exports.getBookingById = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id);
        
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        // Check if user owns this booking or is admin
        if (booking.user_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Not authorized to view this booking' });
        }

        res.json(booking);
    } catch (error) {
        console.error('Get booking error:', error);
        res.status(500).json({ message: 'Failed to get booking' });
    }
};

exports.cancelBooking = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id);
        
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        // Check if user owns this booking
        if (booking.user_id !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized to cancel this booking' });
        }

        // Check if booking can be cancelled (not already completed/cancelled)
        if (booking.status === 'completed') {
            return res.status(400).json({ message: 'Completed bookings cannot be cancelled' });
        }

        if (booking.status === 'cancelled') {
            return res.status(400).json({ message: 'Booking is already cancelled' });
        }

        await Booking.updateStatus(req.params.id, 'cancelled', req.user.id);

        // Create cancellation notification
        await Notification.create({
            user_id: req.user.id,
            booking_id: req.params.id,
            message: `Your booking for ${booking.service_name} on ${booking.date} at ${booking.start_time} has been cancelled.`,
            type: 'booking_cancelled'
        });

        res.json({ message: 'Booking cancelled successfully' });
    } catch (error) {
        console.error('Cancel booking error:', error);
        res.status(500).json({ message: 'Failed to cancel booking' });
    }
};

exports.getUpcomingBookings = async (req, res) => {
    try {
        const bookings = await Booking.getUpcoming(req.user.id);
        res.json(bookings);
    } catch (error) {
        console.error('Get upcoming bookings error:', error);
        res.status(500).json({ message: 'Failed to get upcoming bookings' });
    }
};

exports.getMyStats = async (req, res) => {
    try {
        const stats = await Booking.getStats(req.user.id, false);
        res.json(stats);
    } catch (error) {
        console.error('Get booking stats error:', error);
        res.status(500).json({ message: 'Failed to get booking statistics' });
    }
};