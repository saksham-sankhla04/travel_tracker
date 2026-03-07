// Filter UI logic — reads inputs and triggers data refresh
function initFilters() {
  var dateFrom = document.getElementById('filter-date-from');
  var dateTo = document.getElementById('filter-date-to');
  var transport = document.getElementById('filter-transport');
  var purpose = document.getElementById('filter-purpose');
  var clearBtn = document.getElementById('filter-clear');

  function onFilterChange() {
    AppState.tablePagination.currentPage = 1;
    fetchAndRender();
  }

  dateFrom.addEventListener('change', onFilterChange);
  dateTo.addEventListener('change', onFilterChange);
  transport.addEventListener('change', onFilterChange);
  purpose.addEventListener('change', onFilterChange);

  clearBtn.addEventListener('click', function () {
    dateFrom.value = '';
    dateTo.value = '';
    transport.value = '';
    purpose.value = '';
    onFilterChange();
  });
}
