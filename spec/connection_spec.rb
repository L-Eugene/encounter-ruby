require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Encounter::Connection do
  it 'Should raise if no domain given' do
    expect {
      Encounter::Connection.new(username: 'test', password: 'test')
    }.to raise_error(ArgumentError)
  end
  
  it 'Should raise if domain does not exist' do
    expect {
      Encounter::Connection.new(domain: 'nodomain.en.cx')
    }.to raise_error(RuntimeError)
  end
  
  it 'Should connect without account' do
    expect {
      Encounter::Connection.new(domain: 'test.en.cx')
    }.not_to raise_error
  end
  
  it 'Should connect with account' do
    expect {
      Encounter::Connection.new(
        domain: 'test.en.cx',
        username: 'testuser',
        password: 'correct'
      )
    }.not_to raise_error
  end
  
  it 'Should raise with wrong login/password' do
    expect {
      Encounter::Connection.new(
        domain: 'test.en.cx',
        username: 'testuser',
        password: 'incorrect'
      ).to raise_error(RuntimeError)
    }
  end
end

