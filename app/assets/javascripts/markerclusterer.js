/**
 * @name MarkerClusterer
 * @version 1.0
 * @author Xiaoxi Wu
 * @copyright (c) 2009 Xiaoxi Wu
 * @fileoverview
 * This javascript library creates and manages per-zoom-level
 * clusters for large amounts of markers (hundreds or thousands).
 * This library was inspired by the <a href="http://www.maptimize.com">
 * Maptimize</a> hosted clustering solution.
 * <br /><br/>
 * <b>How it works</b>:<br/>
 * The <code>MarkerClusterer</code> will group markers into clusters according to
 * their distance from a cluster's center. When a marker is added,
 * the marker cluster will find a position in all the clusters, and
 * if it fails to find one, it will create a new cluster with the marker.
 * The number of markers in a cluster will be displayed
 * on the cluster marker. When the map viewport changes,
 * <code>MarkerClusterer</code> will destroy the clusters in the viewport
 * and regroup them into new clusters.
 *
 */

/*
 25	 * Licensed under the Apache License, Version 2.0 (the "License");
 26	 * you may not use this file except in compliance with the License.
 27	 * You may obtain a copy of the License at
 28	 *
 29	 *     http://www.apache.org/licenses/LICENSE-2.0
 30	 *
 31	 * Unless required by applicable law or agreed to in writing, software
 32	 * distributed under the License is distributed on an "AS IS" BASIS,
 33	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 34	 * See the License for the specific language governing permissions and
 35	 * limitations under the License.
 36	 */

/**
 * @name MarkerClustererOptions
 * @class This class represents optional arguments to the {@link MarkerClusterer}
 * constructor.
 * @property {Number} [maxZoom] The max zoom level monitored by a
 * marker cluster. If not given, the marker cluster assumes the maximum map
 * zoom level. When maxZoom is reached or exceeded all markers will be shown
 * without cluster.
 * @property {Number} [gridSize=60] The grid size of a cluster in pixel. Each
 * cluster will be a square. If you want the algorithm to run faster, you can set
 * this value larger.
 * @property {Array of MarkerStyleOptions} [styles]
 * Custom styles for the cluster markers.
 * The array should be ordered according to increasing cluster size,
 * with the style for the smallest clusters first, and the style for the
 * largest clusters last.
 */

/**
 * @name MarkerStyleOptions
 * @class An array of these is passed into the {@link MarkerClustererOptions}
 * styles option.
 * @property {String} [url] Image url.
 * @property {Number} [height] Image height.
 * @property {Number} [height] Image width.
 * @property {Array of Number} [opt_anchor] Anchor for label text, like [24, 12].
 *    If not set, the text will align center and middle.
 * @property {String} [opt_textColor="black"] Text color.
 */

/**
 * Creates a new MarkerClusterer to cluster markers on the map.
 *
 * @constructor
 * @param {GMap2} map The map that the markers should be added to.
 * @param {Array of GMarker} opt_markers Initial set of markers to be clustered.
 * @param {MarkerClustererOptions} opt_opts A container for optional arguments.
 */
function MarkerClusterer(map, opt_markers, opt_opts,currentlat,currentlong,api_key) {
  // private members
  var clusters_ = [];
  var map_ = map;
  var maxZoom_ = null;
  var me_ = this;
  var gridSize_ = 60;
  var sizes = [53, 56, 66, 78, 90];
  var styles_ = [];
  var leftMarkers_ = [];
  var mcfn_ = null;
  var clusterMarkersLayer_ = new OpenLayers.Layer.Markers("Cluster Markers");
  var count = 0;
  var cur_lat = 0;
  var cur_long = 0;
  var strids;

  var i = 0;
  for (i = 1; i <= 5; ++i) {
    styles_.push({
      'url': "assets/map/Raydius_Custom_Markers" + i + ".png",
      'height': sizes[i - 1],
      'width': sizes[i - 1]
    });
  }

  if (typeof opt_opts === "object" && opt_opts !== null) {
    if (typeof opt_opts.gridSize === "number" && opt_opts.gridSize > 0) {
      gridSize_ = opt_opts.gridSize;
    }
    if (typeof opt_opts.maxZoom === "number") {
      maxZoom_ = opt_opts.maxZoom;
    }
    if (typeof opt_opts.styles === "object" && opt_opts.styles !== null && opt_opts.styles.length !== 0) {
      styles_ = opt_opts.styles;
    }
  }

  /**
   * When we add a marker, the marker may not in the viewport of map, then we don't deal with it, instead
   * we add the marker into a array called leftMarkers_. When we reset MarkerClusterer we should add the
   * leftMarkers_ into MarkerClusterer.
   */
  function addLeftMarkers_() {
    if (leftMarkers_.length === 0) {
      return;
    }
    var leftMarkers = [];
    for (i = 0; i < leftMarkers_.length; ++i) {
      me_.addMarker(leftMarkers_[i], true, null, null, true);
    }
    leftMarkers_ = leftMarkers;
  }

  /**
   * Get cluster marker images of this marker cluster. Mostly used by {@link Cluster}
   * @private
   * @return {Array of String}
   */
  this.getStyles_ = function () {
    return styles_;
  };

  /**
   * Remove all markers from MarkerClusterer.
   */
  this.clearMarkers = function () {
    for (var i = 0; i < clusters_.length; ++i) {
      if (typeof clusters_[i] !== "undefined" && clusters_[i] !== null) {
        clusters_[i].clearMarkers();
      }
    }
    clusters_ = [];
    leftMarkers_ = [];
    GEvent.removeListener(mcfn_);
  };



  /**
   * Check a marker, whether it is in current map viewport.
   * @private
   * @return {Boolean} if it is in current map viewport
   */
  function isMarkerInViewport_(marker) {
    return map_.getExtent().containsLonLat(marker.lonlat);
  }

  /**
   * When reset MarkerClusterer, there will be some markers get out of its cluster.
   * These markers should be add to new clusters.
   * @param {Array of GMarker} markers Markers to add.
   */
  function reAddMarkers_(markers) {
    var len = markers.length;
    var clusters = [];
    for (var i = len - 1; i >= 0; --i) {
      me_.addMarker(markers[i].marker, true, markers[i].isAdded, clusters, true);
    }
    addLeftMarkers_();
  }

  /**
   * Add a marker.
   * @private
   * @param {GMarker} marker Marker you want to add
   * @param {Boolean} opt_isNodraw Whether redraw the cluster contained the marker
   * @param {Boolean} opt_isAdded Whether the marker is added to map. Never use it.
   * @param {Array of Cluster} opt_clusters Provide a list of clusters, the marker
   *     cluster will only check these cluster where the marker should join.
   */
  this.addMarker = function (marker, opt_isNodraw, opt_isAdded, opt_clusters, opt_isNoCheck) {
    if (opt_isNoCheck !== true) {
      // SHOULD VIEWPORT ALWAYS BE CHECKED (regardless of opt_isNoCheck???).
      if (!isMarkerInViewport_(marker)) {
        leftMarkers_.push(marker);
        return;
      }
    }

    var isAdded = opt_isAdded;
    var clusters = opt_clusters;
    var pos = map_.getPixelFromLonLat(marker.lonlat);

    if (typeof isAdded !== "boolean") {
      isAdded = false;
    }
    if (typeof clusters !== "object" || clusters === null) {
      clusters = clusters_;
    }

    var length = clusters.length;
    var cluster = null;
    for (var i = length - 1; i >= 0; i--) {
      cluster = clusters[i];
      var center = cluster.getCenter();
      if (center === null) {
        continue;
      }
      center = map_.getPixelFromLonLat(center);

      // Found a cluster which contains the marker.
      if (pos.x >= center.x - gridSize_ && pos.x <= center.x + gridSize_ &&
        pos.y >= center.y - gridSize_ && pos.y <= center.y + gridSize_) {
        cluster.addMarker({
          'isAdded': isAdded,
          'marker': marker
        });
        if (!opt_isNodraw) {
          cluster.redraw_();
        }
        return;
      }
    }

    // No cluster contain the marker, create a new cluster.
    cluster = new Cluster(this, map);
    cluster.addMarker({
      'isAdded': isAdded,
      'marker': marker
    });
    if (!opt_isNodraw) {
      cluster.redraw_();
    }

    // Add this cluster both in clusters provided and clusters_
    clusters.push(cluster);
    if (clusters !== clusters_) {
      clusters_.push(cluster);
    }
  };

  /**
   * Remove a marker.
   *
   * @param {GMarker} marker The marker you want to remove.
   */

  this.removeMarker = function (marker) {
    for (var i = 0; i < clusters_.length; ++i) {
      if (clusters_[i].remove(marker)) {
        clusters_[i].redraw_();
        return;
      }
    }
  };

  /**
   * Redraw all clusters in viewport.
   */
  this.redraw_ = function () {
    var id_array = [];
    strids = "";
    var clusters = this.getClustersInViewport_();

    for (var i = 0; i < clusters.length; ++i) {
      clusters[i].redraw_(true);
      var myMarker = clusters[i].getMarkers();
      id_array[i] = myMarker;
    }

    for (var x = 0; x < id_array.length; x++)
    {
      if (id_array.length != 0)
      {
        for (var y = 0; y < id_array[x].length; y++)
        {
          strids += id_array[x][y].marker.id + ",";
        }
      }
    }
    if (map_.getCenter()  !=null)
    {
      var mapExtent = map_.getCenter().transform(new OpenLayers.Projection("EPSG:900913"), new OpenLayers.Projection("EPSG:4326"));

      var xCoord = mapExtent.lat - 0.0027
      var yCoord = mapExtent.lon
      var panlatlng   = new google.maps.LatLng(xCoord, yCoord);
      var geocoder = new google.maps.Geocoder();
      geocoder.geocode({ 'latLng': panlatlng }, function (results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
          var address = (results[0].formatted_address);
          $("#address").html(address);
          $.cookie('address', address, {expires:null, path: '/'});
        }
      });
      cur_lat = xCoord;
      cur_long = yCoord;

        console.log("Redraw all clusters in viewport.")
        console.log(strids)
        console.log(api_key)

        data= {
                param_place: strids,
                cur_lat: cur_lat,
                cur_long: cur_long,
                api_key: api_key
              };


        var url = 'api/hivev2/get_topic_by_latlon';

        $.ajax({
            dataType: "json",
            cache: false,
            url:url,
            data: data,
            error: function(XMLHttpRequest, errorTextStatus, error){
                console.log("Failed to submit : "+ errorTextStatus+" ;"+error);
            },
            success: function(data){

                console.log(data.pop_topic)

                console.log(data.activeUsersArray)

                appname= data.appname

                console.log(appname)

                if (data.usercount > 0) {

                    usercount = data.usercount
                    username = data.activename
                    avatar= data.avatar

                    console.log(usercount)
                    console.log(username)
                    console.log(avatar)

                    image ='<img src="'+avatar+'"><img/>'

                    if (appname == "carmunicate"){

                        $("#c-usercount").html(usercount)
                        $("#c-username").html(username)
                        $("#c-avatar").html(image)
                    }
                    else if(appname == "favr"){

                        $("#f-usercount").html(usercount)
                        $("#f-username").html(username)
                        $("#f-avatar").html(image)

                    }
                    else if(appname == "meal"){

                        $("#m-usercount").html(usercount)
                        $("#m-username").html(username)
                        $("#m-avatar").html(image)
                    }
                    else if(appname == "socal"){

                        $("#s-usercount").html(usercount)
                        $("#s-username").html(username)
                        $("#s-avatar").html(image)
                    }
                    else if(appname == "round"){
                        $("#r-usercount").html(usercount)
                        $("#r-username").html(username)
                        $("#r-avatar").html(image)
                    }
                    else{

                        $("#h-usercount").html(usercount)
                        $("#h-username").html(username)
                        $("#h-avatar").html(image)
                    }

                }else
                {

                    image ='<img src="assets/Avatars/Chat-Avatar.png"><img/>'

                    if (appname == "carmunicate"){

                        $("#c-usercount").html("0")
                        $("#c-username").html("no user")
                        $("#c-avatar").html(image)
                    }
                    else if(appname == "favr"){

                        $("#f-usercount").html("0")
                        $("#f-username").html("no user")
                        $("#f-avatar").html(image)

                    }
                    else if(appname == "meal"){

                        $("#m-usercount").html("0")
                        $("#m-username").html("no user")
                        $("#m-avatar").html(image)
                    }
                    else if(appname == "socal"){

                        $("#s-usercount").html("0")
                        $("#s-username").html("no user")
                        $("#s-avatar").html(image)
                    }
                    else if(appname == "round"){
                        $("#r-usercount").html("0")
                        $("#r-username").html("no user")
                        $("#r-avatar").html(image)
                    }
                    else{

                        $("#h-usercount").html("0")
                        $("#h-username").html("no user")
                        $("#h-avatar").html(image)
                    }

                }


                if (data.topic_count > 0){

                    title = data.pop_topic.title
                    topic_count = data.topic_count
                    post_count = data.post_count

                    console.log(topic_count)
                    console.log(title)
                    console.log(appname)
                    console.log(post_count)

                    if (appname == "carmunicate"){

                        $("#c-topic-count").html(topic_count)
                        $("#c-topic-title").html(title)
                        $("#c-post-count").html(post_count)

                    }
                    else if(appname == "favr"){

                        $("#f-topic-count").html(topic_count)
                        $("#f-topic-title").html(title)
                        $("#f-post-count").html(post_count)

                    }
                    else if(appname == "meal"){
                        console.log("meal info")
                        $("#m-topic-count").html(topic_count)
                        $("#m-topic-title").html(title)
                        $("#m-post-count").html(post_count)
                    }
                    else if(appname == "socal"){
                        $("#s-topic-count").html(topic_count)
                        $("#s-topic-title").html(title)
                        $("#s-post-count").html(post_count)
                    }
                    else if(appname == "round"){
                        $("#r-topic-count").html(topic_count)
                        $("#r-topic-title").html(title)
                        $("#r-post-count").html(post_count)
                    }
                    else{
                        $("#h-topic-count").html(topic_count)
                        $("#h-topic-title").html(title)
                        $("#h-post-count").html(post_count)
                    }

                }
                else{

                    if (appname == "carmunicate"){

                        $("#c-topic-count").html("0")
                        $("#c-topic-title").html("no topic")
                        $("#c-post-count").html("0")
                    }
                    else if(appname == "favr"){

                        $("#f-topic-count").html("0")
                        $("#f-topic-title").html("no topic")
                        $("#f-post-count").html("0")

                    }
                    else if(appname == "meal"){
                        $("#m-topic-count").html("0")
                        $("#m-topic-title").html("no topic")
                        $("#m-post-count").html("0")
                    }
                    else if(appname == "socal"){
                        $("#s-topic-count").html("0")
                        $("#s-topic-title").html("no topic")
                        $("#s-post-count").html("0")
                    }
                    else if(appname == "round"){
                        ("#r-topic-count").html("0")
                        $("#r-topic-title").html("no topic")
                        $("#r-post-count").html("0")
                    }
                    else{
                        $("#h-topic-count").html("0")
                        $("#h-topic-title").html("no topic")
                        $("#h-post-count").html("0")
                    }


                }

            }
        });


    }
  };
  /**
   * Get all clusters in viewport.
   * @return {Array of Cluster}
   */
  this.getClustersInViewport_ = function () {
    var clusters = [];

    var curBounds = map_.getExtent();
    for (var i = 0; i < clusters_.length; i ++) {
      if (clusters_[i].isInBounds(curBounds)) {
        clusters.push(clusters_[i]);
      }
    }
    return clusters;
  };

  /**
   * Get max zoom level.
   * @private
   * @return {Number}
   */
  this.getMaxZoom_ = function () {
    return maxZoom_;
  };

  /**
   * Get map object.
   * @private
   * @return {GMap2}
   */
  this.getMap_ = function () {
    return map_;
  };

  /**
   * Get grid size
   * @private
   * @return {Number}
   */
  this.getGridSize_ = function () {
    return gridSize_;
  };

  this.getClusterMarkersLayer = function () {
    return clusterMarkersLayer_;
  }

  /**
   * Get total number of markers.
   * @return {Number}
   */
  this.getTotalMarkers = function () {
    var result = 0;
    for (var i = 0; i < clusters_.length; ++i) {
      result += clusters_[i].getTotalMarkers();
    }
    return result;
  };

  /**
   * Get total number of clusters.
   * @return {int}
   */
  this.getTotalClusters = function () {
    return clusters_.length;
  };

  /**
   * Collect all markers of clusters in viewport and regroup them.
   */
  this.resetViewport = function () {
    count++;

    var clusters = this.getClustersInViewport_();
    var tmpMarkers = [];
    var removed = 0;

    for (var i = 0; i < clusters.length; ++i) {
      var cluster = clusters[i];
      var oldZoom = cluster.getCurrentZoom();
      if (oldZoom === null) {
        continue;
      }
      var curZoom = map_.getZoom();
      if (curZoom !== oldZoom) {

        // If the cluster zoom level changed then destroy the cluster
        // and collect its markers.
        var mks = cluster.getMarkers();
        for (var j = 0; j < mks.length; ++j) {
          var newMarker = {
            'isAdded': false,
            'marker': mks[j].marker
          };
          tmpMarkers.push(newMarker);
        }
        cluster.clearMarkers();
        removed++;
        for (j = 0; j < clusters_.length; ++j) {
          if (cluster === clusters_[j]) {
            clusters_.splice(j, 1);
          }
        }
      }
    }

    // Add the markers collected into marker cluster to reset
    reAddMarkers_(tmpMarkers);
    this.redraw_();
  };

  /**
   * Add a set of markers.
   *
   * @param {Array of GMarker} markers The markers you want to add.
   */
  this.addMarkers = function (markers) {
    for (var i = 0; i < markers.length; ++i) {
      this.addMarker(markers[i], true);
    }
    this.redraw_();

  };

  // initialize
  if (typeof opt_markers === "object" && opt_markers !== null) {
    this.addMarkers(opt_markers);
  }

  // when map move end, regroup.
  //mcfn_ = GEvent.addListener(map_, "moveend", function () {
  //  me_.resetViewport();
  //});

  map_.events.register('moveend', map_, function () {
    me_.resetViewport();
  });

  clusterMarkersLayer_.setVisibility(true);
  map_.addLayer(clusterMarkersLayer_);
}

/**
 * Create a cluster to collect markers.
 * A cluster includes some markers which are in a block of area.
 * If there are more than one markers in cluster, the cluster
 * will create a {@link ClusterMarker_} and show the total number
 * of markers in cluster.
 *
 * @constructor
 * @private
 * @param {MarkerClusterer} markerClusterer The marker cluster object
 */
function Cluster(markerClusterer) {
  var center_ = null;
  var centerIcon_ = null;
  var centerURL_ = null;
  var centerTitle_ = null;
  var centerId_ = null;
  var markers_ = [];
  var markerClusterer_ = markerClusterer;
  var map_ = markerClusterer.getMap_();
  var clusterMarker_ = null;
  var zoom_ = map_.getZoom();

  /**
   * Get markers of this cluster.
   *
   * @return {Array of GMarker}
   */
  this.getMarkers = function () {
    return markers_;
  };

  /**
   * If this cluster intersects certain bounds.
   *
   * @param {GLatLngBounds} bounds A bounds to test
   * @return {Boolean} Is this cluster intersects the bounds
   */
  this.isInBounds = function (bounds) {
    if (center_ === null) {
      return false;
    }

    if (!bounds) {
      bounds = map_.getExtent();
    }
    var sw = map_.getPixelFromLonLat(new OpenLayers.LonLat(bounds.left, bounds.bottom));
    var ne = map_.getPixelFromLonLat(new OpenLayers.LonLat(bounds.right, bounds.top));

    var centerxy = map_.getPixelFromLonLat(center_);
    var inViewport = true;
    var gridSize = markerClusterer.getGridSize_();
    if (zoom_ !== map_.getZoom()) {
      var dl = map_.getZoom() - zoom_;
      gridSize = Math.pow(2, dl) * gridSize;
    }
    if (ne.x !== sw.x && (centerxy.x + gridSize < sw.x || centerxy.x - gridSize > ne.x)) {
      inViewport = false;
    }
    if (inViewport && (centerxy.y + gridSize < ne.y || centerxy.y - gridSize > sw.y)) {
      inViewport = false;
    }
    return inViewport;
  };

  /**
   * Get cluster center.
   *
   * @return {GLatLng}
   */
  this.getCenter = function () {
    return center_;
  };

  /**
   * Add a marker.
   *
   * @param {Object} marker An object of marker you want to add:
   *   {Boolean} isAdded If the marker is added on map.
   *   {GMarker} marker The marker you want to add.
   */
  this.addMarker = function (marker) {
    if (center_ === null) {
      /*var pos = marker['marker'].lonlat;
       pos = map.fromLatLngToContainerPixel(pos);
       pos.x = parseInt(pos.x - pos.x % (GRIDWIDTH * 2) + GRIDWIDTH);
       pos.y = parseInt(pos.y - pos.y % (GRIDWIDTH * 2) + GRIDWIDTH);
       center = map.fromContainerPixelToLatLng(pos);*/
      center_ = marker.marker.lonlat;
      centerIcon_ = marker.marker.icon;
//      centerURL_ = marker.marker.URL;
      centerTitle_ = marker.marker.title;
      centerId_ = marker.marker.id;
    }
    markers_.push(marker);
  };

  /**
   * Remove a marker from cluster.
   *
   * @param {GMarker} marker The marker you want to remove.
   * @return {Boolean} Whether find the marker to be removed.
   */
  this.removeMarker = function (marker) {
    for (var i = 0; i < markers_.length; ++i) {
      if (marker === markers_[i].marker) {
        if (markers_[i].isAdded) {
          map_.removeOverlay(markers_[i].marker);
        }
        markers_.splice(i, 1);
        return true;
      }
    }
    return false;
  };

  /**
   * Get current zoom level of this cluster.
   * Note: the cluster zoom level and map zoom level not always the same.
   *
   * @return {Number}
   */
  this.getCurrentZoom = function () {
    return zoom_;
  };

  /**
   * Redraw a cluster.
   * @private
   * @param {Boolean} isForce If redraw by force, no matter if the cluster is
   *     in viewport.
   */
  this.redraw_ = function (isForce) {
    if (!isForce && !this.isInBounds()) {
      return;
    }
    // Set cluster zoom level.
    zoom_ = map_.getZoom();
    var i = 0;
    var c = 0;
    var mz = markerClusterer.getMaxZoom_();

    if (mz === null) {
      mz = map_.getNumZoomLevels();
    }

    if ( zoom_ >= mz || this.getTotalMarkers() === 1 ) {
      // If current zoom level is beyond the max zoom level or the cluster
      // have only one marker, the marker(s) in cluster will be showed on map.
      // Single pins
      for (i = 0; i < markers_.length; ++i) {
        if (markers_[i].isAdded) {
          if (!markers_[i].marker.onScreen()) {
            markers_[i].marker.display();
          }
        }
        else {
          //map_.addOverlay(markers_[i].marker);
//          var iconSize =  new OpenLayers.Size(50,50);
//          var iconOffset = new OpenLayers.Pixel(-(iconSize.w/2), -iconSize.h);
//          var yellowDotIcon = new OpenLayers.Icon('/assets/map/Raydius_Custom_Markers1.png', iconSize, iconOffset);
          //var feature = new OpenLayers.Feature(markerClusterer.getClusterMarkersLayer(), center_, {icon:yellowDotIcon.clone(), id:"single marker"});
//          var marker = new OpenLayers.Marker(center_, yellowDotIcon.clone());
          var marker = new OpenLayers.Marker(center_, centerIcon_.clone());
          marker.icon.imageDiv.title = centerTitle_;
          marker.events.register("click", marker, function(e) {

          var topics = new Array();
          topics = gon.latestTopics;
          var topic_id;
          for (var i = 0; i < topics.length; i++)
          {
            if (topics[i])
            {
              if (topics[i].place_information.id == centerId_)
                topic_id = topics[i].id;
            }
          }
          //clear the existing selected item
          var selected = new Array();
          selected = document.getElementsByClassName("selected");
          for (var i = 0; i < selected.length; i++)
          {
            document.getElementsByClassName("selected")[i].innerHTML=("&nbsp;");
          }

          //get all normal_topic and put image
          var topic_lists = new Array();
          var count = 0;
          topic_lists = document.getElementsByName("topic_lists");
          if (topic_id)
          {
            for (var i = 0; i < topic_lists.length; i++)
            {
              if (topic_lists[i].getAttribute("topicID").toString()== topic_id.toString())
              {
                topic_lists[i].getElementsByClassName("selected")[0].innerHTML = ( "<img height='20px' src='/assets/Pointer.png' width='15px'/>" );
                break;
              }
              else
              {
                count ++;
              }
            }
          }
          else
          {
            //clear the existing post

          }



          console.log("gon latestTopics;")
          console.log(topic_id)

          var scrollHeight = 0;
          $.ajax({
            data: {
              id: topic_id
            },
            success: function(html) {
              var htmlobject = $(html);
              var output = htmlobject.find("#display_post")[0];
              var testing = new XMLSerializer().serializeToString(output);
              $("#display_post").replaceWith(testing);
              var  list_post = new Array();
              list_post = gon.list_posts;
              var current_user = gon.current_user;
              scrollHeight = (60*count) ;
              var channel = "topics_" + topic_id;
              console.height = scrollHeight;
              var objDiv = $("#display_topic");
              if  (objDiv)
              {
                objDiv.scrollTop(scrollHeight);
              }
              var topicsShow = new TopicsShow(
                {
                  id: topic_id,
                  posts: list_post,
                  user_id: current_user,
                  channel: channel
                });
            }
          });

        });
        markerClusterer.getClusterMarkersLayer().addMarker(marker);
        markers_[i].isAdded = true;
      }
    }
      // AG removed these 3 lines - not sure if they should be here or better without?
//      if (clusterMarker_ !== null) {
//        clusterMarker_.display();
//      }
    }
    else {
      // Else add a cluster marker on map to show the number of markers in
      // this cluster.
      for (i = 0; i < markers_.length; ++i) {
        if (markers_[i].isAdded && (markers_[i].marker.onScreen())) {
          markers_[i].marker.display();
        }
      }
      // Clustering
      if (clusterMarker_ === null) {
        //clusterMarker_ = new ClusterMarker_(center_, this.getTotalMarkers(), markerClusterer_.getStyles_(), markerClusterer_.getGridSize_());
        //map_.addOverlay(clusterMarker_);
        var size = Math.min(this.getTotalMarkers(), 40);
        if (size < 50) size = 50;
        var iconSize =  new OpenLayers.Size(size,size);
        var iconOffset = new OpenLayers.Pixel(-(iconSize.w/2), -iconSize.h);
        var whiteDotIcon = new OpenLayers.Icon('/assets/map/Raydius_Custom_Markers3.png', iconSize, iconOffset);
        //var feature = new OpenLayers.Feature(markerClusterer.getClusterMarkersLayer(), center_, {icon:whiteDotIcon.clone(), id:"N = " + this.getTotalMarkers()});
        clusterMarker_ = new OpenLayers.Marker(center_, whiteDotIcon.clone());

        clusterMarker_.events.register("click", clusterMarker_, function(e) {
          map_.setCenter(center_, zoom_ + 1)
        });

        markerClusterer.getClusterMarkersLayer().addMarker(clusterMarker_);
        //clusterMarker_.events.register("mousedown", feature, this.clickOnObs);
      }
      else {
        if (!clusterMarker_.onScreen()) {
          clusterMarker_.display();
        }
//        clusterMarker_.redraw(true);
//        TODO: What to do here instead of line above?
        markerClusterer.getClusterMarkersLayer().removeMarker(clusterMarker_);
        clusterMarker_.destroy();

        var size = Math.min(this.getTotalMarkers(), 40);
        if (size < 50) size = 50;
        var iconSize =  new OpenLayers.Size(size,size);
        var iconOffset = new OpenLayers.Pixel(-(iconSize.w/2), -iconSize.h);
        var whiteDotIcon = new OpenLayers.Icon('/assets/map/Raydius_Custom_Markers3.png', iconSize, iconOffset);
        //var feature = new OpenLayers.Feature(markerClusterer.getClusterMarkersLayer(), center_, {icon:whiteDotIcon.clone(), id:"N = " + this.getTotalMarkers()});
        clusterMarker_ = new OpenLayers.Marker(center_, whiteDotIcon.clone());

        clusterMarker_.events.register("click", clusterMarker_, function(e) {
          map_.setCenter(center_, zoom_ + 1)
        });

        markerClusterer.getClusterMarkersLayer().addMarker(clusterMarker_);
        //clusterMarker_.events.register("mousedown", feature, this.clickOnObs);
      }
    }
  };

  this.clickOnObs = function (e) {
    alert("clickOnObs");
    var feature = this;
    var pos = map_.getPixelFromLonLat(feature.marker.lonlat);
    var padding = markerClusterer_.getGridSize_();

    var sw = new OpenLayers.Pixel(pos.x - padding, pos.y + padding);
    var swLonLat = map_.getLonLatFromPixel(sw);
    var ne = new OpenLayers.Pixel(pos.x + padding, pos.y - padding);
    var neLonLat = map_.getLonLatFromPixel(ne);

    var clusterBounds = new OpenLayers.Bounds(sw.x, sw.y, ne.x, ne.y);
    map_.zoomToExtent(clusterBounds);

    //var zoom = map_.getZoomForExtent(clusterBounds);
    //map_.setCenter(feature.marker.lonlat, zoom, true, true);
  };

  /**
   * Remove all the markers from this cluster.
   */
  this.clearMarkers = function () {
    if (clusterMarker_ !== null) {
      //map_.removeOverlay(clusterMarker_);
      markerClusterer.getClusterMarkersLayer().removeMarker(clusterMarker_);
      clusterMarker_.destroy();
    }
    for (var i = 0; i < markers_.length; ++i) {
      if (markers_[i].isAdded) {
        markerClusterer.getClusterMarkersLayer().removeMarker(markers_[i].marker); //??
//        markers_[i].marker.destroy();
      }
    }
    markers_ = [];
  };

  /**
   * Get number of markers.
   * @return {Number}
   */
  this.getTotalMarkers = function () {
    return markers_.length;
  };
}


/**
 * ClusterMarker_ creates a marker that shows the number of markers that
 * a cluster contains.
 *
 * @constructor
 * @private
 * @param {GLatLng} latlng Marker's lat and lng.
 * @param {Number} count Number to show.
 * @param {Array of Object} styles The image list to be showed:
 *   {String} url Image url.
 *   {Number} height Image height.
 *   {Number} width Image width.
 *   {Array of Number} anchor Text anchor of image left and top.
 *   {String} textColor text color.
 * @param {Number} padding Padding of marker center.
 */
function ClusterMarker_(latlng, count, styles, padding) {
  var index = 0;
  var dv = count;
  while (dv !== 0) {
    dv = parseInt(dv / 10, 10);
    index ++;
  }

  if (styles.length < index) {
    index = styles.length;
  }
  this.url_ = styles[index - 1].url;
  this.height_ = styles[index - 1].height;
  this.width_ = styles[index - 1].width;
  this.textColor_ = styles[index - 1].opt_textColor;
  this.anchor_ = styles[index - 1].opt_anchor;
  this.latlng_ = latlng;
  this.index_ = index;
  this.styles_ = styles;
  this.text_ = count;
  this.padding_ = padding;
}

//ClusterMarker_.prototype = new GOverlay();

/**
 * Initialize cluster marker.
 * @private
 */
ClusterMarker_.prototype.initialize = function (map) {
  this.map_ = map;
  var div = document.createElement("div");
  var latlng = this.latlng_;
  var pos = map.fromLatLngToDivPixel(latlng);
  pos.x -= parseInt(this.width_ / 2, 10);
  pos.y -= parseInt(this.height_ / 2, 10);
  var mstyle = "";
  if (document.all) {
    mstyle = 'filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(sizingMethod=scale,src="' + this.url_ + '");';
  } else {
    mstyle = "background:url(" + this.url_ + ");";
  }
  if (typeof this.anchor_ === "object") {
    if (typeof this.anchor_[0] === "number" && this.anchor_[0] > 0 && this.anchor_[0] < this.height_) {
      mstyle += 'height:' + (this.height_ - this.anchor_[0]) + 'px;padding-top:' + this.anchor_[0] + 'px;';
    } else {
      mstyle += 'height:' + this.height_ + 'px;line-height:' + this.height_ + 'px;';
    }
    if (typeof this.anchor_[1] === "number" && this.anchor_[1] > 0 && this.anchor_[1] < this.width_) {
      mstyle += 'width:' + (this.width_ - this.anchor_[1]) + 'px;padding-left:' + this.anchor_[1] + 'px;';
    } else {
      mstyle += 'width:' + this.width_ + 'px;text-align:center;';
    }
  } else {
    mstyle += 'height:' + this.height_ + 'px;line-height:' + this.height_ + 'px;';
    mstyle += 'width:' + this.width_ + 'px;text-align:center;';
  }
  var txtColor = this.textColor_ ? this.textColor_ : 'black';

  div.style.cssText = mstyle + 'cursor:pointer;top:' + pos.y + "px;left:" +
    pos.x + "px;color:" + txtColor +  ";position:absolute;font-size:11px;" +
    'font-family:Arial,sans-serif;font-weight:bold';
  div.innerHTML = this.text_;
  map.getPane(G_MAP_MAP_PANE).appendChild(div);
  var padding = this.padding_;
  GEvent.addDomListener(div, "click", function () {
    var pos = map.fromLatLngToDivPixel(latlng);
    var sw = new GPoint(pos.x - padding, pos.y + padding);
    sw = map.fromDivPixelToLatLng(sw);
    var ne = new GPoint(pos.x + padding, pos.y - padding);
    ne = map.fromDivPixelToLatLng(ne);
    var zoom = map.getBoundsZoomLevel(new GLatLngBounds(sw, ne), map.getSize());
    map.setCenter(latlng, zoom);
  });
  this.div_ = div;
};

/**
 * Remove this overlay.
 * @private
 */
ClusterMarker_.prototype.remove = function () {
  this.div_.parentNode.removeChild(this.div_);
};

/**
 * Copy this overlay.
 * @private
 */
ClusterMarker_.prototype.copy = function () {
  return new ClusterMarker_(this.latlng_, this.index_, this.text_, this.styles_, this.padding_);
};

/**
 * Redraw this overlay.
 * @private
 */
ClusterMarker_.prototype.redraw = function (force) {
  if (!force) {
    return;
  }
  var pos = this.map_.getPixelFromLonLat(this.latlng_);
  pos.x -= parseInt(this.width_ / 2, 10);
  pos.y -= parseInt(this.height_ / 2, 10);
  this.div_.style.top =  pos.y + "px";
  this.div_.style.left = pos.x + "px";
};

/**
 * Hide this cluster marker.
 */
ClusterMarker_.prototype.hide = function () {
  this.div_.style.display = "none";
};

/**
 * Show this cluster marker.
 */
ClusterMarker_.prototype.show = function () {
  this.div_.style.display = "";
};

/**
 * Get whether the cluster marker is hidden.
 * @return {Boolean}
 */
ClusterMarker_.prototype.isHidden = function () {
  return this.div_.style.display === "none";
};
