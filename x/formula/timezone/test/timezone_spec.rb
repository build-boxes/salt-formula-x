require '/opt/serverspec/spec_helper'

describe 'Timezone configuration' do
  describe file('/etc/localtime') do
    it { should be_symlink }
    it { should be_linked_to '/usr/share/zoneinfo/America/Toronto' }
  end

  describe command('timedatectl') do
    its(:stdout) { should match /Time zone: America\/Toronto/ }
  end
end
