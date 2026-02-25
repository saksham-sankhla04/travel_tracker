async function fetchAndRender() {
  var refreshBtn = document.getElementById('refresh-btn');
  refreshBtn.disabled = true;
  refreshBtn.textContent = '\u21bb Loading...';

  try {
    var qs = buildQueryString();
    var [statsRes, tripsRes] = await Promise.all([
      fetch('/api/trips/stats' + qs),
      fetch('/api/trips' + qs),
    ]);
    var stats = await statsRes.json();
    var trips = await tripsRes.json();

    AppState.stats = stats;
    AppState.trips = trips;

    // Overview cards
    document.getElementById('stat-total').textContent = stats.total;
    document.getElementById('stat-avg-passengers').textContent = stats.avgPassengers;
    document.getElementById('stat-avg-duration').textContent =
      stats.avgTripDurationMinutes + ' min';
    document.getElementById('stat-distance').textContent =
      stats.totalDistanceKm + ' km';
    document.getElementById('stat-top-transport').textContent =
      LABEL_MAP[stats.mostCommonTransport] || stats.mostCommonTransport || '--';
    document.getElementById('stat-top-purpose').textContent =
      LABEL_MAP[stats.mostCommonPurpose] || stats.mostCommonPurpose || '--';
    document.getElementById('stat-peak-hour').textContent =
      stats.total > 0 ? stats.peakHour + ':00' : '--';
    document.getElementById('stat-last-updated').textContent =
      new Date().toLocaleTimeString();

    // Charts
    renderPurposeChart(stats.byPurpose);
    renderTransportChart(stats.byTransport);
    renderTimelineChart(stats.tripsPerDay);

    // Table
    renderTripsTable(trips);

    // Map (respect current view mode)
    if (AppState.currentMapView === 'heatmap' && typeof renderHeatmap === 'function') {
      initMap();
      markersLayer.clearLayers();
      renderHeatmap(trips);
    } else {
      renderTripsMap(trips);
    }
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
  initFilters();
  initMapToggles();
});
