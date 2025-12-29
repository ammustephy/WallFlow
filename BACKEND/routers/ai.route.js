const express = require('express');
const router = express.Router();
const aiController = require('../controller/ai.controller');

// Generate wallpaper from prompt
router.post('/generate-wallpaper', aiController.generateWallpaper);

// Get AI prompt suggestions
router.post('/suggest-prompts', aiController.suggestPrompts);

// Get user's generated wallpapers
router.get('/my-generated', aiController.getMyGeneratedWallpapers);

// Delete generated wallpaper
router.delete('/generated/:id', aiController.deleteGeneratedWallpaper);

module.exports = router;
