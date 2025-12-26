const UserModel = require('../model/user.model');
const jwt = require('jsonwebtoken');

class UserService {
    static async registerUser(email, password) {
        try {
            const createUser = new UserModel({ email, password, provider: 'local' });
            return await createUser.save();
        } catch (err) {
            throw err; // Will be caught in controller
        }
    }

    static async socialLogin(email, provider, displayName) {
        try {
            let user = await UserModel.findOne({ email });
            if (!user) {
                user = new UserModel({ email, provider, displayName });
                await user.save();
            } else if (user.provider === 'local') {
                // Link social account or return error? Let's update provider for simplicity
                user.provider = provider;
                if (displayName) user.displayName = displayName;
                await user.save();
            }
            return user;
        } catch (error) {
            throw error;
        }
    }

    static async checkuser(email) {
        try {
            return await UserModel.findOne({ email });
        } catch (error) {
            throw error;
        }
    }

    static async updateUser(email, updateData) {
        try {
            // Ensure we are only updating valid fields to prevent injection or errors
            const { displayName, profilePicture } = updateData;
            return await UserModel.findOneAndUpdate(
                { email },
                { $set: { displayName, profilePicture } },
                { new: true }
            );
        } catch (error) {
            console.error("UserService updateUser Error:", error);
            throw error;
        }
    }

    static async generateToken(tokenData, jwt_expire = '1h') {
        try {
            const secretKey = process.env.JWT_SECRET; // From .env
            if (!secretKey) throw new Error('JWT_SECRET not set in .env');
            return jwt.sign(tokenData, secretKey, { expiresIn: jwt_expire });
        } catch (error) {
            throw error;
        }
    }
}

module.exports = UserService;