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

// GET /api/trips/stats — basic analytics
router.get('/stats', async (req, res) => {
  try {
    const total = await Trip.countDocuments();
    const byPurpose = await Trip.aggregate([
      { $group: { _id: '$tripPurpose', count: { $sum: 1 } } },
    ]);
    const byTransport = await Trip.aggregate([
      { $group: { _id: '$modeOfTransport', count: { $sum: 1 } } },
    ]);
    res.json({ total, byPurpose, byTransport });
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
