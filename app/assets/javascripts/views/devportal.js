var Devportal = {

  init: function() {
    $('#table_list').hide();
    $('.btn_adv_option_container').click(function() {
      $('#table_list').show();
      $('#create_application_form').animate({
      opacity: 'hide',
      height: 'hide'
      }, 'slow');
    });

    $('.btn_back_option_container').click(function() {
      $('#create_application_form').animate({
          opacity: 'show',
          height: 'show'
      }, 'slow');
      $('#table_list').hide();

      // reset controls
      $('#create_additional_column_container_post').hide();
      main_container = $('#create_additional_column_container_post');
      txt_add_col = $(main_container).find('#AppAdditionalColumn_additional_column_name');
      txt_add_col.val('');

      //set the rest controls to default
      const  col_txt_field_name = 0;
      const col_lbl_field_name = 1;
      const col_img_edit = 2;
      const col_btn_save = 4;
      const col_btn_delete = 5;
      const col_bool_edit_btn_clicked = 6;

      $('table.add_col_post_list tr').each(function (i, row) {
        //check to make sure that the row is not selected row
        $(row).css("background", "none");  //change background color to white
        var all_columns = $(row).find('td') ;
        $(all_columns[col_lbl_field_name]).css ('color', '#FF9B00');

        row.selected = false;

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
      });

      $('table.add_col_topic_list tr').each(function (i, row) {
        //check to make sure that the row is not selected row
        $(row).css("background", "none");  //change background color to white
        var all_columns = $(row).find('td') ;
        $(all_columns[col_lbl_field_name]).css ('color', '#FF9B00');

        row.selected = false;

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
      });

      $('#create_additional_column_container_topic').hide();
      main_container = $('#create_additional_column_container_topic');
      txt_add_col = $(main_container).find('#AppAdditionalColumn_additional_column_name');
      txt_add_col.val('');



    });

    var elements = document.getElementsByTagName("INPUT");
    var hexvalue = $('#dev_portal_theme_color').val();
    $('#dev_portal_theme_color').minicolors({});
    for (var i = 0; i < elements.length; i++) {
      elements[i].oninvalid = function(e) {
        e.target.setCustomValidity("");
        if (!e.target.validity.valid) {
          name = e.target.name;
          if (name.indexOf("name") > -1 )
          {
            e.target.setCustomValidity("Application Name field cannot be left blank");
          }
          else if (name.indexOf("description") > -1 )
          {
            e.target.setCustomValidity("Application Description field cannot be left blank");
          }
          else if (name.indexOf("icon") > -1 )
          {
            e.target.setCustomValidity("Application Icon file must be uploaded");
          }
        }
      };
      elements[i].oninput = function(e) {
        e.target.setCustomValidity("");
      };
    }

    this.updateCountdown();
    $('#dev_portal_description').change(this.updateCountdown);
    $('#dev_portal_description').keyup(this.updateCountdown);


    $("#dev_portal_application_icon").on( 'change', function(){
      var allowedExtension = ["jpg", "jpeg", "gif", "png"];
      if (this.value.split(".").length == 2){
        extName = this.value.split(".")[1] ;
        if ($.inArray(extName, allowedExtension) == -1)
        {
          alert ("Invalid upload icon file format");
          $("#btn_edit_application").attr('disabled','disabled');
        }
        else
        {
          $("#btn_edit_application").removeAttr('disabled');
          var preview = $(".upload-preview img");
          var file = this.files[0];
          var reader = new FileReader();
          reader.onload = function(e){
            image_base64 = e.target.result;
            preview.attr("src", image_base64);
          };
          reader.readAsDataURL(file);
        }
      }

    });

  },
  updateCountdown: function() {
    var remaining = 255 - $('#dev_portal_description').val().length;
    $("label[for='myalue']").html( "( <font color='red'> " + remaining + "</font> CHARACTERS REMAINING )");

  }
}
