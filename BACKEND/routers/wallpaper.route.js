const express = require('express');
const router = express.Router();
const wallpaperController = require('../controller/wallpaper.controller');

// Save custom wallpaper
router.post('/save-custom', wallpaperController.saveCustomWallpaper);

// Get user's custom wallpapers
router.get('/my-custom', wallpaperController.getMyCustomWallpapers);

// Delete custom wallpaper
router.delete('/custom/:id', wallpaperController.deleteCustomWallpaper);

module.exports = router;
