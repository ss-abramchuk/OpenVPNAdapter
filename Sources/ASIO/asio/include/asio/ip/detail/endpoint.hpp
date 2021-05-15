//
// ip/detail/endpoint.hpp
// ~~~~~~~~~~~~~~~~~~~~~~
//
// Copyright (c) 2003-2019 Christopher M. Kohlhoff (chris at kohlhoff dot com)
//
// Distributed under the Boost Software License, Version 1.0. (See accompanying
// file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef ASIO_IP_DETAIL_ENDPOINT_HPP
#define ASIO_IP_DETAIL_ENDPOINT_HPP

#if defined(_MSC_VER) && (_MSC_VER >= 1200)
# pragma once
#endif // defined(_MSC_VER) && (_MSC_VER >= 1200)

#include "asio/detail/config.hpp"
#include <string>
#include "asio/detail/socket_types.hpp"
#include "asio/detail/winsock_init.hpp"
#include "asio/error_code.hpp"
#include "asio/ip/address.hpp"

#include "asio/detail/push_options.hpp"

#if defined(ASIO_USE_KOVPN_ROUTE_ID)
#include <cstdint>
#include <uapi/ovpn/mark.h>
#endif

namespace asio {
namespace ip {
namespace detail {

// Helper class for implementating an IP endpoint.
class endpoint
{
public:
  // Default constructor.
  ASIO_DECL endpoint() ASIO_NOEXCEPT;

  // Construct an endpoint using a family and port number.
  ASIO_DECL endpoint(int family,
      unsigned short port_num) ASIO_NOEXCEPT;

  // Construct an endpoint using an address and port number.
  ASIO_DECL endpoint(const asio::ip::address& addr,
      unsigned short port_num) ASIO_NOEXCEPT;

  // Copy constructor.
  endpoint(const endpoint& other) ASIO_NOEXCEPT
    : data_(other.data_)
  {
  }

  // Assign from another endpoint.
  endpoint& operator=(const endpoint& other) ASIO_NOEXCEPT
  {
    data_ = other.data_;
    return *this;
  }

  // Get the underlying endpoint in the native type.
  asio::detail::socket_addr_type* data() ASIO_NOEXCEPT
  {
    return &data_.base;
  }

  // Get the underlying endpoint in the native type.
  const asio::detail::socket_addr_type* data() const ASIO_NOEXCEPT
  {
    return &data_.base;
  }

  // Get the underlying size of the endpoint in the native type.
  std::size_t size() const ASIO_NOEXCEPT
  {
    if (is_v4())
      return sizeof(asio::detail::sockaddr_in4_type);
    else
      return sizeof(asio::detail::sockaddr_in6_type);
  }

  // Set the underlying size of the endpoint in the native type.
  ASIO_DECL void resize(std::size_t new_size);

  // Get the capacity of the endpoint in the native type.
  std::size_t capacity() const ASIO_NOEXCEPT
  {
    return sizeof(data_);
  }

  // Get the port associated with the endpoint.
  ASIO_DECL unsigned short port() const ASIO_NOEXCEPT;

  // Set the port associated with the endpoint.
  ASIO_DECL void port(unsigned short port_num) ASIO_NOEXCEPT;

  // Get the IP address associated with the endpoint.
  ASIO_DECL asio::ip::address address() const ASIO_NOEXCEPT;

  // Set the IP address associated with the endpoint.
  ASIO_DECL void address(
      const asio::ip::address& addr) ASIO_NOEXCEPT;

  // Compare two endpoints for equality.
  ASIO_DECL friend bool operator==(const endpoint& e1,
      const endpoint& e2) ASIO_NOEXCEPT;

  // Compare endpoints for ordering.
  ASIO_DECL friend bool operator<(const endpoint& e1,
      const endpoint& e2) ASIO_NOEXCEPT;

  // Determine whether the endpoint is IPv4.
  bool is_v4() const ASIO_NOEXCEPT
  {
    return data_.base.sa_family == ASIO_OS_DEF(AF_INET);
  }

#if !defined(ASIO_NO_IOSTREAM)
  // Convert to a string.
  ASIO_DECL std::string to_string() const;
#endif // !defined(ASIO_NO_IOSTREAM)

#if defined(ASIO_USE_KOVPN_ROUTE_ID)
  int get_route_id() const
  {
    if (is_v4())
      {
	if (data_.v4_sin_ovpn_magic == SIN_OVPN_MAGIC)
	  return OVPN_MARK_ROUTE_ID(data_.v4_sin_ovpn_route_id);
      }
    else
      {
	if ((data_.v6.sin6_flowinfo & htonl(SIN6_FLOWINFO_OVPN_MASK)) == htonl(SIN6_FLOWINFO_OVPN_MAGIC))
	  return OVPN_MARK_ROUTE_ID(ntohl(data_.v6.sin6_flowinfo));
      }
    return -1;
  }

  void set_route_id(const int route_id)
  {
    if (is_v4())
      {
	if (route_id >= 0)
	  {
	    data_.v4_sin_ovpn_magic = SIN_OVPN_MAGIC;
	    data_.v4_sin_ovpn_route_id = OVPN_MARK_ROUTE_ID(route_id);
	  }
	else
	  {
	    data_.v4_sin_ovpn_magic = 0;
	    data_.v4_sin_ovpn_route_id = 0;
	  }
      }
    else
      {
	if (route_id >= 0)
	  data_.v6.sin6_flowinfo = htonl(OVPN_MARK_ROUTE_ID(route_id) | SIN6_FLOWINFO_OVPN_MAGIC);
	else
	  data_.v6.sin6_flowinfo = 0;
      }
  }
#endif

private:
  // The underlying IP socket address.
  union data_union
  {
    asio::detail::socket_addr_type base;
    asio::detail::sockaddr_in4_type v4;
    asio::detail::sockaddr_in6_type v6;
#if defined(ASIO_USE_KOVPN_ROUTE_ID)
    struct {
      std::uint8_t head_[8];

      // mirrors definition in <linux-kernel>/include/uapi/linux/in.h
      std::uint32_t v4_sin_ovpn_magic;
      std::uint32_t v4_sin_ovpn_route_id;
    };
#endif
  } data_;
};

} // namespace detail
} // namespace ip
} // namespace asio

#include "asio/detail/pop_options.hpp"

#if defined(ASIO_HEADER_ONLY)
# include "asio/ip/detail/impl/endpoint.ipp"
#endif // defined(ASIO_HEADER_ONLY)

#endif // ASIO_IP_DETAIL_ENDPOINT_HPP
