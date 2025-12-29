const CustomWallpaperModel = require('../model/customWallpaper.model');
const UserModel = require('../model/user.model');

// Save custom wallpaper
exports.saveCustomWallpaper = async (req, res) => {
    try {
        const { email, imageData, metadata } = req.body;

        if (!imageData) {
            return res.status(400).json({ message: 'Image data is required' });
        }

        // Check if user is premium
        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (!user.isPremium) {
            return res.status(403).json({ message: 'Premium subscription required' });
        }

        const wallpaper = new CustomWallpaperModel({
            userId: user._id,
            imageData: imageData,
            metadata: metadata || {}
        });

        await wallpaper.save();

        res.json({
            success: true,
            wallpaper: {
                id: wallpaper._id,
                createdAt: wallpaper.createdAt
            }
        });
    } catch (error) {
        console.error('Save custom wallpaper error:', error);
        res.status(500).json({ message: 'Failed to save wallpaper', error: error.message });
    }
};

// Get user's custom wallpapers
exports.getMyCustomWallpapers = async (req, res) => {
    try {
        const { email } = req.query;

        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const wallpapers = await CustomWallpaperModel.find({ userId: user._id })
            .sort({ createdAt: -1 })
            .limit(50);

        res.json({ wallpapers });
    } catch (error) {
        console.error('Get custom wallpapers error:', error);
        res.status(500).json({ message: 'Failed to get wallpapers', error: error.message });
    }
};

// Delete custom wallpaper
exports.deleteCustomWallpaper = async (req, res) => {
    try {
        const { email } = req.body;
        const { id } = req.params;

        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const wallpaper = await CustomWallpaperModel.findOne({ _id: id, userId: user._id });
        if (!wallpaper) {
            return res.status(404).json({ message: 'Wallpaper not found' });
        }

        await CustomWallpaperModel.deleteOne({ _id: id });

        res.json({ message: 'Wallpaper deleted successfully' });
    } catch (error) {
        console.error('Delete wallpaper error:', error);
        res.status(500).json({ message: 'Failed to delete wallpaper', error: error.message });
    }
};
