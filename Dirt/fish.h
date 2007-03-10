// FiSHy, a plugin for Colloquy providing Blowfish encryption.
// Copyright (C) 2007  Henning Kiel
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#ifndef FISH_H
#define FISH_H

#include <string>
#include <ios>

namespace fish {
	enum { success = 0, cut, plain_text, bad_algo, bad_chars, bad_target };
	void init();
	int encode(std::string s, std::ostream &out, const std::string &key, const bool split);
	int decode(std::string s, std::string &out, const std::string &key);
}

extern const std::string fish_base64;

#endif
