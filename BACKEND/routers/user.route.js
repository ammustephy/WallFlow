const { Router } = require('express');
const UserController = require('../controller/user.controller');

const router = Router();

router.post('/registration', UserController.register);
router.post('/login', UserController.login);
router.post('/social-login', UserController.socialLogin);
router.post('/update-user', UserController.updateUser);

module.exports = router;