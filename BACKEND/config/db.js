require('dotenv').config(); // Load .env vars

const mongoose = require("mongoose");

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/WallFlow';

const connectDB = async () => {
    try {
        await mongoose.connect(mongoUri, {
            serverSelectionTimeoutMS: 5000, // Fast fail if cluster unreachable
            maxPoolSize: 10                 // Connection pool for scalability
        });

        const dbType = mongoUri.includes('mongodb+srv') ? 'Cloud Database (Atlas)' : 'Local Database';
        console.log(`✅ MongoDB connected to: ${dbType}`);
        console.log(`📊 Using DB: ${mongoose.connection.name || 'admin'}`);

        // Listen for DB events
        mongoose.connection.on('disconnected', () => console.log('🔌 MongoDB disconnected'));
        mongoose.connection.on('error', (err) => console.error('❌ MongoDB error:', err.message));

    } catch (err) {
        console.error("❌ MongoDB connection failed:", err.message);
        console.error("💡 Check: URI/password/IP access (11.192.32.32 whitelisted?), or cluster status.");
        process.exit(1);
    }
};

module.exports = connectDB;