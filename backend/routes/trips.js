const express = require('express');
const Trip = require('../models/Trip');
const router = express.Router();

// Build MongoDB filter from query params (shared by /api/trips and /api/trips/stats)
function buildFilter(query) {
  const filter = {};
  if (query.from || query.to) {
    filter.tripStartTime = {};
    if (query.from) filter.tripStartTime.$gte = new Date(query.from);
    if (query.to) filter.tripStartTime.$lte = new Date(query.to + 'T23:59:59.999Z');
  }
  if (query.transport) filter.modeOfTransport = query.transport;
  if (query.purpose) filter.tripPurpose = query.purpose;
  return filter;
}

// POST /api/trips — save a new trip survey (with duplicate prevention)
router.post('/', async (req, res) => {
  try {
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

// GET /api/trips — retrieve trips (supports ?from, ?to, ?transport, ?purpose)
router.get('/', async (req, res) => {
  try {
    const filter = buildFilter(req.query);
    const trips = await Trip.find(filter).sort({ createdAt: -1 });
    res.json(trips);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/trips/stats — analytics (supports same query params as GET /api/trips)
router.get('/stats', async (req, res) => {
  try {
    const filter = buildFilter(req.query);
    const matchStage = Object.keys(filter).length > 0 ? [{ $match: filter }] : [];

    const total = await Trip.countDocuments(filter);

    const byPurpose = await Trip.aggregate([
      ...matchStage,
      { $group: { _id: '$tripPurpose', count: { $sum: 1 } } },
    ]);

    const byTransport = await Trip.aggregate([
      ...matchStage,
      { $group: { _id: '$modeOfTransport', count: { $sum: 1 } } },
    ]);

    const avgResult = await Trip.aggregate([
      ...matchStage,
      { $group: { _id: null, avgPassengers: { $avg: '$numberOfPassengers' } } },
    ]);
    const avgPassengers = avgResult.length > 0
      ? Math.round(avgResult[0].avgPassengers * 10) / 10
      : 0;

    const tripsPerDay = await Trip.aggregate([
      ...matchStage,
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$tripStartTime' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const durationResult = await Trip.aggregate([
      ...matchStage,
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

    // Total distance (haversine approximation in MongoDB)
    const distResult = await Trip.aggregate([
      ...matchStage,
      {
        $match: {
          startLat: { $ne: null }, startLng: { $ne: null },
          endLat: { $ne: null }, endLng: { $ne: null },
        },
      },
      {
        $project: {
          distKm: {
            $let: {
              vars: {
                dLat: { $degreesToRadians: { $subtract: ['$endLat', '$startLat'] } },
                dLng: { $degreesToRadians: { $subtract: ['$endLng', '$startLng'] } },
                lat1: { $degreesToRadians: '$startLat' },
                lat2: { $degreesToRadians: '$endLat' },
              },
              in: {
                $multiply: [
                  6371,
                  2,
                  {
                    $atan2: [
                      {
                        $sqrt: {
                          $add: [
                            { $multiply: [{ $sin: { $divide: ['$$dLat', 2] } }, { $sin: { $divide: ['$$dLat', 2] } }] },
                            {
                              $multiply: [
                                { $cos: '$$lat1' },
                                { $cos: '$$lat2' },
                                { $sin: { $divide: ['$$dLng', 2] } },
                                { $sin: { $divide: ['$$dLng', 2] } },
                              ],
                            },
                          ],
                        },
                      },
                      {
                        $sqrt: {
                          $subtract: [
                            1,
                            {
                              $add: [
                                { $multiply: [{ $sin: { $divide: ['$$dLat', 2] } }, { $sin: { $divide: ['$$dLat', 2] } }] },
                                {
                                  $multiply: [
                                    { $cos: '$$lat1' },
                                    { $cos: '$$lat2' },
                                    { $sin: { $divide: ['$$dLng', 2] } },
                                    { $sin: { $divide: ['$$dLng', 2] } },
                                  ],
                                },
                              ],
                            },
                          ],
                        },
                      },
                    ],
                  },
                ],
              },
            },
          },
        },
      },
      { $group: { _id: null, totalKm: { $sum: '$distKm' } } },
    ]);
    const totalDistanceKm = distResult.length > 0
      ? Math.round(distResult[0].totalKm * 10) / 10
      : 0;

    // Most common transport
    const topTransport = await Trip.aggregate([
      ...matchStage,
      { $group: { _id: '$modeOfTransport', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const mostCommonTransport = topTransport.length > 0 ? topTransport[0]._id : '';

    // Most common purpose
    const topPurpose = await Trip.aggregate([
      ...matchStage,
      { $group: { _id: '$tripPurpose', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const mostCommonPurpose = topPurpose.length > 0 ? topPurpose[0]._id : '';

    // Peak travel hour (IST = UTC+5:30)
    const peakResult = await Trip.aggregate([
      ...matchStage,
      {
        $project: {
          hour: {
            $mod: [
              { $add: [{ $hour: '$tripStartTime' }, 5, { $cond: [{ $gte: [{ $minute: '$tripStartTime' }, 30] }, 1, 0] }] },
              24,
            ],
          },
        },
      },
      { $group: { _id: '$hour', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const peakHour = peakResult.length > 0 ? peakResult[0]._id : 0;

    res.json({
      total,
      byPurpose,
      byTransport,
      avgPassengers,
      avgTripDurationMinutes,
      tripsPerDay,
      totalDistanceKm,
      mostCommonTransport,
      mostCommonPurpose,
      peakHour,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/trips/:id — delete a single trip by ID
router.delete('/:id', async (req, res) => {
  try {
    const result = await Trip.findByIdAndDelete(req.params.id);
    if (!result) return res.status(404).json({ error: 'Trip not found' });
    res.json({ message: 'Trip deleted', id: req.params.id });
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
