FiSHy, a plugin for Colloquy providing Blowfish encryption.
Copyright (C) 2007  Henning Kiel

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=== About =====================================================================

FiSHy is a plugin for Colloquy, providing Blowfish encryption support. You can
encrypt messages you send to chat rooms or queries, and decrypt incoming messa-
ges.
It also supports automatic Diffie-Hellmann key-exchanges for queries, so you can
share channel-keys securely.
It also fits nicely in the OS X eco-system, by saving keys in the Keychain, and
by using a simple Drag'n'Drop install.


=== Requirements ==============================================================

OS X 10.4

Colloquy:
FiSHy makes use of some features of Colloquy which are not yet in any
official release. You can either compile an uptodate version yourself, or down-
load a nightly binary with a date later than 2007-02-22.


=== Installation ==============================================================

To install, simply drag the FiSHy bundle into Colloquy's plugin folder, located
at ~/Library/Application Support/Colloquy/PlugIns.
Then either restart Colloquy, or type "/reload plugins"


=== Usage =====================================================================

You can set the key for a channel or nickname with the /setkey command. This
command expects two parameters, the channel or nickname, and the key to be set.
	/setkey [<channel/nick>] <key>
If no channel/nick has been supplied, it tries to deduce it from the currently
shown channel/query.
The key is saved to your default keychain, where you can also edit and/or de-
lete it.

To initiate an automatic key-exchange use the /keyx command. This command ex-
pects one parameter, the nickname of the person you wish to exchange keys.
	/keyx [<nickname>]
If no nickname has been supplied, it tries to deduce it from the currently
shown query.
Keys from automatic key-exchanges are not saved to the Keychain, and only per-
sists until the program quits. If you have a key saved in Keychain for a nick,
and then do an automatic key-exchange, FiSHy will use the exchanged key instead
of the key in the Keychain.
If a user changes its nickname, you will have to exchange keys again, as FiSHy
currently does not track nick-changes.


=== Deinstallation ============================================================

Just drag the FiSHy bundle out of Colloquy's plugin folder into the Trash. If
you also want to delete any keys saved by FiSHy, you can do so with OS X'
Keychain.app.