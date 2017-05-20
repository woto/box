json.extract! device, :id, :external_reference, :lat, :lng, :location, :is_working, :created_at, :updated_at
json.url device_url(device, format: :json)
