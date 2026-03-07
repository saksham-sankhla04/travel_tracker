// Shared application state and label maps
var AppState = {
  trips: [],
  stats: null,
  currentMapView: 'routes', // 'routes' or 'heatmap'
  tablePagination: {
    currentPage: 1,
    pageSize: 10,
  },
};

var LABEL_MAP = {
  work: 'Work',
  education: 'Education',
  shopping: 'Shopping',
  leisure: 'Leisure',
  other: 'Other',
  unknown: 'Unknown',
  bus: 'Bus',
  car: 'Car',
  bike: 'Bike',
  auto: 'Auto Rickshaw',
  train: 'Train',
  walk: 'Walking',
};

// Build query string from current filter inputs
function buildQueryString() {
  var params = [];
  var from = document.getElementById('filter-date-from');
  var to = document.getElementById('filter-date-to');
  var transport = document.getElementById('filter-transport');
  var purpose = document.getElementById('filter-purpose');

  if (from && from.value) params.push('from=' + from.value);
  if (to && to.value) params.push('to=' + to.value);
  if (transport && transport.value) params.push('transport=' + transport.value);
  if (purpose && purpose.value) params.push('purpose=' + purpose.value);

  return params.length > 0 ? '?' + params.join('&') : '';
}
