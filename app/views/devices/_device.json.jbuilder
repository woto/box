json.extract! device, :id, :external_id, :lat, :lng, :location, :is_working, :comment, :created_at, :updated_at
json.url device_url(device, format: :json)
