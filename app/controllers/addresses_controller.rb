require 'json'
require 'net/http'

##
# This class is responsible for handling application routing.
class AddressesController < ApplicationController
    CITY_INDEX = 1
    STATE_INDEX = 2
    ZIPCODE_INDEX = 3

    ##
    # A general-purpose utility function that is responsible for gathering
    # necessary information from the passed in URL.
    # 
    # @param [String, #url] a URL from the US Census API that includes a specified zip code.
    #
    # It's important to note that this function expects the response body to resemble the following
    #
    # The response body will look something like this:
    # [
    #    [
    #        "S2301_C01_031E",
    #        "zip code tabulation area"
    #    ],
    #    [
    #        "20926", <-- desired field
    #        "30165" <-- zip code
    #    ]
    # ]
    # Hence why indexing at [1][0] is justified.
    def get_info(url)
        req = Net::HTTP::Get.new(url.request_uri)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        response = http.request(req)
        parsed = JSON.parse(response.body)
        return parsed[1][0].to_i # This returns the subpopulation
    end

    ##
    # A utility function that returns subpopulations for different groups within a
    # zip code. This function is used for gathering subpopulations of educational attainments
    # and household sizes.
    #
    # @param [String, #zipcode] a valid zip code
    # @param [[]String, #groups] an array of different groups (defined by the US Census API)
    def get_subpopulations(zipcode, groups)
        subpopulations = []

        groups.each do |group|
            url = URI.parse('https://api.census.gov/data/2022/acs/acs5/subject?get=%s&for=zip+code+tabulation+area:%s' % [group, zipcode])
            subpopulations.push(get_info(url))
        end

        return subpopulations
    end

    ##
    # A utility function that returns the median income for a given zip code
    #
    # @param [String, #zipcode] a valid zip code
    def get_median_income(zipcode)
        group = "S1901_C01_012E"
        url = URI.parse('https://api.census.gov/data/2022/acs/acs5/subject?get=%s&for=zip+code+tabulation+area:%s' % [group, zipcode])
        return get_info(url)
    end

    # Controller functions

    ##
    # This function defines what is done on the main page. It loads up all addresses from the address database.
    def index
        @addresses = Address.all
    end

    ##
    # This function defines what is shown once a user clicks on an address in the main page. Not only does it display basic
    # information such as the address and name, but also makes use of the utility functions defined above to gather 
    # demographic information from the US Census API for the address's zip code.
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

    rescue ActiveRecord::RecordNotFound
        redirect_to root_path 
    end
end