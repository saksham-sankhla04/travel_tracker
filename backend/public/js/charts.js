var purposeChart = null;
var transportChart = null;
var timelineChart = null;

var LABEL_MAP = {
  work: 'Work',
  education: 'Education',
  shopping: 'Shopping',
  leisure: 'Leisure',
  other: 'Other',
  bus: 'Bus',
  car: 'Car',
  bike: 'Bike',
  auto: 'Auto Rickshaw',
  train: 'Train',
  walk: 'Walking',
};

var PIE_COLORS = [
  '#3498db', '#2ecc71', '#e74c3c', '#f39c12', '#9b59b6', '#1abc9c',
];

function renderPurposeChart(byPurpose) {
  if (purposeChart) purposeChart.destroy();
  var ctx = document.getElementById('purpose-chart').getContext('2d');
  purposeChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: byPurpose.map(function (d) { return LABEL_MAP[d._id] || d._id; }),
      datasets: [{
        data: byPurpose.map(function (d) { return d.count; }),
        backgroundColor: PIE_COLORS.slice(0, byPurpose.length),
      }],
    },
    options: {
      responsive: true,
      plugins: {
        legend: { position: 'bottom' },
      },
    },
  });
}

function renderTransportChart(byTransport) {
  if (transportChart) transportChart.destroy();
  var ctx = document.getElementById('transport-chart').getContext('2d');
  transportChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: byTransport.map(function (d) { return LABEL_MAP[d._id] || d._id; }),
      datasets: [{
        data: byTransport.map(function (d) { return d.count; }),
        backgroundColor: PIE_COLORS.slice(0, byTransport.length),
      }],
    },
    options: {
      responsive: true,
      plugins: {
        legend: { position: 'bottom' },
      },
    },
  });
}

function renderTimelineChart(tripsPerDay) {
  if (timelineChart) timelineChart.destroy();
  var ctx = document.getElementById('timeline-chart').getContext('2d');
  timelineChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: tripsPerDay.map(function (d) { return d._id; }),
      datasets: [{
        label: 'Trips',
        data: tripsPerDay.map(function (d) { return d.count; }),
        backgroundColor: '#3498db',
        borderRadius: 4,
      }],
    },
    options: {
      responsive: true,
      scales: {
        y: { beginAtZero: true, ticks: { stepSize: 1 } },
        x: { title: { display: true, text: 'Date' } },
      },
      plugins: {
        legend: { display: false },
      },
    },
  });
}
