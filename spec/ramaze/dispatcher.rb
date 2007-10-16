#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'spec/helper'

class TCDispatcherController < Ramaze::Controller
  map '/'

  def index
    "Hello, World!"
  end
end

describe "Dispatcher" do
  before :all do
    ramaze :ignore => ['/favicon.ico', '/robots.txt'],
      :ignore_body => 'File not found'
  end

  it 'should resolve a normal request' do
    page = get('/')
    page.status.should == 200
    page.body.should == 'Hello, World!'
  end

  it 'should ignore /favicon.ico' do
    Ramaze::Global.ignore = ['/favicon.ico']
    page = get('/favicon.ico')
    page.status.should == 404
    page.body.should == 'File not found'
  end
end