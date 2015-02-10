class WelcomeController < ApplicationController

# todo:
  # foursquare api
  # check tripster w/o a file

  # has_many
  # http://web.archive.org/web/20100210204319/http://blog.hasmanythrough.com/2008/2/27/count-length-size

  def index
    @map_json = visited_cities
  end

  def sync # PATCH?
    # rm cities_json_filename
    # force refresh cities
  end

  private
    def visited_cities

      json_file_name = "public/cities.json"

      if File.exist? json_file_name
        return File.read(json_file_name)
      end

      cities = City.all
      if cities.empty?
         cities_refresh
      end

      json = Gmaps4rails.build_markers(cities) { |city, marker|
        title = "#{city.country_name_en}: #{city.name_en}"
        marker.lat city.latitude
        marker.lng city.longitude
        # marker.infowindow "info #{city.country_name_en}: #{city.name_en}"
        marker.title title
        marker.json({ title: city.name_en })
        marker.picture({
          :url    => "images/map/marker_one.svg",
          :width  => 20,
          :height => 20,
          :anchor => [10, 10],
        })
      }.to_json

      File.write(json_file_name, json)

      return json
    end

    def cities_refresh
      City.delete_all
      Nokogiri::XML(File.read("public/m4rr-tripster-data-basic.xml"))
      .xpath("//data/cities/city").each { |e|
        id  = e.xpath("@country_id").to_s
        ru  = e.xpath("@title_ru").to_s
        en  = e.xpath("@title_en").to_s
        lat = e.xpath("@lat").to_s.to_f
        lng = e.xpath("@lon").to_s.to_f
        country_name_en = country_name_by(id)
        City.new(
          :name_en    => en,
          :name_ru    => ru,
          :latitude   => lat,
          :longitude  => lng,
          :country_alpha2  => id,
          :country_name_en => country_name_en
        ).save
      }
    end

    def country_name_by(abbr)
      if @countries_list == nil
         @countries_list = JSON.parse(File.read('public/iso-3166-countries-list.json'))
      end
      @countries_list.select { |e| e['alpha-2'] == abbr }.first['name']
    end

end
