module SpeedTestClient
	def self.parse_result(result)
		download = result.match(/Download:.*Mbit/).to_s.match(/(\d|\.)+/).to_s
		upload = result.match(/Upload:.*Mbit/).to_s.match(/(\d|\.)+/).to_s
		{ download: download, upload: upload }
	end
end