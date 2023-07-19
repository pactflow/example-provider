const router = require('express').Router();
const controller = require('./user.controller');

router.get("/user/:id", controller.getById);

module.exports = router;