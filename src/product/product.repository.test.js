const ProductRepository = require('./product.repository')

describe("ProductRepository", () => {
  it("has some products", () => {
    const productRepository = new ProductRepository()
    return expect(productRepository.fetchAll()).resolves.toHaveLength(3);
  })
});
