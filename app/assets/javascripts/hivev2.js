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
//= require jquery/cookie
//= require markerclusterer


$(function() {
    $(document).foundation();
});

function showposts(obj){
    var id = $(obj).data("topicid")
    var post_list;

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

                $('#wrapper_post_list').foundation('reveal', 'open');

            }
        });


    }

}

function showtopic(obj){
    $('#topiclist_table').html("");
    var app_id = $(obj).data("app")
    var topic_list;
    if (id > 0 ){
        var url = 'api/hivev2/get_posts_by_topicid';
        $.ajax({
            url: url,
            data: {app_id: app_id},
            success: function(data) {

                $(data.topics).each(function(e){
                    id = data.topics[e].id
                    image = data.topicavatars[id]

                    image ='<img src='+image+'><img/>'
                    topic_list+='<tr><td><div class="picbox">'+image+'<div></td>'
                        +'<td>'+data.topics[e].title+'</td>'
                        +'<td>'+data.topics[e].created_at+'</td></tr>'



                })

                $('#topiclist_table').html(topic_list);

                $('#wrapper_topic_list').foundation('reveal', 'open');

            }
        });


    }



}

window.showposts = showposts;
window.showtopic = showtopic;
