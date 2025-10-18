require '/opt/serverspec/spec_helper'

describe 'NTP configuration' do
  if os[:family] == 'redhat'
    describe package('chrony') do
      it { should be_installed }
    end

    describe service('chronyd') do
      it { should be_enabled }
      it { should be_running }
    end
  elsif os[:family] == 'debian'
    describe package('ntp') do
      it { should be_installed }
    end

    describe service('ntp') do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
