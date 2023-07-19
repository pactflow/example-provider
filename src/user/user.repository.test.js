const User = require('./user');
const UserRepository = require('./user.repository');

describe("UserRepository", () => {
  it("has some users", () => {
    const userRepository = new UserRepository()
    return expect(userRepository.getById('1')).resolves.toEqual(new User("1", "user",  "user@mxmv.uk", "hunter2"));
  });
});
