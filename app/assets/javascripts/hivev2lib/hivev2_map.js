
var Hivemaps = {

    init: function() {
        hiveapp = new Array()
        hiveapp = gon.hiveapplicaiton

        fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
        toProjection = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection;

        size = new OpenLayers.Size(2,2);
        offset = new OpenLayers.Pixel(-(size.w/2), -size.h);

        mOptions = {
            gridSize: 50,
            maxZoom: 8
        };
        latitude = '', longitude = '', zoom = 16;

        this.geoloc(this.success,this.fail);


    },


    geoloc:function(success, fail){
        var is_echo = false;
        if(navigator.geolocation) {
            var location_timeout = setTimeout(fail, 10000);
            navigator.geolocation.getCurrentPosition(
                function (pos) {
                    clearTimeout(location_timeout);
                    if (is_echo){ return; }
                    is_echo = true;
                    success(pos.coords.latitude,pos.coords.longitude);
                },
                function() {
                    clearTimeout(location_timeout);
                    if (is_echo){ return; }
                    is_echo = true;
                    fail();
                }
            );
        } else {
            clearTimeout(location_timeout);
            fail();
        }
    },

    success:function(lat, lng){
        if(navigator.geolocation) {
            $.cookie('currentlat', lat, {expires:null,path:'/'});
            $.cookie('currentlng', lng, {expires:null,path:'/'});

            // Settings for Marker Icon
            var size = new OpenLayers.Size(50,50);
            var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);

            // Settings for positioning

            latitude =lat;
            longitude = lng;

            var address = "", city = "", state = "", zip = "", country = "", formattedAddress = "";
            var latlng   = new google.maps.LatLng(latitude,longitude);
            var geocoder = new google.maps.Geocoder();
            geocoder.geocode({ 'latLng': latlng },
                function (results, status) {
                    if (status == google.maps.GeocoderStatus.OK) {
                        if (results[0]) {

                            for (var i = 0; i < results[0].address_components.length; i++) {
                                var addr = results[0].address_components[i];
                                // check if this entry in address_components has a type of country
                                if (addr.types[0] == 'country')
                                    country = addr.long_name;
                                else if (addr.types[0] == 'street_address') // address 1
                                    address = address + addr.long_name;
                                else if (addr.types[0] == 'establishment')
                                    address = address + addr.long_name;
                                else if (addr.types[0] == 'route')  // address 2
                                    address = address + addr.long_name;
                                else if (addr.types[0] == 'postal_code')       // Zip
                                    zip = addr.short_name;
                                else if (addr.types[0] == ['administrative_area_level_1'])       // State
                                    state = addr.long_name;
                                else if (addr.types[0] == ['locality'])       // City
                                    city = addr.long_name;
                            }


                            if (results[0].formatted_address != null) {
                                formattedAddress = results[0].formatted_address;
                                $("#round_address").html(formattedAddress)
                                $("#round_country").html(country)

                                $("#hive_address").html(formattedAddress)
                                $("#hive_country").html(country)

                                $("#meal_address").html(formattedAddress)
                                $("#meal_country").html(country)

                                $("#favr_address").html(formattedAddress)
                                $("#favr_country").html(country)

                                $("#socal_address").html(formattedAddress)
                                $("#socal_country").html(country)

                                $("#carmic_address").html(formattedAddress)
                                $("#carmic_country").html(country)
                            }

                        }

                    }

                });


            for (var i = 0; i < hiveapp.length; i++){

                var name =  "map_"
                var id=  hiveapp[i].id
                var mapidname = name.concat(id)

                console.log(mapidname)
                map = new OpenLayers.Map(mapidname, {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});


                //map = new OpenLayers.Map("hv_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});
                //
                var markers = new OpenLayers.Layer.Markers("Markers");
                var currentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
                var currentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
                var currentPositionMarker = new OpenLayers.Marker(currentPosition, currentPositionIcon.clone());
                var mapnik = new OpenLayers.Layer.OSM();


                map.addLayer(mapnik);
                //map.addLayer(markers);
                map.setCenter (currentPosition, zoom);
                //map.addMarker(currentPositionMarker);


                api_key =  $("#"+mapidname).data("apikey")
                Hivemaps.addplacemarker(map,lat, lng,api_key)

                map.events.register("moveend", map, function(){

                    var mapExtent = map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                    var xCoord = mapExtent.lat
                    var yCoord = mapExtent.lon

                    console.log(xCoord)
                    console.log(yCoord)

                    var address = "", city = "", state = "", zip = "", country = "", formattedAddress = "";
                    var latlng   = new google.maps.LatLng(xCoord,yCoord);
                    var geocoder = new google.maps.Geocoder();
                    geocoder.geocode({ 'latLng': latlng },
                        function (results, status) {
                            if (status == google.maps.GeocoderStatus.OK) {
                                if (results[0]) {

                                    for (var i = 0; i < results[0].address_components.length; i++) {
                                        var addr = results[0].address_components[i];
                                        // check if this entry in address_components has a type of country
                                        if (addr.types[0] == 'country')
                                            country = addr.long_name;
                                        else if (addr.types[0] == 'street_address') // address 1
                                            address = address + addr.long_name;
                                        else if (addr.types[0] == 'establishment')
                                            address = address + addr.long_name;
                                        else if (addr.types[0] == 'route')  // address 2
                                            address = address + addr.long_name;
                                        else if (addr.types[0] == 'postal_code')       // Zip
                                            zip = addr.short_name;
                                        else if (addr.types[0] == ['administrative_area_level_1'])       // State
                                            state = addr.long_name;
                                        else if (addr.types[0] == ['locality'])       // City
                                            city = addr.long_name;
                                    }


                                    if (results[0].formatted_address != null) {
                                        formattedAddress = results[0].formatted_address;

                                        $("#address"+id).html(formattedAddress)
                                        $("#country"+id).html(country)
                                    }


                                    var location = results[0].geometry.location;


                                }

                            }

                        });


                });

            }

            // setting for round trop map
        }

    },
    fail:function(){} ,


    addplacemarker:function(param_map,param_lat, param_lng,api_key){
        markerArray = new Array();
        var places = new Array();
        var latestTopicUser = new Array();

        var places = new Array();
        places = gon.places;

        for (var i = 0; i < places.length; i++)
        {
            lat = places[i].latitude;
            lng = places[i].longitude;

            title = places[i].name;
            id = places[i].id;
            var placePosition = new OpenLayers.LonLat(lng,lat).transform(fromProjection, toProjection);
            var placeMarker;


            var icon = new OpenLayers.Icon('/assets/map/SingleMap.png', size, offset);
            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());

            markerArray.push(placeMarker);
            placeMarker.title = places[i].name;
            placeMarker.id = places[i].id;
            placeMarker.url = null;

        }

        // Settings for clustering markers
        mOptions = {
            gridSize: 0,
            maxZoom: 0
        };

        var markerCluster = new MarkerClusterer(param_map, markerArray, mOptions,param_lat, param_lng,api_key);


    },



};


window.Hivemaps = Hivemaps ;