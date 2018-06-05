# Copyright (c) 2018 Christian Huxtable <chris@huxtable.ca>.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require "socket"
require "ip_address"


class Hostname


	# MARK: - Resolution

	# Returns the first `IP::Address` resolved for the hostname.
	#
	# Raises: `nil` if no address is found.
	def address(family = Socket::Family::INET, type = Socket::Type::STREAM, protocol = Protocol::IP, timeout = nil) : IP::Address
		return address?(family, type, protocol, timeout) || raise NotFoundError.new(self)
	end

	# Returns the first `IP::Address` resolved for the hostname.
	#
	# Returns: `nil` if no address is found.
	def address?(family = Socket::Family::INET, type = Socket::Type::STREAM, protocol = Protocol::IP, timeout = nil) : IP::Address?
		each_address(family, type, protocol, timeout) { |address|
			return address if ( !address.nil? )
		}
	end

	# Returns an `Array` of `IP::Address`es that were resolved for the hostname.
	def addresses(family = Socket::Family::INET, type = Socket::Type::STREAM, protocol = Protocol::IP, timeout = nil) : Array(IP::Address)
		addresses = Array(IPAddress).new()
		each_address(family, type, protocol, timeout) { |address|
			addresses << address if ( !address.nil? )
		}
		return addresses.uniq!
	end

	# Yields the `IP::Address`es that were resolved for the hostname.
	def each_address(family = Socket::Family::INET, type = Socket::Type::STREAM, protocol = Socket::Protocol::IP, timeout = nil, &block)
		getaddrinfo(self.to_s(), nil, family, type, protocol, timeout) { |addrinfo_ptr|
			yield IP::Address.new(addrinfo_ptr.value.ai_addr)
		}
	end

	# Yields the `IP::Address`es, `Socket::Type`s, and `Socket:: Protocol`s that were resolved for the hostname.
	def resolve(family = Socket::Family::INET, type = Socket::Type::STREAM, protocol = Socket::Protocol::IP, timeout = nil, &block)
		getaddrinfo(self.to_s(), nil, family, type, protocol, timeout) { |ptr|
			address = IP::Address.new(ptr.value.ai_addr)
			type = Socket::Type.new(ptr.value.ai_socktype)
			protocol = Socket::Type.new(ptr.value.ai_socktype)
			yield(address, type, protocol)
		}
	end

	# :nodoc:
	private def getaddrinfo(domain, service, family, type , protocol, timeout)
		hints = LibC::Addrinfo.new
		hints.ai_family = (family || Socket::Family::UNSPEC).to_i32
		hints.ai_socktype = type
		hints.ai_protocol = protocol
		hints.ai_flags = 0

		hints.ai_flags |= LibC::AI_NUMERICSERV if ( service.is_a?(Int) )

		# On OS X < 10.12, the libsystem implementation of getaddrinfo segfaults
		# if AI_NUMERICSERV is set, and servname is NULL or 0.
		{% if flag?(:darwin) %}
			if (service == 0 || service == nil) && (hints.ai_flags & LibC::AI_NUMERICSERV)
				hints.ai_flags |= LibC::AI_NUMERICSERV
				service = "00"
			end
		{% end %}

		ret = LibC.getaddrinfo(domain, service.to_s, pointerof(hints), out ptr)

		begin
			case ret
				when 0 # success
				when LibC::EAI_NONAME then raise ResolutionError.new("No address found for #{domain}:#{service} over #{protocol}")
				else raise ResolutionError.new("getaddrinfo: #{String.new(LibC.gai_strerror(ret))}")
			end

			yield ptr
		ensure
			LibC.freeaddrinfo(ptr)
		end
	end

end
