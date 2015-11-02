describe FaradayMiddleware::AwsSignersV4 do
  let(:response) do
    {"accountUpdate"=>
      {"name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil,
       "updateAccountInput"=>nil},
     "cloudwatchRoleArn"=>nil,
     "self"=>
      {"__type"=>
        "GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/",
       "name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil},
     "throttleSettings"=>{"burstLimit"=>1000, "rateLimit"=>500.0}}
  end

  let(:signed_headers) do
    'host;user-agent;x-amz-content-sha256;x-amz-date'
  end

  let(:default_expected_headers) do
    {"User-Agent"=>"Faraday v0.9.1",
     "X-Amz-Date"=>"20150101T000000Z",
     "Host"=>"apigateway.us-east-1.amazonaws.com",
     "X-Amz-Content-Sha256"=>
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "Authorization"=>
      "AWS4-HMAC-SHA256 Credential=akid/20150101/us-east-1/apigateway/aws4_request, " +
      "SignedHeaders=#{signed_headers}, " +
      "Signature=#{signature}"}
  end

  let(:additional_expected_headers) { {} }

  let(:expected_headers) do
    default_expected_headers.merge(additional_expected_headers)
  end

  let(:client) do
    faraday do |stub|
      stub.get('/account') do |env|
        expect(env.request_headers).to eq expected_headers
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end
  end

  before do
    stub_const('Faraday::VERSION', '0.9.1')
  end

  context 'without query' do
    let(:signature) do
      'd25bb10ed5b6735974a3d1e0bae0bd8e4e28bddfd03a39e3e9ada780d54990a7'
    end

    subject { client.get('/account').body }

    it { is_expected.to eq response }
  end

  context 'with query' do
    let(:signature) do
      '8287c520a389fbb0be36955e19d468d3c50d81cad922f59f2294a4c5b5cb6a73'
    end

    subject { client.get('/account', foo: 'bar').body }

    it { is_expected.to eq response }
  end

  context 'use net/http' do
    let(:signature) do
      '2dacc18472e7c9de3a919a128e00c3db66b257f6675a277cbe389eed993d28e6'
    end

    let(:signed_headers) do
      'accept;accept-encoding;host;user-agent;x-amz-content-sha256;x-amz-date'
    end

    let(:additional_expected_headers) do
      {"Accept"=>"*/*",
       "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3"}
    end

    before do
      expect_any_instance_of(FaradayMiddleware::AwsSignersV4).to receive(:net_http?) { true }
    end

    subject { client.get('/account', foo: 'bar').body }

    it { is_expected.to eq response }
  end
end
