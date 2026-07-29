pragma Singleton
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property bool hasPlasmaBrowserIntegration:
        Mpris.players.values.some(player =>
            player.dbusName?.startsWith(
                "org.mpris.MediaPlayer2.plasma-browser-integration"))

    readonly property list<MprisPlayer> realPlayers:
        Mpris.players.values.filter(player => root.isRealPlayer(player))
    readonly property list<MprisPlayer> players:
        filterDuplicatePlayers(realPlayers)

    property MprisPlayer activePlayer: null

    readonly property bool available:
        activePlayer !== null && players.length > 0
    readonly property bool isPlaying:
        activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property real progress: ratioFor(activePlayer)

    function isRealPlayer(player) {
        if (!player)
            return false;

        const name = player.dbusName || "";
        if (name.startsWith("org.mpris.MediaPlayer2.playerctld"))
            return false;
        if (name.endsWith(".mpd")
                && !name.endsWith("MediaPlayer2.mpd"))
            return false;
        if (hasPlasmaBrowserIntegration
                && (name.startsWith("org.mpris.MediaPlayer2.firefox")
                    || name.startsWith(
                        "org.mpris.MediaPlayer2.chromium")))
            return false;
        return true;
    }

    function filterDuplicatePlayers(sourcePlayers) {
        const filtered = [];
        const used = new Set();

        for (let index = 0; index < sourcePlayers.length; index++) {
            if (used.has(index))
                continue;

            const first = sourcePlayers[index];
            const group = [index];
            for (let candidateIndex = index + 1;
                    candidateIndex < sourcePlayers.length;
                    candidateIndex++) {
                const candidate = sourcePlayers[candidateIndex];
                const firstTitle = String(first.trackTitle || "");
                const candidateTitle = String(candidate.trackTitle || "");
                const matchingTitle = firstTitle && candidateTitle
                    && (firstTitle.includes(candidateTitle)
                        || candidateTitle.includes(firstTitle));
                const matchingTiming = first.length > 0
                    && candidate.length > 0
                    && Math.abs(first.position - candidate.position) <= 2
                    && Math.abs(first.length - candidate.length) <= 2;
                if (matchingTitle || matchingTiming)
                    group.push(candidateIndex);
            }

            let selectedIndex = group.find(candidateIndex => {
                const player = sourcePlayers[candidateIndex];
                return String(player.trackArtUrl || "").length > 0;
            });
            if (selectedIndex === undefined)
                selectedIndex = group[0];

            filtered.push(sourcePlayers[selectedIndex]);
            for (const usedIndex of group)
                used.add(usedIndex);
        }

        return filtered;
    }

    function resolveActivePlayer() {
        const playing = players.find(player => player.isPlaying);
        if (playing) {
            activePlayer = playing;
            return;
        }

        if (activePlayer && players.indexOf(activePlayer) >= 0)
            return;

        activePlayer = players.find(player => player.canControl)
            || players[0] || null;
    }

    function setActivePlayer(player) {
        if (player && players.indexOf(player) >= 0)
            activePlayer = player;
    }

    function togglePlaying(player) {
        const target = player || activePlayer;
        if (target?.canTogglePlaying)
            target.togglePlaying();
    }

    function previous(player) {
        const target = player || activePlayer;
        if (target?.canGoPrevious)
            target.previous();
    }

    function next(player) {
        const target = player || activePlayer;
        if (target?.canGoNext)
            target.next();
    }

    function ratioFor(player) {
        if (!player || !player.lengthSupported || player.length <= 0)
            return 0;
        return Math.max(0, Math.min(1,
            (player.position || 0) / player.length));
    }

    function cleanTitle(title) {
        let value = String(title || "").trim();
        if (!value)
            return "";
        value = value.replace(/\s*[-–—]\s*YouTube\s*$/i, "");
        value = value.replace(
            /\s*[\[(](official (video|audio|music video)|lyrics?)[\])]\s*$/i,
            "");
        return value.trim();
    }

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0));
        const hours = Math.floor(value / 3600);
        const minutes = Math.floor((value % 3600) / 60);
        const remaining = value % 60;
        const paddedSeconds = String(remaining).padStart(2, "0");
        if (hours > 0)
            return hours + ":" + String(minutes).padStart(2, "0")
                + ":" + paddedSeconds;
        return minutes + ":" + paddedSeconds;
    }

    function artSource(player) {
        const value = String(player?.trackArtUrl || "");
        if (!value)
            return "";
        if (/^[a-z][a-z0-9+.-]*:/i.test(value))
            return value;
        return "file://" + value;
    }

    onPlayersChanged: Qt.callLater(resolveActivePlayer)
    Component.onCompleted: resolveActivePlayer()

    Instantiator {
        model: root.players

        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                if (!root.activePlayer || modelData.isPlaying)
                    root.activePlayer = modelData;
            }

            Component.onDestruction:
                Qt.callLater(root.resolveActivePlayer)

            function onPlaybackStateChanged() {
                if (modelData.isPlaying)
                    root.activePlayer = modelData;
                else
                    Qt.callLater(root.resolveActivePlayer);
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: root.activePlayer?.positionChanged()
    }

    IpcHandler {
        target: "media"

        function playPause(): void {
            root.togglePlaying(root.activePlayer);
        }

        function previous(): void {
            root.previous(root.activePlayer);
        }

        function next(): void {
            root.next(root.activePlayer);
        }

        function pauseAll(): void {
            for (const player of root.realPlayers) {
                if (player.canPause)
                    player.pause();
            }
        }
    }
}
