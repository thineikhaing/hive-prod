var EditTopicPost = {

  init: function() {

    //for topic list table
    $("table.add_col_topic_list tr td").click( function(){

      const  col_edit_link = 0;
      const col_del_link= 1;
      const col_id = 2;
      const txt_title = 4;

      var current_col = $(this).parent().children().index($(this));
      var current_row =$(this).parent();
      var columns = $(current_row).find('td');

      //delete the topic
      if (current_col == col_del_link){
        topic_id = columns[col_id].children[0].value;
        $.ajax({
          url: '/delete_topic',
          data: {topic_id: topic_id},
          success: function(html) {
            var htmlobject = $(html);

            //refresh topic list
            var output = htmlobject.find("#list_of_topic_fields_container")[0];
            var testing = new XMLSerializer().serializeToString(output);
            $("#list_of_topic_fields_container").replaceWith(testing);

            //refresh post list also
            output = htmlobject.find("#list_of_post_fields_container")[0];
            testing = new XMLSerializer().serializeToString(output);
            $("#list_of_post_fields_container").replaceWith(testing);

            EditTopicPost.init();
          }
        });
      }

      //edit the topic
      if (current_col == col_edit_link){

        edit_link = columns[col_edit_link].children[0];
        topic_id = columns[col_id].children[0].value;
        title = columns[txt_title].children[0];
        topic_title = columns[txt_title].children[0].value;

        if ($(edit_link)[0].innerHTML.trim() == "Edit")
        {

          title.style.visibility = 'visible';
          $(edit_link)[0].innerHTML = "Save";
        }
        else
        {
          $.ajax({
            url: '/edit_topic',
            data: {topic_id: topic_id, topic_title:topic_title},
            success: function(html) {
              var htmlobject = $(html);

              //refresh topic list
              var output = htmlobject.find("#list_of_topic_fields_container")[0];
              var testing = new XMLSerializer().serializeToString(output);
              $("#list_of_topic_fields_container").replaceWith(testing);

              //reset the controls to enable/disable
              title.style.visibility = 'hidden';
              $(edit_link)[0].innerHTML = "Edit";

              EditTopicPost.init();
            }
          });
        }

      }

    });

    //for post list table
    $("table.add_col_post_list tr td").click( function(){

      const  col_edit_link = 0;
      const col_del_link= 1;
      const col_id = 2;
      const txt_content = 4;

      var current_col = $(this).parent().children().index($(this));
      var current_row =$(this).parent();
      var columns = $(current_row).find('td');

      //delete the post
      if (current_col == col_del_link){
        post_id = columns[col_id].children[0].value;
        $.ajax({
          url: '/delete_post',
          data: {post_id: post_id},
          success: function(html) {
            var htmlobject = $(html);

            //refresh post list also
            output = htmlobject.find("#list_of_post_fields_container")[0];
            testing = new XMLSerializer().serializeToString(output);
            $("#list_of_post_fields_container").replaceWith(testing);

            EditTopicPost.init();
          }
        });
      }

      //edit the post
      if (current_col == col_edit_link){
        edit_link = columns[col_edit_link].children[0];
        post_id = columns[col_id].children[0].value;
        content = columns[txt_content].children[0];
        post_content = columns[txt_content].children[0].value;

        if ($(edit_link)[0].innerHTML.trim() == "Edit")
        {

          content.style.visibility = 'visible';
          $(edit_link)[0].innerHTML = "Save";
        }
        else
        {
          $.ajax({
            url: '/edit_post',
            data: {post_id: post_id, post_content:post_content},
            success: function(html) {
              var htmlobject = $(html);

              //refresh post list
              var output = htmlobject.find("#list_of_post_fields_container")[0];
              var testing = new XMLSerializer().serializeToString(output);
              $("#list_of_post_fields_container").replaceWith(testing);

              //reset the controls to enable/disable
              content.style.visibility = 'hidden';
              $(edit_link)[0].innerHTML = "Edit";

              EditTopicPost.init();
            }
          });
        }
      }

    });
  }
}