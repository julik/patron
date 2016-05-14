## -------------------------------------------------------------------
##
## Copyright (c) 2008 The Hive http://www.thehive.com/
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
## THE SOFTWARE.
##
## -------------------------------------------------------------------


require File.expand_path("./spec") + '/spec_helper.rb'
require 'webrick'
require 'yaml'
require 'base64'
require 'fileutils'
require 'httpi'

describe 'Patron::HTTPIAdapter' do
  
  before :all do
    require 'patron/httpi_adapter'
    HTTPI.adapter = :patron
  end
  
  let(:base_url) { "http://localhost:9001" }

  it "works with a GET" do
    resp = HTTPI.get(base_url + '/test')
    
    expect(resp.headers['Server']).to match(/WEBrick/)
    
    body = YAML.load(resp.body)
    expect(body).to be_kind_of(WEBrick::HTTPRequest)
  end
  
  it 'passes headers'
  
  it 'works with a POST with data' do
    data = SecureRandom.random_bytes(1024 * 24)
    response = HTTPI.put(base_url + "/test", data)
    body = YAML::load(response.body)
    
    expect(body).to be_kind_of(WEBrick::HTTPRequest)
    expect(body.request_method).to be == "PUT"
    expect(body.header['content-length']).to be == [data.size.to_s]
  end
end
