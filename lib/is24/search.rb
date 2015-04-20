module Is24

  class Search

    def initialize connection
      @connection = connection
    end

    def find_by_location_and_radius(location, radius)
      puts "Finding by location " + location.to_s + " and radius " + radius.to_s

      coordinates = location.latitude.to_s + ";" + location.longitude.to_s + ";" + radius.to_s
      estates = radius_search(
          {
              :geocoordinates => coordinates,
              :realestatetype => ["apartmentbuy"],
          })

      ret = estates.collect do |estate|
        EstateWrapper.from_json estate
      end
      ret
    end

    def radius_search(options)
      defaults = {
          :realestatetype => ["housebuy"],
      }
      options = defaults.merge(options)
      types = options[:realestatetype]

      case types
        when String
          types = [types]
      end

      objects = []

      types.each do |type|
        options[:realestatetype] = type
        #puts "Search options are " + options.inspect

        url = @connection.build_url("search/radius", options)
        puts "Calling URL " + url.to_s

        response = @connection.get("search/radius", options )
        puts "Resp " + response.inspect
        if response.status == 200
          if response.body["resultlist.resultlist"].resultlistEntries[0]['@numberOfHits'] == "0"
            response.body["resultlist.resultlist"].resultlistEntries[0].resultlistEntries = []
          end
          arr = response.body["resultlist.resultlist"]['resultlistEntries'][0]['resultlistEntry']
          objects = objects.concat(arr)
        end
      end
      #puts "Object size " + objects.length.to_s
      objects
    end

    # this is to search specific region
    def search_regions(region)
      options = {
          :q => region,
      }

      regions = []

      puts "Search with options " + options.inspect

      response = connection.get("region", options )
      puts "responce is "  + response.inspect

      if response.status == 200
        regions.push response.body["region.regions"][0]['region'][0]
      end

      regions
    end

    # this is to search all immobility
    def search(options)
      defaults = {
          :realestatetype => ["housebuy"],
          :geocodes => 1276,
      }
      options = defaults.merge(options)
      types = options[:realestatetype]

      case types
        when String
          types = [types]
      end

      objects = []

      types.each do |type|
        options[:realestatetype] = type
        #puts "Search options are " + options.inspect

        url = connection.build_url("search/region", options)
        puts "Calling URL " + url.to_s

        response = connection.get("search/region", options )
        puts "Resp " + response.inspect
        if response.status == 200
          if response.body["resultlist.resultlist"].resultlistEntries[0]['@numberOfHits'] == "0"
            response.body["resultlist.resultlist"].resultlistEntries[0].resultlistEntries = []
          end
          arr = response.body["resultlist.resultlist"]['resultlistEntries'][0]['resultlistEntry']
          objects = objects.concat(arr)
        end
      end

      #puts "Object size " + objects.length.to_s
      objects
    end

  end

end