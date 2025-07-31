const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();
const taskRoutes = require("./routes/taskRoutes");




const app = express();
app.use(cors());
app.use(express.json());


app.use("/api", taskRoutes);

const PORT = process.env.PORT || 5000;


mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log("MongoDB Connected"))
.catch((err) => console.error(err));

// Routes
app.get("/", (req, res) => res.send("ToDo API running"));

app.listen(PORT, () => console.log(`Server started on port ${PORT}`));
