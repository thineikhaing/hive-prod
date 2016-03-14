
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

        size = new OpenLayers.Size(50,50);
        offset = new OpenLayers.Pixel(-(size.w/2), -size.h);

        mOptions = {
            gridSize: 50,
            maxZoom: 15
        };
        latitude = '', longitude = '', zoom = 16;

        this.geoloc(this.success,this.fail);


        //cm_map.on('moveend',function(){
        //    // this will only get called when there is a actual move
        //    // this is not always idea; when doing toggling actions
        //    // before and after pan
        //    console.log("[ moveend ]");
        //}),
        //
        //cm_map.on('movestart',function(){
        //    // Whish this callback was available :(
        //    console.log("[ movestart ]");
        //})

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

            var hvmarkers = new OpenLayers.Layer.Markers("Markers");
            var hvcurrentPosition = new OpenLayers.LonLat(lng,lat).transform( fromProjection, toProjection);
            var hvcurrentPositionIcon = new OpenLayers.Icon('/assets/hivev2/WebMapMe.png', size, offset);
            var hvcurrentPositionMarker = new OpenLayers.Marker(hvcurrentPosition, hvcurrentPositionIcon.clone());
            var hvmapnik = new OpenLayers.Layer.OSM();


            hv_map.addLayer(hvmapnik);
            hv_map.addLayer(hvmarkers);
            hv_map.setCenter (hvcurrentPosition, zoom);

            hvmarkers.addMarker(hvcurrentPositionMarker);

            hv_map.events.register("moveend", hv_map, function(){

                var mapExtent = hv_map.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

                var xCoord = mapExtent.lat
                var yCoord = mapExtent.lon

                console.log(xCoord)
                console.log(yCoord)

                $.ajax({
                    data: {
                        cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#hv_map").data("apikey")
                    },
                    success: function(html) {
                        var htmlobject = $(html);
                        var output = htmlobject.find("#display_hiveinfo")[0];
                        var app_info = new XMLSerializer().serializeToString(output);
                        $("#display_hiveinfo").replaceWith(app_info);
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

                $.ajax({
                    data: {
                        cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#mb_map").data("apikey")
                    },
                    success: function(html) {
                        var htmlobject = $(html);
                        var output = htmlobject.find("#display_mealinfo")[0];
                        var app_info = new XMLSerializer().serializeToString(output);
                        $("#display_mealinfo").replaceWith(app_info);
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

                $.ajax({

                    data: {
                        cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#cm_map").data("apikey")

                    },
                    success: function(html) {
                        var htmlobject = $(html);
                        var output = htmlobject.find("#display_carmicinfo")[0];
                        var app_info = new XMLSerializer().serializeToString(output);
                        $("#display_carmicinfo").replaceWith(app_info);

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

                $.ajax({

                    data: {
                        cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#sc_map").data("apikey")

                    },
                    success: function(html) {
                        var htmlobject = $(html);
                        var output = htmlobject.find("#display_socalinfo")[0];
                        var app_info = new XMLSerializer().serializeToString(output);
                        $("#display_socalinfo").replaceWith(app_info);

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

                $.ajax({
                    data: {
                        cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#fv_map").data("apikey")
                    },
                    success: function(html) {
                        var htmlobject = $(html);
                        var output = htmlobject.find("#display_favrinfo")[0];
                        var app_info = new XMLSerializer().serializeToString(output);
                        $("#display_favrinfo").replaceWith(app_info);
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

                $.ajax({
                    data: {
                        cur_lat: xCoord,
                        cur_long: yCoord,
                        api_key: $("#rt_map").data("apikey")
                    },
                    success: function(html) {
                        var htmlobject = $(html);
                        var output = htmlobject.find("#display_roundinfo")[0];
                        var app_info = new XMLSerializer().serializeToString(output);
                        $("#display_roundinfo").replaceWith(app_info);
                    }
                });

            });

            // setting for round trop map
        }

    },
    fail:function(){}





};


window.Hivemaps = Hivemaps ;