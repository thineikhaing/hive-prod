// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require views/devportal
//= require views/edit_column
//= require views/edit_topic_post
//= require views/edit_column_post
//= require views/app_list
//= require jquery
//= require jquery_ujs
//= require jquery/cookie
//= require jquery.minicolors
//= require markerclusterer
//= require underscore
//= require gmaps/google
//= require carmic_map
//= require carmic
//= require_self

(function() {
    /* __markers will hold a reference to all markers currently shown
     on the map, as GMaps4Rails won't do it for you.
     This won't pollute the global window object because we're nested
     in a "self-executed" anonymous function */


    function updateMarkers(map, markersData, old_marker)
    {
        // Remove current markers
        map.removeMarkers(old_marker);

        // Add each marker to the map according to received data

        __markers = _.map(markersData, function(markerJSON) {
            marker = map.addMarker(markerJSON);
            //map.getMap().setZoom(16); // Not sure this should be in this iterator!

            _.extend(marker, markerJSON);

            marker.infowindow = new google.maps.InfoWindow({
                content: marker.infowindow
            });

            return marker;
        });

//        _.each(__markers, function(marker){
//            google.maps.event.trigger(marker.getServiceObject(), 'click');
//        });

        map.bounds.extendWith(__markers);

//        map.fitMapToBounds();
    };

    // "Publish" our method on window. You should probably have your own namespace
    window.updateMarkers = updateMarkers;
})();

