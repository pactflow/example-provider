const Product = require("./product");
const ProductRepository = require("./product.repository");

const repository = new ProductRepository();

exports.getAll = async (req, res) => {
    res.send(await repository.fetchAll())
};
exports.getById = async (req, res) => {
    const product = await repository.getById(req.params.id);
    product ? res.send(product) : res.status(404).send({message: "Product not found"})
};

exports.create = async (req, res) => {
  try {
    return res.send(new Product(req.body).id);
  } catch {
    res.status(400).send({ message: "invalid product" });
  }
};
exports.repository = repository;