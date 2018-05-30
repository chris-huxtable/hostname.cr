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


private def should_be_valid(string : String, equals : String = string, ) : Nil
	Hostname[string]?.to_s.should eq(equals)
end

private def should_not_be_valid(string : String) : Nil
	Hostname[string]?.should be_nil
end


private def should_be_tld(string : String) : Nil
	Hostname[string].tld?.should be_true
end

private def should_not_be_tld(string : String) : Nil
	Hostname[string].tld?.should_not be_true
end


private def should_be_subdomain(string : String, other : String) : Nil
	Hostname[string].subdomain?(Hostname[other]).should be_true
end

private def should_not_be_subdomain(string : String, other : String) : Nil
	Hostname[string].subdomain?(Hostname[other]).should_not be_true
end


private def should_cmp(string : String, other : String, value : Int) : Nil
	(Hostname[string] <=> Hostname[other]).should eq(value)
end


describe Hostname do

	it "takes strings" do
		should_be_valid("test.test")
		should_be_valid("example.com")
		should_be_valid("example.com.", "example.com")

		should_be_valid("crystal-lang.org")
		should_be_valid("crystal-lang.org.", "crystal-lang.org")
	end

	it "recognizes invalid addresses" do
		should_not_be_valid("*.example.com")

		should_not_be_valid("*")

		should_not_be_valid("")
		should_not_be_valid(" ")
		should_not_be_valid(".")
		should_not_be_valid(". ")
		should_not_be_valid(".a")
		should_not_be_valid(" .a")
		should_not_be_valid(".a.")
	end

	it "handles long lengths" do
		should_be_valid("test.test.test.test.t.e.s.t.test")
		should_be_valid("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")

		should_be_valid(("1234567x" * 7) + "1234567.abc")
		should_not_be_valid(("1234567x" * 8) + ".abc")

		should_be_valid(("1.2.3.4.5.6.7.8.9.0." * 12) + "1.2.3.4.5.ab")
		should_not_be_valid(("1.2.3.4.5.6.7.8.9.0." * 12) + "1.2.3.4.5.6.ab")

		should_be_valid(("123456789." * 25) + "abc")
		should_not_be_valid(("123456789." * 25) + "abcd")
	end

	it "handles numbers characters" do
		(0..9).each() { |n|
			n = n.to_s()
			should_be_valid("#{n}.com")
			should_be_valid("example#{n}.com")
			should_be_valid("#{n}example.com")
			should_be_valid("exam#{n}ple.com")
			should_be_valid("#{n}exam#{n}ple#{n}.com")
		}
	end

	it "handles special characters" do
		"@!#$%^&()'\"+=`~".each_char() { |char|
			should_not_be_valid("#{char}.com")
			should_not_be_valid("example#{char}.com")
			should_not_be_valid("#{char}example.com")
			should_not_be_valid("exam#{char}ple.com")
		}

		"_-".each_char() { |char|
			d_char = char.to_s * 2
			should_be_valid("exa#{char}mple.com")
			should_be_valid("exa#{d_char}mple.com")
			should_be_valid("e#{char}x#{char}a#{char}m#{char}p#{char}l#{char}e.com")

			should_not_be_valid("example#{char}.com")
			should_not_be_valid("example#{d_char}.com")
			should_not_be_valid("#{char}example.com")
			should_not_be_valid("#{d_char}example.com")
		}
	end

	it "accurately represents levels" do
		repeat = "a."
		string = String.new()
		(0..125).each() { |n|
			string += repeat
			should_be_valid(string + "c")
		}
		string += repeat
		should_not_be_valid(string + "c")

	end

	it "accurately represents levels" do
		should_be_tld("com")
		should_be_tld("ca")

		should_not_be_tld("example.ca")
		should_not_be_tld("www.example.com")
		should_not_be_tld("examples.com")
	end

	it "accurately detects subdomain" do
		should_be_subdomain("example.com", "www.example.com")
		should_be_subdomain("example.com", "www.example.example.com")
		should_not_be_subdomain("example.com", "example.com")
		should_not_be_subdomain("www.example.com", "example.com")
		should_not_be_subdomain("example.ca", "example.com")
		should_not_be_subdomain("examples.com", "example.com")
		should_not_be_subdomain("examples.com", "www.example.com")
	end

	it "accurately compares" do
		should_cmp("example.com", "www.example.com", -1)
		should_cmp("example.com", "example.com", 0)
		should_cmp("www.example.com", "example.com", 1)
		should_cmp("example.ca", "example.com", 1)
		should_cmp("examples.com", "example.com", -1)
		should_cmp("examples.com", "www.example.com", -1)
	end

	it "resolves" do
		Hostname["example.com"].each_address() { |address|
			address.to_s.should eq("93.184.216.34")
		}
	end

end
