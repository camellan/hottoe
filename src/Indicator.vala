/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Indicator.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class PantheonSoundControl.Indicator : Wingpanel.Indicator {
    private Manager m_Manager;
    private Widgets.DisplayWidget? m_IndicatorIcon;
    private Widgets.MainView m_MainView;
    private uint m_TimeoutActive;

    construct {
        m_Manager = Manager.get ("pulseaudio");
    }

    public Indicator (Wingpanel.IndicatorManager.ServerType inServerType) {
        // very ugly hack when set code name to set position of indicator before
        // sound indicator since they are sorted by name and type name
        Object (code_name: Wingpanel.Indicator.SYNC,
                display_name: _("Sound Devices"),
                description: _("The Sound Devices indicator"));
    }

    public override Gtk.Widget get_display_widget () {
        if (m_IndicatorIcon == null) {
            m_IndicatorIcon = new Widgets.DisplayWidget (m_Manager);

            m_Manager.start ();
        }

        return m_IndicatorIcon;
    }

    public override Gtk.Widget? get_widget () {
        if (m_MainView == null) {
            m_MainView = new Widgets.MainView (m_Manager);
        }

        visible = true;

        return m_MainView;
    }

    public override void opened () {
        if (m_Manager != null) {
            if (m_TimeoutActive != 0) {
                GLib.Source.remove (m_TimeoutActive);
                m_TimeoutActive = 0;
            }
            m_Manager.enable_monitoring = true;
        }
    }

    public override void closed () {
        if (m_Manager != null) {
            if (m_TimeoutActive != 0) {
                GLib.Source.remove (m_TimeoutActive);
                m_TimeoutActive = 0;
            }

            m_TimeoutActive = GLib.Timeout.add_seconds (2, ()=> {
                m_Manager.enable_monitoring = false;

                return true;
            });
        }
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType inServerType) {
    debug ("Activating Sound Devices Indicator");

    if (inServerType != Wingpanel.IndicatorManager.ServerType.SESSION) {
        debug ("Wingpanel is not in session, not loading chat");
        return null;
    }

    var indicator = new PantheonSoundControl.Indicator (inServerType);
    return indicator;
}

