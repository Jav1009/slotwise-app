/**
 * Comprehensive validation utility functions
 * Used throughout the application for data validation
 */

/**
 * Email validation
 * @param {string} email - Email to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateEmail = (email) => {
    if (!email) {
        return { isValid: false, message: 'Email is required' };
    }
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return { isValid: false, message: 'Please provide a valid email address' };
    }
    
    // Check for common email providers (optional)
    const allowedDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'edu'];
    const domain = email.split('@')[1];
    
    // You can uncomment this if you want to restrict domains
    // if (!allowedDomains.some(d => domain.includes(d))) {
    //     return { isValid: false, message: 'Email domain not supported' };
    // }
    
    return { isValid: true, message: 'Email is valid' };
};

/**
 * Password validation
 * @param {string} password - Password to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
const validatePassword = (password) => {
    if (!password) {
        return { isValid: false, message: 'Password is required' };
    }
    
    if (password.length < 6) {
        return { isValid: false, message: 'Password must be at least 6 characters long' };
    }
    
    if (password.length > 50) {
        return { isValid: false, message: 'Password must not exceed 50 characters' };
    }
    
    // Check for password strength (optional)
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);
    
    let strength = 0;
    if (hasUpperCase) strength++;
    if (hasLowerCase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChar) strength++;
    
    if (strength < 3) {
        return { 
            isValid: true, 
            message: 'Password strength: weak (add uppercase, numbers, or special characters)',
            strength: 'weak'
        };
    }
    
    return { 
        isValid: true, 
        message: 'Password is valid',
        strength: strength === 4 ? 'strong' : 'medium'
    };
};

/**
 * Name validation
 * @param {string} name - Name to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateName = (name) => {
    if (!name) {
        return { isValid: false, message: 'Name is required' };
    }
    
    if (name.length < 2) {
        return { isValid: false, message: 'Name must be at least 2 characters long' };
    }
    
    if (name.length > 100) {
        return { isValid: false, message: 'Name must not exceed 100 characters' };
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    const nameRegex = /^[a-zA-Z\s'-]+$/;
    if (!nameRegex.test(name)) {
        return { isValid: false, message: 'Name can only contain letters, spaces, hyphens, and apostrophes' };
    }
    
    return { isValid: true, message: 'Name is valid' };
};

/**
 * Phone number validation
 * @param {string} phone - Phone number to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
const validatePhone = (phone) => {
    if (!phone) {
        return { isValid: true, message: 'Phone number is optional' }; // Optional field
    }
    
    // Remove common phone number formatting
    const cleaned = phone.replace(/[\s\-\(\)]/g, '');
    
    // Check if it contains only digits
    const digitRegex = /^\d+$/;
    if (!digitRegex.test(cleaned)) {
        return { isValid: false, message: 'Phone number can only contain digits' };
    }
    
    // Check length (adjust based on your region)
    if (cleaned.length < 7 || cleaned.length > 15) {
        return { isValid: false, message: 'Phone number must be between 7 and 15 digits' };
    }
    
    return { isValid: true, message: 'Phone number is valid' };
};

/**
 * Date validation
 * @param {string} date - Date string to validate
 * @param {string} format - Expected format (default: YYYY-MM-DD)
 * @returns {Object} { isValid: boolean, message: string, date: Date }
 */
const validateDate = (date, format = 'YYYY-MM-DD') => {
    if (!date) {
        return { isValid: false, message: 'Date is required' };
    }
    
    // Parse date based on format
    let parsedDate;
    if (format === 'YYYY-MM-DD') {
        const parts = date.split('-');
        if (parts.length !== 3) {
            return { isValid: false, message: 'Date must be in YYYY-MM-DD format' };
        }
        
        const year = parseInt(parts[0]);
        const month = parseInt(parts[1]) - 1; // JS months are 0-indexed
        const day = parseInt(parts[2]);
        
        parsedDate = new Date(year, month, day);
        
        // Check if date is valid
        if (isNaN(parsedDate.getTime())) {
            return { isValid: false, message: 'Invalid date' };
        }
        
        // Check if components match (handles invalid dates like Feb 30)
        if (parsedDate.getFullYear() !== year || 
            parsedDate.getMonth() !== month || 
            parsedDate.getDate() !== day) {
            return { isValid: false, message: 'Invalid date' };
        }
    }
    
    return { 
        isValid: true, 
        message: 'Date is valid',
        date: parsedDate 
    };
};

/**
 * Time validation (HH:MM format)
 * @param {string} time - Time string to validate
 * @returns {Object} { isValid: boolean, message: string, hours: number, minutes: number }
 */
const validateTime = (time) => {
    if (!time) {
        return { isValid: false, message: 'Time is required' };
    }
    
    const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
    if (!timeRegex.test(time)) {
        return { isValid: false, message: 'Time must be in HH:MM format (24-hour)' };
    }
    
    const [hours, minutes] = time.split(':').map(Number);
    
    return { 
        isValid: true, 
        message: 'Time is valid',
        hours,
        minutes
    };
};

/**
 * Duration validation (in minutes)
 * @param {number} minutes - Duration in minutes
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateDuration = (minutes) => {
    if (minutes === undefined || minutes === null) {
        return { isValid: false, message: 'Duration is required' };
    }
    
    if (typeof minutes !== 'number' || isNaN(minutes)) {
        return { isValid: false, message: 'Duration must be a number' };
    }
    
    if (minutes < 5) {
        return { isValid: false, message: 'Duration must be at least 5 minutes' };
    }
    
    if (minutes > 480) { // 8 hours max
        return { isValid: false, message: 'Duration must not exceed 8 hours (480 minutes)' };
    }
    
    if (minutes % 5 !== 0) {
        return { isValid: false, message: 'Duration must be in multiples of 5 minutes' };
    }
    
    return { isValid: true, message: 'Duration is valid' };
};

/**
 * Price validation
 * @param {number} price - Price value
 * @returns {Object} { isValid: boolean, message: string }
 */
const validatePrice = (price) => {
    if (price === undefined || price === null) {
        return { isValid: false, message: 'Price is required' };
    }
    
    if (typeof price !== 'number' || isNaN(price)) {
        return { isValid: false, message: 'Price must be a number' };
    }
    
    if (price < 0) {
        return { isValid: false, message: 'Price cannot be negative' };
    }
    
    if (price > 999999.99) {
        return { isValid: false, message: 'Price exceeds maximum allowed value' };
    }
    
    // Check for reasonable decimal places
    const decimalPlaces = (price.toString().split('.')[1] || '').length;
    if (decimalPlaces > 2) {
        return { isValid: false, message: 'Price can only have up to 2 decimal places' };
    }
    
    return { isValid: true, message: 'Price is valid' };
};

/**
 * ID validation (database IDs)
 * @param {*} id - ID to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateId = (id) => {
    if (id === undefined || id === null) {
        return { isValid: false, message: 'ID is required' };
    }
    
    const numId = Number(id);
    if (isNaN(numId) || !Number.isInteger(numId)) {
        return { isValid: false, message: 'ID must be an integer' };
    }
    
    if (numId <= 0) {
        return { isValid: false, message: 'ID must be a positive integer' };
    }
    
    return { isValid: true, message: 'ID is valid' };
};

/**
 * Enum validation
 * @param {string} value - Value to validate
 * @param {Array} allowedValues - Array of allowed values
 * @param {string} fieldName - Name of the field (for error message)
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateEnum = (value, allowedValues, fieldName = 'Value') => {
    if (!value) {
        return { isValid: false, message: `${fieldName} is required` };
    }
    
    if (!allowedValues.includes(value)) {
        return { 
            isValid: false, 
            message: `${fieldName} must be one of: ${allowedValues.join(', ')}` 
        };
    }
    
    return { isValid: true, message: `${fieldName} is valid` };
};

/**
 * Booking status validation
 * @param {string} status - Booking status
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateBookingStatus = (status) => {
    const allowedStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
    return validateEnum(status, allowedStatuses, 'Booking status');
};

/**
 * Role validation
 * @param {string} role - User role
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateRole = (role) => {
    const allowedRoles = ['user', 'admin'];
    return validateEnum(role, allowedRoles, 'Role');
};

/**
 * Notification type validation
 * @param {string} type - Notification type
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateNotificationType = (type) => {
    const allowedTypes = ['welcome', 'booking_confirmed', 'booking_cancelled', 'new_booking', 'reminder'];
    return validateEnum(type, allowedTypes, 'Notification type');
};

/**
 * URL validation
 * @param {string} url - URL to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateUrl = (url) => {
    if (!url) {
        return { isValid: true, message: 'URL is optional' }; // Optional field
    }
    
    try {
        new URL(url);
        return { isValid: true, message: 'URL is valid' };
    } catch (error) {
        return { isValid: false, message: 'Please provide a valid URL' };
    }
};

/**
 * Notes validation
 * @param {string} notes - Notes text
 * @returns {Object} { isValid: boolean, message: string }
 */
const validateNotes = (notes) => {
    if (!notes) {
        return { isValid: true, message: 'Notes are optional' };
    }
    
    if (notes.length > 500) {
        return { isValid: false, message: 'Notes must not exceed 500 characters' };
    }
    
    // Check for potential XSS
    const xssPattern = /<script|javascript:|onerror|onload/i;
    if (xssPattern.test(notes)) {
        return { isValid: false, message: 'Notes contain invalid characters' };
    }
    
    return { isValid: true, message: 'Notes are valid' };
};

/**
 * Pagination validation
 * @param {number} page - Page number
 * @param {number} limit - Items per page
 * @returns {Object} { isValid: boolean, message: string, page: number, limit: number }
 */
const validatePagination = (page, limit) => {
    let validatedPage = 1;
    let validatedLimit = 10;
    
    if (page !== undefined) {
        const pageNum = Number(page);
        if (isNaN(pageNum) || !Number.isInteger(pageNum) || pageNum < 1) {
            return { isValid: false, message: 'Page must be a positive integer' };
        }
        validatedPage = pageNum;
    }
    
    if (limit !== undefined) {
        const limitNum = Number(limit);
        if (isNaN(limitNum) || !Number.isInteger(limitNum) || limitNum < 1 || limitNum > 100) {
            return { isValid: false, message: 'Limit must be an integer between 1 and 100' };
        }
        validatedLimit = limitNum;
    }
    
    return { 
        isValid: true, 
        message: 'Pagination parameters are valid',
        page: validatedPage,
        limit: validatedLimit
    };
};

/**
 * Validate date range
 * @param {string} startDate - Start date
 * @param {string} endDate - End date
 * @returns {Object} { isValid: boolean, message: string, start: Date, end: Date }
 */
const validateDateRange = (startDate, endDate) => {
    const startValidation = validateDate(startDate);
    if (!startValidation.isValid) {
        return { isValid: false, message: `Start date: ${startValidation.message}` };
    }
    
    const endValidation = validateDate(endDate);
    if (!endValidation.isValid) {
        return { isValid: false, message: `End date: ${endValidation.message}` };
    }
    
    if (endValidation.date < startValidation.date) {
        return { isValid: false, message: 'End date must be after start date' };
    }
    
    return { 
        isValid: true, 
        message: 'Date range is valid',
        start: startValidation.date,
        end: endValidation.date
    };
};

/**
 * Comprehensive service validation
 * @param {Object} serviceData - Service data to validate
 * @returns {Object} { isValid: boolean, errors: Array }
 */
const validateService = (serviceData) => {
    const errors = [];
    
    // Name validation
    const nameValidation = validateName(serviceData.name);
    if (!nameValidation.isValid) {
        errors.push({ field: 'name', message: nameValidation.message });
    }
    
    // Duration validation
    const durationValidation = validateDuration(serviceData.duration_minutes);
    if (!durationValidation.isValid) {
        errors.push({ field: 'duration_minutes', message: durationValidation.message });
    }
    
    // Price validation
    const priceValidation = validatePrice(serviceData.price);
    if (!priceValidation.isValid) {
        errors.push({ field: 'price', message: priceValidation.message });
    }
    
    // Description validation (optional)
    if (serviceData.description && serviceData.description.length > 1000) {
        errors.push({ field: 'description', message: 'Description must not exceed 1000 characters' });
    }
    
    // Image URL validation (optional)
    if (serviceData.image_url) {
        const urlValidation = validateUrl(serviceData.image_url);
        if (!urlValidation.isValid) {
            errors.push({ field: 'image_url', message: urlValidation.message });
        }
    }
    
    return {
        isValid: errors.length === 0,
        errors
    };
};

/**
 * Comprehensive booking validation
 * @param {Object} bookingData - Booking data to validate
 * @returns {Object} { isValid: boolean, errors: Array }
 */
const validateBooking = (bookingData) => {
    const errors = [];
    
    // User ID validation
    const userIdValidation = validateId(bookingData.user_id);
    if (!userIdValidation.isValid) {
        errors.push({ field: 'user_id', message: userIdValidation.message });
    }
    
    // Service ID validation
    const serviceIdValidation = validateId(bookingData.service_id);
    if (!serviceIdValidation.isValid) {
        errors.push({ field: 'service_id', message: serviceIdValidation.message });
    }
    
    // Slot ID validation
    const slotIdValidation = validateId(bookingData.slot_id);
    if (!slotIdValidation.isValid) {
        errors.push({ field: 'slot_id', message: slotIdValidation.message });
    }
    
    // Notes validation (optional)
    if (bookingData.notes) {
        const notesValidation = validateNotes(bookingData.notes);
        if (!notesValidation.isValid) {
            errors.push({ field: 'notes', message: notesValidation.message });
        }
    }
    
    return {
        isValid: errors.length === 0,
        errors
    };
};

/**
 * Sanitize input to prevent XSS
 * @param {string} input - Input string to sanitize
 * @returns {string} Sanitized string
 */
const sanitizeInput = (input) => {
    if (!input) return input;
    
    // Convert to string if not already
    const str = String(input);
    
    // Replace potentially dangerous characters
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
};

/**
 * Validate and sanitize user input
 * @param {Object} data - Data object to validate and sanitize
 * @param {Array} fields - Fields to process
 * @returns {Object} Sanitized data with validation results
 */
const validateAndSanitize = (data, fields) => {
    const result = {
        isValid: true,
        errors: [],
        sanitized: {}
    };
    
    for (const field of fields) {
        const value = data[field.name];
        
        // Skip if optional and not provided
        if (field.optional && (value === undefined || value === null)) {
            continue;
        }
        
        // Validate
        let validation;
        switch (field.type) {
            case 'email':
                validation = validateEmail(value);
                break;
            case 'password':
                validation = validatePassword(value);
                break;
            case 'name':
                validation = validateName(value);
                break;
            case 'phone':
                validation = validatePhone(value);
                break;
            case 'date':
                validation = validateDate(value);
                break;
            case 'time':
                validation = validateTime(value);
                break;
            case 'duration':
                validation = validateDuration(value);
                break;
            case 'price':
                validation = validatePrice(value);
                break;
            case 'id':
                validation = validateId(value);
                break;
            case 'url':
                validation = validateUrl(value);
                break;
            case 'notes':
                validation = validateNotes(value);
                break;
            case 'enum':
                validation = validateEnum(value, field.allowedValues, field.label);
                break;
            default:
                validation = { isValid: true };
        }
        
        if (!validation.isValid) {
            result.isValid = false;
            result.errors.push({
                field: field.name,
                message: validation.message
            });
        } else {
            // Sanitize string fields
            if (typeof value === 'string') {
                result.sanitized[field.name] = sanitizeInput(value);
            } else {
                result.sanitized[field.name] = value;
            }
        }
    }
    
    return result;
};

module.exports = {
    validateEmail,
    validatePassword,
    validateName,
    validatePhone,
    validateDate,
    validateTime,
    validateDuration,
    validatePrice,
    validateId,
    validateEnum,
    validateBookingStatus,
    validateRole,
    validateNotificationType,
    validateUrl,
    validateNotes,
    validatePagination,
    validateDateRange,
    validateService,
    validateBooking,
    sanitizeInput,
    validateAndSanitize
};