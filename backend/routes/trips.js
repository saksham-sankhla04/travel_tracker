const express = require('express');
const Trip = require('../models/Trip');
const router = express.Router();

// POST /api/trips — save a new trip survey (with duplicate prevention)
router.post('/', async (req, res) => {
  try {
    // Check for duplicate: same start time, end time, and completedAt
    const existing = await Trip.findOne({
      tripStartTime: req.body.tripStartTime,
      tripEndTime: req.body.tripEndTime,
      surveyCompletedAt: req.body.surveyCompletedAt,
    });
    if (existing) {
      return res.status(201).json({ message: 'Trip already exists', trip: existing });
    }

    const trip = new Trip(req.body);
    await trip.save();
    res.status(201).json({ message: 'Trip saved', trip });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// GET /api/trips — retrieve all trips
router.get('/', async (req, res) => {
  try {
    const trips = await Trip.find().sort({ createdAt: -1 });
    res.json(trips);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/trips/stats — analytics for admin dashboard
router.get('/stats', async (req, res) => {
  try {
    const total = await Trip.countDocuments();

    const byPurpose = await Trip.aggregate([
      { $group: { _id: '$tripPurpose', count: { $sum: 1 } } },
    ]);

    const byTransport = await Trip.aggregate([
      { $group: { _id: '$modeOfTransport', count: { $sum: 1 } } },
    ]);

    const avgResult = await Trip.aggregate([
      { $group: { _id: null, avgPassengers: { $avg: '$numberOfPassengers' } } },
    ]);
    const avgPassengers = avgResult.length > 0
      ? Math.round(avgResult[0].avgPassengers * 10) / 10
      : 0;

    const tripsPerDay = await Trip.aggregate([
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$tripStartTime' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const durationResult = await Trip.aggregate([
      {
        $project: {
          durationMinutes: {
            $divide: [
              { $subtract: ['$tripEndTime', '$tripStartTime'] },
              60000,
            ],
          },
        },
      },
      { $group: { _id: null, avgDuration: { $avg: '$durationMinutes' } } },
    ]);
    const avgTripDurationMinutes = durationResult.length > 0
      ? Math.round(durationResult[0].avgDuration * 10) / 10
      : 0;

    res.json({ total, byPurpose, byTransport, avgPassengers, avgTripDurationMinutes, tripsPerDay });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/trips — delete all trips (for development/testing only)
router.delete('/', async (req, res) => {
  try {
    const result = await Trip.deleteMany({});
    res.json({ message: `Deleted ${result.deletedCount} trips` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
