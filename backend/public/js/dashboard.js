async function fetchAndRender() {
  const refreshBtn = document.getElementById('refresh-btn');
  refreshBtn.disabled = true;
  refreshBtn.textContent = '\u21bb Loading...';

  try {
    const [statsRes, tripsRes] = await Promise.all([
      fetch('/api/trips/stats'),
      fetch('/api/trips'),
    ]);
    const stats = await statsRes.json();
    const trips = await tripsRes.json();

    // Overview cards
    document.getElementById('stat-total').textContent = stats.total;
    document.getElementById('stat-avg-passengers').textContent = stats.avgPassengers;
    document.getElementById('stat-avg-duration').textContent =
      stats.avgTripDurationMinutes + ' min';
    document.getElementById('stat-last-updated').textContent =
      new Date().toLocaleTimeString();

    // Charts
    renderPurposeChart(stats.byPurpose);
    renderTransportChart(stats.byTransport);
    renderTimelineChart(stats.tripsPerDay);

    // Table
    renderTripsTable(trips);

    // Map
    renderTripsMap(trips);
  } catch (err) {
    console.error('Failed to fetch data:', err);
  } finally {
    refreshBtn.disabled = false;
    refreshBtn.textContent = '\u21bb Refresh';
  }
}

document.addEventListener('DOMContentLoaded', function () {
  fetchAndRender();
  document.getElementById('refresh-btn').addEventListener('click', fetchAndRender);
});
