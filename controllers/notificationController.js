const Notification = require('../models/Notification');

exports.getMyNotifications = async (req, res) => {
    try {
        const { unreadOnly } = req.query;
        const notifications = await Notification.findByUser(
            req.user.id, 
            unreadOnly === 'true'
        );
        
        res.json(notifications);
    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ message: 'Failed to get notifications' });
    }
};

exports.markAsRead = async (req, res) => {
    try {
        const marked = await Notification.markAsRead(req.params.id, req.user.id);
        
        if (!marked) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.json({ message: 'Notification marked as read' });
    } catch (error) {
        console.error('Mark as read error:', error);
        res.status(500).json({ message: 'Failed to mark notification as read' });
    }
};

exports.markAllAsRead = async (req, res) => {
    try {
        const count = await Notification.markAllAsRead(req.user.id);
        
        res.json({ 
            message: `${count} notifications marked as read` 
        });
    } catch (error) {
        console.error('Mark all as read error:', error);
        res.status(500).json({ message: 'Failed to mark notifications as read' });
    }
};

exports.getUnreadCount = async (req, res) => {
    try {
        const count = await Notification.getUnreadCount(req.user.id);
        res.json({ unread_count: count });
    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({ message: 'Failed to get unread count' });
    }
};