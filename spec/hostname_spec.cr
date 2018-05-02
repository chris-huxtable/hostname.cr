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

require "./spec_helper"

private def hostname_should_be_valid(string : String, equals : String = string) : Nil
	Hostname[string]?.to_s.should eq(equals)
end

private def hostname_should_not_be_valid(string : String) : Nil
	Hostname[string]?.should be_nil
end


private def hostname_should_be_tld(string : String) : Nil
	Hostname[string].tld?.should be_true
end

private def hostname_should_not_be_tld(string : String) : Nil
	Hostname[string].tld?.should_not be_true
end


private def hostname_should_be_subdomain(string : String, other : String) : Nil
	Hostname[string].subdomain?(Hostname[other]).should be_true
end

private def hostname_should_not_be_subdomain(string : String, other : String) : Nil
	Hostname[string].subdomain?(Hostname[other]).should_not be_true
end


private def hostname_should_cmp(string : String, other : String, value : Int) : Nil
	(Hostname[string] <=> Hostname[other]).should eq(value)
end


describe Hostname do

	it "takes strings" do
		hostname_should_be_valid("test.test")
		hostname_should_be_valid("example.com")
		hostname_should_be_valid("example.com.", "example.com")

		hostname_should_be_valid("crystal-lang.org")
		hostname_should_be_valid("crystal-lang.org.", "crystal-lang.org")
	end

	it "recognizes invalid addresses" do
		hostname_should_not_be_valid("*.example.com")

		hostname_should_not_be_valid("*")

		hostname_should_not_be_valid("")
		hostname_should_not_be_valid(" ")
		hostname_should_not_be_valid(".")
		hostname_should_not_be_valid(". ")
		hostname_should_not_be_valid(".a")
		hostname_should_not_be_valid(" .a")
		hostname_should_not_be_valid(".a.")
	end

	it "handles long lengths" do
		hostname_should_be_valid("test.test.test.test.t.e.s.t.test")
		hostname_should_be_valid("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")

		hostname_should_be_valid(("1234567x" * 7) + "1234567.abc")
		hostname_should_not_be_valid(("1234567x" * 8) + ".abc")

		hostname_should_be_valid(("1.2.3.4.5.6.7.8.9.0." * 12) + "1.2.3.4.5.ab")
		hostname_should_not_be_valid(("1.2.3.4.5.6.7.8.9.0." * 12) + "1.2.3.4.5.6.ab")

		hostname_should_be_valid(("123456789." * 25) + "abc")
		hostname_should_not_be_valid(("123456789." * 25) + "abcd")
	end

	it "handles numbers characters" do
		(0..9).each() { |n|
			n = n.to_s()
			hostname_should_be_valid("#{n}.com")
			hostname_should_be_valid("example#{n}.com")
			hostname_should_be_valid("#{n}example.com")
			hostname_should_be_valid("exam#{n}ple.com")
			hostname_should_be_valid("#{n}exam#{n}ple#{n}.com")
		}
	end

	it "handles special characters" do
		"@!#$%^&()'\"+=`~".each_char() { |char|
			hostname_should_not_be_valid("#{char}.com")
			hostname_should_not_be_valid("example#{char}.com")
			hostname_should_not_be_valid("#{char}example.com")
			hostname_should_not_be_valid("exam#{char}ple.com")
		}

		"_-".each_char() { |char|
			d_char = char.to_s * 2
			hostname_should_be_valid("exa#{char}mple.com")
			hostname_should_be_valid("exa#{d_char}mple.com")
			hostname_should_be_valid("e#{char}x#{char}a#{char}m#{char}p#{char}l#{char}e.com")

			hostname_should_not_be_valid("example#{char}.com")
			hostname_should_not_be_valid("example#{d_char}.com")
			hostname_should_not_be_valid("#{char}example.com")
			hostname_should_not_be_valid("#{d_char}example.com")
		}
	end

	it "accurately represents levels" do
		repeat = "a."
		string = String.new()
		(0..125).each() { |n|
			string += repeat
			hostname_should_be_valid(string + "c")
		}
		string += repeat
		hostname_should_not_be_valid(string + "c")

	end

	it "accurately represents levels" do
		hostname_should_be_tld("com")
		hostname_should_be_tld("ca")

		hostname_should_not_be_tld("example.ca")
		hostname_should_not_be_tld("www.example.com")
		hostname_should_not_be_tld("examples.com")
	end

	it "accurately detects subdomain" do
		hostname_should_be_subdomain("example.com", "www.example.com")
		hostname_should_be_subdomain("example.com", "www.example.example.com")
		hostname_should_not_be_subdomain("example.com", "example.com")
		hostname_should_not_be_subdomain("www.example.com", "example.com")
		hostname_should_not_be_subdomain("example.ca", "example.com")
		hostname_should_not_be_subdomain("examples.com", "example.com")
		hostname_should_not_be_subdomain("examples.com", "www.example.com")
	end

	it "accurately compares" do
		hostname_should_cmp("example.com", "www.example.com", -1)
		hostname_should_cmp("example.com", "example.com", 0)
		hostname_should_cmp("www.example.com", "example.com", 1)
		hostname_should_cmp("example.ca", "example.com", 1)
		hostname_should_cmp("examples.com", "example.com", -1)
		hostname_should_cmp("examples.com", "www.example.com", -1)
	end

	it "resolves" do
		Hostname["example.com"].each_address() { |address|
			address.to_s.should eq("93.184.216.34")
		}
	end

end
