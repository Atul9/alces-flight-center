
site = Site.create!(
  name: 'Liverpool University',
  description: <<-EOF.strip_heredoc
    Clifton Computer Science Building
    Brownlow Hill
    Liverpool
    L69 72X
  EOF
)

User.create!(
  site: site,
  name: 'Dr Cliff Addison',
  email: 'caddison@liverpool.ac.uk',
  password: 'password',
)

Cluster.create!(
  site: site,
  name: 'Hamilton Research Computing Cluster',
  description: 'A cluster for research computing',
  support_type: 'managed'
).tap do |cluster|
  ComponentGroup.create!(
    cluster: cluster,
    name: 'Rack A1 nodes',
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'node[01-20]'
  )

  ComponentGroup.create!(
    cluster: cluster,
    name: 'Rack A1 switches',
    component_type: ComponentType.find_by_name('Network switch')
  ).tap do |group|
    Component.create!(
      component_group: group,
      name: 'Rack A1 Dell N1545 1Gb Ethernet switch 1'
    )
    Component.create!(
      component_group: group,
      name: 'Rack A1 Dell N1545 1Gb Ethernet switch 2'
    )
    Component.create!(
      component_group: group,
      name: 'Rack A1 Omnipath Edge switch 45pt'
    )
  end
end

Cluster.create!(
  site: site,
  name: 'Additional cluster',
  description: 'An additional cluster for development',
  support_type: 'advice'
).tap do |cluster|
  ComponentGroup.create!(
    cluster: cluster,
    name: 'Additional cluster nodes',
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'anode[01-05]'
  )
end
