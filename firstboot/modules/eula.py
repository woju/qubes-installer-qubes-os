#
# Chris Lumens <clumens@redhat.com>
#
# Copyright 2007 Red Hat, Inc.
#
# This copyrighted material is made available to anyone wishing to use, modify,
# copy, or redistribute it subject to the terms and conditions of the GNU
# General Public License v.2.  This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY expressed or implied, including the
# implied warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.  Any Red Hat
# trademarks that are incorporated in the source code or documentation are not
# subject to the GNU General Public License and may only be used or replicated
# with the express permission of Red Hat, Inc. 
#
import gtk

from firstboot.config import *
from firstboot.constants import *
from firstboot.functions import *
from firstboot.module import *

import gettext
_ = lambda x: gettext.ldgettext("firstboot", x)
N_ = lambda x: x

class moduleClass(Module):
    def __init__(self):
        Module.__init__(self)
        self.priority = 2
        self.sidebarTitle = N_("License Information")
        self.title = N_("License Information")
        self.icon = "workstation.png"

    def apply(self, interface, testing=False):
        return RESULT_SUCCESS

    def createScreen(self):
        self.vbox = gtk.VBox(spacing=10)

        label = gtk.Label(("Thank you for installing Qubes. Qubes is a
            compilation of software packages, each under its own license. The
            compilation is made available under the GNU General Public License
            version 2."))

        label.set_line_wrap(True)
        label.set_alignment(0.0, 0.0)
        label.set_size_request(500, -1)
        self.vbox.pack_start(label, expand=False, fill=False)

        label = gtk.Label(_("Understood, please proceed."))
        label.set_alignment(0.0, 0.1)

        self.vbox.pack_start(label)

    def initializeUI(self):
        pass
