const mongoose = require('mongoose');

const tripPurposeValues = ['work', 'education', 'shopping', 'leisure', 'other', 'unknown'];
const transportModeValues = ['bus', 'car', 'bike', 'auto', 'train', 'walk', 'unknown'];

const tripSchema = new mongoose.Schema({
  tripStartTime: { type: Date, required: true },
  tripEndTime: { type: Date, required: true },
  tripPurpose: {
    type: String,
    default: 'unknown',
    validate: {
      validator: (value) => value == null || tripPurposeValues.includes(value),
      message: 'Invalid tripPurpose value',
    },
  },
  modeOfTransport: {
    type: String,
    default: 'unknown',
    validate: {
      validator: (value) => value == null || transportModeValues.includes(value),
      message: 'Invalid modeOfTransport value',
    },
  },
  numberOfPassengers: {
    type: Number,
    default: 0,
    validate: {
      validator: (value) => value == null || value >= 0,
      message: 'numberOfPassengers must be >= 0',
    },
  },
  surveyCompletedAt: { type: Date, default: null },
  isAutoSubmitted: { type: Boolean, default: false },
  startLat: { type: Number },
  startLng: { type: Number },
  endLat: { type: Number },
  endLng: { type: Number },
  routePoints: [{
    lat: { type: Number },
    lng: { type: Number },
  }],
}, { timestamps: true });

module.exports = mongoose.model('Trip', tripSchema);
