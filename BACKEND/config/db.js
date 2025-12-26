const mongoose = require("mongoose");

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/WallFlow';

const connectDB = async () => {
    try {
        await mongoose.connect(mongoUri);
        console.log("MongoDB connected to:",
            mongoUri.includes('mongodb+srv') ? 'Cloud Database' : 'Local Database'
        );
    } catch (err) {
        console.error("MongoDB connection failed:", err.message);
        process.exit(1);
    }
};

module.exports = connectDB;