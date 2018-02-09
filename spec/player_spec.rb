require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Encounter::Player do
  before(:each) do
    @conn = Encounter::Connection.new(domain: 'test.en.cx')
  end

  it 'Should load existing player' do
    pl = Encounter::Player.new(@conn, uid: 1)
    expect{ pl.name }.to eq 'im'
    expect{ pl.avatar }.to eq 'http://cdn.endata.cx/data/user/0/0/1/personal/a_chwrxP.jpg'
    expect{ pl.points }.to eq 729.63
    expect{ pl.first_name}.to eq 'Иван'
    expect{ pl.last_name}.to eq ''
    
    expect{ pl.country }.to eq 'Беларусь'
    expect{ pl.region }.to eq 'Минская обл.'
    expect{ pl.city }.to eq 'Минск'
  end

  it 'Should load all possible information' do
    pl = Encounter::Player.new(@conn, uid: 144762)
    expect{ pl.first_name }.to eq 'Дмитрий'
    expect{ pl.patronymic_name }.to eq 'Александрович'
    expect{ pl.last_name }.to eq 'Колядюк'

    expect{ pl.sex }.to eq :male

    expect{ pl.birthday }.to eq '27 октября 1988'
    expect{ pl.height }.to eq 181

    expect{ pl.email }.to eq 'dnmek1@list.ru'

    expect{ pl.driver_license }.to match_array([:B, :C])
    expect{ pl.transport.size }.to eq 1
    expect{ pl.transport.first }.to include(
      type: 'Автомобиль',
      brand: 'Toyota',
      model: 'Carina',
      number: 'М694КО'
    )
  end

  it 'Should raise if no :uid given' do
    expect{ Encounter::Player.new(@conn, {}) }.to raise_error(ArgumentError)
  end
  
  it 'Should raise if user does not exists' do
    expect{
      Encounter::Player.new(@conn, uid: 6).name
    }.to raise_error(RuntimeError)
  end
end

