function getLatLongDetail(myLatlng) {

    var geocoder = new google.maps.Geocoder();
    geocoder.geocode({ 'latLng': myLatlng },
        function (results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                if (results[0]) {

                    var address = "", city = "", state = "", zip = "", country = "", formattedAddress = "";
                    var lat;
                    var lng;

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
                    }

                    //debugger;

                    var location = results[0].geometry.location;

                    lat = location.lat();
                    lng = location.lng();

                    //console.log('Country: '+ country + '\n' +'City: '+ city + '\n' + 'State: '+ state + '\n' + 'Zip: '+ zip + '\n' + 'Formatted Address: '+ formattedAddress + '\n' + 'Lat: '+ lat + '\n' + 'Lng: '+ lng);
                    var select_country = $('#country_list').val();
                    //console.log(select_country)
                    if (select_country != ""){
                        $("#country").text(select_country)
                    }else{
                        $("#country").text(country)
                    }
                    $("#state").text(city)
                    $("#address").text(formattedAddress)

                    return formattedAddress
                }

            }

        });



    window.getLatLongDetail = getLatLongDetail;
}

