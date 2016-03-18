// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require foundation
//= require jquery-ui
//= require hivev2lib/hivev2_map
//= require spectrum
//= require jquery/cookie
//= require markerclusterer


$(function() {
    $(document).foundation();
});

function showposts(obj){
    var id = $(obj).data("topicid")
    var postcount = $(obj).data("postcount")

    var post_list;

    if (postcount == 0){

        $('#wrapper_post_list').foundation('reveal', 'close');
    }
    else{

        $('#display_topic').html('');
        $('#display_post').html("");
        if (id > 0 ){
            var url = 'api/hivev2/get_posts_by_topicid';
            $.ajax({
                url: url,
                data: {topic: id},
                success: function(data) {
                    title = data.topic.title
                    avatar = data.topicavatar

                    timage  ='<img src='+avatar+'><img/>'

                    topic='<tr><td><div class="picbox">'+timage+'<div></td>'
                        +'<td>'+title+'</td>'
                        +'<td>'+data.topic.created_at+'</td></tr>'

                    $('#display_topic').html(topic);

                    $(data.posts).each(function(e){
                        id = data.posts[e].id
                        image = data.postavatars[id]

                        image ='<img src='+image+'><img/>'
                        post_list+='<tr><td><div class="picbox">'+image+'<div></td>'
                            +'<td>'+data.posts[e].content+'</td>'
                            +'<td>'+data.posts[e].created_at+'</td></tr>'

                        $('#display_post').html(post_list);

                    })



                }
            });


            $('#wrapper_post_list').foundation('reveal', 'open');
        }

    }

}

function showtopic(obj){
    $('#topiclist_table').html("");
    var data = $(obj).data("topiclist")

    //alert(data.length)

    if (data.length == 0){

        $('#wrapper_topic_list').foundation('reveal', 'close');
    }
    else{

        var topic_list = ''
        console.log("topic list")
        for (var i = 0, l = data.length; i < l; i++) {

            console.log(data[i])
            var obj = data[i];
            image ='<img src='+data[i].avatar_url+'><img/>'
            title = data[i].title
            created_at = data[i].created_at

            topic_list+='<tr><td><div class="picbox">'+image+'<div></td>'
                +'<td>'+title+'</td>'
                +'<td>'+created_at+'</td></tr>'


        }
        $('#topiclist_table').html(topic_list);
        $('#wrapper_topic_list').foundation('reveal', 'open');
    }

}

function closeReval(obj){
    settingid = $(obj).data("settingid")
    $('#'+settingid).foundation('reveal', 'close');
}

window.showposts = showposts;
window.showtopic = showtopic;
window.closeReval = closeReval;
