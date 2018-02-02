/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * ChannelView.vala
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class PantheonSoundControl.Widgets.ChannelView : Gtk.Grid {
    private Gtk.Scale m_Volume;
    private Gtk.Scale m_Balance;
    private bool m_Init;

    public unowned Channel channel { get; construct; }
    public Icon.Size icon_size { get; set; default = Icon.Size.LARGE; }
    public bool show_labels { get; set; default = false; }
    public bool show_balance { get; set; default = false; }
    public double monitor_nb_bars { get; set; default = 8.0; }

    construct {
        m_Init = true;

        hexpand = true;
        row_spacing = 6;

        var image_box = new Gtk.EventBox ();
        var image = new PortIcon (channel.port, Icon.Size.EXTRA_LARGE);
        image_box.halign = Gtk.Align.START;
        image_box.valign = Gtk.Align.START;
        image_box.add (image);

        attach (image_box, 0, 0, 1, 3);

        m_Volume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, channel.volume_muted, channel.volume_max, (channel.volume_max - channel.volume_muted) / 20.0);
        m_Volume.adjustment.page_increment = 5;
        m_Volume.adjustment.value = channel.volume;
        m_Volume.margin_start = 6;
        m_Volume.set_size_request (200, -1);
        m_Volume.draw_value = false;
        m_Volume.hexpand = true;
        attach (m_Volume, 1, 0, 1, 1);

        if (channel.direction == Direction.OUTPUT) {
            m_Balance = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -1.0, 1.0, 0.1);
            m_Balance.margin_start = 6;
            m_Balance.margin_end = 12;
            m_Balance.margin_bottom = 6;
            m_Balance.no_show_all = true;
            m_Balance.adjustment.page_increment = 0.1;
            m_Balance.set_size_request (200, -1);
            m_Balance.draw_value = false;
            m_Balance.has_origin = false;
            m_Balance.hexpand = true;

            m_Balance.add_mark (-1, Gtk.PositionType.BOTTOM, _("Left"));
            m_Balance.add_mark (0, Gtk.PositionType.BOTTOM, _("Center"));
            m_Balance.add_mark (1, Gtk.PositionType.BOTTOM, _("Right"));

            attach (m_Balance, 1, 1, 2, 1);
        }

        var switch_widget = new Gtk.Switch ();
        switch_widget.active = true;
        switch_widget.valign = Gtk.Align.START;
        switch_widget.margin_start = 6;
        switch_widget.margin_end = 12;
        attach (switch_widget, 2, 0, 1, 1);

        var volume_progressbar = new VolumeMeter (channel);
        volume_progressbar.margin_start = 6;
        volume_progressbar.margin_end = 24;
        attach (volume_progressbar, 1, 2, 2, 1);

        get_style_context ().add_class ("indicator-switch");

        add_events (Gdk.EventMask.SCROLL_MASK);
        image_box.add_events (Gdk.EventMask.SCROLL_MASK);
        switch_widget.add_events (Gdk.EventMask.SCROLL_MASK);

        // delegate all scroll events to the scale
        scroll_event.connect (on_scroll);
        image_box.scroll_event.connect (on_scroll);
        switch_widget.scroll_event.connect (on_scroll);

        switch_widget.bind_property ("active", m_Volume, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switch_widget.bind_property ("active", image, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switch_widget.bind_property ("active", volume_progressbar, "sensitive", GLib.BindingFlags.SYNC_CREATE);

        channel.bind_property ("port", image, "port");

        channel.bind_property ("volume", m_Volume.adjustment, "value", GLib.BindingFlags.BIDIRECTIONAL);
        channel.bind_property ("is_muted", switch_widget, "active", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);

        bind_property("icon-size", image, "size", GLib.BindingFlags.SYNC_CREATE);
        bind_property("monitor-nb-bars", volume_progressbar, "nb-bars", GLib.BindingFlags.SYNC_CREATE);

        if (channel.direction == Direction.OUTPUT) {
            switch_widget.bind_property ("active", m_Balance, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            bind_property("show-balance", m_Balance, "visible", GLib.BindingFlags.SYNC_CREATE);
            channel.bind_property ("balance", m_Balance.adjustment, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
        }

        notify["show-labels"].connect (on_base_volume_changed);
        channel.notify["volume-base"].connect (on_base_volume_changed);
        on_base_volume_changed ();

        m_Volume.adjustment.value_changed.connect (() => {
            message(@"volume play");
            if (!m_Init) {
                var notification = new Services.SoundNotification.volume_change (channel);
                notification.send ();
            }
            m_Init = false;
        });
    }

    public ChannelView (Channel inChannel) {
        GLib.Object (
            channel: inChannel
        );
    }

    private bool on_scroll (Gdk.EventScroll event) {
        m_Volume.scroll_event (event);

        return Gdk.EVENT_STOP;
    }

    private void on_base_volume_changed () {
        m_Volume.clear_marks ();
        m_Volume.add_mark (channel.volume_muted, Gtk.PositionType.BOTTOM, show_labels ? _("0 %") : null);
        m_Volume.add_mark (channel.volume_norm, Gtk.PositionType.BOTTOM, show_labels ? _("100 %") : null);

        if (channel.volume_base > channel.volume_muted && channel.volume_base < channel.volume_norm) {
            m_Volume.add_mark (channel.volume_base, Gtk.PositionType.BOTTOM, show_labels ? _("Unamplified") : null);
        }
    }
}
