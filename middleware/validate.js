const { body, validationResult } = require('express-validator');

const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ 
            message: 'Validation failed', 
            errors: errors.array() 
        });
    }
    next();
};

const authValidation = {
    register: [
        body('name').notEmpty().withMessage('Name is required'),
        body('email').isEmail().withMessage('Valid email is required'),
        body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
        body('phone').optional().isMobilePhone().withMessage('Valid phone number is required'),
        validate
    ],
    login: [
        body('email').isEmail().withMessage('Valid email is required'),
        body('password').notEmpty().withMessage('Password is required'),
        validate
    ]
};

const serviceValidation = {
    create: [
        body('name').notEmpty().withMessage('Service name is required'),
        body('duration_minutes').isInt({ min: 5 }).withMessage('Duration must be at least 5 minutes'),
        body('price').isFloat({ min: 0 }).withMessage('Price must be a positive number'),
        validate
    ]
};

const bookingValidation = {
    create: [
        body('service_id').isInt().withMessage('Valid service ID is required'),
        body('slot_id').isInt().withMessage('Valid slot ID is required'),
        validate
    ]
};

module.exports = {
    authValidation,
    serviceValidation,
    bookingValidation
};