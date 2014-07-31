var editColumn = {
  init: function() {

    $("#btn_new_field_container").click(function(){
      $('#create_additional_column_container').show();
    });

    $("#add_new_column_form").submit(function(e){
      e.preventDefault();
      /* get some values from elements on the page: */
      var $form = $(this),
        term = $form.find('input[name="s"]').val(),
        url = $form.attr('action');

      /* Send the data using post */
      var posting = $.post(url, {
        s: term
      });

      /* Put the results in a div */
      posting.done(function(data) {
        $.ajax({
          success: function(html) {
            var htmlobject = $(html);
            var output = htmlobject.find("#list_of_topic_fields_container")[0];
            var testing = new XMLSerializer().serializeToString(output);
            $("#list_of_topic_fields_container").replaceWith(testing);
            $('#create_additional_column_container').hide();
            editColumn.init();
          }
        });
      });

    });

    $("table.app_list tr").click( function(){
      //declaration variables
      const  col_txt_field_name = 0;
      const col_lbl_field_name = 1;
      const col_img_edit = 2;
      const col_field_id = 3;
      const col_btn_save = 4;
      const col_btn_delete = 5;
      const col_bool_edit_btn_clicked = 6;
      var columns = $(this).find('td');
      var rowCount = $('table.app_list tr').length;


      // reset the background color & selected value
      $('table.app_list tr').each(function (i, row) {

        $(row).css("background-color", "white");  //change background color to white
        row.selected = false;
      });

      // set selected property to true
      this.selected = true;
      //change background color
      $(this).css("background-color", "#FDAF37");

      //set the rest controls to default
      $('table.app_list tr').each(function (i, row) {
        //check to make sure that the row is not selected row
        if (!row.selected)
        {
          var all_columns = $(row).find('td') ;
          if (all_columns[col_img_edit])
          {
            all_columns[col_bool_edit_btn_clicked].children[0].value = 0;
            all_columns[col_lbl_field_name].children[0].style.visibility = 'visible';
            all_columns[col_img_edit].children[0].style.visibility = 'hidden';
            all_columns[col_txt_field_name].children[0].style.visibility = 'hidden';
            all_columns[col_btn_save].children[0].style.visibility = 'hidden';
            all_columns[col_btn_delete].children[0].style.visibility = 'hidden';
          }

        }
      });

      img_edit_item =  columns[col_img_edit].children[0];
      //when edit cell is clicked
      $(img_edit_item).click(function() {
        columns[col_bool_edit_btn_clicked].children[0].value = 1;
        columns[col_lbl_field_name].children[0].style.visibility = 'hidden';
        columns[col_img_edit].children[0].style.visibility = 'hidden';
        columns[col_txt_field_name].children[0].style.visibility = 'visible';
        columns[col_btn_save].children[0].style.visibility = 'visible';
        columns[col_btn_delete].children[0].style.visibility = 'visible';
      });


    });

    $("table.app_list tr td").click( function(){
      const  col_txt_field_name = 0;
      const col_lbl_field_name = 1;
      const col_img_edit = 2;
      const col_field_id = 3;
      const col_btn_save = 4;
      const col_btn_delete = 5;
      const col_bool_edit_btn_clicked = 6;


      var current_col = $(this).parent().children().index($(this));
      var current_row =$(this).parent();
      var columns = $(current_row).find('td');

      img_edit_item =  columns[col_img_edit].children[0];
      btn_save_item =  columns[col_btn_save].children[0];
      btn_del_item  =  columns[col_btn_delete].children[0];

      var is_edit_clicked = 0;
      is_edit_clicked =  columns[col_bool_edit_btn_clicked].children[0].value;
      if (is_edit_clicked!=1)
      {
        img_edit_item.style.visibility = 'visible';
        columns[col_bool_edit_btn_clicked].children[0].value = 0;
      }

      //when delete cell is clicked
      if (current_col == col_btn_delete){
        if (btn_del_item.style.visibility == 'visible'){

          // check if it is the existing row
          field_id = columns[col_field_id].children[0].value;
          if (field_id)
          {
            if (field_id!= 0)
            {
              // call jquery to controller to del

              $.ajax({
                url: '/delete_additional_column',
                data: {field_id: field_id},
                success: function(html) {
                  var htmlobject = $(html);
                  var output = htmlobject.find("#list_of_topic_fields_container")[0];
                  var testing = new XMLSerializer().serializeToString(output);
                  $("#list_of_topic_fields_container").replaceWith(testing);
                  $('#AppAdditionalColumn_additional_column_name').val('');
                  editColumn.init();
                }
              });
            }
          }

        }
      };

      //when save cell is clicked
      if (current_col == col_btn_save) {
        if (btn_save_item.style.visibility == 'visible'){
          // check if it is the existing row
          field_id = columns[col_field_id].children[0].value;
          if (field_id)
          {
            if (field_id!= 0)
            {
              //get the new field name
              var column_name =  columns[col_txt_field_name].children[0].value;
              if (column_name.length >0)
              {
                // call jquery to controller to save
                $.ajax({
                  url: '/update_additional_column',
                  data: {field_id: field_id, column_name: column_name, table_name: "Toopic"},
                  success: function(html) {
                    var htmlobject = $(html);
                    var output = htmlobject.find("#list_of_topic_fields_container")[0];
                    var testing = new XMLSerializer().serializeToString(output);
                    $("#list_of_topic_fields_container").replaceWith(testing);
                    $('#AppAdditionalColumn_additional_column_name').val('');
                    editColumn.init();
                  }
                });
              }
              else{
                alert ("Please Enter New Column Name");
              }

            }
          }

        }
      };
    });
  }
};


