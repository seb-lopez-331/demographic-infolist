require 'json'
require 'net/http'

class AddressesController < ApplicationController
    CITY_INDEX = 1
    STATE_INDEX = 2
    ZIPCODE_INDEX = 3

    # Utility functions
    def get_info(url)
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

    def get_subpopulations(zipcode, groups)
        subpopulations = []

        groups.each do |group|
            url = URI.parse('https://api.census.gov/data/2022/acs/acs5/subject?get=%s&for=zip+code+tabulation+area:%s' % [group, zipcode])
            subpopulations.push(get_info(url))
        end

        return subpopulations
    end

    def get_median_income(zipcode)
        group = "S1901_C01_012E"
        url = URI.parse('https://api.census.gov/data/2022/acs/acs5/subject?get=%s&for=zip+code+tabulation+area:%s' % [group, zipcode])
        return get_info(url)
    end


    # Controller functions
    def index
        @addresses = Address.all
    end

    def show
        @address = Address.find(params[:id])
        
        # Gather fields for displaying purposes
        fields = @address.address.split(",")
        @city = fields[CITY_INDEX]
        @state = fields[STATE_INDEX]
        @zipcode = fields[ZIPCODE_INDEX]
        
        # Gather subpopulations for each each educational attainment
        educational_subpopulations = get_subpopulations(@zipcode, ["S2301_C01_031E", "S2301_C01_032E", "S2301_C01_033E", "S2301_C01_034E", "S2301_C01_035E"])
        @total_educated = educational_subpopulations[0]
        @under_hs = educational_subpopulations[1]
        @hs_grad = educational_subpopulations[2]
        @some_college = educational_subpopulations[3]
        @bachelors = educational_subpopulations[4]

        # Gather median household income
        @median_income = get_median_income(@zipcode)

        # Gather subpopulations for each houshold size
        household_size_subpopulations = get_subpopulations(@zipcode, ["S2501_C01_001E", "S2501_C01_002E", "S2501_C01_003E", "S2501_C01_004E", "S2501_C01_005E"])
        @occupied_units = household_size_subpopulations[0]
        @one_person = household_size_subpopulations[1]
        @two_people = household_size_subpopulations[2]
        @three_people = household_size_subpopulations[3]
        @four_or_more = household_size_subpopulations[4]

        # We can show 
            # Educational attainment
            # Median income levels
            # Household size

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