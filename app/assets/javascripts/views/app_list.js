var Applicationlist = {

  init: function() {
    $("tr[data-link]").click(function() {
      window.location = this.dataset.link
    });
  }
}