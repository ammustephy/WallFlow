const app = require("./app");
const db = require("./config/db")
const UserModel = require("./model/user.model")

const port = 3000;

app.get("/", (req, res) => {
    res.send("Hello world......wow.......")
});


app.listen(port, "0.0.0.0", () => {
    console.log(`Server running on all interfaces at port ${port}`);
});