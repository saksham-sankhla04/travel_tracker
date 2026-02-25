// Leaflet.heat heatmap layer
var heatLayer = null;

function renderHeatmap(trips) {
  clearHeatmap();
  initMap();

  var heatPoints = [];

  trips.forEach(function (trip) {
    // Add start/end as higher-weight points
    if (trip.startLat != null && trip.startLng != null) {
      heatPoints.push([trip.startLat, trip.startLng, 0.6]);
    }
    if (trip.endLat != null && trip.endLng != null) {
      heatPoints.push([trip.endLat, trip.endLng, 0.6]);
    }

    // Add all route points for density
    if (trip.routePoints && trip.routePoints.length > 0) {
      trip.routePoints.forEach(function (p) {
        heatPoints.push([p.lat, p.lng, 0.3]);
      });
    }
  });

  if (heatPoints.length === 0) return;

  heatLayer = L.heatLayer(heatPoints, {
    radius: 25,
    blur: 15,
    maxZoom: 17,
    gradient: {
      0.2: '#3498db',
      0.4: '#2ecc71',
      0.6: '#f1c40f',
      0.8: '#e67e22',
      1.0: '#e74c3c',
    },
  }).addTo(map);

  // Fit bounds to heat points
  var bounds = heatPoints.map(function (p) { return [p[0], p[1]]; });
  if (bounds.length > 0) {
    map.fitBounds(bounds, { padding: [30, 30] });
  }
}

function clearHeatmap() {
  if (heatLayer && map) {
    map.removeLayer(heatLayer);
    heatLayer = null;
  }
}

// Map toggle logic
function initMapToggles() {
  var routesBtn = document.getElementById('map-routes-btn');
  var heatBtn = document.getElementById('map-heat-btn');

  if (!routesBtn || !heatBtn) return;

  routesBtn.addEventListener('click', function () {
    AppState.currentMapView = 'routes';
    routesBtn.classList.add('active');
    heatBtn.classList.remove('active');
    clearHeatmap();
    renderTripsMap(AppState.trips);
  });

  heatBtn.addEventListener('click', function () {
    AppState.currentMapView = 'heatmap';
    heatBtn.classList.add('active');
    routesBtn.classList.remove('active');
    markersLayer.clearLayers();
    renderHeatmap(AppState.trips);
  });
}
