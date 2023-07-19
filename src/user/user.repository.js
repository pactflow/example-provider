const User = require('./user');

class UserRepository {

    constructor() {
        
        this.Users = new Map([
            ["1", new User("1", "user", "user@mxmv.uk", "hunter2")],
            ["2", new User("2", "admin", "admin@mxmv.uk", "admin")],
        ]);
    }

    async getById(id) {
        return this.Users.get(id);
    }
}

module.exports = UserRepository;
