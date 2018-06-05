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


class Hostname::Parser

	SEPARATOR = '.'
	@char : Char?

	def self.parse(string : String) : Array(String)?
		parser = new(string)
		return parser.parse()
	end

	def self.validate(parts : Array(String)) : Array(String)?
		parts = validate_sizes(parts)
		return nil if ( !parts )

		parts = validate_parts(parts)
		return nil if ( !parts )

		return parts
	end


	# MARK: - Initializer

	def initialize(string : String)
		@cursor = Char::Reader.new(string)
		@char = @cursor.current_char()
	end


	# MARK: - Utilities

	def self.validate_sizes(parts : Array(String)) : Array(String)?
		return nil if ( parts.empty?() )
		return nil if ( parts.size() > 127 )

		length = parts.reduce(0) { |memo, part| memo + part.size }
		length += (parts.size - 1)
		return nil if ( length < 1 || length > 253 )

		return parts
	end

	def self.validate_parts(parts : Array(String)) : Array(String)?
		parts.each() { |part|
			return nil if ( part.empty? )
			return nil if ( part.size > 63 )

			return nil if part[0].ascii_alphanumeric?
			return nil if part[-1].ascii_alphanumeric?

			part.each_char_with_index() { |char, index|
				return nil if ( !char.ascii_alphanumeric? && char != '-' && char != '_' )
			}
		}

		return parts
	end

	# Parse a whole hostname.
	protected def parse() : Array(String)?
		parts = Array(String).new()

		while ( part = parse_part() )
			parts << part
		end

		return nil if !at_end?()
		return Parser.validate_sizes(parts)
	end

	# Parse a part of the hostname.
	protected def parse_part() : String?
		return nil if at_end?()

		string = String.build() { |buffer|
			char = current?()

			return nil if ( !char )
			return nil if ( char == SEPARATOR )
			return nil if !char.ascii_alphanumeric?
			buffer << char.downcase

			while ( char = self.next?() )
				break if ( char == SEPARATOR )
				return nil if !char.ascii_alphanumeric? && char != '-' && char != '_'
				buffer << char.downcase
			end
			self.next?
		}
		return nil if ( string.size < 1 )
		return nil if ( string.size > 63 )

		return nil if !string[0].ascii_alphanumeric?
		return nil if !string[-1].ascii_alphanumeric?

		return string
	end

	# Is the cursor at the end?
	protected def at_end?() : Bool
		return !@cursor.has_next?
	end

	# What is the current character.
	protected def current?() Char?
		return @char
	end

	# Move to the next position, return the character or `nil`.
	protected def next?() : Char?
		return @char = nil if at_end?
		@char = @cursor.next_char()
		@char = nil if @char == Char::ZERO
		return @char
	end

end
