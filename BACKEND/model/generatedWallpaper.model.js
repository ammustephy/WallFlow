const mongoose = require("mongoose");

const { Schema } = mongoose;

const generatedWallpaperSchema = new Schema({
    userId: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    prompt: {
        type: String,
        required: true
    },
    imageData: {
        type: String, // Base64 encoded image
        required: true
    },
    metadata: {
        model: String,
        generatedAt: Date,
        dimensions: {
            width: Number,
            height: Number
        }
    }
}, { timestamps: true });

const GeneratedWallpaperModel = mongoose.model('GeneratedWallpaper', generatedWallpaperSchema);

module.exports = GeneratedWallpaperModel;
