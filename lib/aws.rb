require 'aws-sdk'

class S3
  attr_reader :client

  def initialize
    @client = Aws::S3::Client.new(
      region: 'us-east-1',
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def upload(file)
    File.open("./#{file}", 'rb') do |file|
      @client.put_object(bucket: ENV['S3_BUCKET'], key: "file", body: file)
    end
  end

  def download(file)
    @client.get_object(
      response_target: "./#{file}",
      bucket: ENV['S3_BUCKET'],
      key: file
    )
  end
end
