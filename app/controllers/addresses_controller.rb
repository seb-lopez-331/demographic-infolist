require 'json'
require 'net/http'

class AddressesController < ApplicationController
    CITY_INDEX = 1
    STATE_INDEX = 2
    ZIPCODE_INDEX = 3

    # Utility functions
    def get_subpopulation(url)
        """
        The response body will look something like this
        [
            [
                \"S2301_C01_031E\",
                \"zip code tabulation area\"
            ],
            [
                \"20926\",
                \"30165\"
            ]
        ]
        """
        req = Net::HTTP::Get.new(url.request_uri)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        response = http.request(req)
        parsed = JSON.parse(response.body)
        return parsed[1][0].to_i # This returns the subpopulation
    end

    def get_educational_attainment(zipcode)
        groups = ["S2301_C01_031E", "S2301_C01_032E", "S2301_C01_033E", "S2301_C01_034E", "S2301_C01_035E"]
        subpopulations = []

        groups.each do |group|
            url = URI.parse('https://api.census.gov/data/2022/acs/acs5/subject?get=%s&for=zip+code+tabulation+area:%s' % [group, @zipcode])
            subpopulations.push(get_subpopulation(url))
        end

        return subpopulations
    end

    # Controller functions
    def index
        @addresses = Address.all
    end

    def show
        @address = Address.find(params[:id])
        
        # Do a &for=zip+code+tabulation_area:ZIPCODE
        # And a &for=state:STATECODE (eg NY)
        # And a &key=APIKEY
        fields = @address.address.split(",")
        @city = fields[CITY_INDEX]
        @state = fields[STATE_INDEX]
        @zipcode = fields[ZIPCODE_INDEX]
        
        educational_subpopulations = get_educational_attainment(@zipcode)
        @total = educational_subpopulations[0]
        @under_hs = educational_subpopulations[1]
        @hs_grad = educational_subpopulations[2]
        @some_college = educational_subpopulations[3]
        @bachelors = educational_subpopulations[4]


        # We can show 
            # Educational attainment
            # Median income levels
            # Housing quality
            # Median household size

        """
        Procedure:
        2.) Once we have the zip code
        S2301_C01_031E	Estimate!!Total!!EDUCATIONAL ATTAINMENT!!Population 25 to 64 years	Employment Status	not required	S2301_C01_031EA, S2301_C01_031M, S2301_C01_031MA	0	int	S2301
        S2301_C01_032E	Estimate!!Total!!EDUCATIONAL ATTAINMENT!!Population 25 to 64 years!!Less than high school graduate	Employment Status	not required	S2301_C01_032EA, S2301_C01_032M, S2301_C01_032MA	0	int	S2301
        S2301_C01_033E	Estimate!!Total!!EDUCATIONAL ATTAINMENT!!Population 25 to 64 years!!High school graduate (includes equivalency)	Employment Status	not required	S2301_C01_033EA, S2301_C01_033M, S2301_C01_033MA	0	int	S2301
        S2301_C01_034E	Estimate!!Total!!EDUCATIONAL ATTAINMENT!!Population 25 to 64 years!!Some college or associate's degree	Employment Status	not required	S2301_C01_034EA, S2301_C01_034M, S2301_C01_034MA	0	int	S2301
        S2301_C01_035E	Estimate!!Total!!EDUCATIONAL ATTAINMENT!!Population 25 to 64 years!!Bachelor's degree or higher
        """
    rescue ActiveRecord::RecordNotFound
        redirect_to root_path 
    end
end