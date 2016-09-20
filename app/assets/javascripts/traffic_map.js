var Traffic = {
    init: function() {
        var handler = Gmaps.build('Google');

        handler.buildMap({
            provider: {
                disableDefaultUI:true,
                zoom: 15,
                streetViewControl: false,
                panControl: false,
                mapTypeControl: true,
                mapTypeControlOptions: {
                    style: google.maps.MapTypeControlStyle.DEFAULT,
                    mapTypeIds: [
                        google.maps.MapTypeId.ROADMAP,
                        google.maps.MapTypeId.TERRAIN
                    ]
                },
                zoomControl: false,
            },
            internal: {id: 'trafficmap'}
        }, function(){


            markers = handler.addMarkers(#{raw @hash.to_json});


            __markers = markers
            old_markers = #{raw @hash.to_json}



                _.each(markers, function(marker){
                    google.maps.event.trigger(marker.getServiceObject(), 'click');
                });

            handler.bounds.extendWith(markers);

            handler.fitMapToBounds();

        });
    }
}

