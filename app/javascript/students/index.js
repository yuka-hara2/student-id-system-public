  document.addEventListener('turbo:load', () => {
    const rowCheckboxes = Array.from(document.querySelectorAll('.row-checkbox'));
    const theadCheckbox = document.getElementById('thead-checkbox');
    const linkToGeneratePdf = document.getElementById('js-link-to-generate-pdf');
    const linkToViewCards = document.getElementById('js-link-to-view-cards');

    function setStudentIdsParam() {
      const selectedRows = document.querySelectorAll('.row-checkbox:checked');
      const selectedIds = Array.from(selectedRows).map(cb => cb.dataset.row);

      if(selectedIds.length === 0){
        alert('Please select more than one.');
        return null;
      }

      return selectedIds.map(id => `student_ids[]=${encodeURIComponent(id)}`).join('&');
    }

    theadCheckbox.addEventListener('change', (e) => {
      const isChecked = e.target.checked;
      rowCheckboxes.forEach(cb => {
        cb.checked = isChecked;
      });
    });

    linkToGeneratePdf.addEventListener('click', function(e) {
      e.preventDefault();

      const params = setStudentIdsParam();
      if (params !== null) {
        const url = `/students/download_pdf.pdf?${params}`;
        window.open(url, '_blank');        
      }
    });

    linkToViewCards.addEventListener('click', function(e) {
      e.preventDefault();

      const params = setStudentIdsParam();
      if (params !== null) {
        const url = `/students/test_id_card?${params}`;
        window.open(url, '_blank');        
      }
    });
  });