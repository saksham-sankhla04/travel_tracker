var map = null;
var markersLayer = null;

// Haversine distance in km between two lat/lng points
function haversineKm(lat1, lng1, lat2, lng2) {
  var R = 6371;
  var dLat = ((lat2 - lat1) * Math.PI) / 180;
  var dLng = ((lng2 - lng1) * Math.PI) / 180;
  var a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Haversine distance in metres
function haversineM(lat1, lng1, lat2, lng2) {
  return haversineKm(lat1, lng1, lat2, lng2) * 1000;
}

// Remove GPS jitter: drop consecutive points closer than minMetres
function filterJitter(points, minMetres) {
  if (points.length < 2) return points;
  var filtered = [points[0]];
  for (var i = 1; i < points.length; i++) {
    var last = filtered[filtered.length - 1];
    if (haversineM(last.lat, last.lng, points[i].lat, points[i].lng) >= minMetres) {
      filtered.push(points[i]);
    }
  }
  // Always keep the last point
  var lastPt = points[points.length - 1];
  if (filtered[filtered.length - 1] !== lastPt) {
    filtered.push(lastPt);
  }
  return filtered;
}

// Fetch road route from OSRM (free, no API key)
function fetchOSRMRoute(startLat, startLng, endLat, endLng) {
  var url =
    "https://router.project-osrm.org/route/v1/driving/" +
    startLng + "," + startLat + ";" +
    endLng + "," + endLat +
    "?overview=full&geometries=geojson";

  return fetch(url)
    .then(function (res) { return res.json(); })
    .then(function (data) {
      if (data.routes && data.routes.length > 0) {
        return data.routes[0].geometry.coordinates.map(function (c) {
          return [c[1], c[0]];
        });
      }
      return null;
    })
    .catch(function () { return null; });
}

// Snap GPS trace to roads using OSRM Map Matching API
function fetchOSRMMatch(routePoints) {
  // Build coordinates string: lng,lat;lng,lat;...
  var coords = routePoints.map(function (p) {
    return p.lng + "," + p.lat;
  }).join(";");

  // Set radius to 30m per point (GPS accuracy tolerance)
  var radiuses = routePoints.map(function () { return "30"; }).join(";");

  var url =
    "https://router.project-osrm.org/match/v1/driving/" +
    coords +
    "?overview=full&geometries=geojson&radiuses=" + radiuses;

  return fetch(url)
    .then(function (res) { return res.json(); })
    .then(function (data) {
      if (data.matchings && data.matchings.length > 0) {
        // Combine all matching segments into one path
        var allCoords = [];
        data.matchings.forEach(function (m) {
          m.geometry.coordinates.forEach(function (c) {
            allCoords.push([c[1], c[0]]);
          });
        });
        return allCoords;
      }
      return null;
    })
    .catch(function () { return null; });
}

// Draw a Google Maps-style route line (dark border + bright blue top)
function addStyledRoute(latLngs, layer) {
  // Border (darker, wider)
  var border = L.polyline(latLngs, {
    color: "#1a73a7",
    weight: 7,
    opacity: 0.4,
    lineCap: "round",
    lineJoin: "round",
  });
  layer.addLayer(border);

  // Main line (bright blue, narrower)
  var main = L.polyline(latLngs, {
    color: "#4285F4",
    weight: 4,
    opacity: 0.9,
    lineCap: "round",
    lineJoin: "round",
  });
  layer.addLayer(main);
}

function initMap() {
  if (map) return;

  map = L.map("map").setView([26.9, 75.8], 7);

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "&copy; OpenStreetMap contributors",
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

    var dist = haversineKm(
      trip.startLat,
      trip.startLng,
      trip.endLat,
      trip.endLng
    );

    var startLatLng = [trip.startLat, trip.startLng];
    var endLatLng = [trip.endLat, trip.endLng];
    bounds.push(startLatLng);
    bounds.push(endLatLng);

    // Start marker (green)
    var startMarker = L.circleMarker(startLatLng, {
      radius: 7,
      color: "#2ecc71",
      fillColor: "#2ecc71",
      fillOpacity: 0.8,
    }).bindPopup(
      "<strong>Trip #" +
        (index + 1) +
        " - Start</strong><br>" +
        "Purpose: " +
        capitalize(trip.tripPurpose) +
        "<br>" +
        "Transport: " +
        capitalize(trip.modeOfTransport) +
        "<br>" +
        "Passengers: " +
        trip.numberOfPassengers +
        "<br>" +
        "Distance: " +
        Math.round(dist) +
        " km<br>" +
        "Time: " +
        new Date(trip.tripStartTime).toLocaleString()
    );
    markersLayer.addLayer(startMarker);

    // End marker (red)
    var endMarker = L.circleMarker(endLatLng, {
      radius: 7,
      color: "#e74c3c",
      fillColor: "#e74c3c",
      fillOpacity: 0.8,
    }).bindPopup(
      "<strong>Trip #" +
        (index + 1) +
        " - End</strong><br>" +
        "Purpose: " +
        capitalize(trip.tripPurpose) +
        "<br>" +
        "Time: " +
        new Date(trip.tripEndTime).toLocaleString()
    );
    markersLayer.addLayer(endMarker);

    // Draw route
    if (trip.routePoints && trip.routePoints.length >= 2) {
      // Filter jitter (remove points < 30m apart)
      var cleaned = filterJitter(trip.routePoints, 30);

      if (cleaned.length >= 2) {
        // Snap GPS trace to actual roads via OSRM Map Matching
        fetchOSRMMatch(cleaned).then(function (snapped) {
          if (snapped && snapped.length >= 2) {
            addStyledRoute(snapped, markersLayer);
          } else {
            // Map matching failed — draw filtered GPS points
            var fallback = cleaned.map(function (p) { return [p.lat, p.lng]; });
            addStyledRoute(fallback, markersLayer);
          }
        });
      }
    } else {
      // No route points — fetch road route from OSRM
      fetchOSRMRoute(
        trip.startLat, trip.startLng,
        trip.endLat, trip.endLng
      ).then(function (roadLatLngs) {
        if (roadLatLngs) {
          addStyledRoute(roadLatLngs, markersLayer);
        } else {
          addStyledRoute([startLatLng, endLatLng], markersLayer);
        }
      });
    }
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
