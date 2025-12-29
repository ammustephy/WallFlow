const mongoose = require("mongoose");

const { Schema } = mongoose;

const customWallpaperSchema = new Schema({
    userId: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    imageData: {
        type: String, // Base64 encoded image
        required: true
    },
    metadata: {
        filters: {
            brightness: Number,
            contrast: Number,
            saturation: Number,
            blur: Number
        },
        textElements: [{
            text: String,
            x: Number,
            y: Number,
            fontSize: Number,
            color: String,
            fontFamily: String
        }],
        shapes: [{
            type: String, // 'rectangle', 'circle', 'line'
            x: Number,
            y: Number,
            width: Number,
            height: Number,
            color: String
        }]
    }
}, { timestamps: true });

const CustomWallpaperModel = mongoose.model('CustomWallpaper', customWallpaperSchema);

module.exports = CustomWallpaperModel;
