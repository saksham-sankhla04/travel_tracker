function renderTripsTable(trips) {
  var tbody = document.getElementById('trips-tbody');
  tbody.innerHTML = '';

  if (trips.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="9" class="empty-state">No trips recorded yet.</td></tr>';
    return;
  }

  var recentTrips = trips.slice(0, 50);

  recentTrips.forEach(function (trip, index) {
    var start = new Date(trip.tripStartTime);
    var end = new Date(trip.tripEndTime);
    var durationMin = Math.round((end - start) / 60000);
    var hasLocation = trip.startLat != null && trip.startLng != null;

    var tr = document.createElement('tr');
    if (hasLocation) {
      tr.setAttribute('data-has-location', 'true');
      tr.addEventListener('click', function () {
        panMapToTrip(trip.startLat, trip.startLng);
      });
    }

    tr.innerHTML =
      '<td>' + (index + 1) + '</td>' +
      '<td>' + start.toLocaleDateString() + '</td>' +
      '<td>' + start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + '</td>' +
      '<td>' + end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + '</td>' +
      '<td>' + durationMin + ' min</td>' +
      '<td>' + capitalize(trip.tripPurpose) + '</td>' +
      '<td>' + capitalize(trip.modeOfTransport) + '</td>' +
      '<td>' + trip.numberOfPassengers + '</td>' +
      '<td>' + (hasLocation ? 'Yes' : '\u2014') + '</td>';

    tbody.appendChild(tr);
  });
}

function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
}
