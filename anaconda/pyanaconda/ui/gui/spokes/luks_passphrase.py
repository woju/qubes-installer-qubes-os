# -*- coding: utf-8 -*-
#
# The Qubes OS Project, http://www.qubes-os.org
#
# Copyright (C) 2015  Marek Marczykowski-Górecki
#                                   <marmarek@invisiblethingslab.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#


import sys
import re
import langtable
from gi.repository import Gtk, Gdk
import pwquality

from pyanaconda.ui.gui import GUIObject

from pyanaconda.i18n import _, N_

from pyanaconda.ui.gui.hubs.summary import SummaryHub
from pyanaconda.ui.gui.spokes import StandaloneSpoke
from pyanaconda.ui.gui.spokes.lib.passphrase import PassphraseDialog
from pyanaconda.ui.gui.spokes.lib.passphrase import ERROR_NOT_MATCHING

import logging
log = logging.getLogger("anaconda")

__all__ = ["LUKSPassphraseSpoke"]

class LUKSPassphraseSpoke(PassphraseDialog, StandaloneSpoke):
    builderObjects = ["LUKSPassphraseWindow"]
    mainWidgetName = "LUKSPassphraseWindow"
    uiFile = "spokes/luks_passphrase.glade"

    postForHub = SummaryHub
    priority = 0

    _update_passphrase_strength = PassphraseDialog._update_passphrase_strength

    def __init__(self, data, *args, **kwargs):
        StandaloneSpoke.__init__(self, data, *args, **kwargs)
        PassphraseDialog.__init__(self, data)

    @property
    def completed(self):
        return not any(
            d for d in self.storage.devices
            if d.format.type == "luks"
            and not d.format.exists
            and not d.format.hasKey)

    def refresh(self):
        StandaloneSpoke.refresh(self)
        #super(LUKSPassphraseSpoke, self).refresh()

        # disable input methods for the passphrase Entry widgets and make sure
        # the focus change mask is enabled
        self._passphrase_entry.set_property("im-module", "")
        self._passphrase_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "")
        self._passphrase_entry.add_events(Gdk.EventMask.FOCUS_CHANGE_MASK)
        self._confirm_entry.set_property("im-module", "")
        self._confirm_entry.add_events(Gdk.EventMask.FOCUS_CHANGE_MASK)

        #self._save_button.set_can_default(True)

        # add the passphrase strength meter
        self._strength_bar = Gtk.LevelBar()
        self._strength_bar.set_mode(Gtk.LevelBarMode.DISCRETE)
        self._strength_bar.set_min_value(0)
        self._strength_bar.set_max_value(4)
        self._strength_bar.add_offset_value("low", 2)
        self._strength_bar.add_offset_value("medium", 3)
        self._strength_bar.add_offset_value("high", 4)
        box = self.builder.get_object("strength_box")
        box.pack_start(self._strength_bar, False, True, 0)
        box.show_all()

        # set up passphrase quality checker
        self._pwq = pwquality.PWQSettings()
        self._pwq.read_config()

        # initialize with the previously set passphrase
        self.passphrase = self.data.autopart.passphrase

        if not self.passphrase:
            self.window.set_may_continue(False)

        self._passphrase_entry.set_text(self.passphrase)
        self._confirm_entry.set_text(self.passphrase)

        self._update_passphrase_strength()

    def apply(self):
        self.passphrase = self._passphrase_entry.get_text()

        # make sure any device/passphrase pairs we've obtained are remembered
        for device in self.storage.devices:
            if device.format.type == "luks" and not device.format.exists:
                if not device.format.hasKey:
                    device.format.passphrase = self.passphrase

                self.storage.savePassphrase(device)

    def on_passphrase_changed(self, entry):
        self._update_passphrase_strength()
        if entry.get_text() and entry.get_text() == self._confirm_entry.get_text():
            self._set_entry_icon(self._confirm_entry, "", "")
            self.window.set_may_continue(True)
        else:
            self.window.set_may_continue(False)

        if not self._pwq_error:
            self._set_entry_icon(entry, "", "")

    def on_confirm_changed(self, entry):
        if entry.get_text() and entry.get_text() == self._passphrase_entry.get_text():
            self._set_entry_icon(entry, "", "")
            self.window.set_may_continue(True)
        else:
            self.window.set_may_continue(False)

    def on_confirm_editing_done(self, entry, *args):
        passphrase = self._passphrase_entry.get_text()
        confirm = self._confirm_entry.get_text()
        if passphrase != confirm:
            icon = "gtk-dialog-error"
            msg = ERROR_NOT_MATCHING
            self._set_entry_icon(entry, icon, _(msg))
            self.window.set_may_continue(False)
        else:
            self._set_entry_icon(entry, "", "")

    def on_entry_activated(self, entry):
        self.window.emit("continue-clicked")
