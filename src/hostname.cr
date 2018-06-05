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


class Hostname

	# MARK: - Initializer

	# :nodoc:
	protected def initialize(@parts : Array(String))
	end


	# MARK: - Factories

	# Constructs a new `Hostname` by interpreting the contents of a `String`.
	#
	# Expects an hostname like "example.com" or "example.com.".
	#
	# Raises: `MalformedError` when the input is malformed.
	def self.[](string : String) : self
		return new(string)
	end

	# ditto
	def self.new(string : String) : self
		return new?(string) || raise MalformedError.new()
	end

	# Constructs a new `Hostname` by interpreting the contents of a `String`.
	#
	# Expects an hostname like "example.com" or "example.com.".
	#
	# Returns: `nil` when the input is malformed.
	def self.[]?(string : String) : self?
		return new?(string)
	end

	# ditto
	def self.new?(string : String) : self?
		parts = Parser.parse(string)
		return nil if ( !parts )

		instance = self.allocate
		instance.initialize(parts)
		return instance
	end

	# Constructs a new `Hostname` by interpreting the contents of an `Array` of `String`s.
	#
	# Expects input like: ```["example", "com"]```.
	#
	# Raises: `MalformedError` when the input is malformed.
	def self.new(parts : Array(String)) : self
		return new?(parts) || raise MalformedError.new()
	end

	# Constructs a new `Hostname` by interpreting the contents of an `Array` of `String`s.
	#
	# Expects input like: ```["example", "com"]```.
	#
	# Returns: `nil` when the input is malformed.
	def self.new?(parts : Array(String))
		parts = Parser.validate(parts)
		return nil if ( !parts )

		instance = self.allocate
		instance.initialize(parts)
		return instance
	end


	# MARK: - Properties

	getter parts : Array(String)

	# Returns the number of characters in the whole hostname.
	def size() : UInt32
		return parts.reduce(-1) { |memo, part| memo + part.size + 1 }.to_u32
	end

	# Returns the number of levels in the hostname
	def levels() : UInt32
		return @parts.size().to_u32
	end


	# MARK: - Queries

	def [](index : Int) : String
		return @parts[index]
	end

	# Indicates if the domain is a top level domain.
	def tld?() : Bool
		return ( levels() == 1 )
	end


	# MARK: - Matching

	# Indicates if the domain has the given top level domain.
	def tld?(tld : String) : Bool
		return ( @parts.last == tld )
	end

	# Indicates if the domain has one of the given top level domains.
	def tld?(*tlds : String) : Bool
		return tld?(tlds)
	end

	# ditto
	def tld?(tlds : Enumerable(String)) : Bool
		return tlds.includes?(@parts.last)
	end

	# Indicates if the reciever is a subdomain of the given hostname.
	def subdomain?(other : Hostname, fqn : Bool = false) : Bool
		return false if (self.levels >= other.levels)

		o_iter = other.parts.reverse_each()
		s_iter = @parts.reverse_each()

		loop {
			o_entry = o_iter.next
			s_entry = s_iter.next

			return false if ( o_entry.is_a?(Iterator::Stop) )
			return true if ( s_entry.is_a?(Iterator::Stop) )
			return false if ( o_entry != s_entry )
		}
	end

	# Compares this hostname with another, returning `-1`, `0` or `+1` depending if the
	# hostname is less, equal or greater than the *other* hostname.
	#
	# This compares the top level alphabetically. If they match the next next level is tried.
	def <=>(other : Hostname) : Int
		o_iter = other.parts.reverse_each()
		s_iter = @parts.reverse_each()

		loop {
			o_entry = o_iter.next
			s_entry = s_iter.next

			return 0 if ( o_entry.is_a?(Iterator::Stop) && s_entry.is_a?(Iterator::Stop) )
			return 1 if ( o_entry.is_a?(Iterator::Stop) )
			return -1 if ( s_entry.is_a?(Iterator::Stop) )

			diff = (o_entry <=> s_entry)
			return diff if ( !diff.zero? )
		}
	end


	# MARK: - Relatives

	# Creates the parent hostname.
	#
	# Raises: `Enumerable::EmptyError` if the hostname is a Top-Level-Domain.
	def parent(depth : Int = 1) : Hostname
		raise Enumerable::EmptyError.new("No parent for Top-Level-Domain #{self.to_s.inspect}.") if ( tld? )
		return parent?(depth) || raise MalformedError.new()
	end

	# Creates the parent hostname.
	#
	# Returns: `nil` if the hostname is a Top-Level-Domain.
	def parent?(depth : Int = 1) : Hostname?
		return nil if ( tld? )
		return new?(@parts[1..-1])
	end

	# Creates a new child hostname (subdomain).
	#
	# Raises: `MalformedError` if the hostname is malformed.
	def child(name : String) : Hostname
		return parent?(depth) || raise MalformedError.new(name)
	end

	# Creates a new child hostname (subdomain).
	#
	# Returns: `nil` if the hostname is malformed.
	def child?(name : String) : Hostname?
		return nil if ( !NAME_REGEX.match?(name) )
		parts = Array(String).build(@parts.size + 1) { |buffer|
			buffer[0] = name
			(buffer + 1).copy_from(@parts.to_unsafe(), @parts.size)
		}
		return new?(parts)
	end


	# MARK: - Stringification

	# Appends the string representation of this hostname to the given `IO`.
	def to_s(io : IO) : Nil
		return to_s(false, io)
	end

	# Appends the string representation of this hostname to the given `IO` with the option
	# of making the hostname fully qualified.
	def to_s(fqn : Bool, io : IO) : Nil
		@parts.join('.', io)
		io << '.' if ( fqn )
	end

	# Returns the string representation of this hostname with the option of making the
	# hostname fully qualified.
	def to_s(fqn : Bool) : String
		return String.build() { |io| self.to_s(fqn, io) }
	end


	# MARK: - Errors

	# :nodoc:
	class MalformedError < Exception
		def new(was : String)
			return new("The hostname was malformed: was #{was}")
		end

		def new()
			return new("The hostname was malformed.")
		end
	end

	# :nodoc:
	class Invalid < Exception; end

	# :nodoc:
	class NotFoundError < Exception
		def new(hostname : Hostname)
			return new("No address could be resolved for #{self.inspect}.")
		end
	end

	# :nodoc:
	class ResolutionError < Exception; end

end

require "./hostname/*"
