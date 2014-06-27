var editColumn = {
  init: function() {
    $("form").submit(function(e){
      $.ajax({
        success: function(html) {
          var htmlobject = $(html);
          var output = htmlobject.find("#additional_columns")[0];
          var testing = new XMLSerializer().serializeToString(output);
          $("#additional_columns").replaceWith(testing);
          $('#AppAdditionalColumn_additional_column_name').val('');
          $('#AppAdditionalColumn_field_id').val(0);
          editColumn.init();
        }
      });
    });
//
//    $('a').click(function(e){
//      alert ("innnnnn")
//      $.ajax({
//        success: function(html) {
//          var htmlobject = $(html);
//          var output = htmlobject.find("#additional_columns")[0];
//          var testing = new XMLSerializer().serializeToString(output);
//          $("#additional_columns").replaceWith(testing);
//          $('#AppAdditionalColumn_additional_column_name').val('');
//        }
//      });
//    });

    var table = document.getElementById("tbl_add_fields");
    for (var i = 0, row; row = table.rows[i]; i++) {
      //iterate through rows
      //rows would be accessed using the "row" variable assigned in the for loop

      //      del_link
      $(table.rows[i].cells[1]).click(function(){
        console.log($(this).children().children().attr('value'));
        field_id = $(this).children().children().attr('value');
        $.ajax({
          url: '/delete_additional_column',
          data: {field_id: field_id},
          success: function(html) {
            var htmlobject = $(html);
            var output = htmlobject.find("#additional_columns")[0];
            var testing = new XMLSerializer().serializeToString(output);
            $("#additional_columns").replaceWith(testing);
            $('#AppAdditionalColumn_additional_column_name').val('');
            editColumn.init();
          }
        });
      });

//      edit_link
      $(table.rows[i].cells[2]).click(function(){
        console.log($(this).children().children().attr('value'));
        field_id = $(this).children().children().attr('value');
        console.log(field_id);
        var row= this.parentNode;
        var index = row.rowIndex;
        var table = document.getElementById("tbl_add_fields");
        var txt = table.rows[index].cells[0].innerHTML.trim();
        $('#AppAdditionalColumn_additional_column_name').val(txt);
        $('#AppAdditionalColumn_field_id').val(field_id);
//        console.log(txt);
//        $.ajax({
//          url: '/update_additional_column',
//          data: {field_id: field_id},
//          success: function(html) {
//            var htmlobject = $(html);
//            var output = htmlobject.find("#additional_columns")[0];
//            var testing = new XMLSerializer().serializeToString(output);
//            $("#additional_columns").replaceWith(testing);
//            $('#AppAdditionalColumn_additional_column_name').val('');
//            editColumn.init();
//          }
//        });
      });

    }

  }
};


