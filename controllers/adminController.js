const Booking = require('../models/Booking');
const Service = require('../models/Service');
const User = require('../models/User');
const Notification = require('../models/Notification');

exports.getAllBookings = async (req, res) => {
    try {
        const filters = {
            status: req.query.status,
            date: req.query.date,
            service_id: req.query.service_id
        };
        
        const bookings = await Booking.findAll(filters);
        res.json(bookings);
    } catch (error) {
        console.error('Get all bookings error:', error);
        res.status(500).json({ message: 'Failed to get bookings' });
    }
};

exports.updateBookingStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const validStatuses = ['confirmed', 'completed', 'cancelled'];
        
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        await Booking.updateStatus(req.params.id, status, null, true);

        // Get booking details for notification
        const booking = await Booking.findById(req.params.id);
        
        // Create notification for user
        await Notification.create({
            user_id: booking.user_id,
            booking_id: req.params.id,
            message: `Your booking for ${booking.service_name} has been ${status}.`,
            type: `booking_${status}`
        });

        res.json({ 
            message: `Booking ${status} successfully`,
            booking
        });
    } catch (error) {
        console.error('Update booking status error:', error);
        res.status(500).json({ message: 'Failed to update booking status' });
    }
};

exports.getDashboardStats = async (req, res) => {
    try {
        // Get today's date
        const today = new Date().toISOString().split('T')[0];
        
        // Get various stats
        const totalBookings = await Booking.getStats(null, true);
        const totalServices = await Service.getStats();
        const totalUsers = (await User.getAllUsers()).length;
        
        // Get today's bookings
        const todayBookings = await Booking.findAll({ date: today });

        res.json({
            total_bookings: totalBookings.total,
            pending_bookings: totalBookings.pending,
            confirmed_bookings: totalBookings.confirmed,
            completed_bookings: totalBookings.completed,
            cancelled_bookings: totalBookings.cancelled,
            total_services: totalServices.active_services,
            total_users: totalUsers,
            today_bookings: todayBookings.length,
            recent_bookings: todayBookings.slice(0, 5)
        });
    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({ message: 'Failed to get dashboard statistics' });
    }
};

exports.getBookingAnalytics = async (req, res) => {
    try {
        const { start_date, end_date } = req.query;
        
        // Get bookings in date range
        const bookings = await Booking.findAll({
            date_start: start_date,
            date_end: end_date
        });

        // Group by date
        const analytics = bookings.reduce((acc, booking) => {
            const date = booking.date;
            if (!acc[date]) {
                acc[date] = {
                    date,
                    total: 0,
                    confirmed: 0,
                    completed: 0,
                    cancelled: 0
                };
            }
            
            acc[date].total++;
            if (booking.status === 'confirmed') acc[date].confirmed++;
            if (booking.status === 'completed') acc[date].completed++;
            if (booking.status === 'cancelled') acc[date].cancelled++;
            
            return acc;
        }, {});

        res.json(Object.values(analytics));
    } catch (error) {
        console.error('Get analytics error:', error);
        res.status(500).json({ message: 'Failed to get analytics' });
    }
};