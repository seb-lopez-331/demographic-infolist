class AddressesController < ApplicationController
    def index
        @addresses = Address.all
    end

    def show
        @address = Address.find(params[:id])
    end
end