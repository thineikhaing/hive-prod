var EditTopicPost = {

  init: function() {

    //for topic list table
    $("table.add_col_topic_list tr td").click( function(){

      const  col_edit_link = 0;
      const col_del_link= 1;
      const col_id = 2;

      var current_col = $(this).parent().children().index($(this));
      var current_row =$(this).parent();
      var columns = $(current_row).find('td');

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
    });

    //for post list table
    $("table.add_col_post_list tr td").click( function(){

      const  col_edit_link = 0;
      const col_del_link= 1;
      const col_id = 2;

      var current_col = $(this).parent().children().index($(this));
      var current_row =$(this).parent();
      var columns = $(current_row).find('td');

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
    });
  }
}