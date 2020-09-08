/*
* ShufflerII
* Author: Jacob Vlijm
* Copyright © 2017-2020 Ubuntu Budgie Developers
* Website=https://ubuntubudgie.org
* This program is free software: you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the Free
* Software Foundation, either version 3 of the License, or any later version.
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details. You should have received a copy of the GNU General Public
* License along with this program.  If not, see
* <https://www.gnu.org/licenses/>.
*/

// valac --pkg gio-2.0

/*
/ args: wm_class, xid
*/

namespace ApplyRule {

    GLib.HashTable<string, Variant> windowrules;
    GLib.HashTable<string, Variant> monitordata;
    ShufflerInfoClient? client;
    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    interface ShufflerInfoClient : Object {
        public abstract GLib.HashTable<string, Variant> get_rules () throws Error;
        public abstract GLib.HashTable<string, Variant> get_monitorgeometry () throws Error;
    }

    private bool string_inlist (string lookfor, string[] arr) {
        for (int i=0; i < arr.length; i++) {
            if (lookfor == arr[i]) {
                return true;
            }
        }
        return false;
    }

    private void run_command (string cmd) {
        try {
            Process.spawn_command_line_async(cmd);
        }
        catch (GLib.SpawnError err) {
            /*
            * in case an error occurs, the command most likely is
            * incorrect not much use for any action
            */
        }
    }

    void main (string[] args) {
        string monitor = "";
        string xposition = "";
        string yposition = "";
        string rows = "";
        string cols = "";
        string xspan = "";
        string yspan = "";
        try {
            client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon")
            );
            // get data, geo on windows
            windowrules = client.get_rules();
            GLib.List<weak string> keys = windowrules.get_keys();
            foreach (string key in keys) {
                if (args[1].down() == key.down()) {
                    // get data from fields, move window id to set position
                    Variant windowrule = windowrules[key];
                    monitor = (string)windowrule.get_child_value(0);
                    xposition = (string)windowrule.get_child_value(1);
                    yposition = (string)windowrule.get_child_value(2);
                    rows = (string)windowrule.get_child_value(3);
                    cols = (string)windowrule.get_child_value(4);
                    xspan = (string)windowrule.get_child_value(5);
                    yspan = (string)windowrule.get_child_value(6);
                    // see if monitor arg is valid (monitor connected)
                    string[] found_monitors = {};
                    monitordata = client.get_monitorgeometry ();
                    foreach (string k in monitordata.get_keys()) {
                        found_monitors += k;
                    }
                    // if not connected, ignore argument
                    if (string_inlist(monitor, found_monitors)) {
                        monitor = @"monitor=$monitor";
                    }
                    // produce position arguments
                    // if position is not set properly, fallback to center
                    string[] position_essentials = {xposition, yposition, rows, cols};
                    foreach (string s in position_essentials) {
                        if (s == "") {
                            xposition = "1";
                            yposition = "1";
                            rows = "4";
                            cols = "4";
                            xspan = "2";
                            yspan = "2";
                            break;
                        }
                    }
                    string w_id = args[2];
                    // use .Config dir below
                    string cmd = "/usr/lib/budgie-window-shuffler/tile_active ".concat(
                        @"$xposition $yposition $cols $rows $xspan $yspan id=$w_id windowrule $monitor"
                    );
                    run_command(cmd);
                }
            }
        }
        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }
}