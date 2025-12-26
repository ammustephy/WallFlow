require('dotenv').config();
const app = require("./app");
const connectDB = require("./config/db");

const PORT = process.env.PORT || 3000;

// Listen on 0.0.0.0 to allow ALL local devices (Phone, Emulator, etc.)
connectDB()
    .then(() => {
        console.log('DB connected—starting server...');
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server is LIVE on port ${PORT}`);
            console.log(`Access it from phone via your IP (e.g. 192.168.x.x:${PORT})`);
        });
    })
    .catch((err) => {
        console.error('DB connection failed:', err.message);
        process.exit(1);
    });