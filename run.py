#!/usr/bin/python3

import gi
import sys
import os
import platform
import pwd
import psutil

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

class MainWindow(Gtk.Window):

    class FieldBox(Gtk.Frame):
        def __init__(self, title):
            Gtk.Frame.__init__(self)
            self.set_label(title)

            self.grid = Gtk.Grid(row_spacing=5, column_spacing=5)
            self.row = 0

            self.add(self.grid)
            self.grid.set_border_width(15)

        def field(self, label_text, field):
            label = Gtk.Label(label=label_text)
            self.grid.attach(label, 0, self.row, 1, 1)
            self.grid.attach(field, 1, self.row, 1, 1)
            self.row = self.row + 1
            return field

        def entry(self, label_text):
            return self.field(label_text, Gtk.Entry())

    class ButtonBox(Gtk.FlowBox):
        def __init__(self):
            Gtk.FlowBox.__init__(self)

        def field(self, field):
            self.add(field)
            return field

        def button(self, label_text):
            button = Gtk.Button.new_with_label(label_text)
            self.add(button)
            return button

    def __init__(self):
        Gtk.Window.__init__(self, title="Tunic Linux Installer")

        self.set_border_width(15)

        self.stack = Gtk.Stack()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        column = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        typeFrame = Gtk.Frame(label='Installation Type')
        typeBox   = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        erase     = Gtk.RadioButton(label='Install Linux alongside Windows')
        dual      = Gtk.RadioButton.new_with_label_from_widget(erase, 'Erase entire disk and install Linux')
        custom    = Gtk.RadioButton.new_with_label_from_widget(erase, 'Custom/Advanced')
        typeBox.add(erase)
        typeBox.add(dual)
        typeBox.add(custom)
        typeFrame.add(typeBox)
        column.add(typeFrame)

        box = self.FieldBox('')
        self.distro = box.field('Distro', Gtk.ComboBoxText())
        self.distro.append('1', 'Ubuntu 20.04')
        self.distro.append('2', 'Linux Mint 19.3')
        self.distro.set_active(0)
        column.add(box)

        box = self.FieldBox('Identification')
        self.username  = box.entry('Username')
        self.password  = box.entry('Password')
        self.password.set_visibility(False)
        self.password2 = box.entry('Password, again')
        self.password2.set_visibility(False)
        self.full_name = box.entry('Full Name')
        self.hostname  = box.entry('Computer Name')
        column.add(box)

        box = self.ButtonBox()
        box.field(Gtk.LinkButton(uri='https://www.gnu.org/licenses/gpl-3.0.en.html#section15', label='Read GNU GPL v3 license'))
        box.field(Gtk.CheckButton.new_with_label("I have read the GNU GPL v3 license\nand agree to its terms."))
        column.add(box)

        self.fieldPage = column
        self.stack.add(column)

        column = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        box = self.FieldBox('C: Drive')
        box.field('Total Size', Gtk.Label(label='40GB'))
        box.field('Used by Windows', Gtk.Label(label='16GB'))
        box.field('Free', Gtk.Label(label='24GB'))
        box.field('Available', Gtk.Label(label='24GB'))
        box.field('Linux Size', Gtk.Entry())
        column.add(box)

        box = self.ButtonBox()
        box.button('Clean')
        box.button('Disk Use')
        box.button('Partitions')
        box.button('Disable Swap')
        box.button('Defrag')
        column.add(box)

        self.diskPage = column
        self.stack.add(column)

        column = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        box = self.FieldBox('Progress')
        box.field('Repartion', Gtk.ProgressBar(fraction = 1.0))
        box.field('Download', Gtk.ProgressBar(fraction = 0.4))
        box.field('Install Grub', Gtk.ProgressBar(fraction = 0.0))
        column.add(box)

        self.progressPage = column
        self.stack.add(column)

        outer.add(self.stack)

        box = self.ButtonBox()
        quit = box.button('Quit')
        self.cont = box.button('Continue')
        outer.add(box)

        self.add(outer)

        #TODO: move to presenter
        self.connect("destroy", self.on_quit)
        quit.connect('clicked', self.on_quit)

    def set_presenter(self, presenter):
        self.presenter = presenter

    def init(self):
        self.cont.connect('clicked', self.on_continue_click)
        self.show_all()

    def close(self):
        Gtk.main_quit(self, self)

    def warn(self, message):
        dialog = Gtk.MessageDialog(
            parent = self,
            flags = 0,
            message_type = Gtk.MessageType.WARNING,
            buttons = Gtk.ButtonsType.OK,
            text = message)
        dialog.run()
        dialog.destroy()

    def error(self, message):
        dialog = Gtk.MessageDialog(
            parent = self,
            flags = 0,
            message_type = Gtk.MessageType.ERROR,
            buttons = Gtk.ButtonsType.OK,
            text = message)
        dialog.run()
        dialog.destroy()

    def on_quit(self, widget):
        presenter.on_quit()

    def on_continue_click(self, widget):
        if self.stack.get_visible_child() == self.fieldPage:
            self.stack.set_visible_child(self.diskPage)
        else:
            self.stack.set_visible_child(self.progressPage)
            self.cont.set_visible(False)

    def set_system_info(self, system_info):
        self.username.set_text(system_info['username'])
        self.hostname.set_text(system_info['hostname'])
        self.full_name.set_text(system_info['full_name'])

# OS specific functionality
class LinuxSystem:

    # Must be checked before get_system_info
    def is_admin(self):
        return os.geteuid() == 0

    def get_system_info(self):
        uid = int(os.getenv('SUDO_UID'))
        return {
            'username':     pwd.getpwuid( uid ).pw_name,
            'full_name':    pwd.getpwuid( uid ).pw_gecos.split(',')[0],
            'hostname':     platform.node(),
            'memory':       psutil.virtual_memory().total,
            'on_battery':   not psutil.sensors_battery().power_plugged,
            'architecture': platform.machine(),
            # These are the only os-specific iems
            'timezone':     '/'.join(os.path.realpath('/etc/localtime').split('/')[-2:]),
            'is_efi':       os.path.isdir('/sys/firmware/efi'),
        }

    # Separate from system_info as it can change.
    def get_disk_info(self):
        usage = psutil.disk_usage('/')
        return {
            'size':      usage.total,
            'used':      usage.used,
            'free':      usage.free,
            'available': usage.free,
        }

    # Checks for conditions specific to current OS.
    # Throws exception if Tunic not compatible.
    def special_checks(self):
        # updates, update pending boot
        print('Not implemented')

    def reboot(self):
        os.system('shutdown -r now')

    def grub_install(self, efi_directory):
        os.system("grub-install --boot-directory /boot --efi-directory /boot/{}".efi_directory)

    def resize_partition(self, size):
        print('Not implemented')

    # Buttons available to reduce disk usage
    # for use from dual boot disk page.
    # Can be dynamic as buttons are refreshed after use.
    # Example: Disable/Enable Swap.
    # Returns an array.  Even items are names, odd are functions
    def get_disk_utilities(self):
        return ()

# View logic.
# No app logic should go here.
class Presenter:
    def __init__(self, view, system):
        self.view = view
        self.system = system

    # Load system values
    def init(self):
        view.set_presenter(self)
        view.set_sensitive(False)
        try:
            view.init()
            if not self.system.is_admin():
                self.die('Must be run as administator')
            system_info = self.system.get_system_info()
            view.set_system_info(system_info)
            self.checks(system_info)
        finally:
            view.set_sensitive(True)

    def die(self, message):
        view.error(message)
        sys.exit(1)

    def checks(self, system_info):
        if system_info['on_battery']:
            view.warn('It is not safe to run on battery')

    def on_quit(self):
        view.close()

if len(sys.argv) == 1:
    view = MainWindow()
    presenter = Presenter(view, LinuxSystem())
    view.set_presenter(presenter)
    presenter.init()
    Gtk.main()
else:
    if sys.argv[1] == 'noop':
        print('noop')

