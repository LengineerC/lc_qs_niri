pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.common

Singleton {
    id: root

    readonly property UPowerDevice displayDevice: UPower.displayDevice
    readonly property var laptopBatteries:
        UPower.devices.values.filter(device => device.isLaptopBattery)
    readonly property UPowerDevice physicalBattery:
        laptopBatteries.find(device => device.ready) ?? displayDevice

    readonly property bool available:
        laptopBatteries.length > 0
            || (displayDevice?.isLaptopBattery ?? false)
    readonly property real percentage:
        Math.max(0, Math.min(1, displayDevice?.percentage ?? 0))
    readonly property int percent: Math.round(percentage * 100)
    readonly property int state:
        displayDevice?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging:
        state === UPowerDeviceState.Charging
            || state === UPowerDeviceState.PendingCharge
    readonly property bool fullyCharged:
        state === UPowerDeviceState.FullyCharged
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property bool low: available && percent <= 20 && !pluggedIn

    readonly property real capacityWh:
        displayDevice?.energyCapacity
            || physicalBattery?.energyCapacity || 0
    readonly property real energyWh:
        displayDevice?.energy || physicalBattery?.energy || 0
    readonly property real health: {
        if (!physicalBattery?.healthSupported)
            return 0;
        const value = physicalBattery.healthPercentage;
        return value > 0 && value <= 1 ? value * 100 : value;
    }
    readonly property bool healthAvailable:
        physicalBattery?.healthSupported ?? false

    readonly property int timeRemaining:
        charging
            ? (displayDevice?.timeToFull ?? 0)
            : (displayDevice?.timeToEmpty ?? 0)

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile:
        PowerProfiles.hasPerformanceProfile
    readonly property int degradationReason:
        PowerProfiles.degradationReason

    readonly property string statusText: {
        switch (state) {
        case UPowerDeviceState.Charging:
            return I18n.tr("charging");
        case UPowerDeviceState.Discharging:
            return I18n.tr("discharging");
        case UPowerDeviceState.Empty:
            return I18n.tr("empty");
        case UPowerDeviceState.FullyCharged:
            return I18n.tr("fullyCharged");
        case UPowerDeviceState.PendingCharge:
            return I18n.tr("pendingCharge");
        case UPowerDeviceState.PendingDischarge:
            return I18n.tr("pendingDischarge");
        default:
            return pluggedIn
                ? I18n.tr("pluggedIn") : I18n.tr("unknownStatus");
        }
    }

    readonly property string profileName: profileLabel(profile)

    function setProfile(profileValue) {
        if (profileValue === PowerProfile.Performance
                && !hasPerformanceProfile)
            return;
        PowerProfiles.profile = profileValue;
    }

    function profileLabel(profileValue) {
        switch (profileValue) {
        case PowerProfile.PowerSaver:
            return I18n.tr("powerSaver");
        case PowerProfile.Performance:
            return I18n.tr("performance");
        default:
            return I18n.tr("balanced");
        }
    }

    function profileIcon(profileValue = profile) {
        switch (profileValue) {
        case PowerProfile.PowerSaver:
            return "󰌪";
        case PowerProfile.Performance:
            return "󰓅";
        default:
            return "󰗑";
        }
    }

    function formatTime(seconds = timeRemaining) {
        if (seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (hours > 0) {
            const hourKey = hours === 1 ? "hour" : "hours";
            const minuteKey = minutes === 1 ? "minute" : "minutes";
            return hours + " " + I18n.tr(hourKey) + " "
                + minutes + " " + I18n.tr(minuteKey);
        }
        return minutes + " "
            + I18n.tr(minutes === 1 ? "minute" : "minutes");
    }

    function batteryIcon(value = percent) {
        const level = Math.max(0, Math.min(100, value));
        if (charging) {
            if (level >= 95)
                return "󰂅";
            if (level >= 85)
                return "󰂋";
            if (level >= 75)
                return "󰂊";
            if (level >= 65)
                return "󰢞";
            if (level >= 55)
                return "󰂉";
            if (level >= 45)
                return "󰢝";
            if (level >= 35)
                return "󰂈";
            if (level >= 25)
                return "󰂇";
            if (level >= 15)
                return "󰂆";
            return "󰢜";
        }
        if (level >= 95)
            return "󰁹";
        if (level >= 85)
            return "󰂂";
        if (level >= 75)
            return "󰂁";
        if (level >= 65)
            return "󰂀";
        if (level >= 55)
            return "󰁿";
        if (level >= 45)
            return "󰁾";
        if (level >= 35)
            return "󰁽";
        if (level >= 25)
            return "󰁼";
        if (level >= 15)
            return "󰁻";
        if (level >= 5)
            return "󰁺";
        return "󰂎";
    }
}
