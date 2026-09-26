// Wolf Welcome: pick a security level (runs `wolf level` through pkexec).
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.welcome as Welcome

Welcome.Page {
    id: page

    property string level: ""
    property string status: ""

    heading: "Pick your security level"
    description: "You can change this any time from the wolf icon next to the clock, or with: wolf level"

    function refresh() {
        Welcome.Controller.runCommand("/usr/bin/wolf state", (code, output) => {
            const match = output.match(/^level=(.*)$/m);
            if (match) page.level = match[1];
        });
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, Kirigami.Units.gridUnit * 34)
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: [
                ["gaming", "Gaming", "input-gaming", "For playing a lot: Steam Remote Play and LAN transfers always work at home, and a SteamOS fix for stutter in some games."],
                ["wolf", "Wolf (recommended)", "wolf-os-logo", "The everyday default. Every protection in Wolf OS, nothing that gets in your way."],
                ["sheep", "Sheep", "security-high", "Maximum caution for travel and public places: encrypted DNS, invisible to pings, new USB devices blocked. Wi-Fi login pages (hotels, airports) won't load."]
            ]
            delegate: QQC2.Button {
                required property var modelData
                Layout.fillWidth: true
                checkable: false
                highlighted: page.level === modelData[0]
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        source: modelData[2]
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Kirigami.Heading {
                            text: modelData[1] + (page.level === modelData[0] ? "  ✔" : "")
                            level: 4
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: modelData[3]
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                onClicked: {
                    if (page.level === modelData[0]) return;
                    page.status = "Switching…";
                    Welcome.Controller.runCommand("pkexec /usr/bin/wolf level " + modelData[0] + " --yes", (code, output) => {
                        page.status = code === 0 ? "" : (code === 126 || code === 127 ? "Cancelled: no password given." : output.trim().split("\n").pop());
                        page.refresh();
                    });
                }
            }
        }

        QQC2.Label {
            visible: page.status !== ""
            Layout.fillWidth: true
            text: page.status
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
