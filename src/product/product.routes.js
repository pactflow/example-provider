const router = require('express').Router();
const controller = require('./product.controller');

router.get("/product/:id", controller.getById);
router.delete("/product/:id", controller.deleteById);
router.get("/products", controller.getAll);

module.exports = router;