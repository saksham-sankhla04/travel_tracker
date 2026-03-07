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
    document.getElementById('stat-quality').textContent =
      buildQualitySummary(trips);

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

function buildQualitySummary(trips) {
  var total = trips.length;
  if (total === 0) return '--';

  var completedCount = trips.filter(function (trip) {
    return (
      trip.isAutoSubmitted !== true &&
      trip.tripPurpose &&
      trip.tripPurpose !== 'unknown' &&
      trip.modeOfTransport &&
      trip.modeOfTransport !== 'unknown' &&
      Number(trip.numberOfPassengers) > 0
    );
  }).length;

  var autoSavedCount = trips.filter(function (trip) {
    return (
      trip.isAutoSubmitted === true ||
      trip.tripPurpose === 'unknown' ||
      trip.modeOfTransport === 'unknown' ||
      Number(trip.numberOfPassengers) === 0
    );
  }).length;

  var completedPct = Math.round((completedCount / total) * 100);
  var autoSavedPct = Math.round((autoSavedCount / total) * 100);
  var syncedPct = 100;

  return (
    'Done ' +
    completedPct +
    '% | Auto ' +
    autoSavedPct +
    '% | Sync ' +
    syncedPct +
    '%'
  );
}

// Dark mode toggle
function initTheme() {
  var saved = localStorage.getItem('dashboard-theme');
  if (saved) document.documentElement.setAttribute('data-theme', saved);

  document.getElementById('theme-toggle').addEventListener('click', function () {
    var html = document.documentElement;
    var isDark = html.getAttribute('data-theme') === 'dark';
    var newTheme = isDark ? 'light' : 'dark';
    html.setAttribute('data-theme', newTheme);
    localStorage.setItem('dashboard-theme', newTheme);
    this.textContent = isDark ? '\u{1f319}' : '\u2600\ufe0f';

    // Re-render charts to pick up new theme colors
    if (AppState.stats) {
      renderPurposeChart(AppState.stats.byPurpose);
      renderTransportChart(AppState.stats.byTransport);
      renderTimelineChart(AppState.stats.tripsPerDay);
    }
  });

  // Set initial icon
  if (saved === 'dark') {
    document.getElementById('theme-toggle').textContent = '\u2600\ufe0f';
  }
}

document.addEventListener('DOMContentLoaded', function () {
  initTheme();
  fetchAndRender();
  document.getElementById('refresh-btn').addEventListener('click', fetchAndRender);
  initFilters();
  initMapToggles();
});
