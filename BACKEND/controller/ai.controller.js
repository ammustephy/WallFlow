const { GoogleGenerativeAI } = require("@google/generative-ai");
const GeneratedWallpaperModel = require('../model/generatedWallpaper.model');
const UserModel = require('../model/user.model');

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GEMINI_API_KEY);

// Generate wallpaper from text prompt
exports.generateWallpaper = async (req, res) => {
    try {
        const { email, prompt } = req.body;

        if (!prompt) {
            return res.status(400).json({ message: 'Prompt is required' });
        }

        // Check if user is premium
        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Backend Sync: Allow short prompts for free users (same as frontend)
        const freeLimit = 50;
        if (!user.isPremium && prompt.length > freeLimit) {
            return res.status(403).json({
                message: 'Premium subscription required for long prompts',
                isFreeTierExceeded: true
            });
        }

        // Using Gemini to "enhance" or "validate" the prompt if key is available
        let enhancedPrompt = prompt;
        try {
            if (process.env.GOOGLE_GEMINI_API_KEY && process.env.GOOGLE_GEMINI_API_KEY !== 'your_gemini_api_key_here') {
                const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
                const enhancementPrompt = `As an AI wallpaper expert, refine this prompt into a highly detailed description for a stunning wallpaper: "${prompt}". Return ONLY the refined prompt text, no headers or meta-talk.`;

                const result = await model.generateContent([enhancementPrompt]);
                const response = await result.response;
                enhancedPrompt = response.text().trim();
            }
        } catch (e) {
            console.log('Gemini enhancement failed (probably invalid/missing key), falling back to original prompt');
        }

        // For image generation, we use a service that turns the prompt into a real image
        // This ensures the user sees a valid wallpaper instead of text placeholder.
        const encodedPrompt = encodeURIComponent(enhancedPrompt);
        const imageUrl = `https://pollinations.ai/p/${encodedPrompt}?width=1080&height=1920&seed=${Math.floor(Math.random() * 1000000)}&nologo=true`;

        // Save metadata to database
        const wallpaper = new GeneratedWallpaperModel({
            userId: user._id,
            prompt: prompt,
            imageData: imageUrl, // Storing the generated URL
            metadata: {
                model: 'gemini-1.5-flash + pollinations',
                generatedAt: new Date(),
                dimensions: {
                    width: 1080,
                    height: 1920
                }
            }
        });

        await wallpaper.save();

        res.json({
            success: true,
            wallpaper: {
                id: wallpaper._id,
                prompt: wallpaper.prompt,
                imageUrl: imageUrl, // Frontend looks for imageUrl or base64
                createdAt: wallpaper.createdAt
            }
        });
    } catch (error) {
        console.error('Generate wallpaper error:', error);
        res.status(500).json({ message: 'Failed to generate wallpaper', error: error.message });
    }
};

// Get AI-powered prompt suggestions
exports.suggestPrompts = async (req, res) => {
    try {
        const { email, basePrompt } = req.body;

        // Check if user is premium
        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (!user.isPremium) {
            return res.status(403).json({ message: 'Premium subscription required' });
        }

        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        const suggestionPrompt = `Based on the user's interest in "${basePrompt || 'wallpapers'}", suggest 5 creative and diverse wallpaper prompts. Each prompt should be detailed and visually descriptive. Format the response as a JSON array of strings, like: ["prompt1", "prompt2", "prompt3", "prompt4", "prompt5"]`;

        const result = await model.generateContent([suggestionPrompt]);
        const response = await result.response;
        const text = response.text();

        // Try to parse JSON from response
        let suggestions = [];
        try {
            // Extract JSON array from the response
            const jsonMatch = text.match(/\[.*\]/s);
            if (jsonMatch) {
                suggestions = JSON.parse(jsonMatch[0]);
            } else {
                // Fallback: split by newlines and clean up
                suggestions = text.split('\n')
                    .filter(line => line.trim().length > 0)
                    .slice(0, 5)
                    .map(line => line.replace(/^[-*\d.]+\s*/, '').replace(/^["']|["']$/g, ''));
            }
        } catch (parseError) {
            // If parsing fails, provide default suggestions
            suggestions = [
                "Serene mountain landscape at golden hour",
                "Abstract geometric patterns in vibrant colors",
                "Minimalist nature scene with soft gradients",
                "Cosmic nebula with stars and galaxies",
                "Urban cityscape at night with neon lights"
            ];
        }

        res.json({ suggestions });
    } catch (error) {
        console.error('Suggest prompts error:', error);
        res.status(500).json({ message: 'Failed to generate suggestions', error: error.message });
    }
};

// Get user's generated wallpapers
exports.getMyGeneratedWallpapers = async (req, res) => {
    try {
        const { email } = req.query;

        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const wallpapers = await GeneratedWallpaperModel.find({ userId: user._id })
            .sort({ createdAt: -1 })
            .limit(50);

        // Map imageData to imageUrl/base64 for frontend compatibility
        const mappedWallpapers = wallpapers.map(w => {
            const wallpaperObj = w.toObject();
            if (wallpaperObj.imageData && wallpaperObj.imageData.startsWith('http')) {
                wallpaperObj.imageUrl = wallpaperObj.imageData;
            } else {
                wallpaperObj.base64 = wallpaperObj.imageData;
            }
            return wallpaperObj;
        });

        res.json({ wallpapers: mappedWallpapers });
    } catch (error) {
        console.error('Get generated wallpapers error:', error);
        res.status(500).json({ message: 'Failed to get wallpapers', error: error.message });
    }
};

// Delete generated wallpaper
exports.deleteGeneratedWallpaper = async (req, res) => {
    try {
        const { email } = req.body;
        const { id } = req.params;

        const user = await UserModel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const wallpaper = await GeneratedWallpaperModel.findOne({ _id: id, userId: user._id });
        if (!wallpaper) {
            return res.status(404).json({ message: 'Wallpaper not found' });
        }

        await GeneratedWallpaperModel.deleteOne({ _id: id });

        res.json({ message: 'Wallpaper deleted successfully' });
    } catch (error) {
        console.error('Delete wallpaper error:', error);
        res.status(500).json({ message: 'Failed to delete wallpaper', error: error.message });
    }
};
