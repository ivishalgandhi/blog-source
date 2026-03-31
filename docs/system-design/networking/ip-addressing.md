---
title: IP Addressing
description: IPv4 vs IPv6, addressing schemes, and network design
sidebar_position: 23
---

# IP Addressing

IP addresses are unique numerical identifiers assigned to devices on a network, enabling communication between computers across the internet.

## IPv4 Addressing

### Address Structure
- **32-bit addresses**: 4 octets of 8 bits each
- **Dotted decimal notation**: 192.168.1.1
- **Total addresses**: ~4.3 billion unique addresses
- **Address exhaustion**: Limited address space

### Address Classes
| Class | Range | Default Mask | Use Case |
|-------|-------|--------------|----------|
| A | 1.0.0.0 - 126.255.255.255 | /8 | Large networks |
| B | 128.0.0.0 - 191.255.255.255 | /16 | Medium networks |
| C | 192.0.0.0 - 223.255.255.255 | /24 | Small networks |
| D | 224.0.0.0 - 239.255.255.255 | N/A | Multicast |
| E | 240.0.0.0 - 255.255.255.255 | N/A | Reserved |

### Private Address Ranges
- **10.0.0.0 - 10.255.255.255**: Class A private
- **172.16.0.0 - 172.31.255.255**: Class B private
- **192.168.0.0 - 192.168.255.255**: Class C private

### Subnetting
- **CIDR notation**: 192.168.1.0/24
- **Subnet mask**: 255.255.255.0
- **Network bits**: Fixed portion
- **Host bits**: Variable portion

#### Subnetting Example
```
Network: 192.168.1.0/24
Subnet mask: 255.255.255.0
Host bits: 8 bits (256 addresses)
Usable hosts: 254 (2^8 - 2)
```

## IPv6 Addressing

### Address Structure
- **128-bit addresses**: 8 groups of 4 hex digits
- **Colon notation**: 2001:0db8:85a3:0000:0000:8a2e:0370:7334
- **Total addresses**: 340 undecillion (3.4×10^38)
- **Virtually unlimited**: No address exhaustion concerns

### Address Compression
- **Leading zeros**: Can be omitted
- **Consecutive zeros**: Can be compressed with ::
- **Example**: 2001:db8:85a3::8a2e:370:7334

### Address Types
- **Global Unicast**: Public internet addresses
- **Link-Local**: Communication on same network segment
- **Unique Local**: Private addresses (RFC 4193)
- **Multicast**: One-to-many communication

### IPv6 Subnetting
- **Standard prefix**: /64 for most networks
- **Host portion**: 64 bits for interface identifier
- **Subnet flexibility**: Easy to create multiple subnets

## IPv4 vs IPv6 Comparison

### Address Space
| Feature | IPv4 | IPv6 |
|---------|------|------|
| Address length | 32 bits | 128 bits |
| Total addresses | 4.3 billion | 340 undecillion |
| Address format | Dotted decimal | Colon hexadecimal |
| Private addresses | Limited ranges | Unique local addresses |

### Technical Differences
| Feature | IPv4 | IPv6 |
|---------|------|------|
| Header size | 20-60 bytes | 40 bytes |
| Fragmentation | Router and host | Host only |
| Checksum | Included | Not included |
| Security | Optional (IPsec) | Built-in (IPsec) |
| Autoconfiguration | Limited | Built-in (SLAAC) |

## Network Address Translation (NAT)

### NAT Types
- **Static NAT**: One-to-one mapping
- **Dynamic NAT**: Many-to-many mapping
- **Port Address Translation (PAT)**: Many-to-one mapping
- **Double NAT**: Multiple NAT devices

### NAT Benefits
- **Address conservation**: Extend IPv4 address space
- **Security**: Hide internal network topology
- **Flexibility**: Easy network renumbering
- **Cost savings**: Reduce public IP requirements

### NAT Limitations
- **End-to-end connectivity**: Breaks peer-to-peer
- **Protocol compatibility**: Some protocols don't work
- **Performance overhead**: Additional processing
- **Complexity**: Troubleshooting challenges

## Network Design Considerations

### Address Planning
- **Growth planning**: Allow for future expansion
- **Hierarchical design**: Organize addresses logically
- **Documentation**: Maintain address inventory
- **Consistency**: Follow naming conventions

### Subnet Design
- **Host requirements**: Calculate needed addresses
- **Network segmentation**: Separate traffic types
- **Security boundaries**: Isolate sensitive systems
- **Performance optimization**: Minimize broadcast domains

### IPv6 Transition Strategies
- **Dual stack**: Run both IPv4 and IPv6
- **Tunneling**: Encapsulate IPv6 in IPv4
- **Translation**: Convert between protocols
- **Native deployment**: IPv6-only networks

## Implementation Examples

### IPv4 Network Design
```
Network: 192.168.0.0/16
├── Servers: 192.168.1.0/24 (254 hosts)
├── Workstations: 192.168.10.0/23 (510 hosts)
├── Guest WiFi: 192.168.20.0/25 (126 hosts)
└── IoT Devices: 192.168.30.0/26 (62 hosts)
```

### IPv6 Network Design
```
Global Prefix: 2001:db8:1234::/48
├── Data Center: 2001:db8:1234:1::/64
├── Office Network: 2001:db8:1234:2::/64
├── Guest Network: 2001:db8:1234:3::/64
└── IoT Network: 2001:db8:1234:4::/64
```

### DHCP Configuration
```bash
# IPv4 DHCP scope
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    default-lease-time 86400;
    max-lease-time 604800;
}

# IPv6 DHCP configuration
subnet6 2001:db8:1234:1::/64 {
    range6 2001:db8:1234:1::100 2001:db8:1234:1::200;
    option dhcp6.name-servers 2001:4860:4860::8888;
}
```

## Best Practices

### Address Management
- **Document allocations**: Maintain address inventory
- **Plan for growth**: Reserve address blocks
- **Use standards**: Follow RFC guidelines
- **Regular audits**: Review and optimize usage

### Security Considerations
- **Network segmentation**: Isolate traffic types
- **Access control**: Limit address allocation
- **Monitoring**: Track address usage
- **Firewall rules**: Control traffic flow

### Performance Optimization
- **Appropriate subnet sizes**: Avoid waste
- **Minimize broadcast domains**: Reduce unnecessary traffic
- **Optimize routing**: Use efficient protocols
- **Monitor utilization**: Track network performance

---

**Key Takeaway**: IP addressing is fundamental to network design, requiring careful planning for scalability, security, and performance while considering the transition from IPv4 to IPv6.
