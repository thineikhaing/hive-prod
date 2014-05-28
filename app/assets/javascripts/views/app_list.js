var Application_list = {

  init: function() {
    $("tr[data-link]").click(function() {
      window.location = this.dataset.link
    });
  }
}