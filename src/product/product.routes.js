const router = require('express').Router();
const controller = require('./product.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get("/product/:id", authMiddleware, controller.getById);
router.get("/products", authMiddleware, controller.getAll);

module.exports = router;