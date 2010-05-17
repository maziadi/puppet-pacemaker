require 'rexml/document'

Puppet::Type.type(:ha_crm_property).provide(:crm) do

	commands :crm_resource => "crm_resource"

	def create
		if resource[:meta]
			crm_resource "-m", "-r", resource[:resource], "-p", resource[:name], "-v", resource[:value]
		else
			crm_resource "-r", resource[:resource], "-p", resource[:name], "-v", resource[:value]
		end
	end

	def destroy
		if resource[:meta]
			crm_resource "-m", "-r", resource[:resource], "-d", resource[:name]
		else
			crm_resource "-r", resource[:resource], "-d", resource[:name]
		end
	end

	def exists?
		if resource[:only_run_on_dc] and Facter.value(:ha_cluster_dc) != Facter.value(:fqdn)
			resource[:value]
		else
			cib = REXML::Document.new File.open("/var/lib/heartbeat/crm/cib.xml")
			if resource[:meta]
				type = "meta"
			else
				type = "instance"
			end
			# Someone with some XPath skills can probably make this more efficient
			nvpair = REXML::XPath.first(cib, "//primitive[@id='#{resource[:resource]}']/#{type}_attributes/nvpair[@name='#{resource[:name]}']")
			nvpair = REXML::XPath.first(cib, "//master[@id='#{resource[:resource]}']/#{type}_attributes/nvpair[@name='#{resource[:name]}']") if nvpair.nil?
			nvpair = REXML::XPath.first(cib, "//clone[@id='#{resource[:resource]}']/#{type}_attributes/nvpair[@name='#{resource[:name]}']") if nvpair.nil?
			if nvpair.nil?
				:absent
			else
				nvpair.attribute(:value).value
			end
		end
	end
end
