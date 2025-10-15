const router = require('express').Router();
const controller = require('./product.controller');

router.get("/product/:id", controller.getById);
router.get("/products", controller.getAll);
router.post("/product", controller.create);

module.exports = router;