const userRepository = require("./user.repository");

const repository = new userRepository();

exports.getById = async (req, res) => {
    const user = await repository.getById(req.params.id);
    user ? res.send(user) : res.status(404).send({message: "user not found"})
};

exports.repository = repository;