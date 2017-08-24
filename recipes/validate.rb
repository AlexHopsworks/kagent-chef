  bash "validate_setup" do
    user "root"
    code <<-EOF
    if [ -d #{node['install']['dir']} ] ; then
#       chown root:#{node['hops']['hdfs']['user']} #{node['install']['dir']}
#       chmod 755 #{node['install']['dir']}
    fi    
 EOF
  end

