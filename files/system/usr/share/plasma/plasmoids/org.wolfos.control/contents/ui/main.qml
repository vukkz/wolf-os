/*
 * Wolf OS panel widget: the wolf icon next to the clock.
 * Shows and changes the security level, network trust and Game Mode by running
 * the `wolf` command. Changes go through pkexec, which asks for your password.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string wolf: "/usr/bin/wolf"

    property string level: ""
    property string net: ""
    property string netName: ""
    property bool gameOn: false
    property string score: ""
    property bool busy: false
    property string error: ""
    property bool confirmSheep: false

    readonly property var levelInfo: ({
        gaming: "Steam Remote Play/LAN ports stay open at home, no split-lock slowdown.",
        wolf: "The default: everything in Wolf OS's security baseline.",
        sheep: "Maximum caution: encrypted DNS, invisible to pings, USBGuard on."
    })

    Plasmoid.icon: "wolf-os-logo"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: "Wolf OS"
    toolTipSubText: level === "" ? "" : "Level: " + level + "  ·  Network: " + net + (gameOn ? "  ·  Game Mode on" : "")

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            root.finished(sourceName, data["exit code"], data["stdout"], data["stderr"]);
        }
    }

    // A unique comment on the end lets the same command run again while an earlier one is still open
    function run(command) {
        executable.connectSource(command + " # " + Date.now());
    }
    function refresh() {
        run(wolf + " state");
    }
    function act(args) {
        busy = true;
        error = "";
        run("pkexec " + wolf + " " + args);
    }
    function openInTerminal(args) {
        run("konsole --hold -e " + wolf + " " + args);
    }

    function finished(source, code, stdout, stderr) {
        if (source.startsWith(wolf + " state")) {
            for (const line of stdout.split("\n")) {
                const i = line.indexOf("=");
                if (i < 0) continue;
                const key = line.slice(0, i);
                const value = line.slice(i + 1);
                if (key === "level") level = value;
                else if (key === "net") net = value;
                else if (key === "net_name") netName = value;
                else if (key === "game") gameOn = value === "on";
                else if (key === "score") score = value;
            }
            return;
        }
        if (source.startsWith("pkexec")) {
            busy = false;
            if (code === 126 || code === 127) error = "Cancelled: no password given.";
            else if (code !== 0) error = (stderr || stdout).trim().split("\n").pop();
            refresh();
        }
    }

    onExpandedChanged: if (expanded) refresh()

    Timer {
        interval: 300000 // 5 minutes; it also refreshes whenever you open it
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        spacing: Kirigami.Units.smallSpacing

        // --- Header -----------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                source: "wolf-os-logo"
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
            Kirigami.Heading {
                text: "Wolf OS"
                level: 3
                Layout.fillWidth: true
            }
            PlasmaComponents3.Label {
                text: root.score ? "Security " + root.score : ""
                opacity: 0.8
            }
            PlasmaComponents3.BusyIndicator {
                visible: root.busy
                running: root.busy
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // --- Security level -----------------------------------------------------------
        PlasmaComponents3.Label {
            text: "Security level"
            font.bold: true
        }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: [["gaming", "Gaming"], ["wolf", "Wolf"], ["sheep", "Sheep"]]
                delegate: PlasmaComponents3.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData[1]
                    icon.name: root.level === modelData[0] ? "checkmark" : ""
                    flat: root.level !== modelData[0]
                    enabled: !root.busy
                    onClicked: {
                        if (modelData[0] === root.level) return;
                        if (modelData[0] === "sheep") root.confirmSheep = true;
                        else root.act("level " + modelData[0]);
                    }
                }
            }
        }
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: root.levelInfo[root.level] || ""
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }

        // Sheep breaks Wi-Fi login pages, so ask first
        ColumnLayout {
            visible: root.confirmSheep
            Layout.fillWidth: true
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: "Sheep blocks Wi-Fi login pages (hotels, airports) and new USB devices. Switch to it?"
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.neutralTextColor
            }
            RowLayout {
                PlasmaComponents3.Button {
                    text: "Switch to Sheep"
                    onClicked: {
                        root.confirmSheep = false;
                        root.act("level sheep --yes");
                    }
                }
                PlasmaComponents3.Button {
                    text: "Cancel"
                    flat: true
                    onClicked: root.confirmSheep = false
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // --- Network trust ------------------------------------------------------------
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: root.net === "offline" ? "Not connected" : "This network: " + root.netName
            font.bold: true
            elide: Text.ElideRight
        }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: [["home", "Home (trusted)"], ["public", "Public (invisible)"]]
                delegate: PlasmaComponents3.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData[1]
                    icon.name: root.net === modelData[0] ? "checkmark" : ""
                    flat: root.net !== modelData[0]
                    enabled: !root.busy && root.net !== "offline"
                    onClicked: if (modelData[0] !== root.net) root.act("net " + modelData[0])
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // --- Game Mode ----------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents3.Label {
                    text: "Game Mode"
                    font.bold: true
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: "Remote Play ports, updates paused, performance power"
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }
            }
            PlasmaComponents3.Switch {
                checked: root.gameOn
                enabled: !root.busy
                onToggled: {
                    root.act(checked ? "game on" : "game off");
                    checked = Qt.binding(() => root.gameOn); // follow the real state once it's refreshed
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // --- Shortcuts ------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents3.Button {
                Layout.fillWidth: true
                text: "Security check"
                icon.name: "security-high"
                onClicked: root.openInTerminal("check")
            }
            PlasmaComponents3.Button {
                Layout.fillWidth: true
                text: "Open the Lab"
                icon.name: "utilities-terminal"
                onClicked: root.run("konsole -e " + root.wolf + " lab")
            }
        }

        PlasmaComponents3.Label {
            visible: root.error !== ""
            Layout.fillWidth: true
            text: root.error
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.negativeTextColor
        }
    }
}
