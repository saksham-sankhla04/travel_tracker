const mongoose = require('mongoose');

const tripSchema = new mongoose.Schema({
  tripStartTime: { type: Date, required: true },
  tripEndTime: { type: Date, required: true },
  tripPurpose: {
    type: String,
    enum: ['work', 'education', 'shopping', 'leisure', 'other'],
    required: true,
  },
  modeOfTransport: {
    type: String,
    enum: ['bus', 'car', 'bike', 'auto', 'train', 'walk'],
    required: true,
  },
  numberOfPassengers: { type: Number, required: true, min: 1 },
  surveyCompletedAt: { type: Date, required: true },
  startLat: { type: Number },
  startLng: { type: Number },
  endLat: { type: Number },
  endLng: { type: Number },
}, { timestamps: true });

module.exports = mongoose.model('Trip', tripSchema);
