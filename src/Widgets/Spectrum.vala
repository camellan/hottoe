/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Spectrum.vala
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

public class Hottoe.Widgets.Spectrum : Gtk.Table {
    private class Meter : Gtk.DrawingArea {
        private unowned Spectrum m_spectrum;
        private int m_band;
        private double m_max;

        construct {
            width_request = 8;
            hexpand = true;
            vexpand = true;
        }

        public Meter (Spectrum in_spectrum, int in_band) {
            m_spectrum = in_spectrum;
            m_band = in_band;
        }

        public override bool draw (Cairo.Context in_ctx) {
            int width = get_allocated_width ();
            int height = get_allocated_height ();

            var gradient = new Cairo.Pattern.linear (0, height, 0, 0);
            gradient.add_color_stop_rgb (0.0,
                                         (double)0x68/(double)0xff,
                                         (double)0xb7/(double)0xff,
                                         (double)0x23/(double)0xff);

            gradient.add_color_stop_rgb (m_spectrum.iec_scale(-10),
                                         (double)0xd4/(double)0xff,
                                         (double)0x8e/(double)0xff,
                                         (double)0x15/(double)0xff);

            gradient.add_color_stop_rgb (m_spectrum.iec_scale(-5),
                                         (double)0xc6/(double)0xff,
                                         (double)0x26/(double)0xff,
                                         (double)0x2e/(double)0xff);

            double gain = m_spectrum[m_band];

            in_ctx.set_source (gradient);
            in_ctx.rectangle (0, height - height * gain, width, height * gain);
            in_ctx.fill();

            if (gain >= m_max) {
                m_max = gain;
            } else {
                double pos = (double)height * m_max;
                pos -= 4.0;
                m_max = double.max(0.0, pos / (double)height);
            }

            in_ctx.rectangle (0, height - height * m_max, width, 4.0);
            in_ctx.fill ();

            return true;
        }
    }

    private Hottoe.Spectrum m_spectrum;
    private double[] m_magnitudes;

    public unowned Device device { get; construct; }
    public int interval { get; construct; default = 50; }
    public bool enabled { get; set; default = true; }
    public int nb_bars { get; set; default = 10; }
    public int nb_bands { get; set; default = 30; }
    public double smoothing { get; set; default = 0.00007; }

    construct {
        column_spacing = 6;
        homogeneous = true;

        on_nb_bands_changed ();

        device.manager.channel_added.connect (on_channel_added);

        foreach (var channel in device.get_output_channels ()) {
            on_channel_added (device.manager, channel);
        }

        notify["nb-bands"].connect (on_nb_bands_changed);
    }

    public Spectrum (Device in_device, int in_interval) {
        GLib.Object (
            device: in_device,
            interval: in_interval
        );
    }

    private void on_nb_bands_changed () {
        // Remove all old band meter
        get_children ().foreach ((child) => {
            child.destroy ();
        });

        // Create new magnitudes array
        m_magnitudes = new double[nb_bands];

        // Add all band meter
        for (int cpt = 0; cpt < nb_bands; ++cpt) {
            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.add (new Meter (this, cpt));
            //  double freq =  ((32000.0 / 2.0) * cpt + 32000.0 / 4.0) / nb_bands;
            //  var str = "<span size='x-small'>%0.2g</span>".printf(freq / 1000.0);
            //  var label = new Gtk.Label (str);
            //  label.use_markup = true;
            //  grid.add (label);
            attach (grid, cpt, cpt + 1, 0, 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
        }
    }

    private void on_channel_added (Hottoe.Manager in_manager, Hottoe.Channel in_channel) {
        if (m_spectrum == null && in_channel.direction == Direction.OUTPUT && in_channel in device) {
            m_spectrum = in_manager.create_spectrum (in_channel, 32000, interval);
            m_spectrum.threshold = -70;
            m_spectrum.bands = nb_bands;
            m_spectrum.updated.connect (on_spectrum_updated);
            bind_property ("enabled", m_spectrum, "enabled", GLib.BindingFlags.SYNC_CREATE);
        }
    }

    private void on_spectrum_updated () {
        float[] magnitudes = m_spectrum.get_magnitudes ();
        bool updated = false;

        for (int band = 0; band < nb_bands; ++band) {
            double val = magnitudes[band];

            if (m_magnitudes[band] != val) {
                m_magnitudes[band] = val;
                updated = true;
            }
        }

        //if (updated) {
            queue_draw ();
        //}
    }

    private double
    iec_scale (double inDB) {
        double def = 0.0;

        if (inDB < -70.0)
            def = 0.0;
        else if (inDB < -60.0)
            def = (inDB + 70.0) * 0.25;
        else if (inDB < -50.0)
            def = (inDB + 60.0) * 0.5 + 2.5;
        else if (inDB < -40.0)
            def = (inDB + 50.0) * 0.75 + 7.5;
        else if (inDB < -30.0)
            def = (inDB + 40.0) * 1.5 + 15.0;
        else if (inDB < -20.0)
            def = (inDB + 30.0) * 2.0 + 30.0;
        else if (inDB < 0.0)
            def = (inDB + 20.0) * 2.5 + 50.0;
        else
            def = 100.0;

        return def / 100.0;
    }

    private new double @get(int in_index)
        requires (in_index >= 0 && in_index < m_magnitudes.length) {
        return iec_scale (10.0 + m_magnitudes[in_index]);
    }
}