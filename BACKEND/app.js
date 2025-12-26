const express = require("express");
const cors = require('cors');
const userRouter = require('./routers/user.route');

const app = express();

// JSON parsing (built-in) - Increased limit for Base64 images
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Request Logger
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Static files (for wallpaper uploads later)
app.use('/uploads', express.static('uploads'));

// CORS config - Allow all origins
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "ngrok-skip-browser-warning"]
}));

// Routes
app.use('/', userRouter);

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Wallflow Auth Backend is healthy! 🚀' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ status: false, error: err.message });
});

// 404 handler (no path wildcard—Express auto-matches unmatched routes)
app.use((req, res) => {
  res.status(404).json({ status: false, error: 'Route not found' });
});

module.exports = app;