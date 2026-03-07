function renderTripsTable(trips) {
  var tbody = document.getElementById('trips-tbody');
  tbody.innerHTML = '';
  var pageInfo = document.getElementById('table-page-info');
  var prevBtn = document.getElementById('table-prev-btn');
  var nextBtn = document.getElementById('table-next-btn');

  var pageSize = AppState.tablePagination.pageSize;
  var totalPages = Math.max(1, Math.ceil(trips.length / pageSize));
  var currentPage = Math.min(AppState.tablePagination.currentPage, totalPages);
  AppState.tablePagination.currentPage = currentPage;

  if (trips.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="9" class="empty-state">No trips recorded yet.</td></tr>';
    pageInfo.textContent = 'Page 1 of 1';
    prevBtn.disabled = true;
    nextBtn.disabled = true;
    return;
  }

  var startIndex = (currentPage - 1) * pageSize;
  var endIndex = startIndex + pageSize;
  var pageTrips = trips.slice(startIndex, endIndex);

  pageTrips.forEach(function (trip, index) {
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
      '<td>' + (startIndex + index + 1) + '</td>' +
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

  pageInfo.textContent = 'Page ' + currentPage + ' of ' + totalPages;
  prevBtn.disabled = currentPage <= 1;
  nextBtn.disabled = currentPage >= totalPages;
}

function initTripsPagination() {
  var prevBtn = document.getElementById('table-prev-btn');
  var nextBtn = document.getElementById('table-next-btn');
  var pageSizeSelect = document.getElementById('table-page-size');

  prevBtn.addEventListener('click', function () {
    if (AppState.tablePagination.currentPage > 1) {
      AppState.tablePagination.currentPage--;
      renderTripsTable(AppState.trips || []);
    }
  });

  nextBtn.addEventListener('click', function () {
    var trips = AppState.trips || [];
    var totalPages = Math.max(
      1,
      Math.ceil(trips.length / AppState.tablePagination.pageSize)
    );
    if (AppState.tablePagination.currentPage < totalPages) {
      AppState.tablePagination.currentPage++;
      renderTripsTable(trips);
    }
  });

  pageSizeSelect.addEventListener('change', function () {
    AppState.tablePagination.pageSize = Number(pageSizeSelect.value) || 10;
    AppState.tablePagination.currentPage = 1;
    renderTripsTable(AppState.trips || []);
  });
}

function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
}
