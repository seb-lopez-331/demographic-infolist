class AddressesController < ApplicationController
    def index
        @addresses = Address.all
    end

    def show
        @address = Address.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        redirect_to root_path 
    end
end