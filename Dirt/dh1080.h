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

#ifndef DH1080_H
#define DH1080_H

#include <openssl/dh.h>
#include <openssl/bn.h>
#include <string>
#include <map>

class dhclass {
public:
	dhclass();
	~dhclass();
	void reset();
	bool generate();
	bool compute();
	bool set_her_key(std::string &her_public_key);
	void get_public_key(std::string &s);
	void get_secret(std::string &s);
private:
	DH *dh;
	BIGNUM *herpubkey;
	std::string secret;
};

struct recvkeystruct {
	std::string sender;
	std::string keydata;
};

extern std::map<std::string, dhclass> dhs;
extern std::map<std::string, recvkeystruct> recvkeys;

void dh_base64encode(std::string &s);
void dh_base64decode(std::string &s);

#endif
