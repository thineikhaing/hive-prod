# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class @InfoBoxBuilder extends Gmaps.Google.Builders.Marker # inherit from base builder
  # override method

  create_infowindow: ->
    return null unless _.isString @args.infowindow

    boxText = document.createElement("div")
    boxText.setAttribute('class', 'marker_container') #to customize
    boxText.innerHTML = @args.infowindow
    @infowindow = new InfoBox(@infobox(boxText))

  # add @bind_infowindow() for < 2.1

  infobox: (boxText)->
    content: boxText
    pixelOffset: new google.maps.Size(-40, -80)
    boxStyle:
      width: "70px"
      background: "rgb(2,166,180)"
      opacity: 0.75
      padding: "5px"
      infoBoxClearance: new google.maps.Size(1, 1)

  create_marker: ->
    options = _.extend @marker_options(), @rich_marker_options()
    @serviceObject = new RichMarker options

  rich_marker_options: ->
    marker = document.createElement("div")
    marker.setAttribute('class', 'custom_marker_content')
    marker.innerHTML = this.args.custom_marker

    { content: marker,
    shadow: 'none'}


handler = Gmaps.build 'Google', { builders: { Marker: InfoBoxBuilder} }