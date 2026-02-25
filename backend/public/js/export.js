// CSV Export — pure JS, no library needed
function exportCSV() {
  var trips = AppState.trips;
  if (!trips || trips.length === 0) {
    alert('No trip data to export.');
    return;
  }

  var headers = [
    'Date', 'Start Time', 'End Time', 'Duration (min)', 'Purpose',
    'Transport', 'Passengers', 'Start Lat', 'Start Lng', 'End Lat', 'End Lng',
  ];

  var rows = trips.map(function (t) {
    var start = new Date(t.tripStartTime);
    var end = new Date(t.tripEndTime);
    var dur = Math.round((end - start) / 60000);
    return [
      start.toLocaleDateString(),
      start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      dur,
      t.tripPurpose,
      t.modeOfTransport,
      t.numberOfPassengers,
      t.startLat || '',
      t.startLng || '',
      t.endLat || '',
      t.endLng || '',
    ].map(function (v) {
      // Escape commas and quotes in CSV values
      var s = String(v);
      if (s.indexOf(',') !== -1 || s.indexOf('"') !== -1) {
        return '"' + s.replace(/"/g, '""') + '"';
      }
      return s;
    }).join(',');
  });

  var csv = headers.join(',') + '\n' + rows.join('\n');
  var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  var a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'travel_tracker_trips_' + new Date().toISOString().split('T')[0] + '.csv';
  a.click();
  URL.revokeObjectURL(a.href);
}

// PDF Export — uses jsPDF + Chart.js toBase64Image
function exportPDF() {
  var stats = AppState.stats;
  if (!stats || stats.total === 0) {
    alert('No trip data to export.');
    return;
  }

  var jsPDF = window.jspdf.jsPDF;
  var doc = new jsPDF('p', 'mm', 'a4');

  // Title
  doc.setFontSize(20);
  doc.setTextColor(26, 82, 118);
  doc.text('Travel Tracker - Trip Report', 14, 22);

  doc.setFontSize(10);
  doc.setTextColor(127, 140, 141);
  doc.text('KSCSTE Research Project', 14, 30);
  doc.text('Generated: ' + new Date().toLocaleString(), 14, 36);

  // Divider
  doc.setDrawColor(230, 230, 230);
  doc.line(14, 40, 196, 40);

  // Summary stats
  doc.setFontSize(14);
  doc.setTextColor(26, 82, 118);
  doc.text('Summary Statistics', 14, 50);

  doc.setFontSize(11);
  doc.setTextColor(44, 62, 80);
  var y = 60;
  var statLines = [
    ['Total Trips', stats.total],
    ['Avg. Passengers', stats.avgPassengers],
    ['Avg. Duration', stats.avgTripDurationMinutes + ' min'],
    ['Total Distance', stats.totalDistanceKm + ' km'],
    ['Top Transport', LABEL_MAP[stats.mostCommonTransport] || stats.mostCommonTransport || '--'],
    ['Top Purpose', LABEL_MAP[stats.mostCommonPurpose] || stats.mostCommonPurpose || '--'],
    ['Peak Travel Hour', stats.peakHour + ':00'],
  ];

  statLines.forEach(function (pair) {
    doc.setFont(undefined, 'bold');
    doc.text(pair[0] + ':', 14, y);
    doc.setFont(undefined, 'normal');
    doc.text(String(pair[1]), 70, y);
    y += 8;
  });

  // Add chart images if available
  y += 10;
  var chartsAdded = false;

  try {
    if (typeof purposeChart !== 'undefined' && purposeChart) {
      doc.setFontSize(12);
      doc.setTextColor(26, 82, 118);
      doc.text('Trip Purpose Distribution', 14, y);
      y += 5;
      var purposeImg = purposeChart.toBase64Image();
      doc.addImage(purposeImg, 'PNG', 14, y, 80, 60);
      chartsAdded = true;
    }

    if (typeof transportChart !== 'undefined' && transportChart) {
      if (!chartsAdded) {
        doc.setFontSize(12);
        doc.setTextColor(26, 82, 118);
        doc.text('Transport Mode Distribution', 102, y - 5);
      }
      var transportImg = transportChart.toBase64Image();
      doc.addImage(transportImg, 'PNG', 102, y, 80, 60);
    }
  } catch (e) {
    // Charts not available, skip
  }

  // Trip data table on page 2
  doc.addPage();
  doc.setFontSize(14);
  doc.setTextColor(26, 82, 118);
  doc.text('Trip Details', 14, 20);

  doc.setFontSize(8);
  doc.setTextColor(90, 108, 125);
  var tableY = 30;
  var colWidths = [25, 20, 20, 18, 22, 22, 18, 22, 22];
  var tableHeaders = ['Date', 'Start', 'End', 'Dur.', 'Purpose', 'Transport', 'Pax', 'Start Loc', 'End Loc'];

  // Header row
  doc.setFont(undefined, 'bold');
  doc.setFillColor(248, 249, 250);
  doc.rect(14, tableY - 4, 182, 8, 'F');
  var x = 14;
  tableHeaders.forEach(function (h, i) {
    doc.text(h, x + 1, tableY);
    x += colWidths[i];
  });
  tableY += 8;

  // Data rows
  doc.setFont(undefined, 'normal');
  doc.setTextColor(44, 62, 80);
  var trips = AppState.trips.slice(0, 30); // Limit to 30 for PDF

  trips.forEach(function (t) {
    if (tableY > 275) {
      doc.addPage();
      tableY = 20;
    }

    var start = new Date(t.tripStartTime);
    var end = new Date(t.tripEndTime);
    var dur = Math.round((end - start) / 60000);
    var startLoc = t.startLat ? t.startLat.toFixed(3) + ',' + t.startLng.toFixed(3) : '--';
    var endLoc = t.endLat ? t.endLat.toFixed(3) + ',' + t.endLng.toFixed(3) : '--';

    var rowData = [
      start.toLocaleDateString(),
      start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      dur + 'm',
      (t.tripPurpose || '').slice(0, 8),
      (t.modeOfTransport || '').slice(0, 8),
      String(t.numberOfPassengers),
      startLoc,
      endLoc,
    ];

    x = 14;
    rowData.forEach(function (val, i) {
      doc.text(String(val), x + 1, tableY);
      x += colWidths[i];
    });
    tableY += 6;
  });

  doc.save('travel_tracker_report_' + new Date().toISOString().split('T')[0] + '.pdf');
}
