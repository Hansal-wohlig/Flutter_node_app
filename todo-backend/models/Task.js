const mongoose = require("mongoose");

const taskSchema = new mongoose.Schema({
  user: {
    type: String, // You can later change this to ObjectId if you add user accounts
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: ""
  },
  status: {
    type: String,
    enum: ["pending", "in-progress", "done"],
    default: "pending"
  },
  dueDate: {
    type: Date,
    default: null
  },
}, { timestamps: true });

module.exports = mongoose.model("Task", taskSchema);
