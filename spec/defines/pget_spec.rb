require 'spec_helper'

describe 'pget' do
  let(:title){'Download Puppet'}
  let(:facts){{:operatingsystem => "Windows"}}

  shared_examples 'without user pass' do |protocol|
    let(:params){{:source => "#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi",:target => "C:/software"}}
    it{
      should contain_exec('Download-puppet-3.4.1.msi').with({
        'provider' => 'powershell',
        'command' => "\$wc = New-Object System.Net.WebClient;\$wc.DownloadFile('#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi','C:/software/puppet-3.4.1.msi')"
      })
    }
  end
  shared_examples 'with header' do |protocol|
    let(:params){{:source => "#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi",:target => "C:/software",:headerHash => {"Cookie"=>"C is for Cookie","user-agent"=>"Who dat"}}}
    it{
      should contain_exec('Download-puppet-3.4.1.msi').with({
                                                                'provider' => 'powershell',
                                                                'command' => "\$wc = New-Object System.Net.WebClient;\$wc.Headers.Add('Cookie','C is for Cookie');\$wc.Headers.Add('user-agent','Who dat');\$wc.DownloadFile('#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi','C:/software/puppet-3.4.1.msi')"
                                                            })
    }
  end

  shared_examples 'with user pass' do |protocol|
    let(:params){{:password => 'testme',:username => 'testuser',:source => "#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi",:target => "C:/software"}}
    it{
      should contain_exec('Download-puppet-3.4.1.msi').with({
        'provider' => 'powershell',
        'command' => "\$wc = New-Object System.Net.WebClient;\$wc.Credentials = New-Object System.Net.NetworkCredential('testuser','testme');\$wc.DownloadFile('#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi','C:/software/puppet-3.4.1.msi')"
      })
    }
  end

  %w(ftp sftp ftps https http).each do |protocol|
    describe "Download msi #{protocol}" do
      include_examples 'without user pass',protocol
    end
    describe "Download msi with Headers for #{protocol}" do
      include_examples 'with header',protocol
    end
    describe "Download msi #{protocol} with credentials" do
      include_examples 'with user pass',protocol
    end
    describe "Download via #{protocol} without password" do
      let(:params){{:username => 'testuser',:source => "#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi",:target => "C:/software/"}}
      it{
        expect{
          should contain_exec('Download-puppet-3.4.1.msi')
        }.to raise_error(Puppet::Error,/Password must be supplied/)
      }
    end
    describe "Download via #{protocol} without username" do
      let(:params){{:password => 'testpass',:source => "#{protocol}://downloads.puppetlabs.com/windows/puppet-3.4.1.msi",:target => "C:/software/"}}
      it{
        expect{
          should contain_exec('Download-puppet-3.4.1.msi')
        }.to raise_error(Puppet::Error,/Username must be supplied/)
      }
    end
  end
  %w(redhat ubuntu debian).each do |os|
    describe "Attempt using with #{os}" do
      let(:params){{:source => "http://downloads.puppetlabs.com/windows/puppet-3.4.1.msi",:target => "C:/software/"}}
      let(:facts){{:operatingsystem => os}}
      it{
        expect {
          should contain_exec("Download-puppet-3.4.1.msi")
        }.to raise_error(Puppet::Error, /Unsupported OS #{os}/)
      }
    end
  end
  describe "Download via puppet file" do
    let(:params){{:source => "puppet:///extra_files/windows/puppet-3.4.1.msi",:target => "C:/software"}}
    it {
      should_not contain_exec('Download-puppet-3.4.1.msi')
      should contain_file('Download-puppet-3.4.1.msi').with({
          'path'    => 'C:/software/puppet-3.4.1.msi',
          'source'  => 'puppet:///extra_files/windows/puppet-3.4.1.msi',
          'ensure'  => 'file'
           })

    }
  end
end