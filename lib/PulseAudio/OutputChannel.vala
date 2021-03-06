/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * OutputChannel.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

internal class Hottoe.PulseAudio.OutputChannel : Channel {
    private bool m_is_muted;
    private double m_base_volume;

    public override double volume {
        get {
            return cvolume != null ? Channel.volume_to_double (cvolume.max ()) : 0.0;
        }
        set {
            global::PulseAudio.CVolume? cvol = cvolume;
            if (cvol != null) {
                cvol.scale (Channel.double_to_volume (value));
                ((Manager) manager).operations.set_sink_volume_by_index (index, cvol);
            }
        }
    }

    public override float balance {
        get {
            return cvolume != null && channel_map != null ? cvolume.get_balance (channel_map) : 0.5f;
        }
        set {
            global::PulseAudio.CVolume? cvol = cvolume;
            if (cvol != null && channel_map != null) {
                cvol.set_balance (channel_map, value);
                ((Manager) manager).operations.set_sink_volume_by_index (index, cvol);
            }
        }
    }

    public override bool is_muted {
        get {
            return m_is_muted;
        }
        set {
            m_is_muted = value;
            ((Manager) manager).operations.set_sink_mute_by_index (index, m_is_muted);
        }
    }

    public override double volume_base {
        get {
            return m_base_volume;
        }
    }

    public override double volume_max {
        get {
            return volume_to_double (global::PulseAudio.Volume.UI_MAX);
        }
    }

    [CCode (notify = false)]
    public override unowned Hottoe.Port? port {
        get {
            return m_active_port;
        }
        set {
            if (m_active_port != value) {
                if (value != null) {
                    ((Manager)manager).operations.set_sink_port_by_index (index, m_active_port.name, (s) => {
                        if (s) {
                            if (m_active_port != null) {
                                m_active_port.weak_unref (on_active_port_destroyed);
                            }
                            m_active_port = (Port)value;
                            m_active_port.weak_ref (on_active_port_destroyed);
                            device = (Device)m_active_port.device;
                            notify_property ("port");
                        }
                    });
                } else if (m_active_port != null) {
                    m_active_port.weak_unref (on_active_port_destroyed);
                    m_active_port = null;
                    device = null;
                    notify_property ("port");
                }
            }
        }
    }

    public OutputChannel (Manager in_manager, global::PulseAudio.SinkInfo in_sink_info) {
        GLib.Object (
            manager: in_manager,
            direction: Hottoe.Direction.OUTPUT,
            index: in_sink_info.index,
            id: in_sink_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_ID),
            monitor_index: in_sink_info.monitor_source,
            name: in_sink_info.name,
            description: in_sink_info.description
        );

        update (in_sink_info);
    }

    ~OutputChannel () {
        if (m_active_port != null) {
            m_active_port.weak_unref (on_active_port_destroyed);
            m_active_port = null;
        }
    }

    public bool update (global::PulseAudio.SinkInfo in_sink_info) {
        bool updated = false;

        if (in_sink_info.active_port != null &&
            (m_active_port == null || m_active_port.name != in_sink_info.active_port.name)) {
            bool foundPort = false;
            foreach (var dev in manager.get_devices ()) {
                foreach (var port in dev.get_output_ports ()) {
                    if (port.name == in_sink_info.active_port.name) {
                        if (m_active_port != null) {
                            m_active_port.weak_unref (on_active_port_destroyed);
                        }
                        m_active_port = (Port)port;
                        m_active_port.weak_ref (on_active_port_destroyed);
                        device = (Device)m_active_port.device;
                        notify_property ("port");
                        updated = true;
                        foundPort = true;
                        break;
                    }
                }
                if (foundPort) break;
            }

            if (!foundPort && m_active_port != null) {
                m_active_port.weak_unref (on_active_port_destroyed);
                m_active_port = null;
                device = null;
                notify_property ("port");
            }
        }

        bool send_volume_update = (cvolume == null ||
                                   volume != Channel.volume_to_double (in_sink_info.volume.max ()));
        cvolume = in_sink_info.volume;
        if (send_volume_update) {
            notify_property ("volume");
            notify_property ("balance");
            updated = true;
        }

        bool send_balance_update = (cvolume == null ||
                                    channel_map == null ||
                                    balance != in_sink_info.volume.get_balance (in_sink_info.channel_map));
        channel_map = in_sink_info.channel_map;
        if (send_balance_update) {
            notify_property ("balance");
            updated = true;
        }

        if (in_sink_info.mute != m_is_muted) {
            m_is_muted = in_sink_info.mute;
            notify_property ("is-muted");
            updated = true;
        }

        if (m_base_volume != in_sink_info.base_volume) {
            m_base_volume = Channel.volume_to_double (in_sink_info.base_volume);
            notify_property ("volume-base");
        }

        if (updated) {
            changed ();
        }

        return updated;
    }

    private void on_active_port_destroyed () {
        m_active_port = null;
        notify_property ("port");
    }
}
