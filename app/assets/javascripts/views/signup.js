var Signup = {

  init: function() {
    //check mandatory fields of the form
    var elements = document.getElementsByTagName("INPUT");
    for (var i = 0; i < elements.length; i++) {
      elements[i].oninvalid = function(e) {
        e.target.setCustomValidity("");
        if (!e.target.validity.valid) {
          name = e.target.name;
          console.log(name);
          if (name.indexOf("name") > -1 )
          {
            e.target.setCustomValidity("Name field cannot be left blank");
          }
          else if (name.indexOf("email") > -1 )
          {
            e.target.setCustomValidity("Email field cannot be left blank");
          }
          else if (name.indexOf("sign_up[password]") > -1 )
          {
            e.target.setCustomValidity("Password field cannot be left blank");
          }
          else if (name.indexOf("sign_up[confirm_password]") > -1 )
          {
            e.target.setCustomValidity("Confirm Password field cannot be left blank");
          }
        }
      };
      elements[i].oninput = function(e) {
        e.target.setCustomValidity("");
      };
    }
  }
}