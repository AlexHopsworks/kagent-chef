require 'resolv'

module Hop
    def my_public_ip()
      node[:public_ips][0]
    end

    def my_private_ip()
      node[:private_ips][0]
    end

    def public_cookbook_ip(cookbook)
      node[cookbook][:public_ips][0]
    end

    def public_recipe_ip(cookbook, recipe)
      node[cookbook][recipe][:public_ips][0]
    end

    def private_cookbook_ip(cookbook)
      node[cookbook][:private_ips][0]
    end

    def private_recipe_ip(cookbook, recipe)
      node[cookbook][recipe][:private_ips][0]
    end

    def private_recipe_hostnames(cookbook, recipe)
      hostf = Resolv::Hosts.new
      dns = Resolv::DNS.new

      hostnames = Array.new
      for host in node[cookbook][recipe][:private_ips]
        # resolve the hostname first in /etc/hosts, then using DNS
        # If not found, then write an entry for it in /etc/hosts
        begin
          h = hostf.getname("#{host}")
        rescue
          begin
            h = dns.getname("#{host}")
          rescue
            if (node[:vagrant])
                # gsub() returns a copy of the modified str with replacements
                # gsub!() makes the replacements in-place
              # hostName = host.gsub("\.","_")
              # h = "vagrant_#{hostName}"
              # hostsfile_entry "#{host}" do
              #   hostname  "#{h}"
              #   unique    true
              #   action    :create
              # end
              #h = host
              h = "localhost"
            else 
              raise "You need to supply a valid list  of ips for #{cookbook}/#{recipe}"
            end
           end
         end
         hostnames << h 
      end
      hostnames
    end

    def set_my_hostname()
      my_ip = my_private_ip()
      hostsfile_entry "#{my_ip}" do
        hostname  node['hostname']
        unique    true
        action    :append
      end
    end

    def set_hostnames(cookbook, recipe)
      hostf = Resolv::Hosts.new
      dns = Resolv::DNS.new
      hostnames = Array.new
      for host in node[cookbook][recipe][:private_ips]
        # resolve the hostname first in /etc/hosts, then using DNS
        # If not found, then write an entry for it in /etc/hosts
        begin
            h = dns.getname("#{host}")
        rescue
            # gsub() returns a copy of the modified str with replacements, leaves original string intact.
            hostName = host.gsub("\.","_")
            h = "#{recipe}_#{hostName}"
        end
        hostsfile_entry "#{host}" do
          hostname  "#{h}"
          action    :append
        end

      end

    end


    # get ndb_mgmd_connectstring, or list of mysqld endpoints
    def service_endpoints(cookbook, recipe, port)
      str = ""
      for n in node[cookbook][recipe][:private_ips]
        str += n + ":" + "#{port}" + ","
      end
      str = str.chop
      str
    end
    
    def ndb_connectstring()
      connectString = ""
      for n in node[:ndb][:mgmd][:private_ips]
        connectString += "#{n}:#{node[:ndb][:mgmd][:port]},"
      end
      # Remove the last ','
      connectString = connectString.chop
      node.normal[:ndb][:connect_string] = connectString
    end
    
    def jdbc_url()
      # The first mysqld that a NN should contact is localhost
      # On failure, contact other mysqlds. We should configure
      # the mysqlconnector to use the first localhost and only failover
       # to other mysqlds
      jdbcUrl = "localhost:#{node[:ndb][:mysql_port]},"
      for n in node[:ndb][:mysqld][:private_ips]
        jdbcUrl += "#{n}:#{node[:ndb][:mysql_port]},"
      end
      jdbcUrl = jdbcUrl.chop
      node.normal[:ndb][:mysql][:jdbc_url] = "jdbc:mysql://" + jdbcUrl + "/"
    end
end

Chef::Recipe.send(:include, Hop)
