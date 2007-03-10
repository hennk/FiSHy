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

#include "fish.h"
#include "misc.h"
#include <openssl/blowfish.h>
#include <ostream>
#include <vector>
#include <algorithm>

using namespace std;

union bf_data {
	struct {
		unsigned long left;
		unsigned long right;
	} lr;
	BF_LONG bf_long;
};

const string fish_base64 = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

const string fish_str = "fish";
vector<string> fish_prefix;

inline void backward(string &text);
inline void fish_encrypt(string in, string &out, const string &key);
inline int fish_decrypt(string in, string &out, const string &key);

void fish::init()
{
	fish_prefix.clear();
	fish_prefix.push_back("+OK");
	fish_prefix.push_back("mcps");
}

int fish::encode(string in, ostream &out, const string &key, const bool split)
{
	string enc;
	const string::size_type maxlen = 256;
	while (split && in.size() > maxlen) {
		string substr = in.substr(0, maxlen/* - 3*/);
		in.erase(0, maxlen/* - 3*/);
		//substr += ">>>";
		//in.insert(0, ">>>");
		fish_encrypt(substr, enc, key);
		out << fish_prefix.at(0) << " " << enc << endl;
	}
	fish_encrypt(in, enc, key);
	out << fish_prefix.at(0) << " " << enc << endl;
	return success;
}

int fish::decode(string in, string &out, const string &key)
{
	string ts;
	if (in.substr(0, 1) == "[") {
		string::size_type i = in.find("] ", 1);
		if (i != string::npos) {
			ts = in.substr(0, i + 2);
			in.erase(0, ts.size());
		}
	}
	string prefix;
	string::size_type i = in.find(" ", 0);
	vector<string>::iterator iter = fish_prefix.end();
	if (i != string::npos) {
		prefix = in.substr(0, i);
		iter = find(fish_prefix.begin(), fish_prefix.end(), prefix);
	}
	if (prefix.empty() || iter == fish_prefix.end()) {
		out = ts + in;
		return plain_text;
	}
	string dec;
	int ret = fish_decrypt(in.substr(prefix.size() + 1), dec, key);
	if (ret == bad_chars) {
		out = ts + in;
	} else {
		out = ts + dec;
	}
	return ret;
}

inline void backward(string &text)
{
	string s;
	for (int i = text.size() - 1; i >= 0; i--) s += text[i];
	text.swap(s);
}

inline void fish_encrypt(string in, string &out, const string &key)
{
	int datalen = in.size();
	if (datalen % 8 != 0) {
		datalen += 8 - (datalen % 8);
		in.resize(datalen, 0);
	}
	out.erase();
	BF_KEY bf_key;
	BF_set_key(&bf_key, key.size(), (unsigned char *)key.data());
	bf_data data;
	unsigned long i, part;
	unsigned char *s = (unsigned char *)in.data();
	for (i = 0; i < in.size(); i += 8) {
		data.lr.left = *s++ << 24;
		data.lr.left += *s++ << 16;
		data.lr.left += *s++ << 8;
		data.lr.left += *s++;
		data.lr.right = *s++ << 24;
		data.lr.right += *s++ << 16;
		data.lr.right += *s++ << 8;
		data.lr.right += *s++;
		BF_encrypt(&data.bf_long, &bf_key);
		for (part = 0; part < 6; part++) {
			out += fish_base64[data.lr.right & 0x3f];
			data.lr.right = data.lr.right >> 6;
		}
		for (part = 0; part < 6; part++) {
			out += fish_base64[data.lr.left & 0x3f];
			data.lr.left = data.lr.left >> 6;
		}
	}
}

inline int fish_decrypt(string in, string &out, const string &key)
{
	bool has_cut = false;
	if (in.size() < 12) return fish::bad_chars;
	int cut_off = in.size() % 12;
	if (cut_off > 0) {
		has_cut = true;
		in.erase(in.size() - cut_off, cut_off);
	}
	if (in.find_first_not_of(fish_base64, 0) != string::npos) return fish::bad_chars;
	out.erase();
	BF_KEY bf_key;
	BF_set_key(&bf_key, key.size(), (unsigned char *)key.data());
	bf_data data;
	unsigned long val, i, part;
	char *s = (char *)in.data();
	for (i = 0; i < in.size(); i += 12) {
		data.lr.left = 0;
		data.lr.right = 0;
		for (part = 0; part < 6; part++) {
			if ((val = fish_base64.find(*s++)) == string::npos) return fish::bad_chars;
			data.lr.right |= val << part * 6;
		}
		for (part = 0; part < 6; part++) {
			if ((val = fish_base64.find(*s++)) == string::npos) return fish::bad_chars;
			data.lr.left |= val << part * 6;
		}
		BF_decrypt(&data.bf_long, &bf_key);
		for (part = 0; part < 4; part++) out += (data.lr.left & (0xff << ((3 - part) * 8))) >> ((3 - part) * 8);
		for (part = 0; part < 4; part++) out += (data.lr.right & (0xff << ((3 - part) * 8))) >> ((3 - part) * 8);
	}
	remove_bad_chars(out);
	return cut_off ? fish::cut : fish::success;
}
