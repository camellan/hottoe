wingpanel_dep = dependency('wingpanel-2.0')
switchboard_dep = dependency('switchboard-2.0')

indicatorsdir = wingpanel_dep.get_pkgconfig_variable(
    'indicatorsdir',
    default: join_paths(get_option('prefix'), get_option('libdir'), 'wingpanel')
)
plugsdir = switchboard_dep.get_pkgconfig_variable(
    'plugsdir',
    default: join_paths(get_option('prefix'), get_option('libdir'), 'switchboard')
)

libhottoe_widgets = static_library (
    meson.project_name() + '.widgets',
    [
        'Widgets/MaxWidthLabel.vala',
        'Widgets/Icon.vala',
        'Widgets/PortIcon.vala',
        'Widgets/DeviceIcon.vala',
        'Widgets/ClientIcon.vala',
        'Widgets/ChannelView.vala',
        'Widgets/VuMeter.vala',
        'Widgets/Spectrum.vala',
        'Widgets/DeviceChannelList.vala',
        'Services/Notification.vala',
        'Services/SoundNotification.vala',
        'Services/DesktopNotification.vala',
        'Settings/Equalizer.vala'
    ],
    dependencies: [
        hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libcanberra'),
        dependency('libcanberra-gtk'),
        dependency('libwnck-3.0')
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: false
)

shared_module(
    meson.project_name() + '.indicator',
    [
        'Indicator.vala',
        'Widgets/IndicatorIcon.vala',
        'Widgets/IndicatorView.vala',
        'Widgets/ClientView.vala',
        'Widgets/ClientList.vala',
        'Widgets/PlugChannelList.vala',
        'Widgets/ChannelRadioButton.vala',
        'Widgets/DeviceView.vala',
        'Widgets/DeviceList.vala',
        'Services/EqualizerManager.vala'
    ],
    dependencies: [
        hottoe_dep,
        wingpanel_dep,
        dependency('granite'),
        dependency('libwnck-3.0')
    ],
    link_with: [
        libhottoe_widgets
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : indicatorsdir
)

shared_module(
    meson.project_name() + '.plug',
    [
        'SwitchboardPlug.vala',
        'Widgets/Equalizer.vala',
        'Widgets/DeviceSettingsView.vala',
        'Widgets/DeviceSettingsPage.vala',
        'Widgets/DeviceSettingsListRow.vala',
        'Widgets/DeviceSettingsList.vala',
        'Widgets/PlugSettingsRow.vala',
        'Widgets/PlugSettingsList.vala',
        'Widgets/PlugChooser.vala',
        'Widgets/PlugChooserRow.vala'
    ],
    dependencies: [
        hottoe_dep,
        switchboard_dep,
        dependency('granite'),
        dependency('libwnck-3.0')
    ],
    link_with: [
        libhottoe_widgets
    ],
    c_args: [ '-DWNCK_I_KNOW_THIS_IS_UNSTABLE' ],
    install: true,
    install_dir : join_paths(plugsdir, 'hardware')
)
