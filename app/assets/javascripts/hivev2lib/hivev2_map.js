
var Hivemaps = {

    init: function() {

        hv_map = new OpenLayers.Map("hv_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});

        mb_map = new OpenLayers.Map("mb_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});

        cm_map = new OpenLayers.Map("cm_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});

        sc_map = new OpenLayers.Map("sc_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});

        fv_map = new OpenLayers.Map("fv_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});

        rt_map = new OpenLayers.Map("rt_map", {controls: [ new OpenLayers.Control.Navigation({documentDrag: true})]});

        console.log(hv_map.getSize())
        console.log(mb_map.getSize())

        fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
        toProjection = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection;

        size = new OpenLayers.Size(2,2);
        offset = new OpenLayers.Pixel(-(size.w/2), -size.h);

        mOptions = {
            gridSize: 50,
            maxZoom: 15
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

                            //debugger;

                            var location = results[0].geometry.location;


                        }

                    }

                });

            var hvmarkers = new OpenLayers.Layer.Markers("Markers");
            var hvcurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var hvcurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var hvcurrentPositionMarker = new OpenLayers.Marker(hvcurrentPosition, hvcurrentPositionIcon.clone());
            var hvmapnik = new OpenLayers.Layer.OSM();


            hv_map.addLayer(hvmapnik);
            hv_map.addLayer(hvmarkers);
            hv_map.setCenter (hvcurrentPosition, zoom);

            hvmarkers.addMarker(hvcurrentPositionMarker);

            api_key =  $("#hv_map").data("apikey")

            Hivemaps.addplacemarker(hv_map,lat, lng,api_key)

            hv_map.events.register("moveend", hv_map, function(){

                var mapExtent = hv_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

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

                                    $("#hive_address").html(formattedAddress)
                                    $("#hive_country").html(country)
                                }

                                //debugger;

                                var location = results[0].geometry.location;


                            }

                        }

                    });





            });

            // setting for hive map

            var mbmarkers = new OpenLayers.Layer.Markers("Markers");
            var mbcurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var mbcurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var mbcurrentPositionMarker = new OpenLayers.Marker(mbcurrentPosition, mbcurrentPositionIcon.clone());
            var mbmapnik = new OpenLayers.Layer.OSM();


            mb_map.addLayer(mbmapnik);
            mb_map.addLayer(mbmarkers);
            mb_map.setCenter (mbcurrentPosition, zoom);

            mbmarkers.addMarker(mbcurrentPositionMarker);

            mb_map.events.register("moveend", mb_map, function(){

                var mapExtent = mb_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                var xCoord = mapExtent.lat
                var yCoord = mapExtent.lon

                console.log(xCoord)
                console.log(yCoord)

                var url = 'api/hivev2/get_topic_by_latlon';
                var api_key=  $("#mb_map").data("apikey");
                data =  {cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#mb_map").data("apikey")};

                Hivemaps.addplacemarker(mb_map,lat, lng,api_key)

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
                                    $("#meal_address").html(formattedAddress)
                                    $("#meal_country").html(country)
                                }

                                //debugger;

                                var location = results[0].geometry.location;


                            }

                        }

                    });

            });


            // setting for mealbox map

            var cmmarkers = new OpenLayers.Layer.Markers("Markers");
            var cmcurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var cmcurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var cmcurrentPositionMarker = new OpenLayers.Marker(cmcurrentPosition, cmcurrentPositionIcon.clone());
            var cmmapnik = new OpenLayers.Layer.OSM();


            cm_map.addLayer(cmmapnik);
            cm_map.addLayer(cmmarkers);
            cm_map.setCenter (cmcurrentPosition, zoom);

            cmmarkers.addMarker(cmcurrentPositionMarker);

            cm_map.events.register("moveend", cm_map, function(){

                var mapExtent = cm_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                var xCoord = mapExtent.lat
                var yCoord = mapExtent.lon

                console.log(xCoord)
                console.log(yCoord)

                var url = 'api/hivev2/get_topic_by_latlon';
                var api_key = $("#cm_map").data("apikey")

                data =  {cur_lat: xCoord,
                    cur_long: yCoord,
                    api_key: $("#cm_map").data("apikey")};

                Hivemaps.addplacemarker(cm_map,lat, lng,api_key)

                //$.ajax({
                //    dataType: "json",
                //    cache: false,
                //    url:url,
                //    data: data,
                //    error: function(XMLHttpRequest, errorTextStatus, error){
                //        showMessage("Failed to submit : "+ errorTextStatus+" ;"+error);
                //    },
                //    success: function(data){
                //
                //        if (data.latestTopics.length > 0){
                //            title = data.pop_topic.title
                //            topic_count = data.latestTopics.length
                //
                //            username = data.latestTopicUsers[0]
                //            user_count = data.latestTopicUsers.length
                //
                //            post_count = data.pop_topic_posts.length
                //
                //            console.log(title)
                //
                //            console.log("post_count ",post_count)
                //
                //            $("#c-topic-count").html(topic_count)
                //            $("#c-topic-title").html(title)
                //            $("#c-user-count").html(user_count)
                //            $("#c-user-name").html(username)
                //            $("#c-post-count").html(post_count)
                //        }else{
                //            $("#c-topic-count").html('0')
                //            $("#c-topic-title").html('no topic')
                //            $("#c-user-count").html('0')
                //            $("#c-user-name").html('no user')
                //            $("#c-post-count").html('0')
                //        }
                //
                //
                //        $(data.latestTopics).each(function(e){
                //
                //        });
                //    }
                //});

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
                                    $("#carmic_address").html(formattedAddress)
                                    $("#carmic_country").html(country)
                                }

                                //debugger;

                                var location = results[0].geometry.location;


                            }

                        }

                    });

            });

            // setting for carmunicate map

            var scmarkers = new OpenLayers.Layer.Markers("Markers");
            var sccurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var sccurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var sccurrentPositionMarker = new OpenLayers.Marker(sccurrentPosition, sccurrentPositionIcon.clone());
            var scmapnik = new OpenLayers.Layer.OSM();


            sc_map.addLayer(scmapnik);
            sc_map.addLayer(scmarkers);
            sc_map.setCenter (sccurrentPosition, zoom);

            scmarkers.addMarker(sccurrentPositionMarker);

            sc_map.events.register("moveend", sc_map, function(){

                var mapExtent = sc_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                var xCoord = mapExtent.lat
                var yCoord = mapExtent.lon

                console.log(xCoord)
                console.log(yCoord)

                var api_key = $("#sc_map").data("apikey")

                Hivemaps.addplacemarker(sc_map,lat, lng,api_key)

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
                                    $("#socal_address").html(formattedAddress)
                                    $("#socal_country").html(country)
                                }

                                //debugger;

                                var location = results[0].geometry.location;


                            }

                        }

                    });

            });

            // setting for socal map

            var fvmarkers = new OpenLayers.Layer.Markers("Markers");
            var fvcurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var fvcurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var fvcurrentPositionMarker = new OpenLayers.Marker(fvcurrentPosition, fvcurrentPositionIcon.clone());
            var fvmapnik = new OpenLayers.Layer.OSM();


            fv_map.addLayer(fvmapnik);
            fv_map.addLayer(fvmarkers);
            fv_map.setCenter (fvcurrentPosition, zoom);

            fvmarkers.addMarker(fvcurrentPositionMarker);

            fv_map.events.register("moveend", fv_map, function(){

                var mapExtent = fv_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                var xCoord = mapExtent.lat
                var yCoord = mapExtent.lon

                console.log(xCoord)
                console.log(yCoord)

                //$.ajax({
                //    data: {
                //        cur_lat: xCoord,
                //        cur_long: yCoord,
                //        api_key: $("#fv_map").data("apikey")
                //    },
                //    success: function(html) {
                //        var htmlobject = $(html);
                //        var output = htmlobject.find("#display_favrinfo")[0];
                //        var app_info = new XMLSerializer().serializeToString(output);
                //        $("#display_favrinfo").replaceWith(app_info);
                //
                //    }
                //});


                Hivemaps.addplacemarker(fv_map,lat, lng,api_key);

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
                                    $("#favr_address").html(formattedAddress)
                                    $("#favr_country").html(country)
                                }

                                //debugger;

                                var location = results[0].geometry.location;


                            }

                        }

                    });

            });

            // setting for favr map

            var rtmarkers = new OpenLayers.Layer.Markers("Markers");
            var rtcurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var rtcurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var rtcurrentPositionMarker = new OpenLayers.Marker(rtcurrentPosition, rtcurrentPositionIcon.clone());
            var rtmapnik = new OpenLayers.Layer.OSM();


            rt_map.addLayer(rtmapnik);
            rt_map.addLayer(rtmarkers);
            rt_map.setCenter (rtcurrentPosition, zoom);

            rtmarkers.addMarker(rtcurrentPositionMarker);

            rt_map.events.register("moveend", rt_map, function(){

                var mapExtent = rt_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                var xCoord = mapExtent.lat
                var yCoord = mapExtent.lon

                console.log(xCoord)
                console.log(yCoord)

                //$.ajax({
                //    data: {
                //        cur_lat: xCoord,
                //        cur_long: yCoord,
                //        api_key: $("#rt_map").data("apikey")
                //    },
                //    success: function(html) {
                //        var htmlobject = $(html);
                //        var output = htmlobject.find("#display_roundinfo")[0];
                //        var app_info = new XMLSerializer().serializeToString(output);
                //        $("#display_roundinfo").replaceWith(app_info);
                //    }
                //});

               Hivemaps.addplacemarker(rt_map,lat, lng,api_key);

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
                                    $("#round_address").html(formattedAddress)
                                    $("#round_country").html(country)
                                }

                                //debugger;

                                var location = results[0].geometry.location;


                            }

                        }

                    });

            });

            // setting for round trop map
        }

    },
    fail:function(){} ,


    addplacemarker:function(param_map,param_lat, param_lng,api_key){

        markerArray = new Array();
        var places = new Array();
        var latestTopicUser = new Array();

        var url = '/api/places/retrieve_places';
        $.ajax({
            url: url,
            data: {hivvemap: ''},
            success: function(data) {

                places = data.places
                latestTopicUser = data.latestTopicUser


                for (var i = 0; i < places.length; i++)
                {
                    lat = places[i].latitude;
                    lng = places[i].longitude;

                    title = places[i].name;
                    id = places[i].id;
                    var placePosition = new OpenLayers.LonLat(lng,lat).transform(fromProjection, toProjection);
                    var placeMarker;
                    if (latestTopicUser[i] != "nothing")
                    {
                        if (title.indexOf("MRT") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/MapMRT.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());

                        }
                        else if (latestTopicUser[i].indexOf("Aardvark") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/AardvarkMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Alligator") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/AlligatorMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Bear") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/BearMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Beaver") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/BeaverMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Bluebird") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/BluebirdMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Butterfly") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/ButterflyMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Cat") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/CatMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Chihuahua") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/ChihuahuaMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Chipmunk") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/ChipmunkMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Duck") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/DuckMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Eagle") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/EagleMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Elephant") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/ElephantMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Giraffe") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/GiraffeMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Horse") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/HorseMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Husky") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/HuskyMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Jaguar") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/JaguarMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Kangaroo") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/KangarooMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Kitten") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/KittenMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Koala") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/KoalaMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Lion") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/LionMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Llama") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/LlamaMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Monkey") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/MonkeyMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Panda") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/PandaMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Penguin") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/PenguinMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Puppy") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/PuppyMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());

                        }
                        else if (latestTopicUser[i].indexOf("Raydius") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/RaydiusMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Seal") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/SealMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Snorkie") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/SnorkieMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Swan") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/SwanMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Tiger") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/TigerMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else if (latestTopicUser[i].indexOf("Whale") != -1)
                        {
                            var icon = new OpenLayers.Icon('/assets/map/WhaleMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else
                        {
                            var icon = new OpenLayers.Icon('/assets/map/SingleMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                    }
                    else
                    {
                        if (title.indexOf("MRT" != -1))
                        {
                            var icon = new OpenLayers.Icon('/assets/map/MapMRT.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                        else
                        {
                            var icon = new OpenLayers.Icon('/assets/map/SingleMap.png', size, offset);
                            placeMarker = new OpenLayers.Marker(placePosition, icon.clone());
                        }
                    }
                    markerArray.push(placeMarker);
                    placeMarker.title = places[i].name;
                    placeMarker.id = places[i].id;
                    placeMarker.url = null;

                }

                // Settings for clustering markers
                mOptions = {
                    gridSize: 50,
                    maxZoom: 15
                };


                var markerCluster = new MarkerClusterer(param_map, markerArray, mOptions,param_lat, param_lng,api_key);
            }
        });




    },



};


window.Hivemaps = Hivemaps ;