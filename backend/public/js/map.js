var map = null;
var markersLayer = null;

// Haversine distance in km between two lat/lng points
function haversineKm(lat1, lng1, lat2, lng2) {
  var R = 6371;
  var dLat = (lat2 - lat1) * Math.PI / 180;
  var dLng = (lng2 - lng1) * Math.PI / 180;
  var a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function initMap() {
  if (map) return;

  // Center on Rajasthan
  map = L.map('map').setView([26.9, 75.8], 7);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 18,
  }).addTo(map);

  markersLayer = L.layerGroup().addTo(map);
}

function renderTripsMap(trips) {
  initMap();
  markersLayer.clearLayers();

  var bounds = [];

  trips.forEach(function (trip, index) {
    if (trip.startLat == null || trip.startLng == null) return;
    if (trip.endLat == null || trip.endLng == null) return;

    // Only show trips where start and end are at least 2km apart
    var dist = haversineKm(trip.startLat, trip.startLng, trip.endLat, trip.endLng);
    if (dist < 2) return;

    var startLatLng = [trip.startLat, trip.startLng];
    var endLatLng = [trip.endLat, trip.endLng];
    bounds.push(startLatLng);
    bounds.push(endLatLng);

    // Start marker (green)
    var startMarker = L.circleMarker(startLatLng, {
      radius: 7,
      color: '#2ecc71',
      fillColor: '#2ecc71',
      fillOpacity: 0.8,
    }).bindPopup(
      '<strong>Trip #' + (index + 1) + ' - Start</strong><br>' +
      'Purpose: ' + capitalize(trip.tripPurpose) + '<br>' +
      'Transport: ' + capitalize(trip.modeOfTransport) + '<br>' +
      'Passengers: ' + trip.numberOfPassengers + '<br>' +
      'Distance: ' + Math.round(dist) + ' km<br>' +
      'Time: ' + new Date(trip.tripStartTime).toLocaleString()
    );
    markersLayer.addLayer(startMarker);

    // End marker (red)
    var endMarker = L.circleMarker(endLatLng, {
      radius: 7,
      color: '#e74c3c',
      fillColor: '#e74c3c',
      fillOpacity: 0.8,
    }).bindPopup(
      '<strong>Trip #' + (index + 1) + ' - End</strong><br>' +
      'Purpose: ' + capitalize(trip.tripPurpose) + '<br>' +
      'Time: ' + new Date(trip.tripEndTime).toLocaleString()
    );
    markersLayer.addLayer(endMarker);

    // Dashed line from start to end
    var polyline = L.polyline([startLatLng, endLatLng], {
      color: '#3498db',
      weight: 2,
      dashArray: '5, 8',
      opacity: 0.6,
    });
    markersLayer.addLayer(polyline);
  });

  if (bounds.length > 0) {
    map.fitBounds(bounds, { padding: [30, 30] });
  }
}

function panMapToTrip(lat, lng) {
  if (map) {
    map.setView([lat, lng], 14);
  }
}
