const ProductRepository = require("./product.repository");

const repository = new ProductRepository();

exports.getAll = async (req, res) => {
    res.send(await repository.fetchAll())
};
exports.getById = async (req, res) => {
    const product = await repository.getById(req.params.id);
    product ? res.send(product) : res.status(404).send({message: "Product not found"})
};
exports.deleteById = async (req, res) => {
    const product = await repository.getById(req.params.id);
    if (product) {
        await repository.deleteById(req.params.id);
        res.status(204).send();
    } else {
        res.status(404).send({message: "Product not found"});
    }
};

exports.repository = repository;