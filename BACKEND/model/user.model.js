const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const { Schema } = mongoose;

const userSchema = new Schema({
    email: {
        type: String,
        lowercase: true,
        required: true,
        unique: true,
    },
    password: {
        type: String,
        required: function () {
            return !this.provider; // Password required only if not social login
        }
    },
    provider: {
        type: String,
        enum: ['local', 'google', 'apple', 'facebook'],
        default: 'local'
    },
    displayName: {
        type: String
    },
    profilePicture: {
        type: String
    }
}, { timestamps: true }); // Added timestamps for createdAt/updatedAt

// Pre-save: Hash password (fixed salt to 10 rounds for consistency)
userSchema.pre('save', async function () {
    try {
        if (!this.isModified('password')) return;
        this.password = await bcrypt.hash(this.password, 10);
    } catch (error) {
        throw error;
    }
});

// Compare password method
userSchema.methods.comparePassword = async function (userPassword) {
    try {
        return await bcrypt.compare(userPassword, this.password);
    } catch (error) {
        throw error;
    }
};

// Use global mongoose.model (after connectDB in server)
const UserModel = mongoose.model('User', userSchema); // Capitalized for convention

module.exports = UserModel;