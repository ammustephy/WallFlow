const UserService = require('../services/user.services');

exports.register = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        console.log(`Registration attempt for: ${email}`);

        const user = await UserService.registerUser(email, password);
        const tokenData = { _id: user._id, email: user.email };
        const token = await UserService.generateToken(tokenData);

        res.status(201).json({
            status: true,
            message: "User Registered Successfully",
            token,
            user: { id: user._id, email: user.email }
        });
    } catch (error) {
        next(error); // Pass to global error handler (add one in app.js if needed)
    }
};

exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        const user = await UserService.checkuser(email);
        console.log("-------user----------", user);

        if (!user) {
            return next(new Error('User not exist'));
        }

        const isMatch = await user.comparePassword(password);

        if (!isMatch) {
            return next(new Error('Password Invalid'));
        }

        const tokenData = { _id: user._id, email: user.email };
        const token = await UserService.generateToken(tokenData);

        res.status(200).json({
            status: true,
            message: "Login Successful",
            token,
            user: { id: user._id, email: user.email, displayName: user.displayName, profilePicture: user.profilePicture }
        });
    } catch (error) {
        next(error);
    }
};

exports.socialLogin = async (req, res, next) => {
    try {
        const { email, provider, displayName } = req.body;
        console.log(`Social Login attempt for: ${email} via ${provider}`);

        if (!email || !provider) {
            return res.status(400).json({ status: false, message: "Email and provider are required" });
        }

        const user = await UserService.socialLogin(email, provider, displayName);
        const tokenData = { _id: user._id, email: user.email };
        const token = await UserService.generateToken(tokenData);

        res.status(200).json({
            status: true,
            message: "Social Login Successful",
            token,
            user: { id: user._id, email: user.email, displayName: user.displayName, provider: user.provider, profilePicture: user.profilePicture }
        });
    } catch (error) {
        next(error);
    }
};

exports.updateUser = async (req, res, next) => {
    try {
        const { email, displayName, profilePicture } = req.body;
        console.log(`Update user attempt for: ${email}`);

        const user = await UserService.updateUser(email, { displayName, profilePicture });

        if (!user) {
            return res.status(404).json({ status: false, message: "User not found" });
        }

        res.status(200).json({
            status: true,
            message: "User Updated Successfully",
            user: { id: user._id, email: user.email, displayName: user.displayName, profilePicture: user.profilePicture }
        });
    } catch (error) {
        next(error);
    }
};