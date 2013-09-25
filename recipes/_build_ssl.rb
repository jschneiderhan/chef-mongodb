include_recipe "git"

ssh_known_hosts_entry 'github.com'

package 'build-essential'
package 'scons'
package 'libboost-dev'
package 'libboost-program-options-dev'
package 'libboost-thread-dev'
package 'libboost-filesystem-dev'


directory node['mongodb']['source']['prefix']

build_options = []
build_options << '--ssl' if node['mongodb']['ssl']['enabled']
build_options << "-j #{node['cpu']['total']}"

mongo_source_tarball = "mongodb-src-r#{node[:mongodb][:source][:version]}.tar.gz"
mongo_source_url = "#{node['mongodb']['source']['url']}/#{mongo_source_tarball}"

directory node['mongodb']['source']['src_dir'] do
  action :create
end

remote_file "#{Chef::Config.file_cache_path}/#{mongo_source_tarball}" do
  source mongo_source_url
  mode 0644
  checksum node['mongodb']['source']['sha']
  notifies :run, "execute[mongodb-extract-source]", :immediately
end

execute "mongodb-extract-source" do
  command "tar zxf #{Chef::Config.file_cache_path}/#{mongo_source_tarball} --strip-components 1 -C #{node['mongodb']['source']['src_dir']}"
  creates "#{node['mongodb']['source']['src_dir']}/COPYING"
  only_if do File.exist?("#{Chef::Config.file_cache_path}/#{mongo_source_tarball}") end
  action :run
  notifies :run, "execute[build-mongodb]", :immediately
end

execute 'build-mongodb' do
  action :nothing
  cwd node['mongodb']['source']['src_dir']
  creates "mongod" # TODO: Verify
  command "scons all #{build_options.join(' ')}"
  notifies :run, "execute[install-mongodb]"
end

execute 'install-mongodb' do
  action :nothing
  cwd node['mongodb']['source']['src_dir']
  creates "#{node['mongodb']['source']['prefix']}/bin/mongodb"
  command "scons --prefix #{node['mongodb']['source']['prefix']} install"
end
