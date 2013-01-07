package 'build-essential'
package 'scons'
package 'libboost-dev'
package 'libboost-program-options-dev'
package 'libboost-thread-dev'
package 'libboost-filesystem-dev'

src_dir = node[:mongodb][:src_dir]

directory src_dir do
  recursive true
end

git src_dir do
  repository 'git://github.com/mongodb/mongo.git'
  revision node[:mongodb][:src_revision] 
  action :sync
end

execute 'build-mongodb' do
  cwd src_dir
  command 'scons all --ssl'
  creates "#{src_dir}/mongod"
end

%w(mongoimport mongodump mongoexport mongos mongorestore mongo mongostat mongotop mongofiles mongod bsondump mongooplog mongoperf).each do |binary|
  execute "copy-#{binary}" do
    command "cp #{src_dir}/#{binary} /usr/bin/"
    not_if "diff #{src_dir}/#{binary} /usr/bin/#{binary}" 
  end
end
