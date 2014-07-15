var Devportal = {

  init: function() {
    //check mandatory fields of the form
    var elements = document.getElementsByTagName("INPUT");
    var hexvalue = $('#dev_portal_theme_color').val();
    if (hexvalue.length== 7){
        $('#dev_portal_color_display').css("background-color", hexvalue);
    }
    $('#dev_portal_theme_color').minicolors({
        change: function(hex, rgb) {
            $('#dev_portal_color_display').css("background-color", hex);
        }
    });
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
//      alert("On change");
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
    console.log("inside update count down");
    var remaining = 255 - $('#dev_portal_description').val().length;
    $("label[for='myalue']").html( "( <font color='red'> " + remaining + "</font> CHARACTERS REMAINING )");

  }
}
