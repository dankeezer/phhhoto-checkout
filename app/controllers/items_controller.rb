class ItemsController < ApplicationController
  respond_to :html, :js, :json

  def initialize

  	if @booking_info.nil?
	  	booking_codes = []
	  	@booking_info = Hash.new

	  	bookings_index = JSON.parse(Item.client.get("api/3.0/booking").body)
		
		bookings_index["booking/index"].each do |booking|
			booking_codes << booking.last["code"]
		end

		booking_codes.each do |booking_code|
		  booking_code_response = JSON.parse(Item.client.get("api/3.0/booking/" + booking_code).body)

		  booking_code_response["booking"]["items"].each do |item|
			@booking_info.merge!(item.last["id"] => { name: item.last["name"], booking_code: booking_code, customer_name: booking_code_response["booking"]["customer_name"], start_date: booking_code_response["booking"]["start_date"], end_date: booking_code_response["booking"]["end_date"] })
		  end
		end
	end
  end

  def show

  	@item = Hash.new

  	grace_period = @booking_info[params[:id].to_i][:start_date] < ( Time.now.to_i - 86400 ) && @booking_info[params[:id].to_i][:end_date] < ( Time.now.to_i + 86400 )

  	if @booking_info[params[:id].to_i].nil? || grace_period
  	  item_response = JSON.parse(Item.client.get("api/3.0/item/" + params[:id]).body)
  	  @item.merge!(:name => item_response["item"]["name"], :customer_name => "Not Reserved")
  	  @date = ""
  	else
  	  @item = @booking_info[params[:id].to_i]
  	  @date = "On:" + Time.at(@item[:start_date]).to_date.to_formatted_s(:rfc822)
  	end

    respond_to do |format|
      format.html
      format.svg  { render options }
      format.png  { render options }
      format.jpeg { render options }
      format.gif  { render options }
    end

  end

  def checkout
  	@item = @booking_info[params[:id].to_i]
  	Item.client.get("api/3.0/booking/#{@item[:booking_code]}/note?body=Checked Out: #{@item[:name]} for #{@item[:customer_name]}")
  	respond_with(@item)
  end

  def checkin
  	@item = @booking_info[params[:id].to_i]
  	Item.client.get("api/3.0/booking/#{@item[:booking_code]}/note?body=Checked In: #{@item[:name]} from #{@item[:customer_name]}")
  	respond_with(@item)
  end

  private

  def options
    {:qrcode => request.original_url, :size => 4, :color => "000000" }
  end

end
